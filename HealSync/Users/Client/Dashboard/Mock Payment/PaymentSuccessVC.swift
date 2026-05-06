//
//  PaymentSuccessVC.swift
//  HealSync
//


import UIKit

class PaymentSuccessVC: UIViewController {

    var onGoToSessions: (() -> Void)?

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

    private let checkCircle: UIView = {
        let v = UIView()
        v.backgroundColor   = UIColor(hex: "#A3E8AB")
        v.layer.cornerRadius = 44
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let checkIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .bold)
        let iv = UIImageView(image: UIImage(systemName: "checkmark", withConfiguration: config))
        iv.tintColor   = UIColor(hex: "#1A5C2A")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Payment Successful!"
        lbl.font = .systemFont(ofSize: 24, weight: .bold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Your session has been booked.\nYou'll receive a confirmation shortly."
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = .systemGray
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let goToSessionsButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("GO TO SESSIONS", for: .normal)
        btn.backgroundColor = UIColor(hex: "#4FC3D8")
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 14
        btn.titleLabel?.font   = .systemFont(ofSize: 15, weight: .bold)
        btn.layer.shadowColor   = UIColor(hex: "#4FC3D8").cgColor
        btn.layer.shadowOpacity = 0.35
        btn.layer.shadowOffset  = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius  = 8
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#D1F0F8")
        setupLayout()
        animateCheckIn()
    }

    // MARK: - Layout
    private func setupLayout() {
        checkCircle.addSubview(checkIcon)
        [checkCircle, titleLabel, subtitleLabel, goToSessionsButton].forEach { cardView.addSubview($0) }
        view.addSubview(cardView)

        goToSessionsButton.addTarget(self, action: #selector(goToSessionsTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -36),

            checkCircle.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 36),
            checkCircle.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            checkCircle.widthAnchor.constraint(equalToConstant: 88),
            checkCircle.heightAnchor.constraint(equalToConstant: 88),

            checkIcon.centerXAnchor.constraint(equalTo: checkCircle.centerXAnchor),
            checkIcon.centerYAnchor.constraint(equalTo: checkCircle.centerYAnchor),
            checkIcon.widthAnchor.constraint(equalToConstant: 38),
            checkIcon.heightAnchor.constraint(equalToConstant: 38),

            titleLabel.topAnchor.constraint(equalTo: checkCircle.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            goToSessionsButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            goToSessionsButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 28),
            goToSessionsButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -28),
            goToSessionsButton.heightAnchor.constraint(equalToConstant: 48),
            goToSessionsButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -36)
        ])
    }

    // MARK: - Animation
    private func animateCheckIn() {
        checkCircle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        checkCircle.alpha     = 0
        UIView.animate(withDuration: 0.55, delay: 0.1,
                       usingSpringWithDamping: 0.55,
                       initialSpringVelocity: 0.6,
                       options: .curveEaseOut) {
            self.checkCircle.transform = .identity
            self.checkCircle.alpha     = 1
        }
    }

    // MARK: - Action
    @objc private func goToSessionsTapped() {
            writeSessionThenNavigate()
        }
     
        private func writeSessionThenNavigate() {
            onGoToSessions?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.dismissAndGoToSessions()
            }
        }
     
        private func dismissAndGoToSessions() {
            var root: UIViewController = self
            while let p = root.presentingViewController {
                root = p
            }
     
            func findTabBar(_ vc: UIViewController?) -> UITabBarController? {
                if let tb = vc as? UITabBarController { return tb }
                if let nav = vc as? UINavigationController { return findTabBar(nav.topViewController) }
                for child in vc?.children ?? [] {
                    if let tb = findTabBar(child) { return tb }
                }
                return nil
            }
     
            guard let scene  = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first(where: { $0.isKeyWindow }),
                  let tabBar = findTabBar(window.rootViewController) else {
                root.dismiss(animated: true)
                return
            }
     
            let currentNav = (tabBar.viewControllers?[tabBar.selectedIndex] as? UINavigationController)
            currentNav?.popToRootViewController(animated: false)
     
            root.dismiss(animated: true) {
                tabBar.selectedIndex = 1   // Switch to Sessions tab
            }
        }
}
