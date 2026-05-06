//
//  EmergencyContactVC.swift
//  HealSync
//
//  Created by Arfa on 09/02/2026.
//

import UIKit

class EmergencyContactVC: BaseViewController {
    var onboardingData: PatientOnboardingData
    init(onboardingData: PatientOnboardingData) {
        self.onboardingData = onboardingData
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private var guardianNameField = TextInputField(placeholder: "Enter Name", type: .text)
    private var guardianContactField = TextInputField(placeholder: "Enter Contact Number", type: .number)
    private var nextBtn = PrimaryButton(title: "NEXT")
    private let contentView = UIStackView()
    private let stepLabel: SubtitleLabel = {
        let label = SubtitleLabel(text: "Step 3:")
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
    override func viewDidLoad() {
    super.viewDidLoad()
    setupSteps(total: 4, current: 3)
    setupLayout()
    addHeader()
    addGuardianName(name: guardianNameField)
    addGuardianNumber(number: guardianContactField)
    addContinueButton(btn: nextBtn)

    nextBtn.isEnabled = false
    nextBtn.alpha = 0.5
       
    setupValidation()
    }
    
    private func setupValidation() {
        
        guardianNameField.onValueChanged = { [weak self] _ in
            self?.validateFields()
        }
        
        guardianContactField.onValueChanged = { [weak self] _ in
            self?.validateFields()
        }
    }
    private func validateFields() {
        
        let isNameValid = !(guardianNameField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        let isContactValid = !(guardianContactField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        
        let isFormValid = isNameValid && isContactValid
        
        nextBtn.isEnabled = isFormValid
        nextBtn.alpha = isFormValid ? 1.0 : 0.5
    }
    private func setupLayout() {

    contentView.axis = .vertical
    contentView.spacing = 40

    view.addSubview(contentView)
    view.addSubview(stepLabel)
    view.addSubview(stepsStack)
        
    stepLabel.translatesAutoresizingMaskIntoConstraints = false
    stepsStack.translatesAutoresizingMaskIntoConstraints = false
    contentView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([

    contentView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -80),
    contentView.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
    contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
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
    let titleLabel = TitleLabel(text: "Emergency Contact", fontSize: 30)
    contentView.addArrangedSubview(titleLabel)
    }

    private func addGuardianName(name: TextInputField) {
    let label = SubtitleLabel(text: "Guardian Name")
    label.font = .systemFont(ofSize: 16, weight: .medium)
    label.textAlignment = .left

    let textField = name

    let namefield = UIStackView(arrangedSubviews: [label, textField])
    namefield.axis = .vertical
    namefield.spacing = 15

    contentView.addArrangedSubview(namefield)
    }

    private func addGuardianNumber(number: TextInputField) {
    let label = SubtitleLabel(text: "Guardian Contact Number")
    label.font = .systemFont(ofSize: 16, weight: .medium)
    label.textAlignment = .left

    let textField = number
    let numberField = UIStackView(arrangedSubviews: [label, textField])
    numberField.axis = .vertical
    numberField.spacing = 15

    contentView.addArrangedSubview(numberField)
    }


    private func addContinueButton(btn: PrimaryButton) {
    let button = btn
    button.addTarget(self, action: #selector(toUserPreferencesVC), for: .touchUpInside)
    contentView.addArrangedSubview(button)
    }

    @objc private func toUserPreferencesVC() {
        onboardingData.guardianName = guardianNameField.text
        onboardingData.guardianContact = guardianContactField.text
        
        let vc = UserPreferenceVC(onboardingData: onboardingData)
        navigationController?.pushViewController(vc, animated: true)
    }

}


