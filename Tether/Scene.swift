import SwiftUI

// MARK: - Scenes
//
// The scene owns the BACKDROP. The Feel owns the ACCENT. They never overlap,
// and that is deliberate: the Warm (rose) accent has to sit on every one of
// these backdrops without turning muddy, so no scene is allowed to use the
// accent's hue in its own background. Night is deep blue, Garden green, Jungle
// dark green-gold, Dawn warm paper. Rose lands cleanly on all four.
//
// Scenes are chosen, never assigned. There is no "female theme".
//
// A scene applies across the whole app, not just the jar, so it also carries
// the COLOUR SCHEME. That is not decoration — a dark backdrop with the app's
// light-mode ink would be unreadable. Because every colour in TetherColor is
// already adaptive, setting the scheme is all that is needed: the rest of the
// app re-resolves itself correctly.

enum AppScene: String, CaseIterable, Identifiable {
    // `.automatic` is the default and the answer to "what should the theme do
    // when the phone is in dark mode?" — it follows the phone: dark gets
    // Night, light gets Dawn. Anything else would mean a person who has set
    // their phone to dark mode opening an app that ignores them.
    case automatic, day, dawn, night, garden, jungle, ocean, dune, aurora, meadow

    var id: String { rawValue }

    /// The scene that actually draws, once `.automatic` has been resolved
    /// against the device's appearance.
    ///
    /// Every visual property on this type must be read from the RESOLVED
    /// scene, never from `.automatic` directly — `.automatic` has no backdrop
    /// of its own. `SceneBackdrop` and `TetherBackdrop` resolve first and hand
    /// the concrete case to everything downstream.
    ///
    /// Light mode resolves to DAY, not Dawn. Dawn is a specific moment —
    /// low warm light, a sunrise — and it was wrong as the resting look for
    /// someone whose phone is simply in light mode at noon. Day is the
    /// neutral bright counterpart to Night.
    func concrete(system: ColorScheme) -> AppScene {
        guard self == .automatic else { return self }
        return system == .dark ? .night : .day
    }

    // LocalizedStringKey, not String. `Text(someString)` is treated by SwiftUI
    // as VERBATIM and is never looked up in the catalog, so a plain String here
    // would ship these four names in English to every language, silently.
    var title: LocalizedStringKey {
        switch self {
        case .automatic: return "Match phone"
        case .day:       return "Day"
        case .dawn:      return "Dawn"
        case .night:     return "Night"
        case .garden:    return "Garden"
        case .jungle:    return "Jungle"
        case .ocean:     return "Ocean"
        case .dune:      return "Dune"
        case .aurora:    return "Aurora"
        case .meadow:    return "Meadow"
        }
    }

    var blurb: LocalizedStringKey {
        switch self {
        case .automatic: return "Follows your phone. Dark gets Night, light gets Day."
        case .day:       return "Bright sky, soft cloud, clear light."
        case .dawn:      return "Warm paper and morning light."
        case .night:     return "Deep sky, drifting fireflies."
        case .garden:    return "Soft green, butterflies."
        case .jungle:    return "Dense leaves, warm shafts of light."
        case .ocean:     return "Deep water, slow bubbles rising."
        case .dune:      return "Warm sand at dusk, dust on the wind."
        case .aurora:    return "Cold sky, green light moving."
        case .meadow:    return "Open grass, seed drifting on a warm breeze."
        }
    }

    var symbol: String {
        switch self {
        case .automatic: return "circle.lefthalf.filled"
        case .day:       return "sun.max"
        case .dawn:      return "sun.horizon"
        case .night:     return "moon.stars"
        case .garden:    return "leaf"
        case .jungle:    return "tree"
        case .ocean:     return "water.waves"
        case .dune:      return "sun.dust"
        case .aurora:    return "sparkles"
        case .meadow:    return "camera.macro"
        }
    }

    /// Night and Day are free; everything else is part of the subscription.
    ///
    /// The reasoning: a free user must still get a complete, working app, and
    /// the two that matter most are the ones the phone would pick anyway.
    /// Locking a person into Dawn because they have not paid would make the
    /// free version feel like a demo of itself.
    ///
    /// `.automatic` is free because it only ever resolves to Night or Day.
    var isFree: Bool {
        switch self {
        case .automatic, .day, .night: return true
        default: return false
        }
    }

