import LocalAuthentication
import SwiftUI

// MARK: - Motion

/// Motion is expensive-feeling or it is noise. One screen-transition duration,
/// one long breathing cycle, and spring reserved for the smallest gestures.
enum TetherMotion {
    static let screen: Double = 0.25
    static let breathing: Double = 4.5

    static let fade   = Animation.easeInOut(duration: screen)
    static let settle = Animation.easeOut(duration: 0.35)
}

// MARK: - The slack curve
//
// The whole product grows out of one idea: two points connected by a curve with
// slack. `TetherCurve` (TetherArt.swift) is the large decorative sweep; this is
// the delicate line-level version used inside components.

struct TetherSlackCurve: Shape {
    var sag: CGFloat

    var animatableData: CGFloat {
        get { sag }
        set { sag = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let start = CGPoint(x: rect.minX, y: rect.midY)
        let end   = CGPoint(x: rect.maxX, y: rect.midY)
        var path = Path()
        path.move(to: start)
        // A quad curve reaches halfway to its control point, so doubling the
        // sag puts the visible low point where `sag` says it should be.
        path.addQuadCurve(to: end,
                          control: CGPoint(x: rect.midX, y: rect.midY + sag * 2))
        return path
    }
}

/// Two points, joined, with slack — the small mark used in components.
struct TetherHeroMark: View {
    var width: CGFloat = 72
    var color: Color = TetherColor.brand
    var sag: CGFloat = 9
    var lineWidth: CGFloat = 2
    var dotRadius: CGFloat = 3.5

    private var height: CGFloat { max(sag * 2 + dotRadius * 3, 18) }

    var body: some View {
        ZStack {
            TetherSlackCurve(sag: sag)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .padding(.horizontal, dotRadius)

            HStack {
                Circle()
                    .fill(color)
                    .frame(width: dotRadius * 2, height: dotRadius * 2)
                Spacer(minLength: 0)
                Circle()
                    .fill(color)
                    .frame(width: dotRadius * 2, height: dotRadius * 2)
            }
            .padding(.horizontal, dotRadius)
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Atmosphere

/// The paper the app is printed on. Large, barely-there arcs and brand-tinted
/// haze so the warm background reads as atmosphere rather than an empty canvas.
///
/// Deliberately low contrast: arcs at ~5% opacity, haze blurred until it stops
/// reading as a shape. No landscapes, no religious imagery, no hearts.
struct TetherAtmosphere: View {
    var intensity: Double = 1

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Two wide arcs, anchored off-screen so only a shoulder shows.
                Circle()
                    .stroke(TetherColor.brand.opacity(0.05 * intensity), lineWidth: 1.5)
                    .frame(width: w * 1.55, height: w * 1.55)
                    .offset(x: w * 0.34, y: -h * 0.44)

                Circle()
                    .stroke(TetherColor.warm.opacity(0.05 * intensity), lineWidth: 1.5)
                    .frame(width: w * 1.25, height: w * 1.25)
                    .offset(x: -w * 0.42, y: h * 0.46)

                // Brand haze, blurred until it becomes weather rather than shape.
                Circle()
                    .fill(TetherColor.brand.opacity(0.035 * intensity))
                    .frame(width: w * 0.85, height: w * 0.85)
                    .blur(radius: 72)
                    .offset(x: w * 0.26, y: -h * 0.24)

                Circle()
                    .fill(TetherColor.rose.opacity(0.028 * intensity))
                    .frame(width: w * 0.75, height: w * 0.75)
                    .blur(radius: 84)
                    .offset(x: -w * 0.32, y: h * 0.36)

                // One faint slack line — the only "straight" edge in the system.
                TetherSlackCurve(sag: h * 0.06)
                    .stroke(TetherColor.border, lineWidth: 1)
                    .frame(width: w * 1.4, height: h * 0.3)
                    .offset(x: -w * 0.2, y: h * 0.18)
                    .opacity(0.5)
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    func tetherAtmosphere(intensity: Double = 1) -> some View {
        background(TetherAtmosphere(intensity: intensity))
    }
}

// MARK: - Breathing

/// A 4.5-second breath. Slow enough to feel alive, never distracting, and
/// skipped entirely when Reduce Motion is on.
struct TetherBreathingModifier: ViewModifier {
    var duration: Double = TetherMotion.breathing
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .scaleEffect(breathing ? 1.012 : 0.994)
                .opacity(breathing ? 1 : 0.93)
                .onAppear {
                    withAnimation(.easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)) {
                        breathing = true
                    }
                }
        }
    }
}

extension View {
    func tetherBreathing(duration: Double = TetherMotion.breathing) -> some View {
        modifier(TetherBreathingModifier(duration: duration))
    }
}

// MARK: - Prompt hero

/// The emotional centre of the app: the day's question, given the most space
/// and the most care. The mark sits above it, breathing.
struct TetherPromptHero<Content: View>: View {
    let eyebrow: String
    let prompt: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: TetherSpace.l) {
            TetherHeroMark(width: 84, color: Color.white.opacity(0.85))
                .tetherBreathing()

            Text(eyebrow.uppercased())
                .font(TetherType.micro)
                .foregroundStyle(Color.white.opacity(0.72))
                .tracking(1.1)

            Text(prompt)
                .font(TetherType.prompt)
                .foregroundStyle(Color.white)
                .fixedSize(horizontal: false, vertical: true)

            content()
        }
        .padding(TetherSpace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TetherGradient.brand)
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        )
        .tetherShadow(.floating)
    }
}

