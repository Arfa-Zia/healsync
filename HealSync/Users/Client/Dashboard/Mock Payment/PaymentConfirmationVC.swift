//
//  PaymentConfirmationVC.swift
//  HealSync
//
//  Created by Arfa on 06/05/2026.
//


import UIKit
import FirebaseAuth
import FirebaseFirestore
//import FirebaseFunctions

class PaymentConfirmationVC: UIViewController {

    // Passed in from PaymentVC
    var bookingData:      [String: Any]?
    var therapistId:      String?
    var patientId:        String?
    var bookingId:        String?
    var onPaymentSuccess: (() -> Void)?

    // MARK: - UI
    private let bgColor = UIColor(hex: "#D1F0F8")

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 28
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset  = CGSize(width: 0, height: 8)
        v.layer.shadowRadius  = 18
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Confirm Payment"
        lbl.font = .systemFont(ofSize: 22, weight: .bold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Please review your booking before confirming"
        lbl.font = .systemFont(ofSize: 13)
        lbl.textColor = .systemGray
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#D6EEF5")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Summary rows
    private let therapistRow = PaymentConfirmationVC.makeSummaryRow(icon: "stethoscope",   label: "Therapist")
    private let dateRow      = PaymentConfirmationVC.makeSummaryRow(icon: "calendar",      label: "Date")
    private let timeRow      = PaymentConfirmationVC.makeSummaryRow(icon: "clock",         label: "Time")
    private let typeRow      = PaymentConfirmationVC.makeSummaryRow(icon: "video.fill",    label: "Type")
    private let priceRow     = PaymentConfirmationVC.makeSummaryRow(icon: "creditcard.fill", label: "Amount")

    private let otpNoteLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 12)
        lbl.textColor = .systemGray
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let confirmButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("CONFIRM & SEND OTP", for: .normal)
        btn.backgroundColor = UIColor(hex: "#A3E8AB")
        btn.setTitleColor(UIColor(hex: "#1A4C1A"), for: .normal)
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("BACK", for: .normal)
        btn.backgroundColor = UIColor(hex: "#E3B5B5")
        btn.setTitleColor(UIColor(hex: "#4C1A1A"), for: .normal)
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        setupLayout()
        populateSummary()
    }

    // MARK: - Layout
    private func setupLayout() {
        let summaryStack = UIStackView(arrangedSubviews: [therapistRow, dateRow, timeRow, typeRow, priceRow])
        summaryStack.axis    = .vertical
        summaryStack.spacing = 14
        summaryStack.translatesAutoresizingMaskIntoConstraints = false

        let btnStack = UIStackView(arrangedSubviews: [confirmButton, backButton])
        btnStack.axis         = .vertical
        btnStack.spacing      = 12
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, subtitleLabel, divider, summaryStack, otpNoteLabel, btnStack, activityIndicator].forEach {
            cardView.addSubview($0)
        }
        view.addSubview(cardView)

        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        backButton.addTarget(self,    action: #selector(backTapped),    for: .touchUpInside)

        NSLayoutConstraint.activate([
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            divider.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
            divider.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 1),

            summaryStack.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 18),
            summaryStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            summaryStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            otpNoteLabel.topAnchor.constraint(equalTo: summaryStack.bottomAnchor, constant: 18),
            otpNoteLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            otpNoteLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            btnStack.topAnchor.constraint(equalTo: otpNoteLabel.bottomAnchor, constant: 20),
            btnStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            btnStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            btnStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -28),

            confirmButton.heightAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            activityIndicator.centerXAnchor.constraint(equalTo: confirmButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: confirmButton.centerYAnchor)
        ])
    }

    // MARK: - Populate
    private func populateSummary() {
        guard let data = bookingData else { return }

        setValue(in: therapistRow, text: "Dr. \(data["therapistName"] as? String ?? "—")")

        if let ts = data["sessionDateTime"] as? Timestamp {
            let date = ts.dateValue()
            let df   = DateFormatter()
            df.dateFormat = "dd MMM, yyyy"
            setValue(in: dateRow, text: df.string(from: date))

            df.dateFormat = "h:mm a"
            let duration  = data["duration"] as? Int ?? 45
            let start     = df.string(from: date)
            let end       = df.string(from: date.addingTimeInterval(TimeInterval(duration * 60)))
            setValue(in: timeRow, text: "\(start) – \(end)")
        }

        let type = data["sessionType"] as? String ?? "Video"
        setValue(in: typeRow, text: "\(type)  •  \(data["duration"] as? Int ?? 45) min")

        if let price = data["price"] as? Int {
            setValue(in: priceRow, text: "\(price) PKR", highlight: true)
        } else if let price = data["price"] as? Double {
            setValue(in: priceRow, text: "\(Int(price)) PKR", highlight: true)
        }

        // Show masked email
        let email = Auth.auth().currentUser?.email ?? ""
        otpNoteLabel.text = "A 6-digit OTP will be sent to\n\(maskEmail(email))"
    }

    private func maskEmail(_ email: String) -> String {
        let parts = email.split(separator: "@")
        guard parts.count == 2 else { return email }
        let name   = String(parts[0])
        let domain = String(parts[1])
        let visible = name.prefix(2)
        let stars   = String(repeating: "*", count: max(0, name.count - 2))
        return "\(visible)\(stars)@\(domain)"
    }

    // MARK: - Actions
    @objc private func confirmTapped() {
        setLoading(true)
        sendOTPViaFirebase()
    }

    @objc private func backTapped() { dismiss(animated: true) }

    // MARK: - OTP via Firebase Cloud Function
    private func sendOTPViaFirebase() {
        // Generate a 6-digit OTP and store it in Firestore; the Cloud Function
        // (triggered by onCreate on /otpCodes/{patientId}) emails it.
        let otp       = String(format: "%06d", Int.random(in: 100000...999999))
        let expiresAt = Timestamp(date: Date().addingTimeInterval(300)) // 5 min TTL
        guard let uid = Auth.auth().currentUser?.uid else { setLoading(false); return }

        Firestore.firestore()
            .collection("otpCodes")
            .document(uid)
            .setData(["code": otp, "expiresAt": expiresAt, "used": false]) { [weak self] error in
                guard let self = self else { return }
                self.setLoading(false)
                if let error = error {
                    self.showAlert("Failed to send OTP. Please try again.\n\(error.localizedDescription)")
                    return
                }
                self.navigateToOTPScreen(otp: otp)
            }
    }

    private func navigateToOTPScreen(otp: String) {
        let vc = OTPVerificationVC()
        vc.expectedOTP       = otp
        vc.bookingData       = bookingData
        vc.therapistId       = therapistId
        vc.patientId         = patientId
        vc.bookingId         = bookingId
        vc.onPaymentSuccess  = onPaymentSuccess
        vc.modalPresentationStyle = .overFullScreen
        present(vc, animated: true)
    }

    private func setLoading(_ loading: Bool) {
        confirmButton.isEnabled = !loading
        backButton.isEnabled    = !loading
        loading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        confirmButton.setTitle(loading ? "" : "CONFIRM & SEND OTP", for: .normal)
    }

    private func showAlert(_ msg: String) {
        let a = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // MARK: - Summary row factory
    private static func makeSummaryRow(icon: String, label: String) -> UIStackView {
        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor   = UIColor(hex: "#4FC3D8")
        img.contentMode = .scaleAspectFit
        img.widthAnchor.constraint(equalToConstant: 18).isActive  = true
        img.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let keyLbl = UILabel()
        keyLbl.text      = label
        keyLbl.font      = .systemFont(ofSize: 13, weight: .medium)
        keyLbl.textColor = .systemGray
        keyLbl.widthAnchor.constraint(equalToConstant: 80).isActive = true

        let valueLbl = UILabel()
        valueLbl.font         = .systemFont(ofSize: 14, weight: .semibold)
        valueLbl.textColor    = UIColor(hex: "#1A3A45")
        valueLbl.textAlignment = .right
        valueLbl.adjustsFontSizeToFitWidth = true
        valueLbl.minimumScaleFactor = 0.8

        let row = UIStackView(arrangedSubviews: [img, keyLbl, valueLbl])
        row.axis      = .horizontal
        row.spacing   = 10
        row.alignment = .center
        return row
    }

    private func setValue(in row: UIStackView, text: String, highlight: Bool = false) {
        if let lbl = row.arrangedSubviews.compactMap({ $0 as? UILabel }).last {
            lbl.text      = text
            lbl.textColor = highlight ? UIColor(hex: "#1A5C2A") : UIColor(hex: "#1A3A45")
            lbl.font      = highlight
                ? .systemFont(ofSize: 15, weight: .bold)
                : .systemFont(ofSize: 14, weight: .semibold)
        }
    }
}
