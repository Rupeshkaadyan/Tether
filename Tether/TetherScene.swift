import SwiftUI

/// A hand-drawn landscape for the top of Home. Every line is a `Path` — this
/// is not an image file, so it stays razor sharp at any size, adapts to light
/// and dark mode, and can change with the time of day.
///
/// The scene is the same world the welcome screen describes: two ridges, still
/// water, and a light on the horizon. It is the brand's landscape, drawn.
struct TetherScene: View {
    let timeOfDay: TimeOfDay

    enum TimeOfDay {
        case dawn, day, dusk, night

        static var current: TimeOfDay {
            switch Calendar.current.component(.hour, from: Date()) {
            case 5..<9:   return .dawn
            case 9..<17:  return .day
            case 17..<21: return .dusk
            default:      return .night
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                LinearGradient(colors: sky, startPoint: .top, endPoint: .bottom)

                // The light on the horizon — sun by day, moon at night.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [orb.opacity(0.95), orb.opacity(0.0)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 95
                        )
                    )
                    .frame(width: 170, height: 170)
                    .position(x: w * 0.70, y: h * 0.40)

                // Stars, only when the sky is dark enough to hold them.
                if timeOfDay == .night {
                    Stars()
                        .opacity(0.85)
                }

                // Far ridge.
                Ridge(peaks: [0.20, 0.38, 0.24, 0.44, 0.28], crest: 0.42)
                    .fill(farRidge)
                    .frame(height: h)

                // Near ridge.
                Ridge(peaks: [0.34, 0.52, 0.36, 0.56, 0.40], crest: 0.56)
                    .fill(nearRidge)
                    .frame(height: h)

                // Still water, catching the light.
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [water.opacity(0.0), water],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: h * 0.20)
                }
            }
        }
    }

    // MARK: Palette per time of day

    private var sky: [Color] {
        switch timeOfDay {
        case .dawn:  return [Color(hex: "2E2A55"), Color(hex: "6B5AA8"), Color(hex: "E8A08A")]
        case .day:   return [Color(hex: "6E8FD6"), Color(hex: "9FB6E8"), Color(hex: "E4E9F7")]
        case .dusk:  return [Color(hex: "3B2A63"), Color(hex: "8E5A96"), Color(hex: "E2926F")]
        case .night: return [Color(hex: "141126"), Color(hex: "241E42"), Color(hex: "3A2F5C")]
        }
    }

    private var orb: Color {
        switch timeOfDay {
        case .dawn:  return Color(hex: "FFD9A8")
        case .day:   return Color(hex: "FFF6DC")
        case .dusk:  return Color(hex: "FFB07A")
        case .night: return Color(hex: "D8D4F0")
        }
    }

    private var farRidge: Color {
        switch timeOfDay {
        case .dawn:  return Color(hex: "6A5A9E").opacity(0.85)
        case .day:   return Color(hex: "8FA3D4").opacity(0.80)
        case .dusk:  return Color(hex: "6B4A82").opacity(0.85)
        case .night: return Color(hex: "2C2450").opacity(0.95)
        }
    }

    private var nearRidge: Color {
        switch timeOfDay {
        case .dawn:  return Color(hex: "4A3E78")
        case .day:   return Color(hex: "6B7FBE")
        case .dusk:  return Color(hex: "4A3266")
        case .night: return Color(hex: "1C1738")
        }
    }

    private var water: Color {
        switch timeOfDay {
        case .dawn:  return Color(hex: "3A3068")
        case .day:   return Color(hex: "5C6FB0")
        case .dusk:  return Color(hex: "3A2A58")
        case .night: return Color(hex: "151130")
        }
    }
}

// MARK: - Ridge

/// A layered mountain silhouette. Peaks are normalised heights; `crest` is how
/// far up the view the ridge reaches.
private struct Ridge: Shape {
    let peaks: [CGFloat]
    let crest: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let n = peaks.count
        guard n > 1 else { return path }

        func point(_ i: Int) -> CGPoint {
            let x = rect.width * CGFloat(i) / CGFloat(n - 1)
            let y = rect.height * (crest - peaks[i] * 0.28)
            return CGPoint(x: x, y: y)
        }

        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: point(0))
        for i in 1..<n {
            path.addLine(to: point(i))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Stars

/// A scatter of small dots. Positions are deterministic so the sky does not
/// shimmer when the view redraws.
private struct Stars: View {
    private let points: [(x: CGFloat, y: CGFloat, r: CGFloat)] = {
        var seed: UInt64 = 0x9E3779B97F4A7C15
        func next() -> CGFloat {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return CGFloat((seed >> 33) % 1000) / 1000
        }
        return (0..<34).map { _ in
            (x: next(), y: next() * 0.55, r: 0.7 + next() * 1.1)
        }
    }()

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                for p in points {
                    let rect = CGRect(
                        x: p.x * size.width,
                        y: p.y * size.height,
                        width: p.r * 2,
                        height: p.r * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.75)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
