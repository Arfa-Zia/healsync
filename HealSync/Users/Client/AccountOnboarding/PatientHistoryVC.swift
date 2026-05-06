//
//  PatientHistoryVC.swift
//  HealSync
//
//  Created by Arfa on 19/01/2026.
//

import UIKit

class PatientHistoryVC: BaseViewController {
    var onboardingData: PatientOnboardingData
    init(onboardingData: PatientOnboardingData) {
        self.onboardingData = onboardingData
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    
    private var primaryConcernField = TextInputField(placeholder: "Stress, anxiety, relationships...", type: .text)
    private var therapySegment = UISegmentedControl(items: ["Yes","No"])
    private var medicationSegment = UISegmentedControl(items: ["Yes","No"])
    private var safetySegment = UISegmentedControl(items: ["Yes","No"])
    private var nextBtn = PrimaryButton(title: "NEXT")
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()
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
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSteps(total: 4, current: 2)
        setupLayout()
        addHeader()
        addPrimaryConcern(field: primaryConcernField)
        addTherapyHistory(segment: therapySegment)
        addMedication(medsegment: medicationSegment)
        addSafetyCheck(check: safetySegment)
        addContinueButton(btn: nextBtn)
        setupValidation()
        
        nextBtn.isEnabled = false
        nextBtn.alpha = 0.5
      
    }

    private func setupLayout() {
        
        contentView.axis = .vertical
        contentView.spacing = 25

        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
        view.addSubview(stepLabel)
        view.addSubview(stepsStack)
        
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        stepsStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
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
        let titleLabel = TitleLabel(text: "Help us understand you", fontSize: 25)
        let subtitleLabel = SubtitleLabel(text: "This helps your therapist support you better.")
        subtitleLabel.textColor = .secondaryLabel
        let header = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        header.axis = .vertical
        header.spacing = 15
        contentView.addArrangedSubview(header)
    }
    
    private func addPrimaryConcern(field: TextInputField) {
        let label = SubtitleLabel(text: "What brings you to therapy?")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .left
        
        let textField = field
        
        let primaryConcern = UIStackView(arrangedSubviews: [label, textField])
        primaryConcern.axis = .vertical
        primaryConcern.spacing = 15
        
        contentView.addArrangedSubview(primaryConcern)
    }

    private func addTherapyHistory(segment: UISegmentedControl) {
        let label = SubtitleLabel(text: "Have you tried therapy before?")
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .left

        let segmented = segment
        
        let therapyHistory = UIStackView(arrangedSubviews: [label, segmented])
        therapyHistory.axis = .vertical
        therapyHistory.spacing = 15
        
        contentView.addArrangedSubview(therapyHistory)
    }
    private func addMedication(medsegment: UISegmentedControl) {
        let label = SubtitleLabel(text: "Are you currently taking any medication?")
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .left

        let segmented = medsegment

        let medication = UIStackView(arrangedSubviews: [label, segmented])
        medication.axis = .vertical
        medication.spacing = 15
        
        contentView.addArrangedSubview(medication)
    }
    private func addSafetyCheck(check: UISegmentedControl) {

        let label = SubtitleLabel(text: "Have you had thoughts of harming yourself?")
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .left

        let segmented = check

        let note = UILabel()
        note.text = "Support is always available if you need it."
        note.font = .systemFont(ofSize: 13)
        note.textColor = .secondaryLabel
        
        let safetycheck = UIStackView(arrangedSubviews: [label, segmented, note])
        safetycheck.axis = .vertical
        safetycheck.spacing = 15
        
        contentView.addArrangedSubview(safetycheck)
    }
    
    private func addContinueButton(btn: PrimaryButton) {
        let button = btn
        button.addTarget(self, action: #selector(toEmergencyContact), for: .touchUpInside)
        contentView.addArrangedSubview(button)
    }

    func setupValidation() {
           primaryConcernField.onValueChanged = { [weak self] _ in
               self?.checkFormValidity()
           }
           
           therapySegment.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
           medicationSegment.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
           safetySegment.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
       }
       
       @objc func segmentChanged() {
           checkFormValidity()
       }
       
       func checkFormValidity() {
           let isValid =
           !(primaryConcernField.text?.isEmpty ?? true) &&
           therapySegment.selectedSegmentIndex != UISegmentedControl.noSegment &&
           medicationSegment.selectedSegmentIndex != UISegmentedControl.noSegment &&
           safetySegment.selectedSegmentIndex != UISegmentedControl.noSegment
           
           nextBtn.isEnabled = isValid
           nextBtn.alpha = isValid ? 1.0 : 0.5
       }

    @objc private func toEmergencyContact() {
        onboardingData.primaryConcern = primaryConcernField.text
        onboardingData.therapyHistory = therapySegment.selectedSegmentIndex == 0
        onboardingData.medication = medicationSegment.selectedSegmentIndex == 0
        onboardingData.safetyCheck = safetySegment.selectedSegmentIndex == 0

        let vc = EmergencyContactVC(onboardingData: onboardingData)
        navigationController?.pushViewController(vc, animated: true)
    }

}

