import SwiftUI

/// Launch moment. Shown briefly on cold start, then fades to the app.
///
/// Deliberately quiet: the mark settles in, the wordmark follows, and it leaves.
/// No logo animation theatre — this app gets opened at calm and sometimes
/// vulnerable moments.
struct SplashView: View {
    @State private var markIn = false
    @State private var textIn = false

    var body: some View {
        ZStack {
            TetherBackdrop(style: .dusk)

            VStack(spacing: TetherSpace.xl) {
                TetherMark(size: 132,
                           lineColor: .white.opacity(0.94),
                           dotColor: .white,
                           lineWidth: 14)
                    .scaleEffect(markIn ? 1 : 0.88)
                    .opacity(markIn ? 1 : 0)

                VStack(spacing: 6) {
                    Text("Tether")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .tracking(TetherType.displayTracking)
                        .foregroundStyle(.white)
                    Text("Two people. One practice.")
                        .font(TetherType.callout)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .opacity(textIn ? 1 : 0)
                .offset(y: textIn ? 0 : 8)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { markIn = true }
            withAnimation(.easeOut(duration: 0.7).delay(0.25)) { textIn = true }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tether. Two people. One practice.")
    }
}
