//
//  OTPVerificationVC.swift
//  HealSync
//
//  Created by Arfa on 06/05/2026.
//


import UIKit
import FirebaseAuth
import FirebaseFirestore

class OTPVerificationVC: UIViewController {

    // Passed in
    var expectedOTP:      String = ""
    var bookingData:      [String: Any]?
    var therapistId:      String?
    var patientId:        String?
    var bookingId:        String?
    var onPaymentSuccess: (() -> Void)?

    // MARK: - OTP boxes
    private var otpFields: [UITextField] = []
    private let boxCount = 6

    // MARK: - UI
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

    private let iconLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "✉️"
        lbl.font = .systemFont(ofSize: 44)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Verify OTP"
        lbl.font = .systemFont(ofSize: 22, weight: .bold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Enter the 6-digit code sent to your email"
        lbl.font = .systemFont(ofSize: 13)
        lbl.textColor = .systemGray
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let boxStack: UIStackView = {
        let sv = UIStackView()
        sv.axis         = .horizontal
        sv.spacing      = 10
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let errorLabel: UILabel = {
        let lbl = UILabel()
        lbl.text      = ""
        lbl.font      = .systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = UIColor(hex: "#C0392B")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let verifyButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("VERIFY & PAY", for: .normal)
        btn.backgroundColor = UIColor(hex: "#A3E8AB")
        btn.setTitleColor(UIColor(hex: "#1A4C1A"), for: .normal)
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let resendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Resend Code", for: .normal)
        btn.setTitleColor(UIColor(hex: "#4FC3D8"), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private var resendTimer:   Timer?
    private var resendCountdown = 60

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#D1F0F8")
        buildOTPBoxes()
        setupLayout()
        startResendTimer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.otpFields.first?.becomeFirstResponder()
        }
    }

    // MARK: - Build OTP boxes
    private func buildOTPBoxes() {
        for i in 0..<boxCount {
            let tf = UITextField()
            tf.keyboardType     = .numberPad
            tf.textAlignment    = .center
            tf.font             = .systemFont(ofSize: 22, weight: .bold)
            tf.textColor        = UIColor(hex: "#1A3A45")
            tf.backgroundColor  = UIColor(hex: "#E6F9FF")
            tf.layer.cornerRadius = 10
            tf.layer.borderWidth  = 1.5
            tf.layer.borderColor  = UIColor(hex: "#4FC3D8").cgColor
            tf.tag             = i
            tf.delegate        = self
            tf.addTarget(self, action: #selector(textChanged(_:)), for: .editingChanged)
            otpFields.append(tf)
            boxStack.addArrangedSubview(tf)
        }
    }

    // MARK: - Layout
    private func setupLayout() {
        [iconLabel, titleLabel, subtitleLabel, boxStack, errorLabel, verifyButton, resendButton, activityIndicator].forEach {
            cardView.addSubview($0)
        }
        view.addSubview(cardView)

        verifyButton.addTarget(self, action: #selector(verifyTapped),  for: .touchUpInside)
        resendButton.addTarget(self, action: #selector(resendTapped),  for: .touchUpInside)

        NSLayoutConstraint.activate([
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),

            iconLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 28),
            iconLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            boxStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
            boxStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            boxStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            boxStack.heightAnchor.constraint(equalToConstant: 52),

            errorLabel.topAnchor.constraint(equalTo: boxStack.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            verifyButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 20),
            verifyButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            verifyButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            verifyButton.heightAnchor.constraint(equalToConstant: 44),

            resendButton.topAnchor.constraint(equalTo: verifyButton.bottomAnchor, constant: 14),
            resendButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            resendButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -28),

            activityIndicator.centerXAnchor.constraint(equalTo: verifyButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: verifyButton.centerYAnchor)
        ])
    }

    // MARK: - Verify
    @objc private func verifyTapped() {
        let entered = otpFields.map { $0.text ?? "" }.joined()
        guard entered.count == boxCount else {
            shake(); errorLabel.text = "Please fill all 6 digits."; return
        }
        if entered == expectedOTP {
            errorLabel.text = ""
            verifyOTPInFirestore(enteredCode: entered)
        } else {
            errorLabel.text = "Incorrect code. Please try again."
            shake()
            otpFields.forEach {
                $0.text = ""
                $0.layer.borderColor = UIColor(hex: "#C0392B").cgColor
            }
            otpFields.first?.becomeFirstResponder()
        }
    }

    // Double-check against Firestore and mark as used
    private func verifyOTPInFirestore(enteredCode: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        setLoading(true)

        let ref = Firestore.firestore().collection("otpCodes").document(uid)
        ref.getDocument { [weak self] snap, error in
            guard let self = self else { return }
            self.setLoading(false)

            guard error == nil,
                  let data   = snap?.data(),
                  let stored  = data["code"]      as? String,
                  let expires = data["expiresAt"] as? Timestamp,
                  let used    = data["used"]      as? Bool else {
                self.errorLabel.text = "Verification failed. Please resend."
                return
            }
            guard !used else {
                self.errorLabel.text = "This OTP has already been used."
                return
            }
            guard expires.dateValue() > Date() else {
                self.errorLabel.text = "OTP expired. Please resend."
                return
            }
            guard stored == enteredCode else {
                self.errorLabel.text = "Incorrect code."
                self.shake()
                return
            }
            // Mark used
            ref.updateData(["used": true])
            self.navigateToSuccess()
        }
    }

    private func navigateToSuccess() {
        let vc = PaymentSuccessVC()
        vc.onGoToSessions  = { [weak self] in
            self?.onPaymentSuccess?()
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle   = .crossDissolve
        present(vc, animated: true)
    }

    // MARK: - Resend
    @objc private func resendTapped() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let otp       = String(format: "%06d", Int.random(in: 100000...999999))
        let expiresAt = Timestamp(date: Date().addingTimeInterval(300))
        expectedOTP   = otp
        resendButton.isEnabled = false

        Firestore.firestore().collection("otpCodes").document(uid)
            .setData(["code": otp, "expiresAt": expiresAt, "used": false]) { [weak self] _ in
                self?.startResendTimer()
            }
        otpFields.forEach { $0.text = ""; $0.layer.borderColor = UIColor(hex: "#4FC3D8").cgColor }
        errorLabel.text = ""
        otpFields.first?.becomeFirstResponder()
    }

    private func startResendTimer() {
        resendCountdown = 60
        resendButton.isEnabled = false
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            self.resendCountdown -= 1
            if self.resendCountdown <= 0 {
                t.invalidate()
                self.resendButton.isEnabled = true
                self.resendButton.setTitle("Resend Code", for: .normal)
            } else {
                self.resendButton.setTitle("Resend in \(self.resendCountdown)s", for: .normal)
            }
        }
    }

    // MARK: - Helpers
    private func setLoading(_ on: Bool) {
        verifyButton.isEnabled = !on
        on ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        verifyButton.setTitle(on ? "" : "VERIFY & PAY", for: .normal)
    }

    private func shake() {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.duration       = 0.4
        anim.values         = [-8, 8, -6, 6, -4, 4, 0]
        boxStack.layer.add(anim, forKey: "shake")
    }

    deinit { resendTimer?.invalidate() }
}

// MARK: - UITextFieldDelegate (auto-advance between boxes)
extension OTPVerificationVC: UITextFieldDelegate {
    @objc func textChanged(_ tf: UITextField) {
        let text = tf.text ?? ""
        if text.count > 1 { tf.text = String(text.prefix(1)) }
        tf.layer.borderColor = UIColor(hex: "#4FC3D8").cgColor
        errorLabel.text = ""

        if !text.isEmpty, tf.tag < boxCount - 1 {
            otpFields[tf.tag + 1].becomeFirstResponder()
        }
        // Auto-verify when all boxes filled
        let full = otpFields.map { $0.text ?? "" }.joined()
        if full.count == boxCount { verifyTapped() }
    }

    func textField(_ tf: UITextField, shouldChangeCharactersIn range: NSRange, replacementString s: String) -> Bool {
        if s.isEmpty { // backspace → go back
            tf.text = ""
            if tf.tag > 0 { otpFields[tf.tag - 1].becomeFirstResponder() }
            return false
        }
        return s.rangeOfCharacter(from: .decimalDigits) != nil
    }
}
