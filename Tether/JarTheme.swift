import SwiftUI

// MARK: - Jar themes
//
// The theme owns the SCENE. The Feel owns the ACCENT. They never overlap, and
// that is deliberate: the Warm (rose) accent has to sit on every one of these
// backdrops without turning muddy, so no theme is allowed to use the accent's
// hue in its own background. Night is deep blue, Garden is green, Jungle is
// dark green-gold, Dawn is warm paper. Rose lands cleanly on all four.
//
// Themes are chosen, never assigned. There is no "female jar".

enum JarTheme: String, CaseIterable, Identifiable {
    case dawn, night, garden, jungle

    var id: String { rawValue }

    // LocalizedStringKey, not String. `Text(someString)` is treated by SwiftUI
    // as VERBATIM and is never looked up in the catalog, so a plain String here
    // would ship these four names in English to every language, silently.
    var title: LocalizedStringKey {
        switch self {
        case .dawn:   return "Dawn"
        case .night:  return "Night"
        case .garden: return "Garden"
        case .jungle: return "Jungle"
        }
    }

    var blurb: LocalizedStringKey {
        switch self {
        case .dawn:   return "Warm paper and morning light."
        case .night:  return "Deep sky, drifting fireflies."
        case .garden: return "Soft green, butterflies."
        case .jungle: return "Dense leaves, warm shafts of light."
        }
    }

    var symbol: String {
        switch self {
        case .dawn:   return "sun.horizon"
        case .night:  return "moon.stars"
        case .garden: return "leaf"
        case .jungle: return "tree"
        }
    }

    /// True when the backdrop is dark, so the jar and its labels can adapt.
    var isDark: Bool {
        switch self {
        case .dawn: return false
        case .night, .garden, .jungle: return true
        }
    }

    /// Three stops, top-leading → bottom-trailing.
    var backdrop: [Color] {
        switch self {
        case .dawn:
            return [Color(hex: "FDF6EC"), Color(hex: "F7E9DA"), Color(hex: "F2E3E6")]
        case .night:
            return [Color(hex: "1B1740"), Color(hex: "0E0B22"), Color(hex: "2A1B3D")]
        case .garden:
            return [Color(hex: "1F3A2E"), Color(hex: "16281F"), Color(hex: "2C4436")]
        case .jungle:
            return [Color(hex: "12261C"), Color(hex: "0B1712"), Color(hex: "2A3520")]
        }
    }

    /// A soft light source, so the scene is lit rather than flat.
    var glow: Color {
        switch self {
        case .dawn:   return Color(hex: "FFD9A0")
        case .night:  return Color(hex: "8FA8FF")
        case .garden: return Color(hex: "A8E0B0")
        case .jungle: return Color(hex: "D9C07A")
        }
    }

    var particle: Particle {
        switch self {
        case .dawn:   return .motes
        case .night:  return .fireflies
        case .garden: return .butterflies
        case .jungle: return .butterflies
        }
    }

    /// Foreground text on this backdrop.
    var ink: Color { isDark ? Color(hex: "F2EEE8") : TetherColor.ink }
    var muted: Color { isDark ? Color.white.opacity(0.62) : TetherColor.muted }
    var faint: Color { isDark ? Color.white.opacity(0.38) : TetherColor.faint }
}

enum Particle {
    case motes, fireflies, butterflies
}

// MARK: - Persistence

@Observable
final class JarThemeManager {
    static let shared = JarThemeManager()

    private let key = "tether.jarTheme"

    var raw: String {
        didSet { UserDefaults.standard.set(raw, forKey: key) }
    }

    init() {
        raw = UserDefaults.standard.string(forKey: key) ?? JarTheme.dawn.rawValue
    }

    var theme: JarTheme { JarTheme(rawValue: raw) ?? .dawn }
}

// MARK: - The living backdrop

/// An animated scene behind the jar: gradient, a soft light source, and slow
/// particles. Drawn in a single Canvas driven by TimelineView rather than
/// dozens of animated views — one draw call instead of thirty.
///
/// This is where the "wow" comes from instead of a 3D model: depth, light and
/// movement, at a fraction of the cost and without breaking the illustrated
/// style the rest of the app is built on.
struct JarScene: View {
    let theme: JarTheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate

