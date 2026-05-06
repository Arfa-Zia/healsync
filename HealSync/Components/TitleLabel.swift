//
//  TitleLabel.swift
//  HealSync
//
//  Created by Arfa on 12/01/2026.
//

import UIKit

class TitleLabel: UILabel {

    init(text: String, fontSize: CGFloat = 32 , alignment: NSTextAlignment = .center ){
        super.init(frame: .zero)
        self.text = text
        self.font = .systemFont(ofSize: fontSize, weight: .semibold)
        self.textColor = .black
        self.textAlignment = alignment
        self.translatesAutoresizingMaskIntoConstraints = false
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