    /// True when the backdrop is dark, so the jar and its labels can adapt.
    var isDark: Bool {
        switch self {
        // `.automatic` never reaches here — resolve it first. Treated as light
        // so a missed resolution fails visibly rather than silently dark.
        case .automatic, .day, .dawn, .dune, .meadow: return false
        case .night, .garden, .jungle, .ocean, .aurora: return true
        }
    }

    /// The appearance this scene requires to stay readable.
    ///
    /// Dawn is a light backdrop and needs light-mode ink; the other three are
    /// dark and need dark-mode ink. Applied app-wide, so every adaptive colour
    /// in TetherColor resolves to the legible half of its pair.
    var scheme: ColorScheme { isDark ? .dark : .light }

    /// Ambient particle density for the whole app. Lower than the jar's, so it
    /// reads as atmosphere rather than a scene — the jar is the only place the
    /// particles are the subject.
    var ambientParticleCount: Int {
        switch self {
        case .automatic, .dawn: return 7
        case .day:              return 6
        case .meadow:           return 8
        case .night:            return 9
        case .garden:           return 5
        case .jungle:           return 4
        case .ocean:            return 6
        case .dune:             return 6
        case .aurora:           return 5
        }
    }

    /// Three stops, top-leading → bottom-trailing.
    var backdrop: [Color] {
        switch self {
        case .day:
            return [Color(hex: "EAF4FD"), Color(hex: "DCEBF7"), Color(hex: "F3F7FB")]
        case .meadow:
            return [Color(hex: "F2F7E8"), Color(hex: "E4F0D6"), Color(hex: "FAF6E6")]
        case .automatic, .dawn:
            return [Color(hex: "FDF6EC"), Color(hex: "F7E9DA"), Color(hex: "F2E3E6")]
        case .night:
            return [Color(hex: "1B1740"), Color(hex: "0E0B22"), Color(hex: "2A1B3D")]
        case .garden:
            return [Color(hex: "1F3A2E"), Color(hex: "16281F"), Color(hex: "2C4436")]
        case .jungle:
            return [Color(hex: "12261C"), Color(hex: "0B1712"), Color(hex: "2A3520")]
        case .ocean:
            return [Color(hex: "0C2A3E"), Color(hex: "071A28"), Color(hex: "123C4E")]
        case .dune:
            return [Color(hex: "FBF1E0"), Color(hex: "F3E0C4"), Color(hex: "EAD3BE")]
        case .aurora:
            return [Color(hex: "0B1B2E"), Color(hex: "060F1C"), Color(hex: "14303A")]
        }
    }

    /// A soft light source, so the scene is lit rather than flat.
    var glow: Color {
        switch self {
        case .day:              return Color(hex: "FFE9B8")
        case .meadow:           return Color(hex: "D6E8A0")
        case .automatic, .dawn: return Color(hex: "FFD9A0")
        case .night:            return Color(hex: "8FA8FF")
        case .garden:           return Color(hex: "A8E0B0")
        case .jungle:           return Color(hex: "D9C07A")
        case .ocean:            return Color(hex: "7FD4E8")
        case .dune:             return Color(hex: "F0B463")
        case .aurora:           return Color(hex: "8FF0C4")
        }
    }

    var particle: Particle {
        switch self {
        case .automatic, .dawn, .day, .dune: return .motes
        case .night:                         return .fireflies
        case .garden:                        return .butterflies
        case .jungle:                        return .butterflies
        case .ocean:                         return .bubbles
        case .aurora:                        return .aurora
        case .meadow:                        return .seed
        }
    }

    /// Foreground text on this backdrop.
    var ink: Color { isDark ? Color(hex: "F2EEE8") : TetherColor.ink }
    var muted: Color { isDark ? Color.white.opacity(0.62) : TetherColor.muted }
    var faint: Color { isDark ? Color.white.opacity(0.38) : TetherColor.faint }
}

