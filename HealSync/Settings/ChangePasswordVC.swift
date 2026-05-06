//
//  ChangePasswordVC.swift
//  HealSync
//
//  Created by Arfa on 25/03/2026.
//

import UIKit
import FirebaseAuth

// MARK: - ChangePasswordVC
class ChangePasswordVC: UIViewController {

    private let bgColor = UIColor(hex: "#D1F0F8")

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

    private let titleLbl: UILabel = {
        let l = UILabel()
        l.text = "Change Password"
        l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .black
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let currentField  = ChangePasswordVC.makeField("Current Password",     secure: true)
    private let newField      = ChangePasswordVC.makeField("New Password",          secure: true)
    private let confirmField  = ChangePasswordVC.makeField("Confirm New Password",  secure: true)

    private let updateBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("UPDATE PASSWORD", for: .normal)
        btn.setTitleColor(UIColor(hex: "#1A5C2A"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        btn.backgroundColor  = UIColor(hex: "#A3E8AB")
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

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        setupLayout()
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        updateBtn.addTarget(self, action: #selector(handleUpdate), for: .touchUpInside)
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

        let fieldsStack = UIStackView(arrangedSubviews: [currentField, newField, confirmField])
        fieldsStack.axis    = .vertical
        fieldsStack.spacing = 14
        fieldsStack.translatesAutoresizingMaskIntoConstraints = false

        let btnStack = UIStackView(arrangedSubviews: [updateBtn, cancelBtn])
        btnStack.axis         = .vertical
        btnStack.spacing      = 12
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        [titleLbl, fieldsStack, btnStack].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backBtn.widthAnchor.constraint(equalToConstant: 36),
            backBtn.heightAnchor.constraint(equalToConstant: 36),

            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            titleLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            titleLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            fieldsStack.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 24),
            fieldsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            fieldsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            btnStack.topAnchor.constraint(equalTo: fieldsStack.bottomAnchor, constant: 24),
            btnStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            btnStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            btnStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28),

            updateBtn.heightAnchor.constraint(equalToConstant: 48),
            cancelBtn.heightAnchor.constraint(equalToConstant: 48),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private static func makeField(_ placeholder: String, secure: Bool) -> UITextField {
        let tf = UITextField()
        tf.placeholder        = placeholder
        tf.isSecureTextEntry  = secure
        tf.font               = UIFont.systemFont(ofSize: 15)
        tf.backgroundColor    = UIColor(hex: "#EEF8FB")
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth  = 1
        tf.layer.borderColor  = UIColor(hex: "#C8EDF5").cgColor
        tf.leftView  = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return tf
    }

    @objc private func handleUpdate() {
        guard let current = currentField.text, !current.isEmpty,
              let newPwd  = newField.text,     !newPwd.isEmpty,
              let confirm = confirmField.text, !confirm.isEmpty else {
            showAlert("Please fill in all fields.")
            return
        }
        guard newPwd == confirm else {
            showAlert("New passwords do not match.")
            return
        }
        guard newPwd.count >= 6 else {
            showAlert("Password must be at least 6 characters.")
            return
        }

        activityIndicator.startAnimating()
        updateBtn.isEnabled = false

        // Re-authenticate then update password
        guard let user  = Auth.auth().currentUser,
              let email = user.email else { return }
        let credential = EmailAuthProvider.credential(withEmail: email, password: current)

        user.reauthenticate(with: credential) { [weak self] _, error in
            if error != nil {
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.updateBtn.isEnabled = true
                    self?.showAlert("Current password is incorrect.")
                }
                return
            }
            user.updatePassword(to: newPwd) { [weak self] error in
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.updateBtn.isEnabled = true
                    if let error = error {
                        self?.showAlert(error.localizedDescription)
                    } else {
                        self?.showSuccess()
                    }
                }
            }
        }
    }

    private func showSuccess() {
        let alert = UIAlertController(title: "Password Updated",
                                       message: "Your password has been changed successfully.",
                                       preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func showAlert(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func handleBack()        { navigationController?.popViewController(animated: true) }
    @objc private func dismissKeyboard()   { view.endEditing(true) }
}
