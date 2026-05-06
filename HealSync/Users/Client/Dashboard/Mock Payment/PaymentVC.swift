//
//  PremiumPaymentVC.swift
//  HealSync
//
//  Created by Arfa on 04/03/2026.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class PaymentVC: UIViewController {

    var bookingData: [String: Any]?
    var therapistId: String?
    var patientId: String?
    var bookingId: String?
    var onPaymentSuccess: (() -> Void)?
   
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .interactive
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 35
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.layer.shadowRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    
    private let titleLabel = TitleLabel(text: "Procced to Pay", fontSize: 20)
    
    private let billingHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "BILLING INFO"
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .lightGray
        return label
    }()
    
    private let fieldsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var cardNumberField = TextInputField(placeholder: "Card Number", type: .number , color: UIColor(hex: "#C1EDF6"))
    private var expiryField = TextInputField(placeholder: "MM/YY", type: .text , color: UIColor(hex: "#C1EDF6"))
    private var cvvField = TextInputField(placeholder: "CVV", type: .number , color: UIColor(hex: "#C1EDF6"))
    private var nameField = TextInputField(placeholder: "Name on Card", type: .text , color: UIColor(hex: "#C1EDF6"))
    
    private let payButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("PROCEED TO PAY", for: .normal)
        button.backgroundColor = UIColor(hex: "#A3E8AB")
        button.setTitleColor(UIColor(hex: "#1A4C1A"), for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("CANCEL", for: .normal)
        button.backgroundColor = UIColor(hex: "#E3B5B5")
        button.setTitleColor(UIColor(hex: "#4C1A1A"), for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#D1F0F8")
        
        setupHierarchy()
        setupConstraints()
        setupActions()
        registerKeyboardNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(cardView)
        
        cardView.addSubview(titleLabel)
        cardView.addSubview(billingHeaderLabel)
        cardView.addSubview(fieldsStack)
        cardView.addSubview(payButton)
        cardView.addSubview(cancelButton)
        cardView.addSubview(activityIndicator)
        
        billingHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        [cardNumberField, expiryField, cvvField, nameField].forEach { fieldsStack.addArrangedSubview($0) }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView fills entire screen
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView height must be at least screen height for centering to work
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor),
            
            // Card Container (Properly Centered within ContentView)
            cardView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            
            // Title & Subtitle
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 35),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            
            // Billing Header
            billingHeaderLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 25),
            billingHeaderLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 35),
            
            // Fields Stack
            fieldsStack.topAnchor.constraint(equalTo: billingHeaderLabel.bottomAnchor, constant: 20),
            fieldsStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 30),
            fieldsStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -30),
            
            // Pay Button
            payButton.topAnchor.constraint(equalTo: fieldsStack.bottomAnchor, constant: 30),
            payButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 30),
            payButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -30),
            payButton.heightAnchor.constraint(equalToConstant: 40),

            
            // Cancel Button
            cancelButton.topAnchor.constraint(equalTo: payButton.bottomAnchor, constant: 15),
            cancelButton.leadingAnchor.constraint(equalTo: payButton.leadingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: payButton.trailingAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            cancelButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -35),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: payButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: payButton.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        payButton.addTarget(self, action: #selector(handlePayment), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
    }

    @objc private func handlePayment() {
        view.endEditing(true)
        guard validateFields() else { return }
        
        payButton.isEnabled = false
        cancelButton.isEnabled = false
        activityIndicator.startAnimating()
        payButton.setTitle("", for: .normal)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.activityIndicator.stopAnimating()
            self.showSuccessAlert()
            self.payButton.setTitle("PROCEED TO PAY", for: .normal)
            
        }
    }
    
    @objc private func handleCancel() {
        self.dismiss(animated: true)
    }
    
    private func validateFields() -> Bool {
        let isCardValid = (cardNumberField.text?.replacingOccurrences(of: " ", with: "").count == 16)
        let isExpiryValid = isValidExpiry(expiryField.text ?? "")
        let isCvvValid = (cvvField.text?.count == 3)
        let isNameValid = !(nameField.text?.isEmpty ?? true)
        
        let allInvalid = !isCardValid && !isExpiryValid && !isCvvValid && !isNameValid
  
        isCardValid ? cardNumberField.clearError() : cardNumberField.showError()
        isExpiryValid ? expiryField.clearError() : expiryField.showError()
        isCvvValid ? cvvField.clearError() : cvvField.showError()
        isNameValid ? nameField.clearError() : nameField.showError()
        
        if allInvalid {
            showAlert(message: "Please enter your card details to proceed.")
            return false
        }
        
        if !isCardValid {
            showAlert(message: "Please enter a valid 16-digit card number.")
            return false
        }
        
        if !isExpiryValid {
            showAlert(message: "Please enter a valid expiry date (MM/YY).")
            return false
        }
        
        if !isCvvValid {
            showAlert(message: "Please enter a valid 3-digit CVV.")
            return false
        }
        
        if !isNameValid {
            showAlert(message: "Please enter the name printed on the card.")
            return false
        }
        
        return true
    }

    
    private func updateFieldUI(_ field: TextInputField, isValid: Bool, error: String) {
        if isValid {
            field.clearError()
        } else {
            field.showError()
        }
    }
    
    private func isValidExpiry(_ text: String) -> Bool {
        // Check MM/YY format first
        let regex = try! NSRegularExpression(pattern: "^(0[1-9]|1[0-2])/([0-9]{2})$")
        guard regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil else {
            return false
        }
        
        // Parse MM and YY
        let components = text.split(separator: "/")
        guard components.count == 2,
              let month = Int(components[0]),
              let year = Int(components[1]) else { return false }
        
        // Convert to full year
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date()) % 100 // last 2 digits
        let currentMonth = calendar.component(.month, from: Date())
        
        // Expiry must be current year+month or later
        if year < currentYear {
            return false
        } else if year == currentYear && month < currentMonth {
            return false
        }
        
        return true
    }
  
    
    private func showSuccessAlert() {
        let alert = UIAlertController(title: "Payment Successful", message: "Your session has been booked!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true) { self.onPaymentSuccess?() }
        })
        present(alert, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Payment", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = frame.height
        let rect = cardView.convert(payButton.frame, to: scrollView)
        scrollView.scrollRectToVisible(rect, animated: true)
    }
    
    @objc private func keyboardWillHide() {
        scrollView.contentInset.bottom = 0
    }
}

