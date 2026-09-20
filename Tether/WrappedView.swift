import SwiftData
import SwiftUI

// MARK: - Wrapped
//
// The shape of your year, as a card you can send to someone.
//
// This is a growth mechanic, not a vanity screen. Every share is free
// distribution, and Tether's privacy stance is what makes it safe: the card
// carries NUMBERS ONLY — days, counts, streaks. Not one word either of you
// wrote, and not a single mood.
//
// That constraint is the feature. A wrapped card that leaked your journal
// would be a betrayal; a card that says "we showed up 214 days" is a brag
// anybody can post.

struct WrappedStats {
    let daysShownUp: Int
    let entries: Int
    let longestStreak: Int
    let bestMonth: String?
    let partnerName: String?

    var isMeaningful: Bool { daysShownUp > 0 }
}

enum WrappedBuilder {
    static func stats(profile: UserProfile,
                      partner: UserProfile?,
                      entries: [JournalEntry]) -> WrappedStats {
        let cal = Calendar.current
        let mine = entries.filter { $0.userID == profile.id }

        let days = Set(mine.map { cal.startOfDay(for: $0.entryDate) })
        let streak = Streaks.current(from: mine.map(\.entryDate))

        // The month with the most entries — the one you two leaned in hardest.
        let byMonth = Dictionary(grouping: mine) { entry -> DateComponents in
            cal.dateComponents([.year, .month], from: entry.entryDate)
        }
        let best = byMonth.max { $0.value.count < $1.value.count }
        var bestName: String?
        if let comps = best?.key, let date = cal.date(from: comps) {
            bestName = date.formatted(.dateTime.month(.wide))
        }

        return WrappedStats(
            daysShownUp: days.count,
            entries: mine.count,
            longestStreak: streak,
            bestMonth: bestName,
            partnerName: partner?.displayName
        )
    }
}

// MARK: - The card

/// Rendered to an image for sharing, so it must be self-contained: no
/// environment colours that depend on the parent, no scrolling.
struct WrappedCard: View {
    let stats: WrappedStats
    let year: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                TetherMark(size: 30,
                           lineColor: .white.opacity(0.95),
                           dotColor: .white,
                           lineWidth: 3.4)
                Text("TETHER")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer(minLength: 0)
                Text(String(year))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.bottom, 28)

            Text(headline)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(stats.daysShownUp)")
                    .font(.system(size: 74, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(stats.daysShownUp == 1 ? "day" : "days")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.top, 2)

            Text("you showed up for each other.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom, 30)

            VStack(spacing: 10) {
                row("\(stats.entries)", "things said out loud")
                if stats.longestStreak > 1 {
                    row("\(stats.longestStreak)", "days in a row, at best")
                }
                if let month = stats.bestMonth {
                    row(month, "your fullest month")
                }
            }

            Spacer(minLength: 20)

            Text("Nothing either of you wrote is on this card.")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.42))
        }
        .padding(28)
        .frame(width: 360, height: 520, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color(hex: "3A2A6B"),
                         Color(hex: "1E1733"),
                         Color(hex: "4A2A46")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var headline: String {
        if let name = stats.partnerName { return "This year, you and \(name)" }
        return "This year, you"
    }

    private func row(_ value: String, _ label: String) -> some View {
        HStack(spacing: 10) {
            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 62, alignment: .leading)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.62))
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Screen

struct WrappedView: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    @State private var image: Image?

    let stats: WrappedStats

    private var year: Int { Calendar.current.component(.year, from: Date()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TetherSpace.l) {
                    WrappedCard(stats: stats, year: year)
                        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)

                    Text("Numbers only. Not one word either of you wrote is on this card — that is the point.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Share as an image") { render() }
                        .tetherButton()

                    if let image {
                        ShareLink(item: image,
                                  preview: SharePreview("Our Tether year",
                                                        image: image)) {
                            Text("Send it")
                                .font(TetherType.label)
                                .foregroundStyle(TetherColor.brand)
                        }
                    }
                }
                .padding(TetherSpace.margin)
                .readableFrame()
                .padding(.bottom, TetherSpace.xxl)
            }
            .background { TetherBackdrop() }
            .navigationTitle("Your year")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    /// Renders the card off-screen at 2× so the shared image is crisp.
    @MainActor
    private func render() {
        let renderer = ImageRenderer(
            content: WrappedCard(stats: stats, year: year)
                .environment(\.colorScheme, .dark)
        )
        renderer.scale = 3
        guard let ui = renderer.uiImage else { return }
        image = Image(uiImage: ui)
        TetherHaptics.success()
    }
}
