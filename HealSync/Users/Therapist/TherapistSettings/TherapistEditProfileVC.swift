//
//  TherapistEditProfileVC.swift
//  HealSync
//
//  Created by Arfa on 26/03/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class TherapistEditProfileVC: UIViewController {

    // MARK: - Properties
    private let db      = Firestore.firestore()
    private var therapist: Therapist?
    private var selectedImage: UIImage?

    private let bgColor  = UIColor(hex: "#D1F0F8")
    private let teal     = UIColor(hex: "#4FC3D8")
    private let darkText = UIColor(hex: "#1A3A45")

    // MARK: - UI
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis    = .vertical
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // Custom nav bar
    private let navBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#D1F0F8")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let backBtn = CustomBackButton()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Personal Information"
        lbl.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let navDivider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#C8EDF5")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Avatar
    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor    = UIColor(hex: "#77D7EA")
        v.layer.cornerRadius = 48
        v.clipsToBounds      = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let avatarInitialLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        lbl.textColor = UIColor(hex: "#1A7A8A")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let changePhotoBtn: UIButton = {
        let btn = PrimaryButton(title: "Change Photo", color: UIColor(hex: "#4FC3D8"),
                                fontSize: 14, fontColor: .white, fontWeight: .semibold,
                                paddingTopBottom: 8, paddingLeftRight: 14)
        return btn
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    // MARK: - Fields
    private let contactField  = TherapistEditProfileVC.makeField(placeholder: "Contact Number",
                                                               icon: "phone.fill",
                                                               keyboardType: .phonePad)
    private let dobField      = TherapistEditProfileVC.makeField(placeholder: "Date of Birth",
                                                               icon: "calendar")
    private let genderField   = TherapistEditProfileVC.makeField(placeholder: "Gender",
                                                               icon: "person.fill")
    private let locationField = TherapistEditProfileVC.makeField(placeholder: "Location",
                                                               icon: "mappin.circle.fill")

    // MARK: - Gender Picker
    private let genderPicker = UIPickerView()
    private let genders      = ["Male", "Female", "Other", "Prefer not to say"]

    // MARK: - Location Picker
    private let locationPicker = UIPickerView()
    private let locations      = ["Lahore", "Karachi", "Islamabad", "Multan", "Quetta",
                                   "Azad Jummu Kashmir", "Gilgit", "Peshawar", "Other"]

    // MARK: - DOB Picker — minimum age 18, maximum 100 years old, defaults to -25 years
    private let dobPicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode          = .date
        dp.preferredDatePickerStyle = .wheels
        // Must be at least 18 years old
        dp.maximumDate = Calendar.current.date(byAdding: .year, value: -18, to: Date())
        dp.minimumDate = Calendar.current.date(byAdding: .year, value: -100, to: Date())
        // Default to a sensible age (25 years old)
        if let defaultDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) {
            dp.date = defaultDate
        }
        return dp
    }()

    // MARK: - Save / Cancel buttons
    private let saveBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("SAVE", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        btn.backgroundColor  = UIColor(hex: "#4FC3D8")
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let cancelBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("CANCEL", for: .normal)
        btn.setTitleColor(UIColor(hex: "#7B1C1C"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        btn.backgroundColor  = UIColor(hex: "#F5C6C6")
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        setupLayout()
        setupPickers()
        fetchUserData()

        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        changePhotoBtn.addTarget(self, action: #selector(handleChangePhoto), for: .touchUpInside)
        saveBtn.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        cancelBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Layout
    private func setupLayout() {
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        [backBtn, titleLabel, navDivider].forEach { navBar.addSubview($0) }

        view.addSubview(navBar)
        view.addSubview(scrollView)
        view.addSubview(activityIndicator)
        scrollView.addSubview(contentStack)

        let avatarSection = buildAvatarSection()
        let fieldsCard    = buildFieldsCard()

        let btnStack = UIStackView(arrangedSubviews: [saveBtn, cancelBtn])
        btnStack.axis         = .horizontal
        btnStack.spacing      = 14
        btnStack.distribution = .fillEqually

        let btnWrapper = UIView()
        btnWrapper.addSubview(btnStack)
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btnStack.topAnchor.constraint(equalTo: btnWrapper.topAnchor),
            btnStack.leadingAnchor.constraint(equalTo: btnWrapper.leadingAnchor),
            btnStack.trailingAnchor.constraint(equalTo: btnWrapper.trailingAnchor),
            btnStack.bottomAnchor.constraint(equalTo: btnWrapper.bottomAnchor),
            btnStack.heightAnchor.constraint(equalToConstant: 48)
        ])

        [avatarSection, fieldsCard, btnWrapper].forEach { contentStack.addArrangedSubview($0) }
        contentStack.setCustomSpacing(24, after: avatarSection)
        contentStack.setCustomSpacing(24, after: fieldsCard)

        NSLayoutConstraint.activate([
            // Your original offset kept exactly as-is
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -50),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 52),

            backBtn.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 14),
            backBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            backBtn.widthAnchor.constraint(equalToConstant: 36),
            backBtn.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 60),
            titleLabel.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),

            navDivider.leadingAnchor.constraint(equalTo: navBar.leadingAnchor),
            navDivider.trailingAnchor.constraint(equalTo: navBar.trailingAnchor),
            navDivider.bottomAnchor.constraint(equalTo: navBar.bottomAnchor),
            navDivider.heightAnchor.constraint(equalToConstant: 1),

            scrollView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func buildAvatarSection() -> UIView {
        avatarView.addSubview(avatarImageView)
        avatarView.addSubview(avatarInitialLabel)

        let container = UIView()
        container.addSubview(avatarView)
        container.addSubview(changePhotoBtn)
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 100),

            avatarView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            avatarView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 96),
            avatarView.heightAnchor.constraint(equalToConstant: 96),

            avatarImageView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),

            avatarInitialLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarInitialLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            changePhotoBtn.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 20),
            changePhotoBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    private func buildFieldsCard() -> UIView {
        let card = UIView()
        card.backgroundColor   = .white.withAlphaComponent(0.85)
        card.layer.cornerRadius = 20
        card.layer.shadowColor   = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowOffset  = CGSize(width: 0, height: 3)
        card.layer.shadowRadius  = 8
        card.translatesAutoresizingMaskIntoConstraints = false

        let sections: [(String, UIView)] = [
            ("Contact Number",   contactField),
            ("Date of Birth",    dobField),
            ("Gender",           genderField),
            ("Location",         locationField),
        ]

        var lastView: UIView? = nil

        for (label, field) in sections {
            let lbl = makeFieldLabel(label)
            card.addSubview(lbl)
            card.addSubview(field)

            lbl.translatesAutoresizingMaskIntoConstraints   = false
            field.translatesAutoresizingMaskIntoConstraints = false

            if let prev = lastView {
                lbl.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 18).isActive = true
            } else {
                lbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 20).isActive = true
            }

            NSLayoutConstraint.activate([
                lbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),

                field.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 6),
                field.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
                field.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
                field.heightAnchor.constraint(equalToConstant: 48)
            ])

            lastView = field
        }

        lastView?.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20).isActive = true
        return card
    }

    // MARK: - Field Factory
    private static func makeField(placeholder: String,
                                   icon: String,
                                   keyboardType: UIKeyboardType = .default) -> UITextField {
        let tf = UITextField()
        tf.placeholder        = placeholder
        tf.font               = UIFont.systemFont(ofSize: 15)
        tf.textColor          = UIColor(hex: "#1A3A45")
        tf.keyboardType       = keyboardType
        tf.backgroundColor    = UIColor(hex: "#EEF8FB")
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth  = 1
        tf.layer.borderColor  = UIColor(hex: "#C8EDF5").cgColor

        let config     = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        let iconImg    = UIImage(systemName: icon, withConfiguration: config)
        let iconIV     = UIImageView(image: iconImg)
        iconIV.tintColor   = UIColor(hex: "#4FC3D8")
        iconIV.contentMode = .scaleAspectFit
        let iconWrapper = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 48))
        iconIV.frame = CGRect(x: 10, y: 14, width: 18, height: 18)
        iconWrapper.addSubview(iconIV)
        tf.leftView     = iconWrapper
        tf.leftViewMode = .always

        return tf
    }

    private func makeFieldLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text      = text
        lbl.font      = UIFont.systemFont(ofSize: 13, weight: .medium)
        lbl.textColor = UIColor(hex: "#5A8A99")
        return lbl
    }

    // MARK: - Pickers
    private func setupPickers() {
        // Shared toolbar — no Done button (matching your original)
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [space]

        // Gender picker
        genderPicker.dataSource        = self
        genderPicker.delegate          = self
        genderPicker.tag               = 0
        genderField.inputView          = genderPicker
        genderField.inputAccessoryView = toolbar
        genderField.tintColor          = .clear   // hide cursor

        // Location picker
        locationPicker.dataSource        = self
        locationPicker.delegate          = self
        locationPicker.tag               = 1
        locationField.inputView          = locationPicker
        locationField.inputAccessoryView = toolbar
        locationField.tintColor          = .clear  // hide cursor

        // DOB picker — minimum age 18
        dobField.inputView          = dobPicker
        dobField.inputAccessoryView = toolbar
        dobField.tintColor          = .clear      // hide cursor
        dobPicker.addTarget(self, action: #selector(dobChanged), for: .valueChanged)
    }

    // MARK: - Fetch
    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        activityIndicator.startAnimating()

        db.collection("users").document(uid).getDocument { [weak self] snap, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()

                guard let snap = snap, snap.exists, let therapist = Therapist(document: snap) else {
                    print("Error: User document does not exist")
                    return
                }
                self.therapist = therapist

                self.contactField.text         = therapist.contactNo
                self.dobField.text             = therapist.dob
                self.genderField.text          = therapist.gender
                self.locationField.text        = therapist.location
                self.avatarInitialLabel.text   = String(therapist.fullName.prefix(1)).uppercased()

                // Pre-select gender in picker
                let idx = self.genders.firstIndex(of: therapist.gender)
                self.genderPicker.selectRow(idx!, inComponent: 0, animated: false)

                // Pre-select location in picker
                if let location = therapist.location,
                   let idx = self.locations.firstIndex(of: location) {
                    self.locationPicker.selectRow(idx, inComponent: 0, animated: false)
                }

                // Pre-set DOB picker date — handle multiple stored formats
                if let dobStr = therapist.dob, !dobStr.isEmpty {
                    let formats = ["dd MMM yyyy", "dd-MM-yyyy", "MM/dd/yyyy", "yyyy-MM-dd"]
                    let f = DateFormatter()
                    for fmt in formats {
                        f.dateFormat = fmt
                        if let date = f.date(from: dobStr) {
                            self.dobPicker.date = date
                            // Normalise to dd-MM-yyyy for display
                            f.dateFormat = "dd-MM-yyyy"
                            self.dobField.text = f.string(from: date)
                            break
                        }
                    }
                }

                // Load profile image
                if let urlStr = snap.data()?["profileImageURL"] as? String,
                   !urlStr.isEmpty,
                   let url = URL(string: urlStr) {
                    URLSession.shared.dataTask(with: url) { data, _, _ in
                        if let data = data, let img = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.avatarImageView.image      = img
                                self.avatarInitialLabel.isHidden = true
                            }
                        }
                    }.resume()
                }
            }
        }
    }

    // MARK: - Save
    @objc private func handleSave() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        activityIndicator.startAnimating()
        saveBtn.isEnabled = false

        func commitData(imageURL: String? = nil) {
            var updates: [String: Any] = [
                "contactNumber":   contactField.text         ?? "",
                "dob":             dobField.text             ?? "",
                "gender":          genderField.text          ?? "",
                "location":        locationField.text        ?? "",
            ]
            if let url = imageURL { updates["profileImageURL"] = url }

            self.db.collection("users").document(uid).updateData(updates) { [weak self] error in
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.saveBtn.isEnabled = true
                    if let error = error {
                        self?.showAlert("Error", error.localizedDescription)
                    } else {
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }

        if let image = selectedImage, let data = image.jpegData(compressionQuality: 0.7) {
            let ref = Storage.storage(url: "gs://healsync-storage-us").reference().child("patients/\(uid)/profile.jpg")
            ref.putData(data, metadata: nil) { [weak self] _, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.activityIndicator.stopAnimating()
                        self?.saveBtn.isEnabled = true
                        self?.showAlert("Upload Failed", error.localizedDescription)
                    }
                    return
                }
                ref.downloadURL { url, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.activityIndicator.stopAnimating()
                            self?.saveBtn.isEnabled = true
                            self?.showAlert("Upload Failed", error.localizedDescription)
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        commitData(imageURL: url?.absoluteString)
                    }
                }
            }
        } else {
            commitData()
        }
    }

    // MARK: - Change Photo
    @objc private func handleChangePhoto() {
        let picker = UIImagePickerController()
        picker.delegate      = self
        picker.allowsEditing = true
        let alert = UIAlertController(title: "Change Photo", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
            picker.sourceType = .camera; self.present(picker, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            picker.sourceType = .photoLibrary; self.present(picker, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Actions
    @objc private func handleBack() { navigationController?.popViewController(animated: true) }

    @objc private func dobChanged() {
        let f = DateFormatter()
        f.dateFormat  = "dd-MM-yyyy"
        dobField.text = f.string(from: dobPicker.date)
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIPickerView (Gender + Location)
extension TherapistEditProfileVC: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        pickerView.tag == 0 ? genders.count : locations.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int,
                    forComponent component: Int) -> String? {
        pickerView.tag == 0 ? genders[row] : locations[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int,
                    inComponent component: Int) {
        if pickerView.tag == 0 {
            genderField.text   = genders[row]
        } else {
            locationField.text = locations[row]
        }
    }
}

// MARK: - UIImagePickerController
extension TherapistEditProfileVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let img = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else { return }
        selectedImage = img
        avatarImageView.image        = img
        avatarInitialLabel.isHidden  = true
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

