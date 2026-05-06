//
//  TherapistAddProfileDetailsVC.swift
//  HealSync
//
//  Created by Arfa on 11/03/2026.
//

import UIKit

class TherapistAddProfileDetailsVC: BaseViewController {
    
    var onboardingData = TherapistOnboardingData()
    private let stepLabel: SubtitleLabel = {
        let label = SubtitleLabel(text: "Step 1:")
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

    private var titleLabel = TitleLabel(text: "Add Profile Details", fontSize: 28)
    
    private var contactNo: TextInputField = {
        let contact = TextInputField(placeholder: "Contact Number", type: .number)
        contact.setRightIcon(UIImage(systemName: "phone.fill"))
        return contact
    }()
    
    private var DOB: TextInputField = {
        let field = TextInputField(placeholder: "Date of Birth", type: .date)
        return field
    }()
    
    private var genderField: TextInputField = {
        let field = TextInputField(placeholder: "Gender", type: .text)
        field.setRightIcon(UIImage(systemName: "chevron.down"))
        field.setupPicker(data: Constants.genderOptions)
        return field
    }()
    
    private var locationField: TextInputField = {
        let field = TextInputField(placeholder: "Location", type: .text)
        field.setRightIcon(UIImage(systemName: "location.fill"))
        field.setupPicker(data: Constants.locationOptions)
        return field
    }()
    
    private var nextBtn = PrimaryButton(title: "NEXT", fontSize: 16)
    
    private enum Constants {
        static let genderOptions = ["Male", "Female", "Others", "Prefer not to say"]
        static let locationOptions = ["Lahore", "Karachi", "Islamabad", "Multan", "Quetta", "Azad Jummu Kashmir", "Gilgit", "Peshawar", "Other"]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSteps(total: 2, current: 1)
        setupLayout()
        nextBtn.addTarget(self, action: #selector(toPatientHistory), for: .touchUpInside)
        nextBtn.isEnabled = false
        nextBtn.alpha = 0.5
        setupValueObservers()
    }
    
    private func setupValueObservers() {
        [contactNo, DOB, genderField, locationField].forEach { field in
            field.onValueChanged = { [weak self] _ in
                self?.checkFormValidity()
            }
        }
    }
    private func checkFormValidity() {
        let isValid =
        !(contactNo.text?.isEmpty ?? true) &&
        !(DOB.text?.isEmpty ?? true) &&
        !(genderField.text?.isEmpty ?? true) &&
        !(locationField.text?.isEmpty ?? true)

        nextBtn.isEnabled = isValid
        nextBtn.alpha = isValid ? 1.0 : 0.5
    }
    @objc private func toPatientHistory() {
        onboardingData.contactNo = contactNo.text
        onboardingData.dob = DOB.text
        onboardingData.gender = genderField.text
        onboardingData.location = locationField.text
        
        let vc = TherapistQualificationVC(onboardingData: onboardingData)
        navigationController?.pushViewController(vc, animated: true)
    }
    private func setupLayout() {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, contactNo, DOB, genderField, locationField, nextBtn])
        stackView.axis = .vertical
        stackView.spacing = 25
        stackView.setCustomSpacing(50, after: titleLabel)
        stackView.setCustomSpacing(50, after: locationField)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stepLabel)
        view.addSubview(stepsStack)
        view.addSubview(stackView)
        
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stepLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stepLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stepLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 65),
            
            stepsStack.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 20),
            stepsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stepsStack.heightAnchor.constraint(equalToConstant: 5),
            stepsStack.widthAnchor.constraint(equalToConstant: 270),
            
            stackView.topAnchor.constraint(equalTo: stepsStack.bottomAnchor, constant: 30),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7)
        ])
    }
}

