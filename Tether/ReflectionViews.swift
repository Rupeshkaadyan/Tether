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
