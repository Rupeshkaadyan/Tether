import SwiftUI

// MARK: - Colour
//
// Warm, not clinical. Pure white and pure grey read as "form"; this palette is
// built on warm neutrals so the app feels like paper rather than a spreadsheet.

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        self.init(.sRGB,
                  red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255,
                  opacity: 1)
    }
}

enum TetherColor {
    // Surfaces — warm off-white, never pure white
    static let bg             = Color(hex: "FDFBF8")
    static let surface        = Color(hex: "FFFFFF")
    static let surfaceSunken  = Color(hex: "F6F2EC")
    static let border         = Color(hex: "EAE4DA")
    static let borderStrong   = Color(hex: "D8CFC0")

    // Text — warm near-black, not #000
    static let text           = Color(hex: "2A2438")
    static let muted          = Color(hex: "6F6879")
    static let faint          = Color(hex: "9C95A6")

    // Brand
    static let ink            = Color(hex: "3A2E6E")
    static let brand          = Color(hex: "5B4BC4")
    static let brandSoft      = Color(hex: "EEEAFB")
    static let tint           = Color(hex: "EEEAFB")

    // Warmth — the emotional counterweight to the cool indigo
    static let warm           = Color(hex: "E08A4B")
    static let warmSoft       = Color(hex: "FDF0E4")
    static let rose           = Color(hex: "D96A8A")
    static let roseSoft       = Color(hex: "FCECF1")

    // Semantic
    static let thriving       = Color(hex: "2E9E6B")
    static let thrivingSoft   = Color(hex: "E6F6EE")
    static let drifting       = Color(hex: "D08A28")
    static let driftingSoft   = Color(hex: "FDF3E0")
    static let strained       = Color(hex: "C4463F")
    static let strainedSoft   = Color(hex: "FBEBE9")

    static let accent         = Color(hex: "E08A4B")
}

// MARK: - Gradient

enum TetherGradient {
    static let brand = LinearGradient(
        colors: [Color(hex: "6A57D6"), Color(hex: "4A3AA8")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let dawn = LinearGradient(
        colors: [Color(hex: "FDF0E4"), Color(hex: "FCECF1")],
        startPoint: .top, endPoint: .bottom)

    static let dusk = LinearGradient(
        colors: [Color(hex: "3A2E6E"), Color(hex: "5B4BC4")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let calm = LinearGradient(
        colors: [Color(hex: "FDFBF8"), Color(hex: "F3EEF8")],
        startPoint: .top, endPoint: .bottom)
}

// MARK: - Type
//
// Rounded design throughout. It is the cheapest lever for warmth, and for a
// couples app warmth beats editorial severity.

enum TetherType {
    static let display    = Font.system(size: 34, weight: .bold, design: .rounded)
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title      = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let headline   = Font.system(size: 19, weight: .semibold, design: .rounded)
    static let body       = Font.system(size: 16.5, weight: .regular, design: .rounded)
    static let callout    = Font.system(size: 15, weight: .regular, design: .rounded)
    static let label      = Font.system(size: 15.5, weight: .semibold, design: .rounded)
    static let caption    = Font.system(size: 13, weight: .regular, design: .rounded)
    static let micro      = Font.system(size: 11.5, weight: .medium, design: .rounded)
}

// MARK: - Metrics

enum TetherSpace {
    static let xs: CGFloat = 4
    static let s:  CGFloat = 8
    static let m:  CGFloat = 12
    static let l:  CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 44
    static let margin: CGFloat = 22
}

enum TetherRadius {
    static let small: CGFloat = 10
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xlarge: CGFloat = 32
}

// MARK: - Depth

enum TetherShadow {
    case none, soft, lifted, floating

    var color: Color { Color(hex: "2A2438").opacity(opacity) }
    var radius: CGFloat {
        switch self {
        case .none: return 0
        case .soft: return 10
        case .lifted: return 18
        case .floating: return 28
        }
    }
    var y: CGFloat {
        switch self {
        case .none: return 0
        case .soft: return 3
        case .lifted: return 8
        case .floating: return 14
        }
    }
    var opacity: Double {
        switch self {
        case .none: return 0
        case .soft: return 0.05
        case .lifted: return 0.08
        case .floating: return 0.12
        }
    }
}

extension View {
    func tetherShadow(_ style: TetherShadow = .soft) -> some View {
        shadow(color: style.color, radius: style.radius, x: 0, y: style.y)
    }
}

// MARK: - Button

struct TetherButtonStyle: ButtonStyle {
    enum Variant { case primary, secondary, tertiary, destructive }

    var variant: Variant = .primary
    var isFullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TetherType.label)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(minHeight: 54)
            .padding(.horizontal, isFullWidth ? 0 : TetherSpace.xl)
            .foregroundStyle(foreground)
            .background(background(configuration))
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TetherRadius.medium, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: variant == .tertiary ? 1 : 0)
            )
            .tetherShadow(variant == .primary ? .lifted : .none)
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
            .contentShape(Rectangle())
    }

    private var foreground: Color {
        switch variant {
        case .primary: return .white
        case .secondary: return TetherColor.brand
        case .tertiary: return TetherColor.text
        case .destructive: return TetherColor.strained
        }
    }

    @ViewBuilder
    private func background(_ config: Configuration) -> some View {
        switch variant {
        case .primary:
            TetherGradient.brand.opacity(config.isPressed ? 0.88 : 1)
        case .secondary:
            TetherColor.brandSoft
        case .tertiary, .destructive:
            Color.clear
        }
    }

    private var borderColor: Color {
        variant == .tertiary ? TetherColor.borderStrong : .clear
    }
}

extension View {
    func tetherButton(_ variant: TetherButtonStyle.Variant = .primary, fullWidth: Bool = true)
        -> some View {
        buttonStyle(TetherButtonStyle(variant: variant, isFullWidth: fullWidth))
    }
}
