//
//  BaseContainer.swift
//  HealSync
//
//  Created by Arfa on 12/01/2026.
//

import UIKit

class BaseContainer: UIView {
    
    init(opacity: CGFloat = 0.5 , shadow: Bool = true){
        super.init(frame: .zero)
        backgroundColor = UIColor.white.withAlphaComponent(opacity)
        layer.cornerRadius = 30
        
        if shadow {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.2
            layer.shadowOffset = CGSize(width: 0, height: 5)
            layer.shadowRadius = 15
        }
            
        layer.masksToBounds = false
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
