import SwiftUI

// MARK: - Adaptive colour
//
// Every colour resolves per appearance. This is not decoration: without it,
// iOS renders system control text (TextField, etc.) light in dark mode, and on
// a hardcoded white surface that text becomes invisible.

extension UIColor {
    convenience init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        self.init(red: CGFloat((value >> 16) & 0xFF) / 255,
                  green: CGFloat((value >> 8) & 0xFF) / 255,
                  blue: CGFloat(value & 0xFF) / 255,
                  alpha: 1)
    }
}

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }

    /// A colour that resolves differently in light and dark.
    static func adaptive(_ light: String, _ dark: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

// MARK: - Palette
//
// Warm paper, not clinical white. The indigo is deepened and slightly
// desaturated from the obvious default, and the accents run warm rather than
// neon — the difference between "designed" and "generated".

enum TetherColor {
    // Surfaces
    static let bg            = Color.adaptive("FAF7F2", "15111D")
    static let surface       = Color.adaptive("FFFFFF", "221C2E")
    static let surfaceSunken = Color.adaptive("F2EDE4", "1B1626")
    static let border        = Color.adaptive("E8E1D6", "342C44")
    static let borderStrong  = Color.adaptive("D5CABA", "463B58")

    // Text
    static let text          = Color.adaptive("241F2E", "F2EEF8")
    static let muted         = Color.adaptive("6B6379", "A79FB5")
    static let faint         = Color.adaptive("9A93A6", "7A7189")

    // Brand — deeper and calmer than the default indigo
    static let ink           = Color.adaptive("2E2557", "D8D2F5")
    static let brand         = Color.adaptive("4C3D9E", "9B8BEF")
    static let brandSoft     = Color.adaptive("EDE9FA", "2B2440")
    static let tint          = Color.adaptive("EDE9FA", "2B2440")

    // Warmth — burnt orange and a muted rose, not pastel
    static let warm          = Color.adaptive("C96F3C", "E29A66")
    static let warmSoft      = Color.adaptive("FBEFE4", "362518")
    static let rose          = Color.adaptive("B85A76", "E08FA6")
    static let roseSoft      = Color.adaptive("FAECF0", "33202A")

    // Semantic — natural, slightly desaturated
    static let thriving      = Color.adaptive("3F7D5C", "6FBF91")
    static let thrivingSoft  = Color.adaptive("E8F2EB", "1B2E23")
    static let drifting      = Color.adaptive("B5822E", "DDB05E")
    static let driftingSoft  = Color.adaptive("FAF1DF", "2E2515")
    static let strained      = Color.adaptive("B44A42", "E08B84")
    static let strainedSoft  = Color.adaptive("FAEBE9", "33201E")

    static let accent        = Color.adaptive("C96F3C", "E29A66")
}

// MARK: - Gradient

enum TetherGradient {
    static let brand = LinearGradient(
        colors: [Color.adaptive("5B4BB5", "6E5FD0"), Color.adaptive("3D3086", "4A3AA8")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let dawn = LinearGradient(
        colors: [Color.adaptive("FBF1E6", "241B26"), Color.adaptive("F7E3E9", "2A1D2C")],
        startPoint: .top, endPoint: .bottom)

    static let dusk = LinearGradient(
        colors: [Color.adaptive("2E2557", "171226"), Color.adaptive("4C3D9E", "312667")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let calm = LinearGradient(
        colors: [Color.adaptive("FAF7F2", "15111D"), Color.adaptive("F1EBF5", "1B1526")],
        startPoint: .top, endPoint: .bottom)

    /// Warm rose-to-indigo used for celebratory moments (milestone toasts).
    static let celebration = LinearGradient(
        colors: [Color.adaptive("B85A76", "E08FA6"), Color.adaptive("4C3D9E", "9B8BEF")],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

// MARK: - Type
//
// SF Pro Rounded throughout. Display sizes carry slightly tight tracking, which
// is what stops large text looking like a default system heading.

enum TetherType {
    // Built on semantic text styles rather than fixed point sizes, so every
    // label scales with the user's preferred text size. Fixed sizes silently
    // ignore Dynamic Type, which locks out anyone who needs larger text.

    static let display    = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let largeTitle = Font.system(.title, design: .rounded, weight: .bold)
    static let title      = Font.system(.title2, design: .rounded, weight: .semibold)
    static let headline   = Font.system(.headline, design: .rounded)
    static let body       = Font.system(.body, design: .rounded)
    static let callout    = Font.system(.callout, design: .rounded)
    static let label      = Font.system(.subheadline, design: .rounded, weight: .semibold)
    static let caption    = Font.system(.caption, design: .rounded)
    static let micro      = Font.system(.caption2, design: .rounded, weight: .medium)

    /// Applied to display / largeTitle so big text reads as set, not defaulted.
    static let displayTracking: CGFloat = -0.6
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
    static let small: CGFloat = 12
    static let medium: CGFloat = 18
    static let large: CGFloat = 26
    static let xlarge: CGFloat = 34
}

// MARK: - Depth

enum TetherShadow {
    case none, soft, lifted, floating

    var color: Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(white: 0, alpha: 1)
            : UIColor(hex: "241F2E") }).opacity(opacity)
    }
    var radius: CGFloat {
        switch self {
        case .none: return 0
        case .soft: return 12
        case .lifted: return 22
        case .floating: return 34
        }
    }
    var y: CGFloat {
        switch self {
        case .none: return 0
        case .soft: return 4
        case .lifted: return 10
        case .floating: return 18
        }
    }
    var opacity: Double {
        switch self {
        case .none: return 0
        case .soft: return 0.05
        case .lifted: return 0.10
        case .floating: return 0.16
        }
    }
}

extension DynamicTypeSize {
    /// True at the accessibility sizes. Horizontal label/value rows break down
    /// here — words hyphenate mid-syllable — so those layouts stack instead.
    var isAccessibility: Bool { self >= .accessibility1 }
}

extension View {
    func tetherShadow(_ style: TetherShadow = .soft) -> some View {
        shadow(color: style.color, radius: style.radius, x: 0, y: style.y)
    }

    /// The single input treatment used everywhere, so no field can drift into
    /// an unreadable state. The explicit text colour is the important part.
    func tetherField() -> some View {
        self
            .font(TetherType.body)
            .foregroundStyle(TetherColor.text)
            .tint(TetherColor.brand)
            .padding(TetherSpace.l)
            .background(TetherColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TetherRadius.medium, style: .continuous)
                    .strokeBorder(TetherColor.border, lineWidth: 1)
            )
            .tetherShadow(.soft)
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

    /// Caps content to a comfortable reading width and centers it. On iPhone this
    /// is effectively a no-op (the cap exceeds the screen); on iPad it keeps the
    /// column from stretching edge to edge into an unreadable band.
    func readableFrame() -> some View {
        self.frame(maxWidth: 760)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    /// A gentle lift-and-fade entrance used on hero cards so the screen settles
    /// in rather than snapping. `delay` staggers sibling cards for a composed feel.
    func tetherAppear(delay: Double = 0) -> some View {
        modifier(TetherAppearModifier(delay: delay))
    }
}

/// Spring entrance: fades from 0 opacity and a small downward offset.
struct TetherAppearModifier: ViewModifier {
    var delay: Double = 0
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.84).delay(delay)) {
                    appeared = true
                }
            }
    }
}