                // Light source, upper-left, breathing very slowly.
                let pulse = 1 + 0.04 * sin(t * 0.35)
                let centre = CGPoint(x: size.width * 0.34, y: size.height * 0.30)
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: centre.x - size.width * 0.75 * pulse,
                        y: centre.y - size.width * 0.75 * pulse,
                        width: size.width * 1.5 * pulse,
                        height: size.width * 1.5 * pulse)),
                    with: .radialGradient(
                        Gradient(colors: [theme.glow.opacity(0.22),
                                          theme.glow.opacity(0.0)]),
                        center: centre,
                        startRadius: 0,
                        endRadius: size.width * 0.75))

                draw(theme.particle, in: &ctx, size: size, t: t)
            }
        }
        .allowsHitTesting(false)
    }

    private func draw(_ kind: Particle,
                      in ctx: inout GraphicsContext,
                      size: CGSize,
                      t: Double) {
        switch kind {
        case .motes:      motes(&ctx, size, t)
        case .fireflies:  fireflies(&ctx, size, t)
        case .butterflies: butterflies(&ctx, size, t)
        }
    }

    // MARK: Particles

    /// Slow dust in warm light. Barely there, which is the point.
    private func motes(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        for i in 0..<14 {
            let s = seed(i, 1)
            let x = (seed(i, 2) * size.width + sin(t * 0.18 + s * 6) * 16)
            let y = (seed(i, 3) * size.height - (t * (6 + s * 8)).truncatingRemainder(dividingBy: size.height + 40)) + size.height
            let r = 1.2 + s * 1.6
            ctx.fill(
                Path(ellipseIn: CGRect(x: x, y: y.truncatingRemainder(dividingBy: size.height + 40) - 20,
                                       width: r * 2, height: r * 2)),
                with: .color(Color(hex: "C89B5E").opacity(0.18 + s * 0.12)))
        }
    }

    /// Warm points that drift and fade in and out, each on its own rhythm.
    private func fireflies(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        for i in 0..<16 {
            let s = seed(i, 4)
            let speed = 0.10 + s * 0.16
            let x = seed(i, 5) * size.width + sin(t * speed + s * 9) * 34
            let y = seed(i, 6) * size.height + cos(t * speed * 0.8 + s * 5) * 26
            let blink = 0.35 + 0.65 * abs(sin(t * (0.5 + s * 0.6) + s * 3))
            let r = 1.6 + s * 1.8

            ctx.fill(
                Path(ellipseIn: CGRect(x: x - r * 3, y: y - r * 3,
                                       width: r * 6, height: r * 6)),
                with: .radialGradient(
                    Gradient(colors: [Color(hex: "FFE9A8").opacity(0.30 * blink),
                                      Color(hex: "FFE9A8").opacity(0)]),
                    center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r * 3))

            ctx.fill(
                Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                with: .color(Color(hex: "FFF4C9").opacity(0.55 + 0.45 * blink)))
        }
    }

    /// Two soft wings that open and close as they wander.
    private func butterflies(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        let tints = [Color(hex: "F6C7D8"), Color(hex: "F2D79A"), Color(hex: "CFE3F5"),
                     Color(hex: "E8D3F0")]
        for i in 0..<7 {
            let s = seed(i, 7)
            let speed = 0.07 + s * 0.10
            let x = seed(i, 8) * size.width + sin(t * speed + s * 7) * 52
            let y = seed(i, 9) * size.height + cos(t * speed * 0.7 + s * 4) * 38
            let flap = abs(sin(t * (1.6 + s) + s * 2))
            let w = (3.0 + s * 3.0) * (0.45 + 0.55 * flap)
            let tint = tints[i % tints.count]

            // Wings
            for dir in [-1.0, 1.0] {
                let wing = Path(ellipseIn: CGRect(
                    x: x + dir * (w * 0.35) - w * 0.5,
                    y: y - w * 0.42,
                    width: w, height: w * 0.84))
                ctx.fill(wing, with: .color(tint.opacity(0.42)))
            }
            // Body
            ctx.fill(
                Path(ellipseIn: CGRect(x: x - 0.9, y: y - w * 0.34,
                                       width: 1.8, height: w * 0.68)),
                with: .color(tint.opacity(0.65)))
        }
    }

    /// Stable pseudo-random per particle, so nothing jumps between frames.
    private func seed(_ i: Int, _ salt: Int) -> Double {
        let x = sin(Double(i) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return x - x.rounded(.down)
    }
}