enum Particle {
    case motes, fireflies, butterflies
    /// Slow bubbles rising — Ocean. Movement is vertical and unhurried.
    case bubbles
    /// Vertical ribbons of light that drift and fade — Aurora.
    case aurora
    /// Dandelion seed on a breeze — Meadow. Carried sideways, unlike the
    /// bubbles which only rise.
    case seed
}

// MARK: - Persistence

@Observable
final class SceneManager {
    static let shared = SceneManager()

    private let key = "tether.scene"

    var raw: String {
        didSet { UserDefaults.standard.set(raw, forKey: key) }
    }

    init() {
        // Default is `.automatic`, NOT `.dawn`. Someone who has set their
        // phone to dark mode must not open the app into a bright morning.
        raw = UserDefaults.standard.string(forKey: key) ?? AppScene.automatic.rawValue
    }

    /// What the person chose. May be `.automatic`.
    var choice: AppScene { AppScene(rawValue: raw) ?? .automatic }

    /// Back-compat: the chosen scene. Callers that DRAW must resolve it first
    /// with `concrete(system:)` — see `SceneBackdrop`.
    var theme: AppScene { choice }
}

// MARK: - The living backdrop

/// An animated scene behind the jar: gradient, a soft light source, and slow
/// particles. Drawn in a single Canvas driven by TimelineView rather than
/// dozens of animated views — one draw call instead of thirty.
///
/// This is where the "wow" comes from instead of a 3D model: depth, light and
/// movement, at a fraction of the cost and without breaking the illustrated
/// style the rest of the app is built on.
struct SceneBackdrop: View {
    /// The CHOSEN scene. May be `.automatic`, which is resolved below against
    /// the device appearance before anything is drawn.
    var theme: AppScene = .automatic
    /// Fraction of the particles to draw. The jar uses 1 (the scene is the
    /// subject); the app-wide backdrop uses less, so it reads as atmosphere.
    var density: Double = 1
    /// How often to redraw, in frames per second.
    ///
    /// THIS IS A THERMAL DECISION, not a visual one. Running at the display's
    /// native rate meant a Canvas full of radial gradients redrawing 120 times
    /// a second on every screen, forever — which is what made the phone hot.
    ///
    /// The particles drift a few pixels per second. At 15fps they are
    /// indistinguishable from 120fps, because there is no fast motion for the
    /// eye to track. The jar gets a little more because it is the focus and
    /// the draw is the point; the ambient backdrop gets less.
    var framesPerSecond: Double = 15

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var systemScheme

    /// Resolving here rather than at every call site means `.automatic` cannot
    /// leak into a switch that has no case for it — the compiler would catch
    /// that, but the call sites would all have to change too.
    private var resolved: AppScene { theme.concrete(system: systemScheme) }

