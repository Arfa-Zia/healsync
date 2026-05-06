//
//  CustomBackButton.swift
//  HealSync
//
//  Created by Arfa on 04/03/2026.
//

import UIKit

class CustomBackButton: UIButton {
    
    init(iconName: String = "arrow.left", tintColor: UIColor = .black) {
        super.init(frame: .zero)

        var config = UIButton.Configuration.plain()

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        config.image = UIImage(systemName: iconName, withConfiguration: symbolConfig)

        config.baseForegroundColor = tintColor
        
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 8)
 
        self.configuration = config
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.layer.shadowOpacity = 0
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
