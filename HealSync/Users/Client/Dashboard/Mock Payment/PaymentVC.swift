//
//  PaymentVC.swift
//  HealSync
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

    // MARK: - UI
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

    private let titleLabel = TitleLabel(text: "Proceed to Pay", fontSize: 20)

    // ── NEW: Price pill ──────────────────────────────────────────────────────
    private let pricePill: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E6F9FF")
        v.layer.cornerRadius = 14
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(hex: "#4FC3D8").cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let priceIconLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "💳"
        lbl.font = .systemFont(ofSize: 16)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let priceTextLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Session Fee: —"
        lbl.font = .systemFont(ofSize: 14, weight: .semibold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    // ────────────────────────────────────────────────────────────────────────

    private let billingHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "BILLING INFO"
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let fieldsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var cardNumberField = TextInputField(placeholder: "Card Number", type: .number, color: UIColor(hex: "#C1EDF6"))
    private var expiryField     = TextInputField(placeholder: "MM/YY",       type: .text,   color: UIColor(hex: "#C1EDF6"))
    private var cvvField        = TextInputField(placeholder: "CVV",          type: .number, color: UIColor(hex: "#C1EDF6"))
    private var nameField       = TextInputField(placeholder: "Name on Card", type: .text,   color: UIColor(hex: "#C1EDF6"))

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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#D1F0F8")
        setupHierarchy()
        setupConstraints()
        setupActions()
        registerKeyboardNotifications()
        populatePrice()          // ← fill price pill
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Price pill
    private func populatePrice() {
        if let price = bookingData?["price"] as? Int {
            priceTextLabel.text = "Session Fee: \(price) PKR"
        } else if let price = bookingData?["price"] as? Double {
            priceTextLabel.text = "Session Fee: \(Int(price)) PKR"
        }
    }

    // MARK: - Hierarchy
    private func setupHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(cardView)

        pricePill.addSubview(priceIconLabel)
        pricePill.addSubview(priceTextLabel)

        cardView.addSubview(titleLabel)
        cardView.addSubview(pricePill)
        cardView.addSubview(billingHeaderLabel)
        cardView.addSubview(fieldsStack)
        cardView.addSubview(payButton)
        cardView.addSubview(cancelButton)
        cardView.addSubview(activityIndicator)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints        = false

        [cardNumberField, expiryField, cvvField, nameField].forEach { fieldsStack.addArrangedSubview($0) }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor),

            cardView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),

            // Title
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 35),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            // Price pill
            pricePill.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            pricePill.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            pricePill.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            pricePill.heightAnchor.constraint(equalToConstant: 44),

            priceIconLabel.leadingAnchor.constraint(equalTo: pricePill.leadingAnchor, constant: 14),
            priceIconLabel.centerYAnchor.constraint(equalTo: pricePill.centerYAnchor),

            priceTextLabel.leadingAnchor.constraint(equalTo: priceIconLabel.trailingAnchor, constant: 8),
            priceTextLabel.centerYAnchor.constraint(equalTo: pricePill.centerYAnchor),
            priceTextLabel.trailingAnchor.constraint(equalTo: pricePill.trailingAnchor, constant: -14),

            // Billing header
            billingHeaderLabel.topAnchor.constraint(equalTo: pricePill.bottomAnchor, constant: 22),
            billingHeaderLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 35),

            // Fields
            fieldsStack.topAnchor.constraint(equalTo: billingHeaderLabel.bottomAnchor, constant: 20),
            fieldsStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 30),
            fieldsStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -30),

            // Pay button
            payButton.topAnchor.constraint(equalTo: fieldsStack.bottomAnchor, constant: 30),
            payButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 30),
            payButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -30),
            payButton.heightAnchor.constraint(equalToConstant: 40),

            // Cancel button
            cancelButton.topAnchor.constraint(equalTo: payButton.bottomAnchor, constant: 15),
            cancelButton.leadingAnchor.constraint(equalTo: payButton.leadingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: payButton.trailingAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            cancelButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -35),

            activityIndicator.centerXAnchor.constraint(equalTo: payButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: payButton.centerYAnchor)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        payButton.addTarget(self,   action: #selector(handlePayment), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(handleCancel),  for: .touchUpInside)
    }

    @objc private func handlePayment() {
        view.endEditing(true)
        guard validateFields() else { return }

        payButton.isEnabled    = false
        cancelButton.isEnabled = false
        activityIndicator.startAnimating()
        payButton.setTitle("", for: .normal)

        // Simulate a brief processing delay then go to Confirmation screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.payButton.setTitle("PROCEED TO PAY", for: .normal)
            self.payButton.isEnabled    = true
            self.cancelButton.isEnabled = true
            self.presentConfirmationScreen()
        }
    }

    private func presentConfirmationScreen() {
        let vc = PaymentConfirmationVC()
        vc.bookingData       = bookingData
        vc.therapistId       = therapistId
        vc.patientId         = patientId
        vc.bookingId         = bookingId
        vc.onPaymentSuccess  = onPaymentSuccess
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: true)
    }

    @objc private func handleCancel() { dismiss(animated: true) }

    // MARK: - Validation (unchanged)
    private func validateFields() -> Bool {
        let isCardValid   = (cardNumberField.text?.replacingOccurrences(of: " ", with: "").count == 16)
        let isExpiryValid = isValidExpiry(expiryField.text ?? "")
        let isCvvValid    = (cvvField.text?.count == 3)
        let isNameValid   = !(nameField.text?.isEmpty ?? true)

        isCardValid   ? cardNumberField.clearError() : cardNumberField.showError()
        isExpiryValid ? expiryField.clearError()     : expiryField.showError()
        isCvvValid    ? cvvField.clearError()         : cvvField.showError()
        isNameValid   ? nameField.clearError()        : nameField.showError()

        let allInvalid = !isCardValid && !isExpiryValid && !isCvvValid && !isNameValid
        if allInvalid { showAlert(message: "Please enter your card details to proceed."); return false }
        if !isCardValid   { showAlert(message: "Please enter a valid 16-digit card number."); return false }
        if !isExpiryValid { showAlert(message: "Please enter a valid expiry date (MM/YY)."); return false }
        if !isCvvValid    { showAlert(message: "Please enter a valid 3-digit CVV."); return false }
        if !isNameValid   { showAlert(message: "Please enter the name printed on the card."); return false }
        return true
    }

    private func isValidExpiry(_ text: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^(0[1-9]|1[0-2])/([0-9]{2})$")
        guard regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil else { return false }
        let components = text.split(separator: "/")
        guard components.count == 2, let month = Int(components[0]), let year = Int(components[1]) else { return false }
        let calendar     = Calendar.current
        let currentYear  = calendar.component(.year,  from: Date()) % 100
        let currentMonth = calendar.component(.month, from: Date())
        if year < currentYear { return false }
        if year == currentYear && month < currentMonth { return false }
        return true
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Payment", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Keyboard
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

    @objc private func keyboardWillHide() { scrollView.contentInset.bottom = 0 }
}
