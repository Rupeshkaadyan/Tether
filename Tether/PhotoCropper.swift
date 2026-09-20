import SwiftUI
import UIKit

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

    /// The output is always a square, so the avatar never has letterboxing.
    private let outputSize: CGFloat = 512

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height) - 48

                ZStack {
                    TetherBackdrop().ignoresSafeArea()

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

    /// Renders the current framing to a square image.
    ///
    /// The preview is square and the avatar is a circle, so the square is
    /// rendered large enough that the circle inscribed in it is still sharp.
    private func cropped() -> UIImage {
        let side = min(image.size.width, image.size.height)
        guard side > 0 else { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: CGSize(width: outputSize,
                                                    height: outputSize),
                                       format: format).image { _ in
            // Centre the image, then apply the scale and the drag.
            let drawSide = side / scale
            let x = (image.size.width - drawSide) / 2
                    - (offset.width / 512) * drawSide
            let y = (image.size.height - drawSide) / 2
                    - (offset.height / 512) * drawSide

            image.draw(in: CGRect(x: x * (outputSize / image.size.width),
                                  y: y * (outputSize / image.size.height),
                                  width: (drawSide / image.size.width) * outputSize,
                                  height: (drawSide / image.size.height) * outputSize))
        }
    }
}
