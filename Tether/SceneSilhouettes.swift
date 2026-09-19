import SwiftUI

// MARK: - Horizon silhouettes
//
// One shape per place. The palette alone is not enough: recolouring the same
// two hills green still reads as hills, so Jungle needs foliage and Ocean
// needs a flat waterline.
//
// All are `Shape`s so they stay sharp at any size and cost nothing to draw.

/// Layered rounded foliage. Overlapping arcs of decreasing size, which is how
/// a canopy actually reads — mass first, detail second.
struct FoliageShape: Shape {
    /// 0 = far layer (smaller, higher), 1 = near layer (bigger, lower).
    let depth: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        guard w > 0, h > 0 else { return p }

        // The canopy sits lower for the near layer, so the two overlap.
        let baseline = h * (0.62 + depth * 0.16)
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: baseline))

        // Clumps across the width, sized by a stable pattern so the outline
        // looks grown rather than random.
        let count = depth < 0.5 ? 7 : 5
        let clumpW = w / Double(count)
        for i in 0..<count {
            let cx = clumpW * (Double(i) + 0.5)
            let swell = 0.55 + 0.45 * abs(sin(Double(i) * 2.1 + depth * 5))
            let r = clumpW * (0.62 + 0.34 * swell) * (0.85 + depth * 0.3)
            let cy = baseline - r * (0.30 + 0.30 * swell)
            p.addArc(center: CGPoint(x: cx, y: cy),
                     radius: r,
                     startAngle: .degrees(180),
                     endAngle: .degrees(360),
                     clockwise: false)
        }

        p.addLine(to: CGPoint(x: w, y: baseline))
        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }
}

/// A flat waterline with banded swell. Ocean is horizontal; the ridges are
/// not, which is why Ocean used to look like hills under a blue sky.
struct SwellShape: Shape {
    let depth: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        guard w > 0, h > 0 else { return p }

        let baseline = h * (0.58 + depth * 0.12)
        let amp = h * (0.012 + depth * 0.014)

        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: baseline))

        let steps = 24
        for i in 0...steps {
            let x = w * Double(i) / Double(steps)
            let y = baseline + sin(Double(i) * 0.55 + depth * 3) * amp
            p.addLine(to: CGPoint(x: x, y: y))
        }

        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }
}

/// Smooth dunes — long, soft shoulders with no sharp crest.
struct DuneShape: Shape {
    let depth: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        guard w > 0, h > 0 else { return p }

        let baseline = h * (0.54 + depth * 0.14)
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: baseline))

        // Three long quad curves — dunes are wide and gentle, not peaked.
        let crest = h * (0.10 + depth * 0.05)
        p.addQuadCurve(to: CGPoint(x: w * 0.55, y: baseline + crest * 0.4),
                       control: CGPoint(x: w * 0.26, y: baseline - crest))
        p.addQuadCurve(to: CGPoint(x: w, y: baseline - crest * 0.2),
                       control: CGPoint(x: w * 0.82, y: baseline + crest * 0.7))

        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }
}

/// Low rolling grass. Shallow, many small bumps — the opposite of the dunes.
struct GrassShape: Shape {
    let depth: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        guard w > 0, h > 0 else { return p }

        let baseline = h * (0.66 + depth * 0.12)
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: baseline))

        let count = 14
        for i in 0..<count {
            let x0 = w * Double(i) / Double(count)
            let x1 = w * Double(i + 1) / Double(count)
            let bump = h * (0.018 + 0.012 * abs(sin(Double(i) * 1.7 + depth * 4)))
            p.addQuadCurve(to: CGPoint(x: x1, y: baseline),
                           control: CGPoint(x: (x0 + x1) / 2, y: baseline - bump))
        }

        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }
}

/// Picks the right shape for a scene's silhouette.
struct SceneSilhouetteShape: Shape {
    let kind: SceneSilhouette
    let depth: Double

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .ridge:   return Ridge(peaks: depth < 0.5
                                    ? [0.20, 0.38, 0.24, 0.44, 0.28]
                                    : [0.34, 0.52, 0.36, 0.56, 0.40],
                                    crest: depth < 0.5 ? 0.42 : 0.56).path(in: rect)
        case .foliage: return FoliageShape(depth: depth).path(in: rect)
        case .water:   return SwellShape(depth: depth).path(in: rect)
        case .dune:    return DuneShape(depth: depth).path(in: rect)
        case .grass:   return GrassShape(depth: depth).path(in: rect)
        }
    }
}
