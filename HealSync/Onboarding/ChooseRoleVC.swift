//
//  chooseRoleScreen.swift
//  HealSync
//
//  Created by Arfa on 12/01/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ChooseRoleVC: BaseViewController {
   
    var pendingGoogleUser: User? // FirebaseAuth.User
    private var containerView = BaseContainer()
    private var titleLabel = TitleLabel(text: "Select your Role", fontSize: 24)
    private var selectPatientBtn = PrimaryButton(title: "I'm a patient")
    private var selectTherapistBtn = PrimaryButton(title: "I'm a therapist")

        override func viewDidLoad() {
            super.viewDidLoad()
            setupLayout()
            selectPatientBtn.addTarget(self, action: #selector(patientSelected), for: .touchUpInside)
            selectTherapistBtn.addTarget(self, action: #selector(therapistSelected), for: .touchUpInside)
        }
    
    private func setupLayout(){
        let btnStack = UIStackView(arrangedSubviews: [selectPatientBtn, selectTherapistBtn])
        btnStack.axis = .vertical
        btnStack.spacing = 15
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, btnStack])
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        containerView.addSubview(stackView)
        
        containerView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 60, leading: 30, bottom: 60, trailing: 30)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.77),
            
            stackView.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor),
            
            selectTherapistBtn.heightAnchor.constraint(equalToConstant: 45),
            selectPatientBtn.heightAnchor.constraint(equalToConstant: 45)
            
        ])
    }

    // Update both button handlers to check for pending Google user
    @objc private func patientSelected() {
        UserDefaults.standard.set("patient", forKey: "selectedRole")
        
        if let googleUser = pendingGoogleUser {
            // ✅ Complete Google onboarding directly, skip email SignupVC
            saveGoogleUserAndOnboard(user: googleUser, role: "patient")
        } else {
            let nextVC = SignupVC()
            navigationController?.pushViewController(nextVC, animated: true)
        }
    }

    @objc private func therapistSelected() {
        UserDefaults.standard.set("therapist", forKey: "selectedRole")
        
        if let googleUser = pendingGoogleUser {
            // ✅ Complete Google onboarding directly, skip email SignupVC
            saveGoogleUserAndOnboard(user: googleUser, role: "therapist")
        } else {
            let nextVC = SignupVC()
            navigationController?.pushViewController(nextVC, animated: true)
        }
    }

    private func saveGoogleUserAndOnboard(user: User, role: String) {
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData([
            "fullName": user.displayName ?? "",
            "email": user.email ?? "",
            "role": role,
            "createdAt": Timestamp()
        ]) { [weak self] error in
            if let error = error { self?.showAlert(message: error.localizedDescription); return }
            UserDefaults.standard.removeObject(forKey: "selectedRole")
            DispatchQueue.main.async {
                if role == "patient" {
                    let vc = ClientWelcomeVC()
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let vc = TherapistWelcomeVC()
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }


}

