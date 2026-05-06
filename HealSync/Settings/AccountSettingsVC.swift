//
//  AccountSettingsVC.swift
//  HealSync
//
//  Created by Arfa on 24/03/2026.
//
//


import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - ClientAccountSettingsVC
class AccountSettingsVC: UIViewController {

    private let bgColor = UIColor(hex: "#D1F0F8")
    private let db = Firestore.firestore()

    // MARK: - Custom Nav Bar
    private let navBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#D1F0F8")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let backBtn  = CustomBackButton()
    private let titleLbl: UILabel = {
        let l = UILabel()
        l.text = "Account Settings"
        l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .black
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let navDivider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#C8EDF5")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Menu Card
    private let menuCard: UIView = {
        let v = UIView()
        v.backgroundColor  = .white.withAlphaComponent(0.85)
        v.layer.cornerRadius = 20
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset  = CGSize(width: 0, height: 3)
        v.layer.shadowRadius  = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let menuItems: [(String, String, UIColor)] = [
        ("lock.rotation",      "Change Password", UIColor(hex: "#4FC3D8")),
        ("trash.fill",         "Delete Account",  UIColor.systemRed)
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        setupLayout()
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Layout
    private func setupLayout() {
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        [backBtn, titleLbl, navDivider].forEach { navBar.addSubview($0) }
        view.addSubview(navBar)
        view.addSubview(menuCard)
        buildMenuCard()

        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -50),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 52),

            backBtn.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 14),
            backBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            backBtn.widthAnchor.constraint(equalToConstant: 36),
            backBtn.heightAnchor.constraint(equalToConstant: 36),

            titleLbl.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 60),
            titleLbl.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),

            navDivider.leadingAnchor.constraint(equalTo: navBar.leadingAnchor),
            navDivider.trailingAnchor.constraint(equalTo: navBar.trailingAnchor),
            navDivider.bottomAnchor.constraint(equalTo: navBar.bottomAnchor),
            navDivider.heightAnchor.constraint(equalToConstant: 1),

            menuCard.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 24),
            menuCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            menuCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func buildMenuCard() {
        var lastView: UIView? = nil
        for (index, item) in menuItems.enumerated() {
            let row = makeMenuRow(icon: item.0, title: item.1, iconColor: item.2, index: index)
            menuCard.addSubview(row)
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: menuCard.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: menuCard.trailingAnchor),
                row.heightAnchor.constraint(equalToConstant: 56)
            ])
            if let prev = lastView {
                row.topAnchor.constraint(equalTo: prev.bottomAnchor).isActive = true
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
    }

    private func makeMenuRow(icon: String, title: String, iconColor: UIColor, index: Int) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.tag = index

        let iconContainer = UIView()
        iconContainer.backgroundColor  = iconColor.withAlphaComponent(0.12)
        iconContainer.layer.cornerRadius = 10
        iconContainer.translatesAutoresizingMaskIntoConstraints = false

        let config  = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let iconIV  = UIImageView(image: UIImage(systemName: icon, withConfiguration: config))
        iconIV.tintColor    = iconColor
        iconIV.contentMode  = .scaleAspectFit
        iconIV.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconIV)

        let lbl = UILabel()
        lbl.text      = title
        lbl.font      = UIFont.systemFont(ofSize: 15, weight: .medium)
        lbl.textColor = index == 1 ? UIColor.systemRed : UIColor(hex: "#1A3A45")
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)))
        chevron.tintColor = .systemGray3
        chevron.translatesAutoresizingMaskIntoConstraints = false

        [iconContainer, lbl, chevron].forEach { row.addSubview($0) }

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 36),
            iconContainer.heightAnchor.constraint(equalToConstant: 36),

            iconIV.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconIV.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconIV.widthAnchor.constraint(equalToConstant: 18),
            iconIV.heightAnchor.constraint(equalToConstant: 18),

            lbl.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        let tap   = UITapGestureRecognizer(target: self, action: #selector(rowTapped(_:)))
        row.addGestureRecognizer(tap)
        row.isUserInteractionEnabled = true
        return row
    }

    // MARK: - Actions
    @objc private func rowTapped(_ g: UITapGestureRecognizer) {
        guard let idx = g.view?.tag else { return }
        switch idx {
        case 0:
            let vc = ChangePasswordVC()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case 1:
            let vc = DeleteAccountVC()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        default: break
        }
    }

    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
}



