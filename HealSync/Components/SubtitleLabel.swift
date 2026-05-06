//
//  SubtitleLabel.swift
//  HealSync
//
//  Created by Arfa on 12/01/2026.
//

import UIKit

class SubtitleLabel: UILabel {

    init(text: String , noOfLines: Int = 0 , fontSize: CGFloat = 14 ) {
            super.init(frame: .zero)
            self.text = text
            self.font = .systemFont(ofSize: fontSize, weight: .regular)
            self.textColor = .black
            self.textAlignment = .center
            self.numberOfLines = noOfLines
            self.translatesAutoresizingMaskIntoConstraints = false
        }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}




