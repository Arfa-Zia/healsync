//
//  SignupVC.swift
//  HealSync
//
//  Created by Arfa on 12/01/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore
import AuthenticationServices
import CryptoKit

class SignupVC: BaseViewController {

    private var containerView = BaseContainer()
    private var titleLabel = TitleLabel(text: "Welcome", fontSize: 30)
    private var subtitleLabel = SubtitleLabel(text: "Sign up to start your journey", noOfLines: 0)
    private var fullName = TextInputField(placeholder: "Full Name", type: .text, color: UIColor(hex: "#90E0EF"), alphaValue: 0.44)
    private var email = TextInputField(placeholder: "Email Address", type: .email, color: UIColor(hex: "#90E0EF"), alphaValue: 0.44)
    private var password = TextInputField(placeholder: "Password", type: .password, color: UIColor(hex: "#90E0EF"), alphaValue: 0.44)
    private var againPassword = TextInputField(placeholder: "Confirm Password", type: .password, color: UIColor(hex: "#90E0EF"), alphaValue: 0.44)
    private var signupBtn = PrimaryButton(title: "Sign Up")
    private var googleBtn = SocialButton(title: "Sign up with", iconName: "google-logo")
    private var appleBtn = SocialButton(title: "Sign up with", iconName: "apple-logo")
    private var loginLink = Hyperlink(fullText: "Already have an account  Log In", linkText: "Log In")

