//
//  PrimaryButton.swift
//  HealSync
//
//  Created by Arfa on 12/01/2026.
//

import UIKit

class PrimaryButton: UIButton {

    init(title: String, color: UIColor = UIColor(hex: "#74D6EA"), fontSize: CGFloat = 14, fontColor: UIColor = UIColor.black , fontWeight: UIFont.Weight = .semibold, paddingTopBottom: CGFloat = 10 , paddingLeftRight: CGFloat = 20) {
            super.init(frame: .zero)
            
            var config = UIButton.Configuration.filled()
            var container = AttributeContainer()
            container.font = .systemFont(ofSize: fontSize, weight: fontWeight)
            
            config.attributedTitle = AttributedString(title, attributes: container)
            config.baseBackgroundColor = color
            config.baseForegroundColor = fontColor
            config.background.cornerRadius = 10
            config.contentInsets = NSDirectionalEdgeInsets(top: paddingTopBottom, leading: paddingLeftRight, bottom: paddingTopBottom, trailing: paddingLeftRight)
            
            self.configuration = config
            self.translatesAutoresizingMaskIntoConstraints = false
            layer.shadowColor = UIColor.gray.cgColor
            layer.shadowOpacity = 0.1
            layer.shadowOffset = CGSize(width: 0, height: 3)
            layer.shadowRadius = 5

            layer.masksToBounds = false
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

}
