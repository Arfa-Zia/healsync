//
//  HelpAndSupportVC.swift
//  HealSync
//
//  Created by Arfa on 24/03/2026.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore


class HelpAndSupportVC: UIViewController {

    private let bgColor  = UIColor(hex: "#D1F0F8")
    private let darkText = UIColor(hex: "#1A3A45")

    private let menuCard: UIView = {
        let v = UIView()
        v.backgroundColor    = .white.withAlphaComponent(0.85)
        v.layer.cornerRadius = 20
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset  = CGSize(width: 0, height: 3)
        v.layer.shadowRadius  = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let items: [(String, String)] = [
        ("questionmark.circle.fill", "FAQs"),
        ("envelope.fill",            "Contact Us")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        setupNav()
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupNav() {
        let backBtn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        backBtn.setImage(UIImage(systemName: "arrow.left", withConfiguration: cfg), for: .normal)
        backBtn.tintColor = darkText
        backBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = "Help & Support"
        titleLbl.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLbl.textColor = .black
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(backBtn)
        view.addSubview(titleLbl)

        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backBtn.widthAnchor.constraint(equalToConstant: 32),
            backBtn.heightAnchor.constraint(equalToConstant: 32),

            titleLbl.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLbl.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 10)
        ])
    }

    private func setupLayout() {
        view.addSubview(menuCard)

        NSLayoutConstraint.activate([
            menuCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            menuCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            menuCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        var lastView: UIView? = nil
        for (index, item) in items.enumerated() {
            let row = makeRow(icon: item.0, title: item.1, index: index)
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

            if index == items.count - 1 {
                row.bottomAnchor.constraint(equalTo: menuCard.bottomAnchor).isActive = true
            }
            lastView = row
        }
    }

    private func makeRow(icon: String, title: String, index: Int) -> UIView {
        let colors: [UIColor] = [UIColor(hex: "#F0A070"), UIColor(hex: "#4FC3D8")]
        let color = colors[index]

        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.tag = index

        let iconContainer = UIView()
        iconContainer.backgroundColor    = color.withAlphaComponent(0.12)
        iconContainer.layer.cornerRadius = 10
        iconContainer.translatesAutoresizingMaskIntoConstraints = false

        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: cfg))
        iconView.tintColor    = color
        iconView.contentMode  = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconView)

        let lbl = UILabel()
        lbl.text      = title
        lbl.font      = UIFont.systemFont(ofSize: 15, weight: .medium)
        lbl.textColor = UIColor(hex: "#1A3A45")
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

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            lbl.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(rowTapped(_:)))
        row.addGestureRecognizer(tap)
        row.isUserInteractionEnabled = true
        return row
    }

    @objc private func rowTapped(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }
        if index == 0 {
            navigationController?.pushViewController(FAQsVC(), animated: true)
        } else {
            navigationController?.pushViewController(ContactUsVC(), animated: true)
        }
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }
}

