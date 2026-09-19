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
    // MARK: Brand palette — fixed values.
    //
    // These are the product's identity and must not drift. Dark mode is a
    // deliberate warm-dark counterpart, never an inversion.

    // Surfaces
    static let bg            = Color.adaptive("FDFBF8", "171320")
    static let surface       = Color.adaptive("FFFFFF", "221D2B")
    static let surfaceSunken = Color.adaptive("F6F2EC", "1C1724")
    static let border        = Color.adaptive("EAE4DB", "332B3F")
    static let borderStrong  = Color.adaptive("D8D0C4", "453B54")

    // Text — never pure black
    static let text          = Color.adaptive("2A2438", "F3EFF7")
    static let muted         = Color.adaptive("6F6879", "A79FB5")
    // Lifted in dark mode: at #7A7189 the tertiary labels (mood names under
    // journal entries) sat too close to the surface to read comfortably.
    static let faint         = Color.adaptive("9A93A6", "8A8299")

    // Brand
    static let ink           = Color.adaptive("2A2438", "D8D2F5")

    /// The accent follows the chosen Feel. Not a gender switch — a tone
    /// preference anyone can set, whichever way they answer the (optional)
    /// gender question.
    static var brand: Color {
        switch FeelManager.shared.feel {
        case .classic: return Color.adaptive("5B4BC4", "8B7BE8")
        case .warm:    return Color.adaptive("B0486E", "E08FA8")
        }
    }

    static var brandSoft: Color {
        switch FeelManager.shared.feel {
        case .classic: return Color.adaptive("EFECFB", "2A2440")
        case .warm:    return Color.adaptive("FBEDF1", "34202A")
        }
    }
    static let tint          = Color.adaptive("EFECFB", "2A2440")

    // Warmth
    static let warm          = Color.adaptive("E08A4B", "E29A66")
    static let warmSoft      = Color.adaptive("FBEDE3", "362518")
    static let rose          = Color.adaptive("D96A8A", "E08FA6")
    static let roseSoft      = Color.adaptive("FAECEF", "33202A")

    // Semantic
    static let thriving      = Color.adaptive("2E9E6B", "6FBF91")
    static let thrivingSoft  = Color.adaptive("E7F3ED", "1B2E23")
    static let drifting      = Color.adaptive("D08A28", "DDB05E")
    static let driftingSoft  = Color.adaptive("FAF1E0", "2E2515")
    static let strained      = Color.adaptive("C4463F", "E08B84")
    static let strainedSoft  = Color.adaptive("F9EBE9", "33201E")

    static let accent        = Color.adaptive("E08A4B", "E29A66")
}

// MARK: - Gradient

enum TetherGradient {
    /// The brand gradient, following the chosen Feel.
    /// Classic: #6A57D6 → #4A3AA8. Warm: rose → plum.
    static var brand: LinearGradient {
        switch FeelManager.shared.feel {
        case .classic:
            return LinearGradient(
                colors: [Color.adaptive("6A57D6", "7E6BE0"), Color.adaptive("4A3AA8", "5B4BC4")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .warm:
            return LinearGradient(
                colors: [Color.adaptive("C4608A", "D98BA8"), Color.adaptive("8E3A61", "A85B7E")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

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
    /// The daily question — more presence than body copy, never shouting.
    /// ~21pt semibold at the default size, and it still scales with Dynamic Type.
    static let prompt     = Font.system(.title3, design: .rounded, weight: .semibold)
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
    static let large: CGFloat = 24
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
