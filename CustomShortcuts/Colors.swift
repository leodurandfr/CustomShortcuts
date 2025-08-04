import SwiftUI
import AppKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
    
    init(light: Color, dark: Color) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            if appearance.name == .darkAqua {
                return NSColor(dark)
            } else {
                return NSColor(light)
            }
        })
    }
    
    func opacity(light: Double, dark: Double) -> Color {
        Color(light: self.opacity(light), dark: self.opacity(dark))
    }
}

enum Constants {
    enum Icons {
        static let circleButtonSize: CGFloat = 16
    }
    
    enum ViewDimensions {
        static let minWindowWidth: CGFloat = 812
        static let minWindowHeight: CGFloat = 500
    }
}

enum CustomColors {
    // MARK: - Couleurs de base
    static let textPrimary = Color(light: Color(hex: "212121"), dark: Color(hex: "F2F2F2"))
    static let backgroundWindow = Color(light: Color(hex: "FFFFFF"), dark: Color(hex: "1E1E1E"))
    
    // MARK: - Buttons
    static let secondaryButton = Color(light: Color(hex: "EDEDED"), dark: Color(hex: "333333"))
    static let secondaryButtonHover = Color(light: Color(hex: "E3E3E3"), dark: Color(hex: "3D3D3D"))
    static let saveButton = Color.accentColor
    static let saveButtonHover = Color.accentColor.opacity(0.8)
    
    // MARK: - Rows
    static let backgroundNormalRow = Color(light: Color(hex: "F7F7F7"), dark: Color(hex: "222222"))
   // static let backgroundAlternateRow = Color(light: Color(hex: "FFFFFF"), dark: Color(hex: "1E1E1E"))
    
    // MARK: - Keys "alt,option,cmd,shift"
    static let keysEnabledLight = Color(hex: "FFFFFF")
    static let keysEnabledDark = Color(hex: "1B1B1B")
    static let keysDisabledLight = Color(hex: "F0F0F0")
    static let keysDisabledDark = Color(hex: "FFFFFF0A")
    
    // MARK: - Fields (Input, Name, Hotkey)
    private enum FieldColors {
        // Standard (non-alterné)
        static let disabledLight = "0000000F"
        static let disabledDark = "FFFFFF0A"
        static let enabledLight = "FFFFFF"
        static let enabledDark = "1B1B1B"
        
        // Alterné
        static let disabledAltLight = "0000000F"
        static let disabledAltDark = "FFFFFF0A"
        static let enabledAltLight = "FFFFFF"
        static let enabledAltDark = "1B1B1B"
        
        // Bordures standard
        static let disabledBorderLight = "FFFFFF00"
        static let disabledBorderDark = "FFFFFF00"
        static let enabledBorderLight = "0000001F"
        static let enabledBorderDark = "41414180"
        
        // Bordures alternées
        static let disabledBorderAltLight = "FFFFFF00"
        static let disabledBorderAltDark = "FFFFFF00"
        static let enabledBorderAltLight = "0000001F"
        static let enabledBorderAltDark = "41414180"
    }
    
    static func fieldBackground(isDisabled: Bool, isAlternate: Bool) -> Color {
        if isAlternate {
            return Color(
                light: Color(hex: isDisabled ? FieldColors.disabledAltLight : FieldColors.enabledAltLight),
                dark: Color(hex: isDisabled ? FieldColors.disabledAltDark : FieldColors.enabledAltDark)
            )
        } else {
            return Color(
                light: Color(hex: isDisabled ? FieldColors.disabledLight : FieldColors.enabledLight),
                dark: Color(hex: isDisabled ? FieldColors.disabledDark : FieldColors.enabledDark)
            )
        }
    }
    
    static func fieldBorder(isDisabled: Bool, isAlternate: Bool) -> Color {
        if isAlternate {
            return Color(
                light: Color(hex: isDisabled ? FieldColors.disabledBorderAltLight : FieldColors.enabledBorderAltLight),
                dark: Color(hex: isDisabled ? FieldColors.disabledBorderAltDark : FieldColors.enabledBorderAltDark)
            )
        } else {
            return Color(
                light: Color(hex: isDisabled ? FieldColors.disabledBorderLight : FieldColors.enabledBorderLight),
                dark: Color(hex: isDisabled ? FieldColors.disabledBorderDark : FieldColors.enabledBorderDark)
            )
        }
    }
    
    static func fieldText(isDisabled: Bool) -> Color {
        isDisabled ? textPrimary.opacity(0.5) : textPrimary
    }
    
    // MARK: - Popover
    static let toggleButtonInactive = Color(light: Color(hex: "EDEDED"),
                                          dark: Color(hex: "FFFFFF").opacity(0.16))
    static let toggleButtonActive = Color(light: Color(hex: "E3E3E3"),
                                        dark: Color(hex: "FFFFFF").opacity(0.32))
    
    // MARK: - Accents & Icons
    static let recordingBorder = Color.accentColor
    static let arrowColor = Color(light: Color(hex: "666666"), dark: Color(hex: "FFFFFF52"))
    
    static func IconColor(isHovered: Bool) -> Color {
        Color(
            light: Color.black.opacity(isHovered ? 0.8 : 0.4),
            dark: Color.white.opacity(isHovered ? 0.8 : 0.4)
        )
    }
}