    var body: some View {
        // No minimumInterval: the schedule follows the display's native rate,
        // so a ProMotion iPhone animates at 120 and everything else at 60.
        // Capping it lower was a false economy — the particles are the point.
        //
        // It DOES pause when the app is not in the foreground. That is where
        // the real waste was: a display link ticking behind a backgrounded app
        // buys nothing and costs battery.
        TimelineView(.animation(minimumInterval: 1.0 / framesPerSecond,
                                paused: scenePhase != .active)) { timeline in
            Canvas { ctx, size in
                // Guard before ANY arithmetic.
                //
                // SwiftUI can hand a Canvas a zero or non-finite size during
                // the first layout pass, or while a container is collapsing.
                // Every particle does `r * 2.6` and `size.width * 0.75` from
                // this value, so a NaN or a negative propagates straight into
                // CGRect and logs "Invalid frame dimension (negative or
                // non-finite)" — once per particle, per frame, which is its own
                // performance problem on top of the visual one.
                guard size.width.isFinite, size.height.isFinite,
                      size.width > 0, size.height > 0 else { return }

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
                        Gradient(colors: [resolved.glow.opacity(0.22),
                                          resolved.glow.opacity(0.0)]),
                        center: centre,
                        startRadius: 0,
                        endRadius: size.width * 0.75))

                draw(resolved.particle, in: &ctx, size: size, t: t)
            }
        }
        .allowsHitTesting(false)
    }

    private func draw(_ kind: Particle,
                      in ctx: inout GraphicsContext,
                      size: CGSize,
                      t: Double) {
        switch kind {
        case .motes:       motes(&ctx, size, t)
        case .fireflies:   fireflies(&ctx, size, t)
        case .butterflies: butterflies(&ctx, size, t)
        case .bubbles:     bubbles(&ctx, size, t)
        case .aurora:      aurora(&ctx, size, t)
        case .seed:        seed(&ctx, size, t)
        }
    }

    /// Dandelion seed carried on a breeze. Horizontal drift with a slow bob —
    /// the sideways motion is what separates it from the bubbles.
    private func seed(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        for i in 0..<max(1, Int(11 * density)) {
            let s = seed(i, 15)
            let speed = 14 + s * 20
            let travel = size.width + 70
            let x = (t * speed + s * travel).truncatingRemainder(dividingBy: travel) - 35
            let y = seed(i, 16) * size.height + sin(t * 0.45 + s * 9) * 14
            let r = 1.4 + s * 2.2

            // A soft halo reads as fluff rather than a hard dot.
            ctx.fill(
                Path(ellipseIn: CGRect(x: x - r * 2.6, y: y - r * 2.6,
                                       width: r * 5.2, height: r * 5.2)),
                with: .radialGradient(
                    Gradient(colors: [Color(hex: "FFFFFF").opacity(0.34),
                                      Color(hex: "FFFFFF").opacity(0)]),
                    center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r * 2.6))

            ctx.fill(
                Path(ellipseIn: CGRect(x: x - r * 0.5, y: y - r * 0.5,
                                       width: r, height: r)),
                with: .color(Color(hex: "FFFFFF").opacity(0.55)))
        }
    }

    // MARK: Particles

    /// Slow dust in warm light. Barely there, which is the point.
    private func motes(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        for i in 0..<Int(14 * density) {
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
        for i in 0..<Int(16 * density) {
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
        for i in 0..<max(1, Int(7 * density)) {
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

    /// Bubbles rising. Vertical and unhurried — the opposite of the fireflies,
    /// which wander. This is what makes Ocean read as water rather than sky.
    private func bubbles(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        for i in 0..<max(1, Int(12 * density)) {
            let s = seed(i, 11)
            let speed = 12 + s * 22
            let x = seed(i, 12) * size.width + sin(t * 0.25 + s * 8) * 10
            // Rise from the bottom, wrap cleanly.
            let travel = size.height + 60
            let y = size.height + 30 - (t * speed + s * travel)
                .truncatingRemainder(dividingBy: travel)
            let r = 1.5 + s * 3

            ctx.stroke(
                Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                with: .color(Color(hex: "BFEAF5").opacity(0.16 + s * 0.16)),
                lineWidth: 1)
        }
    }

    /// Vertical ribbons of light that drift sideways and fade — Aurora.
    /// Drawn as soft vertical strokes rather than points, because the aurora
    /// is a curtain, not a star field.
    private func aurora(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        let tints = [Color(hex: "8FF0C4"), Color(hex: "7FD4E8"), Color(hex: "C9A8F0")]
        for i in 0..<max(1, Int(6 * density)) {
            let s = seed(i, 13)
            let x = seed(i, 14) * size.width + sin(t * 0.12 + s * 7) * 40
            let h = size.height * (0.30 + s * 0.45)
            let breathe = 0.5 + 0.5 * abs(sin(t * 0.22 + s * 4))
            let tint = tints[i % tints.count]

            var path = Path()
            path.move(to: CGPoint(x: x, y: size.height * 0.10))
            path.addQuadCurve(
                to: CGPoint(x: x + 14, y: size.height * 0.10 + h),
                control: CGPoint(x: x - 20, y: size.height * 0.10 + h * 0.5))
            ctx.stroke(path,
                       with: .color(tint.opacity(0.05 + 0.11 * breathe)),
                       style: StrokeStyle(lineWidth: 18 + s * 22,
                                          lineCap: .round))
        }
    }

    /// Stable pseudo-random per particle, so nothing jumps between frames.
    private func seed(_ i: Int, _ salt: Int) -> Double {
        let x = sin(Double(i) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return x - x.rounded(.down)
    }
}
