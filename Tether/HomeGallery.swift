import SwiftUI

// MARK: - Home gallery
//
// Home used to be ten identical full-width buttons stacked vertically — a
// list wearing a card's clothes. It read as a settings screen, not as a
// place you want to be.
//
// This is a gallery: two columns of tiles, each with its own illustration
// and its own reason to be tapped right now. Varied heights and a real
// rhythm, so scrolling feels like browsing rather than reading a menu.

struct GalleryTile: Identifiable {
    let id: String
    var icon: TetherIcon
    var title: LocalizedStringKey
    var detail: LocalizedStringKey
    /// A live reason to tap — "3 notes waiting" beats a static label.
    var badge: String?
    var tint: Color
    /// Wide tiles break the grid rhythm so it does not become another list.
    var isWide: Bool = false
    let action: () -> Void

    static func == (lhs: GalleryTile, rhs: GalleryTile) -> Bool { lhs.id == rhs.id }
}

/// One tile: illustration, name, and the reason to tap it now.
struct GalleryTileView: View {
    let tile: GalleryTile

    var body: some View {
        Button(action: tile.action) {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(tile.tint.opacity(0.16))
                            .frame(width: 38, height: 38)
                        Icon(tile.icon, size: 18, color: tile.tint)
                    }
                    Spacer(minLength: 0)
                    if let badge = tile.badge {
                        Text(badge)
                            .font(TetherType.micro)
                            .foregroundStyle(tile.tint)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(tile.tint.opacity(0.14), in: Capsule())
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(tile.title)
                        .font(TetherType.label)
                        .foregroundStyle(TetherColor.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(tile.detail)
                        .font(TetherType.micro)
                        .foregroundStyle(TetherColor.faint)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(TetherSpace.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Taller than a list row so the grid reads as a gallery.
            .frame(minHeight: 116)
            .background(TetherColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large,
                                        style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous)
                    .strokeBorder(TetherColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(tile.title))
        .accessibilityHint(Text(tile.detail))
    }
}

/// The collection, laid out as a two-column gallery with wide tiles breaking
/// the rhythm.
struct HomeGallery: View {
    let tiles: [GalleryTile]

    private let columns = [
        GridItem(.flexible(), spacing: TetherSpace.m),
        GridItem(.flexible(), spacing: TetherSpace.m)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: TetherSpace.m) {
            ForEach(tiles) { tile in
                // A wide tile spans both columns. Without these the grid is
                // just a list with two columns, and the eye slides straight
                // past it.
                if tile.isWide {
                    GalleryTileView(tile: tile)
                        .gridCellColumns(2)
                } else {
                    GalleryTileView(tile: tile)
                }
            }
        }
    }
}
