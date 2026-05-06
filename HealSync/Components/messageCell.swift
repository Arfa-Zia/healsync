//
//  messageCell.swift
//  HealSync
//
//  Created by Arfa on 18/02/2026.
//

import UIKit

class MessageTableViewCell: UITableViewCell {
    
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // Avatar
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.layer.cornerRadius = 28
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.backgroundColor = .lightGray
        
        // Name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = .label
        
        // Message
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 1
        
        // Time
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = .systemFont(ofSize: 13)
        timeLabel.textColor = .tertiaryLabel
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 56),
            avatarImageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),
            
            messageLabel.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor),
            messageLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            timeLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    func configure(with item: ChatItem) {
        nameLabel.text = item.doctorName
        messageLabel.text = item.lastMessage
        timeLabel.text = item.time
        
        if let image = item.avatarImage {
            avatarImageView.image = image
        } else {
            let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
            let icon = UIImage(systemName: "person.fill", withConfiguration: config)

            avatarImageView.image = icon
            avatarImageView.tintColor = .white
            avatarImageView.contentMode = .center
            avatarImageView.backgroundColor = UIColor(hex: "#8BD8ED")

        }
    }
}

struct ChatItem {
    let doctorName: String
    let lastMessage: String
    let time: String
    let avatarImage: UIImage?
}
