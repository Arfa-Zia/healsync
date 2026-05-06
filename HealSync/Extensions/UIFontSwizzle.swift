import UIKit

extension UIFont {
    
    static func swizzleSystemFonts() {
        let swizzle: (Selector, Selector) -> Void = { original, swizzled in
            guard let originalMethod = class_getClassMethod(UIFont.self, original),
                  let swizzledMethod = class_getClassMethod(UIFont.self, swizzled) else { return }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        swizzle(#selector(systemFont(ofSize:)), #selector(mySystemFont(ofSize:)))
        
        swizzle(#selector(boldSystemFont(ofSize:)), #selector(myBoldSystemFont(ofSize:)))
        
        swizzle(#selector(italicSystemFont(ofSize:)), #selector(myItalicSystemFont(ofSize:)))
  
        swizzle(#selector(systemFont(ofSize:weight:)), #selector(mySystemFont(ofSize:weight:)))
    }

    @objc class func mySystemFont(ofSize size: CGFloat) -> UIFont {
        return safeFont(name: "Poppins-Regular", size: size, fallbackWeight: .regular)
    }

    @objc class func myBoldSystemFont(ofSize size: CGFloat) -> UIFont {
        return safeFont(name: "Poppins-Bold", size: size, fallbackWeight: .bold)
    }

    @objc class func myItalicSystemFont(ofSize size: CGFloat) -> UIFont {
        return safeFont(name: "Poppins-Italic", size: size, fallbackWeight: .regular)
    }

    @objc class func mySystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        var fontName = "Poppins-Regular"
        
        switch weight {
        case .ultraLight, .thin, .light:
            fontName = "Poppins-Light"
        case .regular:
            fontName = "Poppins-Regular"
        case .medium:
            fontName = "Poppins-Medium"
        case .semibold:
            fontName = "Poppins-SemiBold"
        case .bold, .heavy, .black:
            fontName = "Poppins-Bold"
        default:
            fontName = "Poppins-Regular"
        }
        
        return safeFont(name: fontName, size: size, fallbackWeight: weight)
    }
    
  
    private static func safeFont(name: String, size: CGFloat, fallbackWeight: UIFont.Weight) -> UIFont {
        if let customFont = UIFont(name: name, size: size) {
            return customFont
        }
        
        print("DEBUG: Font '\(name)' not found. Check Info.plist and Target Membership.")
        
        return UIFont.systemFont(ofSize: size, weight: fallbackWeight)
    }
}
