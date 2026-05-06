//
//  DeleteAccountVC.swift
//  HealSync
//
//  Created by Arfa on 25/03/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - DeleteAccountVC
class DeleteAccountVC: UIViewController {

    private let bgColor = UIColor(hex: "#D1F0F8")
    private let db      = Firestore.firestore()

    private let backBtn = CustomBackButton()

    private let card: UIView = {
        let v = UIView()
        v.backgroundColor  = .white
        v.layer.cornerRadius = 24
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.07
        v.layer.shadowOffset  = CGSize(width: 0, height: 4)
        v.layer.shadowRadius  = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let warningIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        let iv = UIImageView(image: UIImage(systemName: "exclamationmark.triangle", withConfiguration: config))
        iv.tintColor = UIColor.systemRed
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLbl: UILabel = {
        let l = UILabel()
        l.text = "Delete Account"
        l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLbl: UILabel = {
        let l = UILabel()
        l.text = "We're sad to see you go. Deleting your account is permanent and cannot be undone. Please tell us why you're leaving:"
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .systemGray
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let feedbackView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.textColor = .systemGray
        tv.text = "Your feedback helps us improve ..."
        tv.backgroundColor = UIColor(hex: "#EEF8FB")
        tv.layer.cornerRadius = 12
        tv.layer.borderWidth  = 1
        tv.layer.borderColor  = UIColor(hex: "#C8EDF5").cgColor
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let deleteBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("YES, DELETE MY ACCOUNT", for: .normal)
        btn.setTitleColor(UIColor(hex: "#7B1C1C"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        btn.backgroundColor  = UIColor(hex: "#F5C6C6")
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let cancelBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("CANCEL", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        btn.backgroundColor  = UIColor(hex: "#4FC3D8")
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        setupLayout()
        feedbackView.delegate = self
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        deleteBtn.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
        cancelBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupLayout() {
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)
        view.addSubview(card)
        view.addSubview(activityIndicator)

        let btnStack = UIStackView(arrangedSubviews: [deleteBtn, cancelBtn])
        btnStack.axis    = .vertical
        btnStack.spacing = 12
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        [warningIcon, titleLbl, subtitleLbl, feedbackView, btnStack].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backBtn.widthAnchor.constraint(equalToConstant: 36),
            backBtn.heightAnchor.constraint(equalToConstant: 36),

            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            warningIcon.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            warningIcon.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            warningIcon.widthAnchor.constraint(equalToConstant: 50),
            warningIcon.heightAnchor.constraint(equalToConstant: 50),

            titleLbl.topAnchor.constraint(equalTo: warningIcon.bottomAnchor, constant: 12),
            titleLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            subtitleLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 12),
            subtitleLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            subtitleLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            feedbackView.topAnchor.constraint(equalTo: subtitleLbl.bottomAnchor, constant: 16),
            feedbackView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            feedbackView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            feedbackView.heightAnchor.constraint(equalToConstant: 120),

            btnStack.topAnchor.constraint(equalTo: feedbackView.bottomAnchor, constant: 20),
            btnStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            btnStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            btnStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28),

            deleteBtn.heightAnchor.constraint(equalToConstant: 48),
            cancelBtn.heightAnchor.constraint(equalToConstant: 48),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Delete Account
    @objc private func handleDelete() {
        let confirm = UIAlertController(
            title: "Are you sure?",
            message: "This action is permanent and cannot be undone. All your data will be deleted.",
            preferredStyle: .alert
        )
        confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirm.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDelete()
        })
        present(confirm, animated: true)
    }

    private func performDelete() {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid
        activityIndicator.startAnimating()
        deleteBtn.isEnabled = false
        cancelBtn.isEnabled = false

        let group = DispatchGroup()

        // 1. Delete Firestore user document + subcollections
        group.enter()
        deleteFirestoreData(uid: uid) { group.leave() }

        // 2. Delete Storage files
        group.enter()
        deleteStorageFiles(uid: uid) { group.leave() }

        group.notify(queue: .main) { [weak self] in
            // 3. Delete Auth account last
            user.delete { error in
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    if let error = error {
                        self?.deleteBtn.isEnabled = true
                        self?.cancelBtn.isEnabled = true
                        // Re-auth may be needed
                        if (error as NSError).code == AuthErrorCode.requiresRecentLogin.rawValue {
                            self?.showReauthAlert()
                        } else {
                            self?.showAlert(error.localizedDescription)
                        }
                        return
                    }
                    // Success — navigate to login
                    ChatBadgeManager.shared.stopListening()
                    let scene  = UIApplication.shared.connectedScenes.first as? UIWindowScene
                    let window = scene?.windows.first(where: { $0.isKeyWindow })
                    let loginVC = LoginVC()
                    window?.rootViewController = UINavigationController(rootViewController: loginVC)
                    window?.makeKeyAndVisible()
                }
            }
        }
    }

    private func deleteFirestoreData(uid: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        // Delete subcollections
        let subcollections = ["mySessions", "notifications"]
        let subGroup = DispatchGroup()

        for sub in subcollections {
            subGroup.enter()
            userRef.collection(sub).getDocuments { snapshot, _ in
                let batch = db.batch()
                snapshot?.documents.forEach { batch.deleteDocument($0.reference) }
                batch.commit { _ in subGroup.leave() }
            }
        }

        subGroup.notify(queue: .global()) {
            // Delete main user document
            userRef.delete { _ in completion() }
        }
    }

    private func deleteStorageFiles(uid: String, completion: @escaping () -> Void) {
        let storage = Storage.storage(url: "gs://healsync-storage-us")
        let paths   = ["patients/\(uid)/profile.jpg"]
        let group   = DispatchGroup()

        for path in paths {
            group.enter()
            storage.reference().child(path).delete { _ in group.leave() }
        }
        group.notify(queue: .global()) { completion() }
    }

    private func showReauthAlert() {
        let alert = UIAlertController(
            title: "Re-authentication Required",
            message: "Please enter your password to confirm account deletion.",
            preferredStyle: .alert
        )
        alert.addTextField { $0.placeholder = "Password"; $0.isSecureTextEntry = true }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { [weak self] _ in
            guard let pwd   = alert.textFields?.first?.text,
                  let user  = Auth.auth().currentUser,
                  let email = user.email else { return }
            let credential = EmailAuthProvider.credential(withEmail: email, password: pwd)
            user.reauthenticate(with: credential) { [weak self] _, error in
                if error != nil { self?.showAlert("Incorrect password."); return }
                self?.performDelete()
            }
        })
        present(alert, animated: true)
    }

    private func showAlert(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func handleBack()      { navigationController?.popViewController(animated: true) }
    @objc private func dismissKeyboard() { view.endEditing(true) }
}

// MARK: - UITextViewDelegate (placeholder for feedbackView)
extension DeleteAccountVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .systemGray {
            textView.text      = ""
            textView.textColor = UIColor(hex: "#1A3A45")
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text      = "Your feedback helps us improve ..."
            textView.textColor = .systemGray
        }
    }
}
