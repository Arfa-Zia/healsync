//
//  PaddingLabel.swift
//  HealSync
//
//  Created by Arfa on 02/03/2026.
//

import UIKit

class PaddingLabel: UILabel {
    var padding = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8) // adjust as needed

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + padding.left + padding.right,
                      height: size.height + padding.top + padding.bottom)
    }
}
