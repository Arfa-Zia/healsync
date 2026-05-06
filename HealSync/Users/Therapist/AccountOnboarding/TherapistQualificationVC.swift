//
//  TherapistQualificationVC.swift
//  HealSync
//
//  Created by Arfa on 11/03/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class TherapistQualificationVC: BaseViewController {
    
    var onboardingData: TherapistOnboardingData
    init(onboardingData: TherapistOnboardingData) {
        self.onboardingData = onboardingData
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    private var qualification = TextInputField(placeholder: "Qualification", type: .text)
    private var licenseNo = TextInputField(placeholder: "License Number", type: .text)
    private var specialization = TextInputField(placeholder: "Specialization", type: .text)
    private var yearsOfExperience = TextInputField(placeholder: "Years of Experience", type: .number)
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()
    private let termsCheckbox = UIButton(type: .system)
    private let continueButton = PrimaryButton(title: "NEXT", fontSize: 16)
    private var isTermsAccepted = false
    private let stepLabel: SubtitleLabel = {
        let label = SubtitleLabel(text: "Step 2:")
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let stepsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.distribution = .fillEqually
        return stack
    }()
    
    private func setupSteps(total: Int, current: Int) {
        stepsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for i in 1...total {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.heightAnchor.constraint(equalToConstant: 10).isActive = true
            dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
            dot.layer.cornerRadius = 4
            dot.backgroundColor = i <= current ? .systemCyan: .systemGray3
            stepsStack.addArrangedSubview(dot)
        }
    }
    
    private func addQualificationFields() {
        
        let fieldsStack = UIStackView(arrangedSubviews: [
            qualification,
            licenseNo,
            specialization,
            yearsOfExperience
        ])
        
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 20
        
        contentView.addArrangedSubview(fieldsStack)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSteps(total: 2, current: 2)
        setupLayout()
        addHeader()
        addQualificationFields()
        addTermsAndPolicy()
        addContinueButton()
        
        

        continueButton.isEnabled = false
        continueButton.alpha = 0.5

        setupValidation()
    }
    
    private func setupValidation() {

        qualification.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        licenseNo.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        specialization.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        yearsOfExperience.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
    }
    
    @objc private func textFieldChanged() {
        validateForm()
    }
    
    private func validateForm() {

        let isQualificationValid = !(qualification.text ?? "").isEmpty
        let isLicenseValid = !(licenseNo.text ?? "").isEmpty
        let isSpecializationValid = !(specialization.text ?? "").isEmpty
        let isExperienceValid = !(yearsOfExperience.text ?? "").isEmpty

        let isFormValid =
            isQualificationValid &&
            isLicenseValid &&
            isSpecializationValid &&
            isExperienceValid &&
            isTermsAccepted

        continueButton.isEnabled = isFormValid
        continueButton.alpha = isFormValid ? 1.0 : 0.5
    }
    private func setupLayout() {
        
        contentView.axis = .vertical
        contentView.spacing = 35

        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
        view.addSubview(stepLabel)
        view.addSubview(stepsStack)
            
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsStack.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -80),
            contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            
            stepLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stepLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stepLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 53),
            
            stepsStack.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 20),
            stepsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stepsStack.heightAnchor.constraint(equalToConstant: 5),
            stepsStack.widthAnchor.constraint(equalToConstant: 300)
        ])
    }
    
    private func addHeader() {
        let titleLabel = TitleLabel(text: "Qualifications", fontSize: 35)
        let header = UIStackView(arrangedSubviews: [titleLabel])
        header.axis = .vertical
        header.spacing = 15
        contentView.addArrangedSubview(header)
    }
    
    
    
    private func addTermsAndPolicy() {

        termsCheckbox.setImage(UIImage(systemName: "square"), for: .normal)
        termsCheckbox.tintColor = .systemCyan
        termsCheckbox.addTarget(self, action: #selector(toggleTerms), for: .touchUpInside)

        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.font = .systemFont(ofSize: 16)
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0

        let text = "I agree to the Terms & Conditions and Privacy Policy"

        let attributed = NSMutableAttributedString(string: text)

        let termsRange = (text as NSString).range(of: "Terms & Conditions")
        let privacyRange = (text as NSString).range(of: "Privacy Policy")

        attributed.addAttribute(.link, value: "terms://", range: termsRange)
        attributed.addAttribute(.link, value: "privacy://", range: privacyRange)

        textView.attributedText = attributed
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.systemCyan,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        let stack = UIStackView(arrangedSubviews: [termsCheckbox, textView])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center

        contentView.addArrangedSubview(stack)
    }

    
    @objc private func toggleTerms() {
        isTermsAccepted.toggle()

        let imageName = isTermsAccepted ? "checkmark.square.fill" : "square"
        termsCheckbox.setImage(UIImage(systemName: imageName), for: .normal)

        validateForm()
    }
    
    private func addContinueButton() {
        continueButton.isEnabled = false
        continueButton.alpha = 0.5
        continueButton.addTarget(self, action: #selector(finishOnboarding), for: .touchUpInside)
        contentView.addArrangedSubview(continueButton)
    }

    @objc private func handleTermsTap(_ gesture: UITapGestureRecognizer) {

        guard let label = gesture.view as? UILabel,
              let text = label.text else { return }

        let termsRange = (text as NSString).range(of: "Terms")
        let privacyRange = (text as NSString).range(of: "Privacy Policy")

        let tapLocation = gesture.location(in: label)
        let index = label.characterIndex(at: tapLocation)

        if termsRange.contains(index) {
            openLegalPage(title: "Terms & Conditions",
                          url: "https://arfazia2810.github.io/HealSync-legal/terms.html")
        } else if privacyRange.contains(index) {
            openLegalPage(title: "Privacy Policy",
                          url: "https://arfazia2810.github.io/HealSync-legal/privacy.html")
        }
    }
    
    private func openLegalPage(title: String, url: String) {
        let vc = LegalWebViewVC(title: title, urlString: url)
        let nav = UINavigationController(rootViewController: vc)

        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    @objc private func finishOnboarding() {

        onboardingData.qualification = qualification.text
        onboardingData.licenseNo = licenseNo.text
        onboardingData.specialization = specialization.text
        onboardingData.experience = Int(yearsOfExperience.text ?? "0")
        onboardingData.termsAccepted = isTermsAccepted

        saveOnboardingData(onboardingData)
    }
    
    private func saveOnboardingData(_ data: TherapistOnboardingData) {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()

        let docData: [String: Any] = [

            // Step 1
            "contactNo": data.contactNo ?? "",
            "dob": data.dob ?? "",
            "gender": data.gender ?? "",
            "location": data.location ?? "",

            // Step 2
            "qualification": data.qualification ?? "",
            "licenseNo": data.licenseNo ?? "",
            "specialization": data.specialization ?? "",
            "experience": data.experience ?? 0,

            "termsAccepted": data.termsAccepted,
        ]

        db.collection("users").document(uid).setData(docData, merge: true) { error in

            if let error = error {
                self.showAlert(message: error.localizedDescription)
                return
            }

            let nextVC = TherapistUploadLicenseVC()
            self.navigationController?.setViewControllers([nextVC], animated: true)
        }
    }
 
}

extension TherapistQualificationVC: UITextViewDelegate {
    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange) -> Bool {

        if URL.scheme == "terms" {
            openLegalPage(
                title: "Terms & Conditions",
                url: "https://arfazia2810.github.io/HealSync-legal/terms.html"
            )
            return false
        }

        if URL.scheme == "privacy" {
            openLegalPage(
                title: "Privacy Policy",
                url: "https://arfazia2810.github.io/HealSync-legal/privacy.html"
            )
            return false
        }

        return true
    }
}


