//
//  Hyperlink.swift
//  HealSync
//
//  Created by Arfa on 13/01/2026.
//

import UIKit

class Hyperlink: UITextView{
    
    var onLinkTap: (() -> Void)?
    
    init(fullText: String, linkText: String){
        super.init(frame: .zero, textContainer: nil)
        setupStyle()
        setupAttributes(fullText: fullText, linkText: linkText)
        delegate = self
    }
    
    private func setupStyle(){
        self.isEditable = false
        self.isScrollEnabled = false
        self.backgroundColor = .clear
        self.textContainerInset = .zero
        self.textContainer.lineFragmentPadding = 0
        self.translatesAutoresizingMaskIntoConstraints = false
        self.textAlignment = .center
        
        self.tintColor = UIColor(hex: "#0077B6")
    }
    
    private func setupAttributes(fullText: String, linkText: String){
        let attributedString = NSMutableAttributedString(string: fullText)
        
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 12), range: NSRange(location: 0, length: fullText.count))
        
        let linkRange = (fullText as NSString).range(of: linkText)
        
        attributedString.addAttribute(.link, value: "action://tap", range: linkRange)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: linkRange)
        self.attributedText = attributedString
    }
    
    required init?(coder: NSCoder){
        fatalError()
    }
}

extension Hyperlink: UITextViewDelegate{
    func textView(
        _ textView: UITextView,
        shouldInteractWith url: URL,
        in range: NSRange
    ) -> Bool {
        onLinkTap?()
        return false
    }
}
