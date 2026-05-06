//
//  ForgotPasswordVCViewController.swift
//  HealSync
//
//  Created by Arfa on 13/01/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ForgotPasswordVC: BaseViewController {

    private var containerView = BaseContainer()
    private var titleLabel = TitleLabel(text: "Forgot Password", fontSize: 24)
    private var subtitleLabel = SubtitleLabel(text: "Enter your email to reset password", noOfLines: 0)
    private var email = TextInputField(placeholder: "Email Address", type: .email, color: UIColor(hex: "#90E0EF") , alphaValue: 0.44)
    
    private var sendEmailBtn = PrimaryButton(title: "Send Email")
    private var loginLink = Hyperlink(fullText: "Remember password  Log In", linkText: "Log In")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
        setupLayout()
    }
    
    private func setupActions() {
        loginLink.onLinkTap = { [weak self] in
            self?.navigateToLogin()
        }
        sendEmailBtn.addTarget(self, action: #selector(handlePasswordReset), for: .touchUpInside)
    }
    
    private func navigateToLogin() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func handlePasswordReset() {
        
        email.clearError()
        
        guard let emailText = email.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !emailText.isEmpty else {
            email.showError()
            showAlert(message: "Please enter your email address.")
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: emailText) { error in
            
            if let error = error as NSError? {
                guard let errorCode = AuthErrorCode(rawValue: error.code) else {
                    self.showAlert(message: error.localizedDescription)
                    return
                }
                
                switch errorCode {
                case .invalidEmail:
                    self.email.showError()
                    self.showAlert(message: "Invalid email format.")
                    
                case .userNotFound:
                    self.email.showError()
                    self.showAlert(message: "No account found with this email.")
                    
                default:
                    self.showAlert(message: error.localizedDescription)
                }
                return
            }
            
            self.showAlert(title: "Success", message: "Password reset email sent. Check your inbox.")
        }
    }
    
    private func showAlert(title: String = "Error", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            if title == "Success" {
                self.navigateToLogin()
            }
        })
        present(alert, animated: true)
    }
    
    private func setupLayout() {
        
        let formHeaderView = UIStackView(arrangedSubviews: [titleLabel , subtitleLabel])
        formHeaderView.axis = .vertical
        formHeaderView.spacing = 10
        
        let loginView = UIStackView(arrangedSubviews: [sendEmailBtn, loginLink])
        loginView.axis = .vertical
        loginView.spacing = 20
        loginView.alignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [formHeaderView, email, loginView])
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        containerView.addSubview(stackView)
        
        containerView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 40, leading: 30, bottom: 40, trailing: 30)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.77),
            
            stackView.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor),
 
            sendEmailBtn.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }
}

