//
//  TherapistProfileTabVC.swift
//  HealSync
//
//  Created by Arfa on 13/03/2026.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore

class TherapistProfileTabVC: UIViewController {

    // MARK: - Properties
    private let db = Firestore.firestore()
    private var userListener: ListenerRegistration?

    private let bgColor  = UIColor(hex: "#D1F0F8")
    private let teal     = UIColor(hex: "#4FC3D8")
    private let darkText = UIColor(hex: "#1A3A45")

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis    = .vertical
        sv.spacing = 20
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // Profile card
    private let profileCard: UIView = {
        let v = UIView()
        v.backgroundColor  = .white.withAlphaComponent(0.85)
        v.layer.cornerRadius = 20
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset  = CGSize(width: 0, height: 3)
        v.layer.shadowRadius  = 8
        return v
    }()

    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor  = UIColor(hex: "#C8EDF5")
        v.layer.cornerRadius = 36
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let avatarInitialLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        lbl.textColor = UIColor(hex: "#1A7A8A")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        return lbl
    }()

    private let emailLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = .systemGray
        return lbl
    }()

    private let chevronIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let iv = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: config))
        iv.tintColor = .systemGray3
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Menu card
    private let menuCard: UIView = {
        let v = UIView()
        v.backgroundColor  = .white.withAlphaComponent(0.85)
        v.layer.cornerRadius = 20
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset  = CGSize(width: 0, height: 3)
        v.layer.shadowRadius  = 8
        return v
    }()

    // Logout card
    private let logoutCard: UIView = {
        let v = UIView()
        v.backgroundColor  = .white.withAlphaComponent(0.85)
        v.layer.cornerRadius = 20
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset  = CGSize(width: 0, height: 3)
        v.layer.shadowRadius  = 8
        return v
    }()

    // MARK: - Menu Items
    private let menuItems: [(String, String, UIColor)] = [
        ("person.fill",              "Professional Info",     UIColor(hex: "#4FC3D8")),
        ("calendar.badge.clock",     "Manage Scheduling",     UIColor(hex: "#5BB8A0")),
        ("dollarsign.circle.fill",   "Pricing & Duration",    UIColor(hex: "#7B9FD4")),
        ("clock.arrow.circlepath",   "Session History",       UIColor(hex: "#F0A070")),
        ("gearshape.fill",           "Account Settings",      UIColor(hex: "#5BB8A0")),
        ("questionmark.circle.fill", "Help & Support",        UIColor(hex: "#4FC3D8"))
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        setupLayout()
        listenToUserData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        userListener?.remove()
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: -50),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        contentStack.addArrangedSubview(buildProfileCard())
        contentStack.addArrangedSubview(buildMenuCard())
        contentStack.addArrangedSubview(buildLogoutCard())
    }

    // MARK: - Profile Card
    private func buildProfileCard() -> UIView {
        avatarView.addSubview(avatarImageView)
        avatarView.addSubview(avatarInitialLabel)

        let nameStack = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        nameStack.axis    = .vertical
        nameStack.spacing = 4
        nameStack.translatesAutoresizingMaskIntoConstraints = false

        profileCard.addSubview(avatarView)
        profileCard.addSubview(nameStack)
        profileCard.addSubview(chevronIcon)
        profileCard.translatesAutoresizingMaskIntoConstraints = false
    

        NSLayoutConstraint.activate([
            profileCard.heightAnchor.constraint(equalToConstant: 100),

            avatarView.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: profileCard.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 72),
            avatarView.heightAnchor.constraint(equalToConstant: 72),

            avatarImageView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),

            avatarInitialLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarInitialLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            nameStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 14),
            nameStack.trailingAnchor.constraint(equalTo: chevronIcon.leadingAnchor, constant: -10),
            nameStack.centerYAnchor.constraint(equalTo: profileCard.centerYAnchor),

            chevronIcon.leadingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -25),
            chevronIcon.centerYAnchor.constraint(equalTo: profileCard.centerYAnchor)
        ])

        // Tap to edit profile
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleEditProfile))
        profileCard.addGestureRecognizer(tap)
        profileCard.isUserInteractionEnabled = true

        return profileCard
    }

    // MARK: - Menu Card
    private func buildMenuCard() -> UIView {
        menuCard.translatesAutoresizingMaskIntoConstraints = false

        var lastView: UIView? = nil

        for (index, item) in menuItems.enumerated() {
            let row = makeMenuRow(icon: item.0, title: item.1, iconColor: item.2, index: index)
            menuCard.addSubview(row)

            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: menuCard.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: menuCard.trailingAnchor),
                row.heightAnchor.constraint(equalToConstant: 60)
            ])

            if let prev = lastView {
                row.topAnchor.constraint(equalTo: prev.bottomAnchor).isActive = true

                // Divider
                let div = UIView()
                div.backgroundColor = UIColor(hex: "#EAF5F8")
                div.translatesAutoresizingMaskIntoConstraints = false
                menuCard.addSubview(div)
                NSLayoutConstraint.activate([
                    div.topAnchor.constraint(equalTo: prev.bottomAnchor),
                    div.leadingAnchor.constraint(equalTo: menuCard.leadingAnchor, constant: 52),
                    div.trailingAnchor.constraint(equalTo: menuCard.trailingAnchor),
                    div.heightAnchor.constraint(equalToConstant: 0.5)
                ])
            } else {
                row.topAnchor.constraint(equalTo: menuCard.topAnchor).isActive = true
            }

            if index == menuItems.count - 1 {
                row.bottomAnchor.constraint(equalTo: menuCard.bottomAnchor).isActive = true
            }

            lastView = row
        }

        return menuCard
    }

    private func makeMenuRow(icon: String, title: String, iconColor: UIColor, index: Int) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.tag = index

        // Icon container
        let iconContainer = UIView()
        iconContainer.backgroundColor  = iconColor.withAlphaComponent(0.12)
        iconContainer.layer.cornerRadius = 10
        iconContainer.translatesAutoresizingMaskIntoConstraints = false

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: config))
        iconView.tintColor = iconColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconView)

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLbl.textColor = UIColor(hex: "#1A3A45")
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)))
        chevron.tintColor = .systemGray3
        chevron.translatesAutoresizingMaskIntoConstraints = false

        [iconContainer, titleLbl, chevron].forEach { row.addSubview($0) }

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 36),
            iconContainer.heightAnchor.constraint(equalToConstant: 36),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            titleLbl.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            titleLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(menuItemTapped(_:)))
        row.addGestureRecognizer(tap)
        row.isUserInteractionEnabled = true

        return row
    }

    // MARK: - Logout Card
    private func buildLogoutCard() -> UIView {
        logoutCard.translatesAutoresizingMaskIntoConstraints = false

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: "rectangle.portrait.and.arrow.right",
                                                  withConfiguration: config))
        iconView.tintColor = UIColor.systemRed
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = "Log out"
        titleLbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLbl.textColor = UIColor.systemRed
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        [iconView, titleLbl].forEach { logoutCard.addSubview($0) }

        NSLayoutConstraint.activate([
            logoutCard.heightAnchor.constraint(equalToConstant: 56),

            iconView.leadingAnchor.constraint(equalTo: logoutCard.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: logoutCard.centerYAnchor),

            titleLbl.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            titleLbl.centerYAnchor.constraint(equalTo: logoutCard.centerYAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleLogout))
        logoutCard.addGestureRecognizer(tap)
        logoutCard.isUserInteractionEnabled = true

        return logoutCard
    }

    // MARK: - Fetch User Data
    private func listenToUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        userListener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self = self, let data = snap?.data() else { return }
                let fullName = data["fullName"] as? String ?? ""
                let email    = Auth.auth().currentUser?.email ?? ""
                let imageURL = data["profileImageURL"] as? String ?? ""

                DispatchQueue.main.async {
                    self.nameLabel.text  = fullName
                    self.emailLabel.text = email
                    self.avatarInitialLabel.text = String(fullName.prefix(1)).uppercased()

                    guard !imageURL.isEmpty, let url = URL(string: imageURL) else { return }
                    URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                        if let data = data, let img = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self?.avatarImageView.image   = img
                                self?.avatarImageView.isHidden = false
                                self?.avatarInitialLabel.isHidden = true
                            }
                        }
                    }.resume()
                }
            }
    }

    // MARK: - Actions
    @objc private func handleEditProfile() {
        navigationController?.pushViewController(TherapistEditProfileVC(), animated: true)
    }

    @objc private func menuItemTapped(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }
        switch index {
        case 0:
            navigationController?.pushViewController(TherapistProfessionalInfoVC(), animated: true)
        case 1:
            navigationController?.pushViewController(TherapistSchedulingVC(), animated: true)
        case 2:
            navigationController?.pushViewController(TherapistPricingVC(), animated: true)
        case 3:
            let vc = SessionHistoryVC(role: .therapist)
            navigationController?.pushViewController(vc, animated: true)
        case 4:
            navigationController?.pushViewController(AccountSettingsVC(), animated: true)
        case 5:
            navigationController?.pushViewController(HelpAndSupportVC(), animated: true)
        default: break
        }
    }
    
    @objc private func handleLogout() {
        let alert = UIAlertController(title: "Logout",
                                      message: "Are you sure you want to log out?",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            do {
                try Auth.auth().signOut()
                ListenerManager.shared.stopListening()
                ChatBadgeManager.shared.stopListening()
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let sceneDelegate = windowScene.delegate as? UIWindowSceneDelegate,
                   let window = sceneDelegate.window {
                    
                    window?.rootViewController = UINavigationController(rootViewController: GetStartedVC())
                    window?.makeKeyAndVisible()
                }
                
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError)
            }
        }))
        
        present(alert, animated: true)
    }
}



