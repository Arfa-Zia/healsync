//
//  LoginVC.swift
//  HealSync
//
//  Created by Arfa on 13/01/2026.
//
//
//import UIKit
//import FirebaseAuth
//import FirebaseFirestore
//import GoogleSignIn
//import FirebaseCore
//import AuthenticationServices
//import CryptoKit
//
//class LoginVC: BaseViewController {
//
//    private var containerView = BaseContainer()
//    private var titleLabel = TitleLabel(text: "Welcome Back", fontSize: 30)
//    private var subtitleLabel = SubtitleLabel(text: "Log In to continue your journey", noOfLines: 0)
//    private var email = TextInputField(placeholder: "Email Address", type: .email, color: UIColor(hex: "#90E0EF"), alphaValue: 0.44)
//    private var password = TextInputField(placeholder: "Password", type: .password, color: UIColor(hex: "#90E0EF"), alphaValue: 0.44)
//
//    private var loginBtn = PrimaryButton(title: "Log In")
//    private var googleBtn = SocialButton(title: "Log In with", iconName: "google-logo")
//    private var appleBtn = SocialButton(title: "Log In with", iconName: "apple-logo")
//    private var signupLink = Hyperlink(fullText: "Don't have an account  Sign up", linkText: "Sign up")
//    private var forgotLink = Hyperlink(fullText: "Forgot password?", linkText: "Forgot password?")
//
//    fileprivate var currentNonce: String?
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupAction()
//        setupLayout()
//    }
//
//    private func setupAction() {
//        signupLink.onLinkTap = { [weak self] in self?.navigateToSignup() }
//        forgotLink.onLinkTap = { [weak self] in self?.navigateToForgotPassword() }
//        loginBtn.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
//        googleBtn.addTarget(self, action: #selector(handleGoogleLogin), for: .touchUpInside)
//        appleBtn.addTarget(self, action: #selector(handleAppleLogin), for: .touchUpInside)
//    }
//
//    private func navigateToSignup() {
//        let vc = SignupVC()
//        guard let wecolmeVC = navigationController?.viewControllers.first else { return }
//        navigationController?.setViewControllers([wecolmeVC, vc], animated: true)
//    }
//
//    private func navigateToForgotPassword() {
//        let vc = ForgotPasswordVC()
//        navigationController?.pushViewController(vc, animated: true)
//    }
//
//    @objc private func handleLogin() {
//        email.clearError()
//        password.clearError()
//
//        var hasError = false
//        if email.text?.isEmpty ?? true { email.showError(); hasError = true }
//        if password.text?.isEmpty ?? true { password.showError(); hasError = true }
//        if hasError { return }
//
//        loginUser(email: email.text!, password: password.text!)
//    }
//
//    private func loginUser(email: String, password: String) {
//        Auth.auth().signIn(withEmail: email, password: password) { result, error in
//            if let error = error as NSError? {
//                guard let errorCode = AuthErrorCode(rawValue: error.code) else {
//                    self.showAlert(message: error.localizedDescription)
//                    return
//                }
//
//                switch errorCode {
//                case .userNotFound:
//                    self.email.showError(); self.showAlert(message: "No account found with this email.")
//                case .wrongPassword:
//                    self.password.showError(); self.showAlert(message: "Incorrect password.")
//                case .invalidEmail:
//                    self.email.showError(); self.showAlert(message: "Invalid email format.")
//                default:
//                    self.showAlert(message: error.localizedDescription)
//                }
//                return
//            }
//
//            guard let uid = result?.user.uid else { return }
//            self.fetchUserRole(uid: uid)
//        }
//    }
//
//    private func fetchUserRole(uid: String) {
//        let db = Firestore.firestore()
//        db.collection("users").document(uid).getDocument { document, error in
//            if let error = error { self.showAlert(message: error.localizedDescription); return }
//
//            if let data = document?.data(),
//               let role = data["role"] as? String {
//                DispatchQueue.main.async { self.navigateAfterLogin(role: role) }
//            } else {
//                // If role not found, maybe ask user to select role
//                DispatchQueue.main.async {
//                    let roleVC = ChooseRoleVC()
//                    self.navigationController?.pushViewController(roleVC, animated: true)
//                }
//            }
//        }
//    }
//
//    private func navigateAfterLogin(role: String) {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        let db = Firestore.firestore()
//
//        db.collection("users").document(uid).getDocument { [weak self] document, error in
//            if let error = error { self?.showAlert(message: error.localizedDescription); return }
//
//            let isComplete = document?.data()?["isOnboardingComplete"] as? Bool ?? false
//
//            DispatchQueue.main.async {
//                if isComplete {
//                    // Fully onboarded — go to dashboard
//                    if role == "patient" {
//                        ListenerManager.shared.startListening()
//                        let vc = ClientMainTabBarController()
//                        self?.navigationController?.setViewControllers([vc], animated: true)
//                    } else {
//                        ListenerManager.shared.startListening()
//                        let vc = TherapistMainTabBarController()
//                        self?.navigationController?.setViewControllers([vc], animated: true)
//                    }
//                } else {
//                    // Incomplete onboarding — resume where they left off
//                    if role == "patient" {
//                        let vc = ClientWelcomeVC()
//                        self?.navigationController?.setViewControllers([vc], animated: true)
//                    } else {
//                        let vc = TherapistWelcomeVC()
//                        self?.navigationController?.setViewControllers([vc], animated: true)
//                    }
//                }
//            }
//        }
//    }
//
//    @objc private func handleGoogleLogin() {
//        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
//        let config = GIDConfiguration(clientID: clientID)
//        GIDSignIn.sharedInstance.configuration = config
//
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let rootVC = windowScene.windows.first?.rootViewController else { return }
//
//        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
//            if let error = error { self?.showAlert(message: error.localizedDescription); return }
//            guard let user = result?.user, let idToken = user.idToken?.tokenString else { return }
//
//            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
//            Auth.auth().signIn(with: credential) { authResult, error in
//                if let error = error { self?.showAlert(message: error.localizedDescription); return }
//                guard let firebaseUser = authResult?.user else { return }
//                self?.checkUserInFirestore(uid: firebaseUser.uid, name: firebaseUser.displayName, email: firebaseUser.email)
//            }
//        }
//    }
//
//    private func checkUserInFirestore(uid: String, name: String?, email: String?) {
//        let db = Firestore.firestore()
//        db.collection("users").document(uid).getDocument { document, error in
//            if let error = error { self.showAlert(message: error.localizedDescription); return }
//
//            if let data = document?.data(), let role = data["role"] as? String {
//                DispatchQueue.main.async { self.navigateAfterLogin(role: role) }
//            } else {
//                // ✅ Pass the Firebase user so ChooseRoleVC can complete signup
//                DispatchQueue.main.async {
//                    let roleVC = ChooseRoleVC()
//                    roleVC.pendingGoogleUser = Auth.auth().currentUser // pass the logged-in user
//                    self.navigationController?.pushViewController(roleVC, animated: true)
//                }
//            }
//        }
//    }
//    
//    @objc private func handleAppleLogin() {
//        let nonce = randomNonceString()
//        currentNonce = nonce
//
//        let request = ASAuthorizationAppleIDProvider().createRequest()
//        request.requestedScopes = [.fullName, .email]
//        request.nonce = sha256(nonce)
//
//        let controller = ASAuthorizationController(authorizationRequests: [request])
//        controller.delegate = self
//        controller.presentationContextProvider = self
//        controller.performRequests()
//    }
//
//    private func sha256(_ input: String) -> String {
//        let inputData = Data(input.utf8)
//        let hashedData = SHA256.hash(data: inputData)
//        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
//    }
//
//    private func randomNonceString(length: Int = 32) -> String {
//        precondition(length > 0)
//        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
//        var result = ""
//        var remainingLength = length
//
//        while remainingLength > 0 {
//            let randoms: [UInt8] = (0..<16).map { _ in
//                var random: UInt8 = 0
//                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
//                if status != errSecSuccess { fatalError("Unable to generate nonce: \(status)") }
//                return random
//            }
//            randoms.forEach { random in
//                if remainingLength == 0 { return }
//                if random < charset.count { result.append(charset[Int(random) % charset.count]); remainingLength -= 1 }
//            }
//        }
//        return result
//    }
//    
//    private func setupLayout(){
//        let leftLine = UIView()
//        leftLine.backgroundColor = .systemGray4
//            
//        let orLabel = UILabel()
//        orLabel.text = "OR"
//        orLabel.font = .systemFont(ofSize: 12, weight: .medium)
//        orLabel.textColor = .systemGray
//        orLabel.textAlignment = .center
//            
//        let rightLine = UIView()
//        rightLine.backgroundColor = .systemGray4
//            
//           
//        let dividerStack = UIStackView(arrangedSubviews: [leftLine, orLabel, rightLine])
//        dividerStack.axis = .horizontal
//        dividerStack.spacing = 10
//        dividerStack.alignment = .center
//        dividerStack.distribution = .fill
//        
//        
//        let formView = UIStackView(arrangedSubviews: [email , password ])
//        formView.axis = .vertical
//        formView.spacing = 20
//        
//        let formHeaderView = UIStackView(arrangedSubviews: [titleLabel , subtitleLabel])
//        formHeaderView.axis = .vertical
//        formHeaderView.spacing = 7
//        
//        let socialLoginView = UIStackView(arrangedSubviews: [googleBtn , appleBtn])
//        socialLoginView.axis = .horizontal
//        socialLoginView.spacing = 16
//        socialLoginView.distribution = .fillEqually
//        
//        let loginView = UIStackView(arrangedSubviews: [loginBtn, forgotLink ,dividerStack, socialLoginView , signupLink])
//        loginView.axis = .vertical
//        loginView.spacing = 16
//        loginView.alignment = .fill
//       
//        let stackView = UIStackView(arrangedSubviews: [formHeaderView, formView, loginView])
//        stackView.axis = .vertical
//        stackView.spacing = 24
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        
//        
//        view.addSubview(containerView)
//        containerView.addSubview(stackView)
//        
//        containerView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 40, leading: 30, bottom: 40, trailing: 30)
//        
//        forgotLink.textAlignment = .right
//        signupLink.textAlignment = .center
//        
//        NSLayoutConstraint.activate([
//            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.77),
//            
//            stackView.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor),
//            stackView.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
//            stackView.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor),
//            stackView.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor),
//            
//            socialLoginView.heightAnchor.constraint(equalToConstant: 35),
//            loginBtn.widthAnchor.constraint(equalTo: loginView.widthAnchor),
//            socialLoginView.widthAnchor.constraint(equalTo: loginView.widthAnchor),
//            leftLine.heightAnchor.constraint(equalToConstant: 1),
//            rightLine.heightAnchor.constraint(equalToConstant: 1),
//            leftLine.widthAnchor.constraint(equalTo: rightLine.widthAnchor),
//            dividerStack.widthAnchor.constraint(equalTo: stackView.widthAnchor)
//    
//        ])
//    }
//   
//}
//
//extension LoginVC: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
//    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
//        return self.view.window!
//    }
//
//    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
//        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
//            guard let nonce = currentNonce else { fatalError("Invalid state: No login request sent") }
//            guard let appleIDToken = appleIDCredential.identityToken else { print("No token"); return }
//            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else { print("Cannot serialize token"); return }
//
//            let credential = OAuthProvider.credential(
//                providerID: .apple,
//                idToken: idTokenString,
//                rawNonce: nonce
//            )
//
//            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
//                if let error = error { self?.showAlert(message: error.localizedDescription); return }
//                guard let firebaseUser = authResult?.user else { return }
//                self?.checkUserInFirestore(uid: firebaseUser.uid, name: firebaseUser.displayName, email: firebaseUser.email)
//            }
//        }
//    }
//
//    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
//        showAlert(message: error.localizedDescription)
//    }
//}

