//
//  TherapistEditProfessionalInfoVC.swift
//  HealSync
//
//  Created by Arfa on 26/03/2026.
//

import UIKit

import UIKit
import FirebaseFirestore
import FirebaseAuth

class TherapistProfessionalInfoVC: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Properties
    private let db = Firestore.firestore()
    private var selectedTags: [String] = []
    private var selectedLanguages: [String] = []
    private let maxChips = 5

    // MARK: - Colors
    private let bgColor            = UIColor(hex: "#D6EEF5")
    private let accentBlue         = UIColor(hex: "#4FC3D8")
    private let unselectedDayColor = UIColor(hex: "#B8E6F0")
    private let textColor          = UIColor(hex: "#1A3A45")

    // MARK: - UI
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Tell clients about yourself and your expertise"
        lbl.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        lbl.textColor = UIColor(hex: "#5A8A99")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // About Me
    private let aboutMeLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "About Me"
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let aboutMeTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.backgroundColor = .white.withAlphaComponent(0.7)
        tv.layer.cornerRadius = 12
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.textColor = UIColor(hex: "#1A3A45")
        return tv
    }()

    private let aboutCharCountLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "0 / 500"
        lbl.font = UIFont.systemFont(ofSize: 11)
        lbl.textColor = UIColor(hex: "#5A8A99")
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // Tags
    private let tagsLabel: UILabel = makeFieldLabel("TAGS  (max 5)")
    private let tagsTextField: UITextField = makeInputTextField(placeholder: "e.g. Anxiety, Depression")
    private let tagsAddButton: UIButton = makeAddButton()
    private let tagsChipsView: UIStackView = makeChipsStack()

    // Languages
    private let languagesLabel: UILabel = makeFieldLabel("LANGUAGES  (max 5)")
    private let languagesTextField: UITextField = makeInputTextField(placeholder: "e.g. English, Urdu")
    private let languagesAddButton: UIButton = makeAddButton()
    private let languagesChipsView: UIStackView = makeChipsStack()

    private let divider1: UIView = makeDivider()

    // Save / Cancel
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(hex: "#4FC3D8")
        btn.layer.cornerRadius = 14
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Cancel", for: .normal)
        btn.setTitleColor(UIColor(hex: "#4A1113"), for: .normal)
        btn.backgroundColor = UIColor(hex: "#D3AAB1")
        btn.layer.cornerRadius = 14
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.color = .white
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        titleLabel.text = "EDIT PROFESSIONAL INFO"
        saveButton.setTitle("Save Changes", for: .normal)

        setupUI()
        setupActions()
        loadExistingData()
        setupKeyboardDismiss()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        let allSubviews: [UIView] = [
            titleLabel, subtitleLabel,
            aboutMeLabel, aboutMeTextView, aboutCharCountLabel,
            tagsLabel, tagsTextField, tagsAddButton, tagsChipsView,
            languagesLabel, languagesTextField, languagesAddButton, languagesChipsView,
            divider1,
            saveButton, cancelButton
        ]
        allSubviews.forEach { contentView.addSubview($0) }
        saveButton.addSubview(activityIndicator)

        let p: CGFloat = 22
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: -20),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            aboutMeLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
            aboutMeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),

            aboutMeTextView.topAnchor.constraint(equalTo: aboutMeLabel.bottomAnchor, constant: 8),
            aboutMeTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            aboutMeTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            aboutMeTextView.heightAnchor.constraint(equalToConstant: 130),

            aboutCharCountLabel.topAnchor.constraint(equalTo: aboutMeTextView.bottomAnchor, constant: 4),
            aboutCharCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            tagsLabel.topAnchor.constraint(equalTo: aboutCharCountLabel.bottomAnchor, constant: 22),
            tagsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),

            tagsTextField.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: 8),
            tagsTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            tagsTextField.trailingAnchor.constraint(equalTo: tagsAddButton.leadingAnchor, constant: -8),
            tagsTextField.heightAnchor.constraint(equalToConstant: 46),

            tagsAddButton.centerYAnchor.constraint(equalTo: tagsTextField.centerYAnchor),
            tagsAddButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            tagsAddButton.widthAnchor.constraint(equalToConstant: 46),
            tagsAddButton.heightAnchor.constraint(equalToConstant: 46),

            tagsChipsView.topAnchor.constraint(equalTo: tagsTextField.bottomAnchor, constant: 8),
            tagsChipsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            tagsChipsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            languagesLabel.topAnchor.constraint(equalTo: tagsChipsView.bottomAnchor, constant: 22),
            languagesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),

            languagesTextField.topAnchor.constraint(equalTo: languagesLabel.bottomAnchor, constant: 8),
            languagesTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            languagesTextField.trailingAnchor.constraint(equalTo: languagesAddButton.leadingAnchor, constant: -8),
            languagesTextField.heightAnchor.constraint(equalToConstant: 46),

            languagesAddButton.centerYAnchor.constraint(equalTo: languagesTextField.centerYAnchor),
            languagesAddButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            languagesAddButton.widthAnchor.constraint(equalToConstant: 46),
            languagesAddButton.heightAnchor.constraint(equalToConstant: 46),

            languagesChipsView.topAnchor.constraint(equalTo: languagesTextField.bottomAnchor, constant: 8),
            languagesChipsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            languagesChipsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            divider1.topAnchor.constraint(equalTo: languagesChipsView.bottomAnchor, constant: 24),
            divider1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            divider1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            divider1.heightAnchor.constraint(equalToConstant: 1),

            saveButton.topAnchor.constraint(equalTo: divider1.bottomAnchor, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            saveButton.heightAnchor.constraint(equalToConstant: 40),

            cancelButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            activityIndicator.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor)
        ])
    }

    // MARK: - Actions Setup
    private func setupActions() {
        tagsAddButton.addTarget(self, action: #selector(addTag), for: .touchUpInside)
        languagesAddButton.addTarget(self, action: #selector(addLanguage), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        aboutMeTextView.delegate = self
        tagsTextField.returnKeyType = .done
        languagesTextField.returnKeyType = .done
        tagsTextField.addTarget(self, action: #selector(addTag), for: .editingDidEndOnExit)
        languagesTextField.addTarget(self, action: #selector(addLanguage), for: .editingDidEndOnExit)
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Load Data
    private func loadExistingData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let self = self, let data = snapshot?.data() else { return }
            DispatchQueue.main.async {
                let about = data["about"] as? String ?? ""
                self.aboutMeTextView.text = about
                self.aboutCharCountLabel.text = "\(about.count) / 500"

                (data["tags"] as? [String] ?? []).forEach {
                    self.addChip($0, to: &self.selectedTags, stackView: self.tagsChipsView)
                }
                (data["languages"] as? [String] ?? []).forEach {
                    self.addChip($0, to: &self.selectedLanguages, stackView: self.languagesChipsView)
                }
            }
        }
    }

    // MARK: - Chip Logic
    private func chipCount(in stackView: UIStackView) -> Int {
        stackView.arrangedSubviews.compactMap { $0 as? UIStackView }.reduce(0) { $0 + $1.arrangedSubviews.count }
    }

    private func currentRow(in stackView: UIStackView, maxPerRow: Int = 2) -> UIStackView {
        if let lastRow = stackView.arrangedSubviews.last as? UIStackView,
           lastRow.arrangedSubviews.count < maxPerRow { return lastRow }
        let row = UIStackView()
        row.axis = .horizontal; row.spacing = 8
        row.alignment = .leading; row.distribution = .fill
        row.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(row)
        return row
    }

    private func addChip(_ text: String, to array: inout [String], stackView: UIStackView) {
        guard !text.isEmpty, !array.contains(text) else { return }
        if array.count >= maxChips {
            showAlert(message: "You can add a maximum of \(maxChips) items."); return
        }
        array.append(text)

        let container = UIView()
        container.backgroundColor = UIColor(hex: "#B8E6F0")
        container.layer.cornerRadius = 10
        container.translatesAutoresizingMaskIntoConstraints = false

        let lbl = UILabel()
        lbl.text = text
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = UIColor(hex: "#1A4A5A")
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let removeBtn = UIButton(type: .system)
        removeBtn.setTitle("×", for: .normal)
        removeBtn.setTitleColor(UIColor(hex: "#3A7A8A"), for: .normal)
        removeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        removeBtn.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(lbl)
        container.addSubview(removeBtn)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            lbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            removeBtn.leadingAnchor.constraint(equalTo: lbl.trailingAnchor, constant: 4),
            removeBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            removeBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: 30)
        ])

        let capturedText = text
        let isTagsStack = stackView == tagsChipsView
        removeBtn.addAction(UIAction { [weak self, weak container, weak stackView] _ in
            guard let self = self, let container = container, let stackView = stackView else { return }
            for case let row as UIStackView in stackView.arrangedSubviews {
                if row.arrangedSubviews.contains(container) {
                    row.removeArrangedSubview(container); container.removeFromSuperview()
                    if row.arrangedSubviews.isEmpty { stackView.removeArrangedSubview(row); row.removeFromSuperview() }
                    break
                }
            }
            if isTagsStack { self.selectedTags.removeAll { $0 == capturedText } }
            else            { self.selectedLanguages.removeAll { $0 == capturedText } }
        }, for: .touchUpInside)

        currentRow(in: stackView).addArrangedSubview(container)
    }

    // MARK: - Button Actions
    @objc private func addTag() {
        guard let text = tagsTextField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return }
        addChip(text, to: &selectedTags, stackView: tagsChipsView)
        tagsTextField.text = ""
    }

    @objc private func addLanguage() {
        guard let text = languagesTextField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return }
        addChip(text, to: &selectedLanguages, stackView: languagesChipsView)
        languagesTextField.text = ""
    }

    @objc private func handleCancel() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Save
    @objc private func handleSave() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let about = aboutMeTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !about.isEmpty else { showAlert(message: "Please fill in your About Me section."); return }

        setSavingState(true)

        let data: [String: Any] = [
            "about":     about,
            "tags":      selectedTags,
            "languages": selectedLanguages,
            "updatedAt": Timestamp()
        ]

        db.collection("users").document(uid).updateData(data) { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.setSavingState(false)
                if let error = error { self.showAlert(message: "Failed to save: \(error.localizedDescription)"); return }
                    self.navigationController?.popViewController(animated: true)
            }
        }
    }

    private func setSavingState(_ saving: Bool) {
        if saving {
            saveButton.setTitle("", for: .normal)
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            saveButton.setTitle("Save Changes", for: .normal)
        }
        saveButton.isEnabled = !saving
    }

    // MARK: - Helpers
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Factory
    private static func makeFieldLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = UIFont.systemFont(ofSize: 13, weight: .heavy)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }

    private static func makeInputTextField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.backgroundColor = .white.withAlphaComponent(0.7)
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        tf.leftViewMode = .always
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.textColor = UIColor(hex: "#1A3A45")
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }

    private static func makeAddButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("+", for: .normal)
        btn.setTitleColor(UIColor(hex: "#4A8A9A"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .light)
        btn.backgroundColor = .white.withAlphaComponent(0.7)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    private static func makeChipsStack() -> UIStackView {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 8
        sv.alignment = .leading; sv.distribution = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }

    private static func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#9ECEDD").withAlphaComponent(0.5)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }
}

// MARK: - UITextViewDelegate
extension TherapistProfessionalInfoVC: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let current = textView.text ?? ""
        guard let range = Range(range, in: current) else { return true }
        let updated = current.replacingCharacters(in: range, with: text)
        return updated.count <= 500
    }

    func textViewDidChange(_ textView: UITextView) {
        aboutCharCountLabel.text = "\(textView.text.count) / 500"
    }
}