    fileprivate var currentNonce: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
        setupLayout()
    }

    private func setupActions() {
        loginLink.onLinkTap = { [weak self] in self?.navigateToLogin() }
        signupBtn.addTarget(self, action: #selector(handleEmailSignup), for: .touchUpInside)
        googleBtn.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
        appleBtn.addTarget(self, action: #selector(handleAppleSignIn), for: .touchUpInside)
    }

    private func navigateToLogin() {
        let vc = LoginVC()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func handleEmailSignup() {
        fullName.clearError()
        email.clearError()
        password.clearError()
        againPassword.clearError()

        var hasError = false
        if fullName.text?.isEmpty ?? true { fullName.showError(); hasError = true }
        if email.text?.isEmpty ?? true { email.showError(); hasError = true }
        if password.text?.isEmpty ?? true { password.showError(); hasError = true }
        if againPassword.text?.isEmpty ?? true { againPassword.showError(); hasError = true }
        if hasError { return }

        guard let userPassword = password.text, let confirmPassword = againPassword.text else { return }
        if userPassword != confirmPassword {
            password.showError()
            againPassword.showError()
            showAlert(message: "Passwords do not match")
            return
        }

        guard let role = UserDefaults.standard.string(forKey: "selectedRole") else {
            showAlert(message: "Something went wrong. Please select your role again.")
            return
        }

        Auth.auth().createUser(withEmail: email.text!, password: userPassword) { [weak self] result, error in
            if let error = error {
                self?.showAlert(message: error.localizedDescription)
                return
            }
            guard let uid = result?.user.uid else { return }
            self?.saveUserData(uid: uid, name: self?.fullName.text ?? "", email: self?.email.text ?? "", role: role)
        }
    }

    @objc private func handleGoogleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
            if let error = error { self?.showAlert(message: error.localizedDescription); return }
            guard let user = result?.user, let idToken = user.idToken?.tokenString else { return }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error { self?.showAlert(message: error.localizedDescription); return }
                guard let firebaseUser = authResult?.user else { return }

                // ✅ Check if user already exists before overwriting
                let db = Firestore.firestore()
                db.collection("users").document(firebaseUser.uid).getDocument { document, error in
                    if let error = error { self?.showAlert(message: error.localizedDescription); return }

                    if let data = document?.data(), let role = data["role"] as? String {
                        // User already exists — go straight to dashboard
                        DispatchQueue.main.async { self?.navigateAfterLogin(role: role) }
                    } else {
                        // New user — save data and start onboarding
                        self?.saveUserToFirestore(user: firebaseUser)
                    }
                }
            }
        }
    }

    private func navigateAfterLogin(role: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(uid).getDocument { [weak self] document, error in
            if let error = error { self?.showAlert(message: error.localizedDescription); return }

            let isComplete = document?.data()?["isOnboardingComplete"] as? Bool ?? false

            DispatchQueue.main.async {
                if isComplete {
                    // Fully onboarded — go to dashboard
                    if role == "patient" {
                        ListenerManager.shared.startListening()
                        let vc = ClientMainTabBarController()
                        self?.navigationController?.setViewControllers([vc], animated: true)
                    } else {
                        ListenerManager.shared.startListening()
                        let vc = TherapistMainTabBarController()
                        self?.navigationController?.setViewControllers([vc], animated: true)
                    }
                } else {
                    // Incomplete onboarding — resume where they left off
                    if role == "patient" {
                        let vc = ClientWelcomeVC()
                        self?.navigationController?.setViewControllers([vc], animated: true)
                    } else {
                        let vc = TherapistWelcomeVC()
                        self?.navigationController?.setViewControllers([vc], animated: true)
                    }
                }
            }
        }
    }


    @objc private func handleAppleSignIn() {
        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }


    private func saveUserToFirestore(user: User) {
        guard let role = UserDefaults.standard.string(forKey: "selectedRole") else {
            showAlert(message: "Please select role again.")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).setData([
            "fullName": user.displayName ?? "",
            "email": user.email ?? "",
            "role": role,
            "createdAt": Timestamp()
        ]) { [weak self] error in
            if let error = error { self?.showAlert(message: error.localizedDescription); return }
            UserDefaults.standard.removeObject(forKey: "selectedRole")
            self?.navigateAfterSignup(role: role)
        }
    }

    private func saveUserData(uid: String, name: String, email: String, role: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "uid": uid,
            "fullName": name,
            "email": email,
            "role": role,
            "createdAt": Timestamp()
        ]) { [weak self] error in
            if let error = error { print("Firestore error:", error.localizedDescription); return }
            self?.navigateAfterSignup(role: role)
        }
    }

    
    private func navigateAfterSignup(role: String) {
        UserDefaults.standard.removeObject(forKey: "selectedRole")
        if role == "patient" {
            let vc = ClientWelcomeVC()
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = TherapistWelcomeVC()
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if status != errSecSuccess { fatalError("Unable to generate nonce: \(status)") }
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count { result.append(charset[Int(random) % charset.count]); remainingLength -= 1 }
            }
        }
        return result
    }

    
    private func setupLayout() {
        let leftLine = UIView(); leftLine.backgroundColor = .systemGray4
        let orLabel = UILabel(); orLabel.text = "OR"; orLabel.font = .systemFont(ofSize: 12, weight: .medium); orLabel.textColor = .systemGray; orLabel.textAlignment = .center
        let rightLine = UIView(); rightLine.backgroundColor = .systemGray4
        let dividerStack = UIStackView(arrangedSubviews: [leftLine, orLabel, rightLine])
        dividerStack.axis = .horizontal; dividerStack.spacing = 10; dividerStack.alignment = .center; dividerStack.distribution = .fill

        let formView = UIStackView(arrangedSubviews: [fullName, email, password, againPassword])
        formView.axis = .vertical; formView.spacing = 20

        let formHeaderView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        formHeaderView.axis = .vertical; formHeaderView.spacing = 7

        let socialLoginView = UIStackView(arrangedSubviews: [googleBtn, appleBtn])
        socialLoginView.axis = .horizontal; socialLoginView.spacing = 16; socialLoginView.distribution = .fillEqually

        let loginView = UIStackView(arrangedSubviews: [signupBtn, dividerStack, socialLoginView, loginLink])
        loginView.axis = .vertical; loginView.spacing = 12; loginView.alignment = .center

        let stackView = UIStackView(arrangedSubviews: [formHeaderView, formView, loginView])
        stackView.axis = .vertical; stackView.spacing = 25; stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(containerView)
        containerView.addSubview(stackView)
        containerView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 30, leading: 30, bottom: 50, trailing: 30)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.77),
            stackView.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor),
            socialLoginView.heightAnchor.constraint(equalToConstant: 35),
            signupBtn.widthAnchor.constraint(equalTo: loginView.widthAnchor),
            socialLoginView.widthAnchor.constraint(equalTo: loginView.widthAnchor),
            leftLine.heightAnchor.constraint(equalToConstant: 1),
            rightLine.heightAnchor.constraint(equalToConstant: 1),
            leftLine.widthAnchor.constraint(equalTo: rightLine.widthAnchor),
            dividerStack.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }
}


extension SignupVC: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else { fatalError("Invalid state: No login request sent") }
            guard let appleIDToken = appleIDCredential.identityToken else { print("No token"); return }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else { print("Cannot serialize token"); return }

            let credential = OAuthProvider.credential(providerID: .apple, idToken: idTokenString, rawNonce: nonce)
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                if let error = error { self?.showAlert(message: error.localizedDescription); return }
                guard let firebaseUser = authResult?.user else { return }
                self?.saveUserToFirestore(user: firebaseUser)
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        showAlert(message: error.localizedDescription)
    }
}