//
//  LoginVC.swift
//  HealSync
//
//  Created by Arfa on 13/01/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore

class LoginVC: BaseViewController {

    private var containerView = BaseContainer()
    private var titleLabel = TitleLabel(text: "Welcome Back", fontSize: 30)
    private var subtitleLabel = SubtitleLabel(text: "Log In to continue your journey", noOfLines: 0)
    private var email = TextInputField(placeholder: "Email Address", type: .email, color: UIColor(hex: "#90E0EF"), alphaValue: 0.44)
    private var password = TextInputField(placeholder: "Password", type: .password, color: UIColor(hex: "#90E0EF"), alphaValue: 0.44)

    private var loginBtn = PrimaryButton(title: "Log In")
    private var googleBtn = SocialButton(title: "Log In with", iconName: "google-logo")
    private var signupLink = Hyperlink(fullText: "Don't have an account  Sign up", linkText: "Sign up")
    private var forgotLink = Hyperlink(fullText: "Forgot password?", linkText: "Forgot password?")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAction()
        setupLayout()
    }

    private func setupAction() {
        signupLink.onLinkTap = { [weak self] in self?.navigateToSignup() }
        forgotLink.onLinkTap = { [weak self] in self?.navigateToForgotPassword() }
        loginBtn.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        googleBtn.addTarget(self, action: #selector(handleGoogleLogin), for: .touchUpInside)
    }

    private func navigateToSignup() {
        let vc = SignupVC()
        guard let wecolmeVC = navigationController?.viewControllers.first else { return }
        navigationController?.setViewControllers([wecolmeVC, vc], animated: true)
    }

    private func navigateToForgotPassword() {
        let vc = ForgotPasswordVC()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func handleLogin() {
        email.clearError()
        password.clearError()

        var hasError = false
        if email.text?.isEmpty ?? true { email.showError(); hasError = true }
        if password.text?.isEmpty ?? true { password.showError(); hasError = true }
        if hasError { return }

        loginUser(email: email.text!, password: password.text!)
    }

    private func loginUser(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                guard let errorCode = AuthErrorCode(rawValue: error.code) else {
                    self.showAlert(message: error.localizedDescription)
                    return
                }

                switch errorCode {
                case .userNotFound:
                    self.email.showError(); self.showAlert(message: "No account found with this email.")
                case .wrongPassword:
                    self.password.showError(); self.showAlert(message: "Incorrect password.")
                case .invalidEmail:
                    self.email.showError(); self.showAlert(message: "Invalid email format.")
                default:
                    self.showAlert(message: error.localizedDescription)
                }
                return
            }

            guard let uid = result?.user.uid else { return }
            self.fetchUserRole(uid: uid)
        }
    }

    private func fetchUserRole(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error { self.showAlert(message: error.localizedDescription); return }

            if let data = document?.data(),
               let role = data["role"] as? String {
                DispatchQueue.main.async { self.navigateAfterLogin(role: role) }
            } else {
                DispatchQueue.main.async {
                    let roleVC = ChooseRoleVC()
                    self.navigationController?.pushViewController(roleVC, animated: true)
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

    @objc private func handleGoogleLogin() {
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
                self?.checkUserInFirestore(uid: firebaseUser.uid, name: firebaseUser.displayName, email: firebaseUser.email)
            }
        }
    }

    private func checkUserInFirestore(uid: String, name: String?, email: String?) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error { self.showAlert(message: error.localizedDescription); return }

            if let data = document?.data(), let role = data["role"] as? String {
                DispatchQueue.main.async { self.navigateAfterLogin(role: role) }
            } else {
                DispatchQueue.main.async {
                    let roleVC = ChooseRoleVC()
                    roleVC.pendingGoogleUser = Auth.auth().currentUser
                    self.navigationController?.pushViewController(roleVC, animated: true)
                }
            }
        }
    }

    private func setupLayout() {
        let leftLine = UIView()
        leftLine.backgroundColor = .systemGray4

        let orLabel = UILabel()
        orLabel.text = "OR"
        orLabel.font = .systemFont(ofSize: 12, weight: .medium)
        orLabel.textColor = .systemGray
        orLabel.textAlignment = .center

        let rightLine = UIView()
        rightLine.backgroundColor = .systemGray4

        let dividerStack = UIStackView(arrangedSubviews: [leftLine, orLabel, rightLine])
        dividerStack.axis = .horizontal
        dividerStack.spacing = 10
        dividerStack.alignment = .center
        dividerStack.distribution = .fill

        let formView = UIStackView(arrangedSubviews: [email, password])
        formView.axis = .vertical
        formView.spacing = 20

        let formHeaderView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        formHeaderView.axis = .vertical
        formHeaderView.spacing = 7

        let loginView = UIStackView(arrangedSubviews: [loginBtn, forgotLink, dividerStack, googleBtn, signupLink])
        loginView.axis = .vertical
        loginView.spacing = 16
        loginView.alignment = .fill

        let stackView = UIStackView(arrangedSubviews: [formHeaderView, formView, loginView])
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(containerView)
        containerView.addSubview(stackView)

        containerView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 40, leading: 30, bottom: 40, trailing: 30)

        forgotLink.textAlignment = .right
        signupLink.textAlignment = .center

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.77),

            stackView.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor),

            googleBtn.heightAnchor.constraint(equalToConstant: 35),
            loginBtn.widthAnchor.constraint(equalTo: loginView.widthAnchor),
            googleBtn.widthAnchor.constraint(equalTo: loginView.widthAnchor),
            leftLine.heightAnchor.constraint(equalToConstant: 1),
            rightLine.heightAnchor.constraint(equalToConstant: 1),
            leftLine.widthAnchor.constraint(equalTo: rightLine.widthAnchor),
            dividerStack.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }
}
