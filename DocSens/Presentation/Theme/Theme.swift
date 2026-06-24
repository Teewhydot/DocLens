import SwiftUI

/// Centralized design tokens for DocSens.
/// Palette: deep navy primary, electric teal accent, soft white background,
/// warning amber, danger crimson. All colors are dark-mode aware.
enum Theme {
    // MARK: Brand colors
    static let navy = Color(hex: 0x0D1B2A)
    static let accent = Color(hex: 0x0ABFBC)
    static let amber = Color(hex: 0xF4A261)
    static let crimson = Color(hex: 0xE63946)

    /// Adaptive surface background — soft white in light, near-navy in dark.
    static let background = Color("AppBackground", bundle: nil)

    // MARK: Risk semantics
    static func riskColor(for score: Double) -> Color {
        switch score {
        case ..<0.3: return Color(hex: 0x2A9D8F)   // calm green
        case 0.3..<0.6: return amber
        default: return crimson
        }
    }

    static func riskLabel(for score: Double) -> String {
        switch score {
        case ..<0.3: return "Low"
        case 0.3..<0.6: return "Moderate"
        default: return "High"
        }
    }

    // MARK: Spacing & shape
    static let cornerRadius: CGFloat = 16
    static let rowHPadding: CGFloat = 16
    static let rowVPadding: CGFloat = 12
}

extension Color {
    /// Hex initializer, e.g. Color(hex: 0x0ABFBC)
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Typography helpers

extension Font {
    static func docTitle() -> Font { .system(.largeTitle, design: .rounded).weight(.bold) }
    static func docHeadline() -> Font { .system(.headline, design: .rounded) }
    static func docBody() -> Font { .system(.body) }
}
