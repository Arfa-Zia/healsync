//
//  AgoraConfig.swift
//  HealSync
//
//  Created by Arfa on 30/03/2026.
//


import UIKit
import AgoraRtcKit

// MARK: - AgoraConfig
enum AgoraConfig {
    static let appId = "8c7da5bef4d2486299ca23000b754dca"
}

// MARK: - CallControlButton

class CallControlButton: UIButton {

    private let iconView  = UIImageView()
    private let titleView = UILabel()
    private var activeColor:   UIColor = UIColor(red: 0.95, green: 0.23, blue: 0.23, alpha: 1)
    private var inactiveColor: UIColor = UIColor.white.withAlphaComponent(0.15)

    convenience init(icon: String, label: String) {
        self.init(frame: .zero)
        setup(icon: icon, label: label)
    }

    private func setup(icon: String, label: String) {
        backgroundColor = UIColor.white.withAlphaComponent(0.15)
        layer.cornerRadius = 16
        clipsToBounds = true

        iconView.image = UIImage(systemName: icon,
                                 withConfiguration: UIImage.SymbolConfiguration(
                                    pointSize: 20, weight: .medium))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        titleView.text = label
        titleView.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        titleView.textColor = UIColor.white.withAlphaComponent(0.85)
        titleView.textAlignment = .center
        titleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleView)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -8),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleView.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
        ])
    }

    /// Toggle active (highlighted/red) state
    func setActive(_ active: Bool, activeIcon: String, inactiveIcon: String) {
        let icon = active ? activeIcon : inactiveIcon
        iconView.image = UIImage(systemName: icon,
                                 withConfiguration: UIImage.SymbolConfiguration(
                                    pointSize: 20, weight: .medium))
        UIView.animate(withDuration: 0.2) {
            self.backgroundColor = active
                ? UIColor.white.withAlphaComponent(0.35)
                : UIColor.white.withAlphaComponent(0.15)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let remoteUserLeft = Notification.Name("remoteUserLeft")
}

