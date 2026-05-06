//
//  SocialButton.swift
//  HealSync
//
//  Created by Arfa on 12/01/2026.
//

import UIKit

class SocialButton: UIButton {
    
    init(title: String, iconName: String) {
        super.init(frame: .zero)
      
        var config = UIButton.Configuration.filled()
            
        var container = AttributeContainer()
        container.font = .systemFont(ofSize: 10)
        config.attributedTitle = AttributedString(title, attributes: container)
            
        config.baseForegroundColor = .black
        config.baseBackgroundColor = UIColor(hex: "#74D6EA")
        
        config.image = UIImage(named: iconName)?.withRenderingMode(.alwaysOriginal)
        config.imagePadding = 10
        config.imagePlacement = .trailing
        config.background.cornerRadius = 10
        
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 5

        layer.masksToBounds = false
            
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 20)
        config.preferredSymbolConfigurationForImage = iconConfig

        let image = UIImage(named: iconName)
        config.image = image?.preparingThumbnail(of: CGSize(width: 16, height: 16))
        
            self.configuration = config
            self.translatesAutoresizingMaskIntoConstraints = false
        }
        
        required init?(coder: NSCoder) { fatalError() }


}
