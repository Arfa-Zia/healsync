//
//  TherapistUploadLicenseVC.swift
//  HealSync
//
//  Created by Arfa on 11/03/2026.
//

import UIKit
import FirebaseAuth
import UniformTypeIdentifiers
import FirebaseStorage
import FirebaseFirestore

class TherapistUploadLicenseVC: BaseViewController {
    
    private var selectedFileURL: URL?

    private let cardView = BaseContainer()

    private let uploadButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .light, scale: .medium)
        btn.setImage(UIImage(systemName: "square.and.arrow.up", withConfiguration: config), for: .normal)
        btn.tintColor = .black
        btn.backgroundColor = UIColor(hex: "#A2E3F1")
        btn.layer.cornerRadius = 12
        return btn
    }()

    private let fileLabel: UILabel = {
        let label = UILabel()
        label.text = "No file selected"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let titleLabel = TitleLabel(text: "UPLOAD MEDICAL LICENSE", fontSize: 18)
    
    private let descriptionLabel = SubtitleLabel(text: "Please upload your professional license or certification document (PDF, JPG, PNG)" , fontSize: 14)

    private let clickLabel: UILabel = {
        let label = UILabel()
        label.text = "Click to Upload"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private let submitButton = PrimaryButton(title: "Submit For Verification", fontSize: 16)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(hex: "#D1F0F8")

        setupUI()

        uploadButton.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        submitButton.isEnabled = false
        submitButton.alpha = 0.5
    }
    
    private func setupUI() {

        view.addSubview(cardView)

        [titleLabel, descriptionLabel, uploadButton, clickLabel, fileLabel, submitButton].forEach {
            cardView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        descriptionLabel.textColor = .gray

        cardView.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descriptionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            uploadButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 25),
            uploadButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            uploadButton.widthAnchor.constraint(equalToConstant: 80),
            uploadButton.heightAnchor.constraint(equalToConstant: 80),

            clickLabel.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 12),
            clickLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            fileLabel.topAnchor.constraint(equalTo: clickLabel.bottomAnchor, constant: 6),
            fileLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            submitButton.topAnchor.constraint(equalTo: fileLabel.bottomAnchor, constant: 30),
            submitButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 30),
            submitButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -30),
            submitButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -25)
        ])
    }
   
    @objc func submitTapped() {
        uploadLicense()
    }
    @objc func uploadTapped() {

        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                UTType.pdf,
                UTType.image
            ],
            asCopy: true
        )

        picker.delegate = self
        present(picker, animated: true)
    }
    
    func uploadLicense() {

        guard let fileURL = selectedFileURL,
              let uid = Auth.auth().currentUser?.uid else { return }

        let storage = Storage.storage(url: "gs://healsync-storage-us")

        // create a file path in storage
        _ = UUID().uuidString + "." + fileURL.pathExtension
        let storageRef = storage.reference()
            .child("licenses/\(uid)/license.\(fileURL.pathExtension)")

        storageRef.putFile(from: fileURL, metadata: nil) { metadata, error in

            if let error = error {
                print("Upload failed:", error)
                return
            }

            storageRef.downloadURL { downloadURL, error in
                guard let downloadURL = downloadURL else { return }
                self.saveLicenseURL(downloadURL.absoluteString)
            }
        }
    }
    
    func saveLicenseURL(_ url: String) {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .updateData([
                "licenseURL": url,
                "verificationStatus": "pending"
            ]) { error in

                if error == nil {
                    self.goToPendingScreen()
                }
            }
    }
    
    func goToPendingScreen() {

        let nextVC = VerificationPendingVC()
        navigationController?.setViewControllers([nextVC], animated: true)
    }
}

extension TherapistUploadLicenseVC: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {

        guard let url = urls.first else { return }

        selectedFileURL = url
        fileLabel.text = url.lastPathComponent
        
        submitButton.isEnabled = true
        submitButton.alpha = 1
    }
}

