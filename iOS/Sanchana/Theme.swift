import SwiftUI

// MARK: - Colours
extension Color {
    static let ink       = Color(hex: "120800")
    static let deep      = Color(hex: "1c0a04")
    static let maroon    = Color(hex: "6b1a1a")
    static let crimson   = Color(hex: "9c2626")
    static let gold      = Color(hex: "c9922a")
    static let goldLight = Color(hex: "e8b84b")
    static let saffron   = Color(hex: "e07b20")
    static let ivory     = Color(hex: "f5ede0")
    static let ivoryDim  = Color(hex: "c9b99a")
    static let silk      = Color(hex: "fdf6ec")

    init(hex: String) {
        var h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if h.hasPrefix("#") { h.removeFirst() }
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        self.init(
            red:   Double((val >> 16) & 0xFF) / 255,
            green: Double((val >>  8) & 0xFF) / 255,
            blue:  Double( val        & 0xFF) / 255
        )
    }
}

// MARK: - Font scale

enum FontSizePreset: Int, CaseIterable {
    case standard = 0, comfortable, spacious, large, extraLarge

    var scale: CGFloat {
        switch self {
        case .standard:    return 1.00
        case .comfortable: return 1.12
        case .spacious:    return 1.25
        case .large:       return 1.45
        case .extraLarge:  return 1.60
        }
    }

    var label: String {
        switch self {
        case .standard:    return "Standard"
        case .comfortable: return "Comfortable"
        case .spacious:    return "Spacious"
        case .large:       return "Large"
        case .extraLarge:  return "Extra Large"
        }
    }
}

/// Reads the current font scale from UserDefaults.
/// Reactive because views that hold @AppStorage("font_size_preset") will re-render,
/// which causes Font calls to re-evaluate this value.
var appFontScale: CGFloat {
    let idx = UserDefaults.standard.integer(forKey: "font_size_preset")
    return FontSizePreset(rawValue: idx)?.scale ?? 1.0
}

// MARK: - Fonts
// Add Cinzel Decorative (.ttf) and Cormorant Garamond (.ttf) to the Xcode target
// and declare them in Info.plist under "Fonts provided by application".
extension Font {
    static func cinzel(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let s = size * appFontScale
        switch weight {
        case .bold:               return .custom("CinzelDecorative-Bold",    size: s)
        case .heavy, .black:      return .custom("CinzelDecorative-Black",   size: s)
        default:                  return .custom("CinzelDecorative-Regular", size: s)
        }
    }
    static func cormorant(_ size: CGFloat, italic: Bool = false) -> Font {
        let s = size * appFontScale
        return italic ? .custom("CormorantGaramond-Italic", size: s)
                      : .custom("CormorantGaramond-Light",  size: s)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let goldGradient = LinearGradient(
        colors: [.goldLight, .saffron, .gold],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cardBackground = LinearGradient(
        colors: [Color(hex: "2c1208").opacity(0.27), Color(hex: "1a0802").opacity(0.14)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Reusable Components

/// Horizontal gold gradient divider line
struct GoldRule: View {
    var body: some View {
        LinearGradient(colors: [.clear, .gold, .clear],
                       startPoint: .leading, endPoint: .trailing)
            .frame(height: 1)
    }
}

/// OM symbol rendered with gold gradient text
struct OmSymbol: View {
    var size: CGFloat = 24
    var body: some View {
        Text("ॐ")
            .font(.system(size: size))
            .foregroundStyle(LinearGradient.goldGradient)
    }
}
