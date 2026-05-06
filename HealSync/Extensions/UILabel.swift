//
//  Ui.swift
//  HealSync
//
//  Created by Arfa on 11/03/2026.
//
import UIKit

extension UILabel {
    func characterIndex(at point: CGPoint) -> Int {
        guard let attributedText = attributedText else { return NSNotFound }

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: bounds.size)

        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let location = layoutManager.characterIndex(
            for: point,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        return location
    }
}
