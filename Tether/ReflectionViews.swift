import SwiftData
import SwiftUI

// MARK: - On this day

/// Quietly resurfaces something written on this date in a previous year.
/// Entirely local — nothing leaves the device, and it costs nothing to compute.
struct OnThisDayCard: View {
    let entries: [JournalEntry]

    @ViewBuilder
    var body: some View {
        if let entry = entries.first {
            TetherCard {
                VStack(alignment: .leading, spacing: TetherSpace.s) {
                    Text("ON THIS DAY")
                        .font(TetherType.micro)
                        .foregroundStyle(TetherColor.faint)
                        .tracking(1.2)

                    Text(SecureContent.read(entry.body))
                        .font(TetherType.callout)
                        .foregroundStyle(TetherColor.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(entry.entryDate.formatted(date: .abbreviated, time: .omitted))
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                }
            }
        }
    }

    /// Entries from this calendar date in any earlier year.
    static func matches(in entries: [JournalEntry], userID: UUID) -> [JournalEntry] {
        let cal = Calendar.current
        let now = Date()
        let target = cal.dateComponents([.month, .day], from: now)
        let thisYear = cal.component(.year, from: now)

        return entries.filter { entry in
            guard entry.userID == userID else { return false }
            let parts = cal.dateComponents([.year, .month, .day], from: entry.entryDate)
            return parts.month == target.month
                && parts.day == target.day
                && parts.year != thisYear
        }
        .sorted { $0.entryDate > $1.entryDate }
    }
}

// MARK: - Year in review

/// A private summary of the last twelve months. No sharing, no judgement —
/// just what the year actually held.
struct YearInReviewView: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    private var mine: [JournalEntry] { entries.filter { $0.userID == profile.id } }

    private var yearEntries: [JournalEntry] {
        let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return mine.filter { $0.entryDate >= yearAgo }
    }

    private var avgMood: Double? {
        guard !yearEntries.isEmpty else { return nil }
        return Double(yearEntries.map(\.mood).reduce(0, +)) / Double(yearEntries.count)
    }

    /// Best three moments by mood — the year's own highlights.
    private var highlights: [JournalEntry] {
        Array(yearEntries.sorted { $0.mood > $1.mood }.prefix(3))
    }

    private var monthWithMostEntries: String? {
        guard !yearEntries.isEmpty else { return nil }
        let cal = Calendar.current
        let grouped = Dictionary(grouping: yearEntries) { cal.component(.month, from: $0.entryDate) }
        guard let best = grouped.max(by: { $0.value.count < $1.value.count }) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        return formatter.monthSymbols[best.key - 1]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.xl) {
                    header
                    statRow
                    if !highlights.isEmpty { highlightsSection }
                    if yearEntries.isEmpty { emptyNote }
                }
                .padding(TetherSpace.margin)
                .readableFrame()
                .padding(.bottom, TetherSpace.xl)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            TetherMark(size: 56,
                       lineColor: TetherColor.brand.opacity(0.35),
                       dotColor: TetherColor.brand,
                       lineWidth: 6)
            Text("A year of showing up")
                .font(TetherType.largeTitle)
                .foregroundStyle(TetherColor.ink)
            Text("Everything here was written by you, on your device. Nothing was sent anywhere.")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statRow: some View {
        HStack(alignment: .top, spacing: 0) {
            stat("Entries", value: "\(yearEntries.count)")
            divider
            stat("Avg mood", value: avgMood.map { String(format: "%.1f", $0) } ?? "—")
            divider
            stat("Best month", value: monthWithMostEntries ?? "—")
        }
        .padding(TetherSpace.xl)
        .background(TetherColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous)
                .strokeBorder(TetherColor.border, lineWidth: 1)
        )
        .tetherShadow(.soft)
    }

    private func stat(_ label: String, value: String) -> some View {
        VStack(spacing: TetherSpace.xs) {
            Text(value)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(TetherColor.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label.uppercased())
                .font(TetherType.micro)
                .foregroundStyle(TetherColor.muted)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(TetherColor.border)
            .frame(width: 1, height: 36)
            .padding(.horizontal, TetherSpace.s)
    }

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            Text("Moments worth keeping")
                .font(TetherType.title)
                .foregroundStyle(TetherColor.ink)

            ForEach(highlights) { entry in
                TetherCard {
                    VStack(alignment: .leading, spacing: TetherSpace.xs) {
                        Text(SecureContent.read(entry.body))
                            .font(TetherType.callout)
                            .foregroundStyle(TetherColor.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(entry.entryDate.formatted(date: .abbreviated, time: .omitted))
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                    }
                }
            }
        }
    }

    private var emptyNote: some View {
        TetherEmptyState(
            title: "Not enough yet",
            message: "A few more entries and this page will show your year — the moments, the mood, the months you showed up most."
        )
    }
}

// MARK: - Reveal moment

/// Both partners answered. This is the emotional heart of Tether and the only
/// celebration the product allows itself: the curve opens, the answers fade in,
/// one soft haptic. No confetti, no bouncing, no badges.
struct RevealMomentView: View {
    let myEntry: JournalEntry?
    let partnerEntry: JournalEntry?
    let partnerName: String
    let onClose: () -> Void

    @State private var revealed = false

    var body: some View {
        ZStack {
            TetherBackdrop(style: .dusk).ignoresSafeArea()

            VStack(spacing: TetherSpace.xl) {
                Spacer(minLength: TetherSpace.xxl)

                // The curve slackens and opens as the two answers meet.
                TetherSlackCurve(sag: revealed ? 34 : 2)
                    .stroke(
                        LinearGradient(colors: [Color(hex: "B3A4F0"), Color(hex: "6A57D6")],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 190, height: 74)
                    .animation(.easeOut(duration: 1.5), value: revealed)

                VStack(spacing: TetherSpace.xs) {
                    Text("You both showed up")
                        .font(TetherType.largeTitle)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("Today's answers, together.")
                        .font(TetherType.callout)
                        .foregroundStyle(.white.opacity(0.75))
                }

                VStack(spacing: TetherSpace.m) {
                    revealCard(label: "You", entry: myEntry)
                    revealCard(label: partnerName, entry: partnerEntry)
                }
                .padding(.horizontal, TetherSpace.margin)

                Spacer()

                Button("Close", action: onClose)
                    .tetherButton(.secondary)
                    .padding(.horizontal, TetherSpace.margin)
                    .padding(.bottom, TetherSpace.xl)
            }
            // A slow fade and a small lift — nothing bounces.
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 14)
            .animation(.easeOut(duration: 1.0), value: revealed)
        }
        .onAppear {
            TetherHaptics.success()
            revealed = true
        }
    }

    @ViewBuilder
    private func revealCard(label: String, entry: JournalEntry?) -> some View {
        if let entry {
            VStack(alignment: .leading, spacing: TetherSpace.xs) {
                HStack(spacing: TetherSpace.xs) {
                    Circle()
                        .fill(Mood.color(for: entry.mood))
                        .frame(width: 8, height: 8)
                    Text(label)
                        .font(TetherType.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Text(SecureContent.read(entry.body))
                    .font(TetherType.body)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(TetherSpace.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large,
                                        style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )
        }
    }
}
