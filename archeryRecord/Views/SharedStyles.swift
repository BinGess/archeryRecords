import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum SharedStyles {
    static let primaryColor = Color.blue
    static let secondaryColor = Color.gray.opacity(0.6)
    #if canImport(UIKit)
    static let backgroundColor = Color(UIColor.systemBackground)
    static let groupBackgroundColor = Color(UIColor.systemGroupedBackground)
    #else
    static let backgroundColor = Color.white
    static let groupBackgroundColor = Color.gray.opacity(0.1)
    #endif
    
    static let sectionSpacing: CGFloat = 20
    static let itemSpacing: CGFloat = 12
    static let cornerRadius: CGFloat = 12
    
    struct Text {
        static let title = Font.headline
        static let subtitle = Font.subheadline
        static let caption = Font.system(size: 12)
        static let body = Font.system(size: 14)
    }
    
    struct Shadow {
        static let light = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.1)
    }
    
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
    }
    
    struct Score {
        static let tenColor = Color.orange
        static let nineColor = Color.yellow
        static let defaultColor = Color.primary
        
        static func color(for score: String) -> Color {
            if score == "X" || score == "10" {
                return tenColor
            } else if score == "9" {
                return nineColor
            }
            return defaultColor
        }
    }
}