import Charts
import SwiftData
import SwiftUI

// MARK: - Mood over time
//
// Two lines, one for each of you, over the last thirty days.
//
// Deliberately not a "connection score". A single number would be a verdict,
// and this app does not grade anyone. Two lines show something truer and more
// useful: when you were close, when one of you dropped, and whether you came
// back up together.
//
// Days with no entry are gaps, not zeros. Plotting a missing day as zero would
// make an absence look like despair.

struct MoodPoint: Identifiable {
    let id = UUID()
    let day: Date
    let mood: Double
    let isMe: Bool
}

struct MoodGraphCard: View {
    let profile: UserProfile
    let partner: UserProfile?
    let entries: [JournalEntry]

    /// 1–5, matching the mood scale used everywhere else.
    private var points: [MoodPoint] {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recent = entries.filter { $0.entryDate >= cutoff }

        // Average per person per day, so three entries on a Tuesday do not
        // outweigh a single entry on Wednesday.
        func series(for userID: UUID, isMe: Bool) -> [MoodPoint] {
            let mine = recent.filter { $0.userID == userID }
            let grouped = Dictionary(grouping: mine) {
                cal.startOfDay(for: $0.entryDate)
            }
            return grouped.map { day, items in
                let avg = Double(items.map(\.mood).reduce(0, +)) / Double(items.count)
                return MoodPoint(day: day, mood: avg, isMe: isMe)
            }
            .sorted { $0.day < $1.day }
        }

        var out = series(for: profile.id, isMe: true)
        if let partner {
            out += series(for: partner.id, isMe: false)
        }
        return out
    }

    private var hasAny: Bool { !points.isEmpty }
    private var hasBoth: Bool {
        points.contains { $0.isMe } && points.contains { !$0.isMe }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            SectionHeader(title: "Mood, last 30 days")

            if hasAny {
                chart
                legend
            } else {
                TetherCard {
                    Text("Nothing to chart yet. A few days of entries and this fills in.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var chart: some View {
        TetherCard {
            Chart {
                ForEach(points) { p in
                    LineMark(
                        x: .value("Day", p.day),
                        y: .value("Mood", p.mood)
                    )
                    .foregroundStyle(by: .value("Who", p.isMe ? "You" : "Them"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                    PointMark(
                        x: .value("Day", p.day),
                        y: .value("Mood", p.mood)
                    )
                    .foregroundStyle(by: .value("Who", p.isMe ? "You" : "Them"))
                    .symbolSize(28)
                }
            }
            .chartForegroundStyleScale([
                "You": TetherColor.brand,
                "Them": TetherColor.rose
            ])
            .chartYScale(domain: 1...5)
            .chartYAxis {
                AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                    AxisGridLine().foregroundStyle(TetherColor.border)
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text(Mood.label(for: v))
                                .font(.system(size: 9))
                                .foregroundStyle(TetherColor.faint)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine().foregroundStyle(TetherColor.border.opacity(0.5))
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.system(size: 9))
                        .foregroundStyle(TetherColor.faint)
                }
            }
            .frame(height: 200)
            .accessibilityLabel("Mood over the last 30 days")
        }
    }

    private var legend: some View {
        HStack(spacing: TetherSpace.m) {
            legendDot(TetherColor.brand, "You")
            if hasBoth {
                legendDot(TetherColor.rose, partner?.displayName ?? "Them")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
        }
    }
}
