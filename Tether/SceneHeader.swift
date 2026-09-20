import SwiftUI

// MARK: - The header, per scene
//
// The header used to be ONE landscape recoloured by time of day: two bare
// ridges, still water, a light on the horizon. That is a fine drawing, but it
// is not ten drawings. Choosing Jungle gave you a green body under a blue
// daytime sky — two different worlds stacked, which is exactly what it looked
// like.
//
// A scene now owns the whole header: its own sky, its own light, its own
// colours, AND its own silhouette. Jungle is layered foliage. Ocean is water
// with a low horizon. Dune is smooth sand. Meadow is open grass. Night and
// Aurora keep the ridges, because that is what those places actually look
// like.
//
// The silhouette matters more than the palette. Recolouring the same hills
// green still reads as hills.

/// What the horizon is made of.
enum SceneSilhouette {
    /// Two bare ridges — the original, and right for open sky.
    case ridge
    /// Layered rounded foliage, near-black at the front.
    case foliage
    /// Flat horizon with banded swell.
    case water
    /// Smooth, soft-shouldered dunes.
    case dune
    /// Low rolling grass, soft and irregular.
    case grass
}

struct SceneHeader {
    var sky: [Color]
    var orb: Color
    var far: Color
    var near: Color
    var water: Color
    var silhouette: SceneSilhouette
    /// Stars only belong where the sky is dark enough to hold them.
    var showsStars: Bool
}

extension AppScene {
    /// Resolved scenes only. `.automatic` falls back to Day.
    var header: SceneHeader {
        switch self {
        case .glass:
            // Pale, cool and almost colourless. The glass theme is carried by
            // the card material rather than the sky, so the horizon stays
            // quiet — colour here would fight it.
            return SceneHeader(
                sky: [Color(hex: "DCE7F2"), Color(hex: "EAF1F8"), Color(hex: "F8FBFD")],
                orb: Color(hex: "FFFFFF"),
                far: Color(hex: "CFDDEA").opacity(0.9),
                near: Color(hex: "B4C7DA"),
                water: Color(hex: "C9D9E8"),
                silhouette: .ridge, showsStars: false)

        case .automatic, .day:
            return SceneHeader(
                sky: [Color(hex: "5E86D8"), Color(hex: "9FB6E8"), Color(hex: "EAF1FA")],
                orb: Color(hex: "FFF6DC"),
                far: Color(hex: "8FA3D4").opacity(0.85),
                near: Color(hex: "6B7FBE"),
                water: Color(hex: "5C6FB0"),
                silhouette: .ridge, showsStars: false)

        case .dawn:
            return SceneHeader(
                sky: [Color(hex: "2E2A55"), Color(hex: "6B5AA8"), Color(hex: "E8A08A")],
                orb: Color(hex: "FFD9A8"),
                far: Color(hex: "6A5A9E").opacity(0.85),
                near: Color(hex: "4A3E78"),
                water: Color(hex: "3A3068"),
                silhouette: .ridge, showsStars: false)

        case .night:
            return SceneHeader(
                sky: [Color(hex: "141126"), Color(hex: "241E42"), Color(hex: "3A2F5C")],
                orb: Color(hex: "D8D4F0"),
                far: Color(hex: "2C2450").opacity(0.95),
                near: Color(hex: "1C1738"),
                water: Color(hex: "151130"),
                silhouette: .ridge, showsStars: true)

        case .aurora:
            return SceneHeader(
                sky: [Color(hex: "08131F"), Color(hex: "0F2733"), Color(hex: "1B4A4E")],
                orb: Color(hex: "CFF6E4"),
                far: Color(hex: "12303A").opacity(0.95),
                near: Color(hex: "08181F"),
                water: Color(hex: "061218"),
                silhouette: .ridge, showsStars: true)

        case .garden:
            // Bright, and GREEN all the way up. The old header put a blue sky
            // over a green body; this keeps the whole screen one place.
            return SceneHeader(
                sky: [Color(hex: "1D3B2C"), Color(hex: "2C5540"), Color(hex: "6E9C63")],
                orb: Color(hex: "EAF6C8"),
                far: Color(hex: "2F5C42").opacity(0.95),
                near: Color(hex: "1A3A28"),
                water: Color(hex: "14301F"),
                silhouette: .foliage, showsStars: false)

        case .jungle:
            // Deepest green. Almost no sky visible — that is the point of a
            // jungle: the canopy is the view.
            return SceneHeader(
                sky: [Color(hex: "0A1A12"), Color(hex: "14301F"), Color(hex: "2F5A34")],
                orb: Color(hex: "DCEFA8"),
                far: Color(hex: "1E4429").opacity(0.95),
                near: Color(hex: "0C2015"),
                water: Color(hex: "08160E"),
                silhouette: .foliage, showsStars: false)

        case .ocean:
            return SceneHeader(
                sky: [Color(hex: "08243A"), Color(hex: "124A63"), Color(hex: "4FA0B8")],
                orb: Color(hex: "EAF7FA"),
                far: Color(hex: "1B4E63").opacity(0.9),
                near: Color(hex: "0B2C3E"),
                water: Color(hex: "061E2C"),
                silhouette: .water, showsStars: false)

        case .dune:
            // Warm all the way up. Sand reflects into the sky at dusk.
            return SceneHeader(
                sky: [Color(hex: "C98A4E"), Color(hex: "E7B677"), Color(hex: "F6E0BC")],
                orb: Color(hex: "FFF1D2"),
                far: Color(hex: "D8A468").opacity(0.9),
                near: Color(hex: "A9703C"),
                water: Color(hex: "8A5A2E"),
                silhouette: .dune, showsStars: false)

        case .meadow:
            return SceneHeader(
                sky: [Color(hex: "7FB2DC"), Color(hex: "BCD9EC"), Color(hex: "F2F7E4")],
                orb: Color(hex: "FFF8DE"),
                far: Color(hex: "A8C87E").opacity(0.9),
                near: Color(hex: "7BA357"),
                water: Color(hex: "6C9349"),
                silhouette: .grass, showsStars: false)
        }
    }
}