// MARK: - Section header

/// A quiet section divider that still carries the hierarchy.
struct TetherSectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: TetherSpace.xs) {
            Text(title)
                .font(TetherType.title)
                .foregroundStyle(TetherColor.ink)
            if let subtitle {
                Text(subtitle)
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Empty state

/// Every "nothing yet" in the app gets the same treatment: the mark, one
/// honest line, and a single clear next action. No giant blank areas.
struct TetherEmptyState: View {
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: TetherSpace.l) {
            // The mark, given room to breathe — it is the whole message here.
            TetherMark(size: 96,
                       lineColor: TetherColor.brand.opacity(0.28),
                       dotColor: TetherColor.brand,
                       lineWidth: 9)

            VStack(spacing: TetherSpace.s) {
                Text(title)
                    .font(TetherType.title)
                    .foregroundStyle(TetherColor.ink)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .tetherButton(.secondary, fullWidth: false)
                    .padding(.top, TetherSpace.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TetherSpace.xxxl)
        .padding(.horizontal, TetherSpace.xl)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Language

/// Lets someone choose Tether's language inside the app instead of inheriting
/// the device language. Applied as an environment locale at the root, so it
/// takes effect immediately — no restart, no AppleLanguages hack.
@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    /// Shown in Settings. Displayed in each language's own script so it is
    /// readable whether or not you understand the current one.
    static let available: [(code: String, name: String)] = [
        ("en", "English"),
        ("hi", "हिन्दी"),
        ("es", "Español")
    ]

    private let key = "tether.language"

    var code: String {
        didSet { UserDefaults.standard.set(code, forKey: key) }
    }

    init() {
        code = UserDefaults.standard.string(forKey: key) ?? "en"
    }

    var locale: Locale { Locale(identifier: code) }

    var displayName: String {
        Self.available.first { $0.code == code }?.name ?? "English"
    }
}

// MARK: - Appearance

/// Lets someone pick light, dark, or follow the system — rather than only
/// inheriting the device setting. Persisted, applied at the root via
/// preferredColorScheme.
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    enum Mode: String, CaseIterable, Identifiable {
        case system, light, dark

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return "System"
            case .light:  return "Light"
            case .dark:   return "Dark"
            }
        }
    }

    private let key = "tether.theme"

    var modeRaw: String {
        didSet { UserDefaults.standard.set(modeRaw, forKey: key) }
    }

    init() {
        modeRaw = UserDefaults.standard.string(forKey: key) ?? Mode.system.rawValue
    }

    var mode: Mode { Mode(rawValue: modeRaw) ?? .system }

    /// `nil` means "follow the system", which is what SwiftUI expects.
    var colorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - App lock

/// For an app holding someone's private journal this is table stakes: lock it
/// behind the device passcode or Face ID so nobody else can read it.
@Observable
final class AppLockManager {
    static let shared = AppLockManager()

    private let key = "tether.lockEnabled"

    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: key) }
    }

    /// True while the lock screen is covering the app.
    var isLocked = false

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: key)
    }

    /// Called when the app moves to the background.
    func lock() {
        guard isEnabled else { return }
        isLocked = true
    }

    /// Prompts for device authentication. If the device has no passcode or
    /// biometrics configured we unlock rather than trapping the person out of
    /// their own journal.
    func unlock() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isLocked = false
            return
        }
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Unlock Tether to read your journal"
        ) { granted, _ in
            DispatchQueue.main.async {
                if granted { self.isLocked = false }
            }
        }
    }
}

/// The cover shown while locked — the mark, the wordmark, one way back in.
struct LockScreen: View {
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            TetherBackdrop(style: .dusk).ignoresSafeArea()

            VStack(spacing: TetherSpace.l) {
                TetherMark(size: 104,
                           lineColor: .white.opacity(0.45),
                           dotColor: .white,
                           lineWidth: 9)
                Text("Tether")
                    .font(TetherType.largeTitle)
                    .foregroundStyle(.white)
                Text("Your journal is locked.")
                    .font(TetherType.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Button("Unlock", action: onUnlock)
                    .tetherButton(.secondary, fullWidth: false)
                    .padding(.top, TetherSpace.s)
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}
