import SwiftUI

// MARK: - The mark
//
// Two people, connected, still able to move. This curve is the brand. It appears
// in the icon, as the onboarding hero, as a faint backdrop, and as the pairing
// animation — one shape used consistently is what makes an app feel designed
// rather than assembled.

struct TetherCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let start = CGPoint(x: rect.minX + rect.width * 0.10,
                            y: rect.minY + rect.height * 0.24)
        let end   = CGPoint(x: rect.maxX - rect.width * 0.10,
                            y: rect.maxY - rect.height * 0.24)
        p.move(to: start)
        p.addCurve(to: end,
                   control1: CGPoint(x: rect.minX + rect.width * 0.78,
                                     y: rect.minY + rect.height * 0.16),
                   control2: CGPoint(x: rect.minX + rect.width * 0.22,
                                     y: rect.maxY - rect.height * 0.16))
        return p
    }
}

struct TetherMark: View {
    var size: CGFloat = 120
    var lineColor: Color = TetherColor.brandSoft
    var dotColor: Color = .white
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            TetherCurve()
                .stroke(lineColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)

            Circle()
                .fill(dotColor)
                .frame(width: size * 0.19, height: size * 0.19)
                .offset(x: -size * 0.40, y: -size * 0.26)

            Circle()
                .fill(dotColor)
                .frame(width: size * 0.19, height: size * 0.19)
                .offset(x: size * 0.40, y: size * 0.26)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Backdrop

enum TetherBackdropStyle { case calm, dawn, dusk, brand }

struct TetherBackdrop: View {
    var style: TetherBackdropStyle = .calm
    @Environment(\.colorScheme) private var systemScheme

    private var fill: AnyShapeStyle {
        switch style {
        // The resting screen is warm paper, not a gradient. The atmospheric
        // layer supplies the depth instead, so #FDFBF8 never looks empty.
        // The resting backdrop follows the chosen scene, app-wide. Everything
        // else that uses TetherBackdrop() picks this up for free.
        case .calm:
            // Resolved, not raw: `.automatic` has no backdrop of its own.
            return AnyShapeStyle(LinearGradient(
                colors: SceneManager.shared.choice.concrete(system: systemScheme).backdrop,
                startPoint: .topLeading,
                endPoint: .bottomTrailing))
        case .dawn:  return AnyShapeStyle(TetherGradient.dawn)
        case .dusk:  return AnyShapeStyle(TetherGradient.dusk)
        case .brand: return AnyShapeStyle(TetherGradient.brand)
        }
    }

    private var curveOpacity: Double {
        switch style {
        case .dusk, .brand: return 0.18
        case .calm: return 0.05
        default: return 0.22
        }
    }

    private var curveColor: Color {
        switch style {
        case .dusk, .brand: return .white
        default: return TetherColor.brand
        }
    }

    var body: some View {
        ZStack {
            Rectangle().fill(fill)

            // Ambient particles, app-wide. Deliberately sparse — this is
            // atmosphere, not a scene. The jar is the only place where the
            // particles are the subject rather than the setting.
            if style == .calm {
                // No theme passed: SceneBackdrop reads the manager itself and
                // resolves `.automatic` against the device appearance.
                SceneBackdrop(density: 0.45, framesPerSecond: 12)
            }

            // Arcs and haze over the paper, under the content.
            if style == .calm || style == .dawn {
                TetherAtmosphere(intensity: style == .calm ? 1 : 0.6)
            }
            GeometryReader { geo in
                TetherCurve()
                    .stroke(curveColor.opacity(curveOpacity),
                            style: StrokeStyle(lineWidth: 90, lineCap: .round))
                    .frame(width: geo.size.width * 1.5, height: geo.size.height * 0.9)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -geo.size.width * 0.25, y: geo.size.height * 0.08)
                    .blur(radius: 2)
            }
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

// MARK: - Breathing orb
//
// A slow, calm pulse. Used on the daily prompt so the app feels alive and
// invites a breath before answering — this is the "ritual, not form" moment.

struct BreathingOrb: View {
    var size: CGFloat = 220
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [TetherColor.brandSoft, .clear],
                                     center: .center, startRadius: 4, endRadius: size * 0.5))
                .frame(width: size, height: size)
                .scaleEffect(animate ? 1.06 : 0.94)
                .opacity(animate ? 0.95 : 0.65)

            Circle()
                .fill(RadialGradient(colors: [TetherColor.warmSoft, .clear],
                                     center: .center, startRadius: 2, endRadius: size * 0.36))
                .frame(width: size * 0.72, height: size * 0.72)
                .scaleEffect(animate ? 0.92 : 1.05)
                .opacity(animate ? 0.7 : 1)
        }
        .animation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate = true }
        .accessibilityHidden(true)
    }
}

// MARK: - Avatar

struct AvatarBubble: View {
    var name: String
    var size: CGFloat = 44
    var tint: Color = TetherColor.brand

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init)
        return letters.joined().uppercased()
    }

    var body: some View {
        ZStack {
            Circle().fill(tint.opacity(0.14))
            Text(initials.isEmpty ? "?" : initials)
                .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(name)
    }
}

// MARK: - Two-avatar pairing

struct PairedAvatars: View {
    var left: String
    var right: String?
    var size: CGFloat = 40
    var converged: Bool = false

    var body: some View {
        HStack(spacing: converged ? -8 : 6) {
            AvatarBubble(name: left, size: size)
            if let right {
                AvatarBubble(name: right, size: size, tint: TetherColor.warm)
            } else {
                ZStack {
                    Circle().strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .foregroundStyle(TetherColor.borderStrong)
                    Image(systemName: "plus")
                    .accessibilityHidden(true)
                        .font(.system(size: size * 0.3, weight: .medium))
                        .foregroundStyle(TetherColor.faint)
                }
                .frame(width: size, height: size)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: converged)
    }
}
