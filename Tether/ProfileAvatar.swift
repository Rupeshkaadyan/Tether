import SwiftData
import SwiftUI

extension UIImage {
    /// Re-encode at a sane size.
    ///
    /// A full-resolution photo from the camera roll is several megabytes.
    /// Stored per profile it makes the store grow and every fetch slower, for
    /// an image displayed at 62 points. Downsampling first costs one decode
    /// and saves it on every subsequent read.
    func downsampled(to maxDimension: CGFloat) -> Data? {
        let scale = min(maxDimension / max(size.width, 1),
                        maxDimension / max(size.height, 1),
                        1)
        guard scale < 1 else { return jpegData(compressionQuality: 0.8) }

        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: target, format: format)
            .jpegData(withCompressionQuality: 0.8) { _ in
                draw(in: CGRect(origin: .zero, size: target))
            }
    }
}

// MARK: - Avatar

/// A person's picture, or their initial when there isn't one.
///
/// Never an empty grey circle. An initial reads as a person; a placeholder
/// reads as an unfinished screen.
struct ProfileAvatar: View {
    var name: String = ""
    var photoData: Data?
    var size: CGFloat = 44
    /// Warm accent for the fallback, so two people are never the same colour.
    var tint: Color = TetherColor.brand

    private var image: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }

    private var initial: String {
        let t = name.trimmingCharacters(in: .whitespaces)
        return String(t.first ?? "?").uppercased()
    }

    var body: some View {
        Group {
            if let ui = image {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(tint.opacity(0.18))
                    Text(initial)
                        .font(.system(size: size * 0.42, weight: .medium,
                                      design: .rounded))
                        .foregroundStyle(tint)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(TetherColor.border, lineWidth: 1))
        .accessibilityLabel(name.isEmpty ? "Profile picture" : "\(name)'s picture")
    }
}

// MARK: - The tether

/// Two people, joined by the rope the app is named for.
///
/// The rope is DRAWN, not an image: it hangs with a real catenary sag, which
/// is the difference between a line between two dots and something that reads
/// as a connection under gentle tension. When nobody is connected yet, the
/// rope hangs loose from one side only — visibly waiting, not broken.
struct TetherConnection: View {
    var meName: String = ""
    var mePhoto: Data?
    var partnerName: String?
    var partnerPhoto: Data?
    var size: CGFloat = 56

    private var isConnected: Bool { partnerName != nil }

    var body: some View {
        HStack(spacing: 0) {
            ProfileAvatar(name: meName, photoData: mePhoto, size: size,
                          tint: TetherColor.brand)

            // The rope lives in the gap between them.
            Canvas { ctx, canvasSize in
                let w = canvasSize.width
                let h = canvasSize.height
                guard w > 0, h > 0 else { return }

                var path = Path()
                // Anchor at the avatar edges, not the canvas edge, so the rope
                // touches the people rather than floating beside them.
                path.move(to: CGPoint(x: 0, y: h * 0.5))
                path.addQuadCurve(
                    to: CGPoint(x: w, y: h * 0.5),
                    control: CGPoint(x: w * 0.5, y: h * 0.5 + sag(for: w)))

                ctx.stroke(path,
                           with: .color(TetherColor.brand.opacity(isConnected ? 0.85 : 0.3)),
                           style: StrokeStyle(lineWidth: 2,
                                              lineCap: .round,
                                              dash: isConnected ? [] : [3, 5]))
            }
            .frame(height: size)
            .frame(minWidth: 44)

            if let partnerName {
                ProfileAvatar(name: partnerName, photoData: partnerPhoto,
                              size: size, tint: TetherColor.rose)
            } else {
                // A loose end, not a second person. Someone is missing and
                // the screen says so without a word.
                Circle()
                    .strokeBorder(TetherColor.border, style: StrokeStyle(lineWidth: 1.5,
                                                                         dash: [3, 4]))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: size * 0.34))
                            .foregroundStyle(TetherColor.faint)
                    )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isConnected
                            ? "You and \(partnerName ?? ""), connected"
                            : "You, not connected yet")
    }

    /// A slack rope hangs deeper the wider the gap. Real sag, not a fixed arc.
    private func sag(for width: CGFloat) -> CGFloat {
        min(max(width * 0.34, 8), 26)
    }
}
