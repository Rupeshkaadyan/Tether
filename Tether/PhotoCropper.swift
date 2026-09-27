import SwiftUI
import UIKit

private struct PreviewSideKey: PreferenceKey {
    static let defaultValue: CGFloat = 320
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Pinch, drag, and confirm — the minimum that makes "crop my photo" real.
///
/// A profile picture taken straight from the camera roll is whatever framing
/// the camera happened to capture. Letting someone set the framing is the
/// difference between a photo that looks chosen and one that looks uploaded.
struct PhotoCropper: View {
    let image: UIImage
    var onDone: (UIImage) -> Void
    var onCancel: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    /// The on-screen square the preview draws into. The export needs it to
    /// reproduce the same framing, so it is captured when the view lays out.
    @State private var previewSide: CGFloat = 320

    /// The output is always a square, so the avatar never has letterboxing.
    private let outputSize: CGFloat = 512

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height) - 48

                ZStack {
                    TetherBackdrop().ignoresSafeArea()

                    // Publishes the preview square so the export can reproduce
                    // it. A preference rather than a direct assignment, which
                    // would mutate state while the view is being evaluated.
                    Color.clear.preference(key: PreviewSideKey.self,
                                           value: max(side, 1))

                    VStack(spacing: TetherSpace.l) {
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: side, height: side)
                                .scaleEffect(scale)
                                .offset(offset)
                                .clipped()

                            // A ring so it is obvious the result is a circle.
                            Circle()
                                .strokeBorder(.white.opacity(0.9), lineWidth: 2)
                                .frame(width: side, height: side)
                        }
                        .frame(width: side, height: side)
                        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large,
                                                    style: .continuous))
                        .contentShape(Rectangle())
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    // Clamped so the photo cannot be shrunk
                                    // inside the frame or blown up to mush.
                                    scale = min(max(lastScale * value, 1), 5)
                                }
                                .onEnded { _ in lastScale = scale }
                                .simultaneously(with:
                                    DragGesture()
                                        .onChanged { value in
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height)
                                        }
                                        .onEnded { _ in lastOffset = offset }
                                )
                        )

                        Text("Pinch to zoom, drag to move.")
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .onPreferenceChange(PreviewSideKey.self) { previewSide = $0 }
            }
            .navigationTitle("Position")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use") { onDone(cropped()) }
                }
                ToolbarItem(placement: .bottomBar) {
                    // Because pinch does not reset itself, and someone who
                    // has dragged a photo somewhere silly needs a way back.
                    Button("Reset") { reset() }
                }
            }
        }
    }

    private func reset() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }

    /// Renders exactly what the preview is showing.
    ///
    /// The old version divided the drag offset by a hard-coded 512 and scaled
    /// the original image rather than the `scaledToFill` content, so the saved
    /// avatar was framed differently from the one the person had just
    /// positioned — a crop UI that silently ignores the crop.
    ///
    /// The maths now mirrors the preview: `scaledToFill` gives a scale factor
    /// k, the drawn image is centred, and the visible square is `side / scale`
    /// points of that drawn content, centred at `side/2 + offset`.
    private func cropped() -> UIImage {
        let imgW = image.size.width
        let imgH = image.size.height
        let side = previewSide
        guard imgW > 0, imgH > 0, side > 0 else { return image }

        // How scaledToFill fits the image into the square.
        let k = max(side / imgW, side / imgH)
        let drawnW = imgW * k
        let drawnH = imgH * k
        let originX = (side - drawnW) / 2
        let originY = (side - drawnH) / 2

        // The visible window, in drawn-content points.
        let window = side / max(scale, 0.0001)
        let centreX = side / 2 + offset.width
        let centreY = side / 2 + offset.height

        // Back to original-image pixels, then clamped to the bitmap.
        var x = (centreX - window / 2 - originX) / k
        var y = (centreY - window / 2 - originY) / k
        var w = window / k
        var h = window / k

        if x < 0 { w += x; x = 0 }
        if y < 0 { h += y; y = 0 }
        w = min(w, imgW - x)
        h = min(h, imgH - y)
        guard w > 1, h > 1 else { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: CGSize(width: outputSize,
                                                    height: outputSize),
                                       format: format).image { _ in
            // Draw the whole image scaled and shifted so the crop rect exactly
            // fills the square output. `UIImage.draw(in:)` takes a single rect,
            // so the offset is applied by moving the drawn image rather than by
            // cropping from a source rect.
            let ratio = outputSize / w
            image.draw(in: CGRect(x: -x * ratio,
                                  y: -y * ratio,
                                  width: imgW * ratio,
                                  height: imgH * ratio))
        }
    }
}
