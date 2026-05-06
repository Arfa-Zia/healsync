//
//  ContactUsVC.swift
//  HealSync
//
//  Created by Arfa on 25/03/2026.
//
import UIKit
import FirebaseFirestore
import FirebaseAuth

class ContactUsVC: UIViewController, UITextViewDelegate {

   private let db       = Firestore.firestore()
   private let bgColor  = UIColor(hex: "#D1F0F8")
   private let teal     = UIColor(hex: "#4FC3D8")
   private let darkText = UIColor(hex: "#1A3A45")
   private let fieldBg  = UIColor(hex: "#EAF7FB")

   private let scrollView: UIScrollView = {
       let sv = UIScrollView()
       sv.showsVerticalScrollIndicator = false
       sv.translatesAutoresizingMaskIntoConstraints = false
       return sv
   }()

   private let card: UIView = {
       let v = UIView()
       v.backgroundColor    = .white.withAlphaComponent(0.9)
       v.layer.cornerRadius = 24
       v.layer.shadowColor   = UIColor.black.cgColor
       v.layer.shadowOpacity = 0.07
       v.layer.shadowOffset  = CGSize(width: 0, height: 4)
       v.layer.shadowRadius  = 12
       v.translatesAutoresizingMaskIntoConstraints = false
       return v
   }()

   // Info labels
   private lazy var emailInfoLbl = makeInfoLabel(text: "support@healsync.com", icon: "envelope.fill")
   private lazy var phoneInfoLbl = makeInfoLabel(text: "+92 300 1234567",       icon: "phone.fill")
   private lazy var locInfoLbl   = makeInfoLabel(text: "Lahore, Pakistan",      icon: "location.fill")

   private lazy var nameFieldWrapper  = makeFieldWrapper(placeholder: "Your Name",   icon: "person.fill",   keyboardType: .default)
   private lazy var emailFieldWrapper = makeFieldWrapper(placeholder: "Your Email",  icon: "envelope.fill", keyboardType: .emailAddress)

   private var nameTextField:  UITextField { nameFieldWrapper.viewWithTag(1)  as! UITextField }
   private var emailTextField: UITextField { emailFieldWrapper.viewWithTag(1) as! UITextField }

   private lazy var msgView: UITextView = {
       let tv = UITextView()
       tv.backgroundColor    = fieldBg
       tv.layer.cornerRadius = 14
       tv.font               = UIFont.systemFont(ofSize: 14)
       tv.textColor          = .placeholderText
       tv.text               = "How can we help you?"
       tv.textContainerInset = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
       tv.isScrollEnabled    = false
       tv.translatesAutoresizingMaskIntoConstraints = false
       tv.delegate           = self
       return tv
   }()

   private let sendBtn: UIButton = {
       let btn = UIButton(type: .system)
       btn.setTitle("SEND MESSAGE", for: .normal)
       btn.titleLabel?.font     = UIFont.systemFont(ofSize: 14, weight: .bold)
       btn.setTitleColor(.white, for: .normal)
       btn.backgroundColor      = UIColor(hex: "#4FC3D8")
       btn.layer.cornerRadius   = 14
       btn.translatesAutoresizingMaskIntoConstraints = false
       return btn
   }()

   private let activityIndicator: UIActivityIndicatorView = {
       let ai = UIActivityIndicatorView(style: .medium)
       ai.color = .white
       ai.hidesWhenStopped = true
       ai.translatesAutoresizingMaskIntoConstraints = false
       return ai
   }()

   // MARK: - Lifecycle
   override func viewDidLoad() {
       super.viewDidLoad()
       view.backgroundColor = bgColor
       setupNav()
       setupLayout()
       sendBtn.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

       let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
       view.addGestureRecognizer(tap)

       NotificationCenter.default.addObserver(self,
           selector: #selector(keyboardWillShow(_:)),
           name: UIResponder.keyboardWillShowNotification, object: nil)
       NotificationCenter.default.addObserver(self,
           selector: #selector(keyboardWillHide(_:)),
           name: UIResponder.keyboardWillHideNotification, object: nil)
   }

