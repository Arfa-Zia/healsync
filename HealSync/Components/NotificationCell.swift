//
//  NotificationCell.swift
//  HealSync
//
//  Created by Arfa on 10/03/2026.
//


import UIKit

class NotificationCell: UITableViewCell {

    static let identifier = "NotificationCell"

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.numberOfLines = 0
        label.textColor = .black
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        return label
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#EAF8FB")
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    private let unreadDot: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue
        view.layer.cornerRadius = 5
        return view
    }()
    private let iconView: UIImageView = {
        let img = UIImageView()
        img.tintColor = UIColor.systemBlue
        img.contentMode = .scaleAspectFit
        return img
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.addSubview(messageLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(unreadDot)
        containerView.addSubview(iconView)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        unreadDot.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([

            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // ICON
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            // UNREAD DOT
            unreadDot.widthAnchor.constraint(equalToConstant: 10),
            unreadDot.heightAnchor.constraint(equalToConstant: 10),
            unreadDot.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            unreadDot.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            

            // MESSAGE LABEL
            messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            messageLabel.trailingAnchor.constraint(equalTo: unreadDot.leadingAnchor, constant: -10),

            // TIME LABEL
            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 6),
            timeLabel.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)

        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(message: String, date: Date, isRead: Bool, type: String) {

        messageLabel.text = message

        let formatter = RelativeDateTimeFormatter()
        timeLabel.text = formatter.localizedString(for: date, relativeTo: Date())

        unreadDot.isHidden = isRead

        switch type {
        case "booked":
            iconView.image = UIImage(systemName: "checkmark.circle.fill")
            iconView.tintColor = .systemGreen

        case "cancelled":
            iconView.image = UIImage(systemName: "xmark.circle.fill")
            iconView.tintColor = .systemRed

        case "reminder":
            iconView.image = UIImage(systemName: "bell.fill")
            iconView.tintColor = .systemOrange

        default:
            iconView.image = UIImage(systemName: "bell")
        }
    }
}