   override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
       navigationController?.setNavigationBarHidden(true, animated: animated)
       if let email = Auth.auth().currentUser?.email {
           emailTextField.text = email
       }
   }

   deinit { NotificationCenter.default.removeObserver(self) }

   // MARK: - Nav
   private func setupNav() {
       let backBtn = UIButton(type: .system)
       let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
       backBtn.setImage(UIImage(systemName: "arrow.left", withConfiguration: cfg), for: .normal)
       backBtn.tintColor = darkText
       backBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
       backBtn.translatesAutoresizingMaskIntoConstraints = false
       view.addSubview(backBtn)
       NSLayoutConstraint.activate([
           backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
           backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
           backBtn.widthAnchor.constraint(equalToConstant: 32),
           backBtn.heightAnchor.constraint(equalToConstant: 32)
       ])
   }

   // MARK: - Layout
   private func setupLayout() {
       view.addSubview(scrollView)
       scrollView.addSubview(card)
       sendBtn.addSubview(activityIndicator)

       NSLayoutConstraint.activate([
           scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
           scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
           scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
           scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

           card.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
           card.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 40),
           card.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -40),
           card.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
           card.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -80)
       ])

       let titleLbl = UILabel()
       titleLbl.text          = "Contact Us"
       titleLbl.font          = UIFont.systemFont(ofSize: 22, weight: .semibold)
       titleLbl.textAlignment = .center
       titleLbl.translatesAutoresizingMaskIntoConstraints = false

       let infoStack = UIStackView(arrangedSubviews: [emailInfoLbl, phoneInfoLbl, locInfoLbl])
       infoStack.axis      = .vertical
       infoStack.spacing   = 6
       infoStack.alignment = .center
       infoStack.translatesAutoresizingMaskIntoConstraints = false

       let divider = UIView()
       divider.backgroundColor = UIColor(hex: "#EAF5F8")
       divider.translatesAutoresizingMaskIntoConstraints = false

       [titleLbl, infoStack, divider,
        nameFieldWrapper, emailFieldWrapper, msgView, sendBtn].forEach { card.addSubview($0) }

       NSLayoutConstraint.activate([
           titleLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
           titleLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),

           infoStack.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 12),
           infoStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
           infoStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

           divider.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: 20),
           divider.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
           divider.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
           divider.heightAnchor.constraint(equalToConstant: 1),

           nameFieldWrapper.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 20),
           nameFieldWrapper.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 25),
           nameFieldWrapper.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -25),
           nameFieldWrapper.heightAnchor.constraint(equalToConstant: 45),

           emailFieldWrapper.topAnchor.constraint(equalTo: nameFieldWrapper.bottomAnchor, constant: 12),
           emailFieldWrapper.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 25),
           emailFieldWrapper.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -25),
           emailFieldWrapper.heightAnchor.constraint(equalToConstant: 45),

           msgView.topAnchor.constraint(equalTo: emailFieldWrapper.bottomAnchor, constant: 12),
           msgView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 25),
           msgView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -25),
           msgView.heightAnchor.constraint(greaterThanOrEqualToConstant: 110),

           sendBtn.topAnchor.constraint(equalTo: msgView.bottomAnchor, constant: 20),
           sendBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 25),
           sendBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -25),
           sendBtn.heightAnchor.constraint(equalToConstant: 45),
           sendBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28),

           activityIndicator.centerXAnchor.constraint(equalTo: sendBtn.centerXAnchor),
           activityIndicator.centerYAnchor.constraint(equalTo: sendBtn.centerYAnchor)
       ])
   }

   // MARK: - Factory: Info label
   private func makeInfoLabel(text: String, icon: String) -> UILabel {
       let lbl = UILabel()
       let cfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
       let img = UIImage(systemName: icon, withConfiguration: cfg)?
           .withTintColor(teal, renderingMode: .alwaysOriginal)
       let attachment = NSTextAttachment()
       attachment.image  = img
       attachment.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
       let attrStr = NSMutableAttributedString(attachment: attachment)
       attrStr.append(NSAttributedString(string: "  \(text)",
           attributes: [.font: UIFont.systemFont(ofSize: 13), .foregroundColor: UIColor.systemGray]))
       lbl.attributedText = attrStr
       lbl.translatesAutoresizingMaskIntoConstraints = false
       return lbl
   }

   private func makeFieldWrapper(placeholder: String, icon: String, keyboardType: UIKeyboardType) -> UIView {
       let wrapper = UIView()
       wrapper.backgroundColor    = fieldBg
       wrapper.layer.cornerRadius = 14
       wrapper.clipsToBounds      = true
       wrapper.translatesAutoresizingMaskIntoConstraints = false

       // Icon
       let cfg     = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
       let iconImg = UIImage(systemName: icon, withConfiguration: cfg)?
           .withTintColor(teal, renderingMode: .alwaysOriginal)
       let iconView = UIImageView(image: iconImg)
       iconView.contentMode = .scaleAspectFit
       iconView.translatesAutoresizingMaskIntoConstraints = false

       // Text field — no leftView, no padding tricks needed
       let tf = UITextField()
       tf.backgroundColor = .clear
       tf.font            = UIFont.systemFont(ofSize: 14)
       tf.textColor       = darkText
       tf.keyboardType    = keyboardType
       tf.attributedPlaceholder = NSAttributedString(
           string: placeholder,
           attributes: [.foregroundColor: UIColor.placeholderText])
       tf.translatesAutoresizingMaskIntoConstraints = false
       tf.tag = 1   // used by nameTextField / emailTextField computed vars

       wrapper.addSubview(iconView)
       wrapper.addSubview(tf)

       NSLayoutConstraint.activate([
           // Icon: fixed width, vertically centered
           iconView.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 14),
           iconView.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor),
           iconView.widthAnchor.constraint(equalToConstant: 18),
           iconView.heightAnchor.constraint(equalToConstant: 18),

           // TextField: starts right after icon, fills the rest
           tf.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
           tf.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -14),
           tf.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor),
           tf.heightAnchor.constraint(equalTo: wrapper.heightAnchor)
       ])

       return wrapper
   }

   // MARK: - Actions
   @objc private func sendTapped() {
       guard
           let name  = nameTextField.text,  !name.trimmingCharacters(in: .whitespaces).isEmpty,
           let email = emailTextField.text, !email.trimmingCharacters(in: .whitespaces).isEmpty,
           msgView.textColor != .placeholderText,
           !msgView.text.trimmingCharacters(in: .whitespaces).isEmpty
       else {
           showAlert(title: "Missing Info", message: "Please fill in all fields before sending.")
           return
       }

       setLoading(true)

       let data: [String: Any] = [
           "name":      name.trimmingCharacters(in: .whitespaces),
           "email":     email.trimmingCharacters(in: .whitespaces),
           "message":   msgView.text.trimmingCharacters(in: .whitespaces),
           "uid":       Auth.auth().currentUser?.uid ?? "anonymous",
           "timestamp": Timestamp(date: Date()),
           "status":    "unread"
       ]

       db.collection("contactSubmissions").addDocument(data: data) { [weak self] error in
           DispatchQueue.main.async {
               self?.setLoading(false)
               if let error = error {
                   self?.showAlert(title: "Error", message: "Could not send message.\n\(error.localizedDescription)")
               } else {
                   self?.showSuccessAndClear()
               }
           }
       }
   }

   private func setLoading(_ loading: Bool) {
       sendBtn.isEnabled = !loading
       if loading {
           sendBtn.setTitle("", for: .normal)
           activityIndicator.startAnimating()
       } else {
           activityIndicator.stopAnimating()
           sendBtn.setTitle("SEND MESSAGE", for: .normal)
       }
   }

   private func showSuccessAndClear() {
       nameTextField.text  = ""
       emailTextField.text = Auth.auth().currentUser?.email ?? ""
       msgView.text        = "How can we help you?"
       msgView.textColor   = .placeholderText

       let alert = UIAlertController(
           title: "Message Sent ✓",
           message: "We've received your message and will get back to you within 24 hours.",
           preferredStyle: .alert)
       alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
           self?.navigationController?.popViewController(animated: true)
       })
       present(alert, animated: true)
   }

   private func showAlert(title: String, message: String) {
       let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
       alert.addAction(UIAlertAction(title: "OK", style: .default))
       present(alert, animated: true)
   }

   @objc private func goBack()          { navigationController?.popViewController(animated: true) }
   @objc private func dismissKeyboard() { view.endEditing(true) }

   @objc private func keyboardWillShow(_ n: Notification) {
       if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
           scrollView.contentInset.bottom = frame.height + 20
       }
   }

   @objc private func keyboardWillHide(_ n: Notification) {
       scrollView.contentInset.bottom = 0
   }

   // MARK: - TextView placeholder
   func textViewDidBeginEditing(_ textView: UITextView) {
       if textView.textColor == .placeholderText {
           textView.text      = ""
           textView.textColor = darkText
       }
   }

   func textViewDidEndEditing(_ textView: UITextView) {
       if textView.text.trimmingCharacters(in: .whitespaces).isEmpty {
           textView.text      = "How can we help you?"
           textView.textColor = .placeholderText
       }
   }
}

