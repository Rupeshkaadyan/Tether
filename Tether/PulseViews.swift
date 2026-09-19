import SwiftUI
import SwiftData

// MARK: - Engine

struct PulseResult {
    let state: PulseState
    let score: Double
    let trend: PulseTrend
    let cadence: Double
    let mood: Double
    let consistency: Double
    let daysOfData: Int
}

/// Describes, never predicts. The Pulse reports what has happened; it does not
/// forecast the relationship. That distinction is deliberate and should hold
/// for v1 — see PRD open questions.
enum PulseEngine {

    static func compute(entries: [JournalEntry], ownerID: UUID) -> PulseResult {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let mine = entries.filter { $0.userID == ownerID }

        func daysAgo(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: today) ?? today
        }

        let last7 = mine.filter { $0.entryDate >= daysAgo(6) }
        let prev7 = mine.filter { $0.entryDate >= daysAgo(13) && $0.entryDate < daysAgo(6) }

        let activeDays = Set(last7.map { cal.startOfDay(for: $0.entryDate) }).count
        let cadence = min(Double(last7.count) / 7.0, 1.0)
        let consistency = min(Double(activeDays) / 7.0, 1.0)

        let moodsLast7 = last7.map { Double($0.mood) }
        let moodScore: Double = moodsLast7.isEmpty
            ? 0
            : min(max(((moodsLast7.reduce(0, +) / Double(moodsLast7.count)) - 1) / 4, 0), 1)

        let score = (moodScore * 0.40) + (cadence * 0.35) + (consistency * 0.25)

        let state: PulseState
        if activeDays < 3 {
            state = .unknown
        } else if score >= 0.68 {
            state = .thriving
        } else if score >= 0.40 {
            state = .drifting
        } else {
            state = .strained
        }

        let prevMoods = prev7.map { Double($0.mood) }
        var trend: PulseTrend = .unknown
        if !moodsLast7.isEmpty && !prevMoods.isEmpty {
            let delta = (moodsLast7.reduce(0, +) / Double(moodsLast7.count))
                      - (prevMoods.reduce(0, +) / Double(prevMoods.count))
            trend = delta > 0.3 ? .rising : (delta < -0.3 ? .falling : .steady)
        } else if !moodsLast7.isEmpty {
            trend = .steady
        }

        return PulseResult(state: state, score: score, trend: trend,
                           cadence: cadence, mood: moodScore,
                           consistency: consistency, daysOfData: activeDays)
    }

    static func focusSuggestion(for result: PulseResult) -> String {
        let weakest = min(result.cadence, min(result.mood, result.consistency))
        if result.daysOfData < 3 {
            return "Keep showing up for a few more days. There is not enough here to read yet."
        }
        if weakest == result.mood {
            return "Your mood has been low. Try naming one concrete thing that would help this week."
        }
        if weakest == result.cadence {
            return "You have been showing up less. Even one line a day keeps the thread."
        }
        return "You are consistent but the mood is flat. Try one prompt that asks something harder."
    }
}

// MARK: - Home card

struct PulseCard: View {
    let result: PulseResult
    let onTap: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: onTap) {
            TetherCard {
                if typeSize.isAccessibility {
                    // Stacked, because the horizontal row hyphenates labels
                    // mid-word at accessibility sizes.
                    VStack(alignment: .leading, spacing: TetherSpace.m) {
                        HStack(spacing: TetherSpace.m) {
                            IconDisc(icon: result.state.icon, size: 40, color: result.state.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Relationship Pulse")
                                    .font(TetherType.caption)
                                    .foregroundStyle(TetherColor.muted)
                                Text(result.state.displayName)
                                    .font(TetherType.label)
                                    .foregroundStyle(TetherColor.text)
                            }
                        }
                        HStack(spacing: TetherSpace.xs) {
                            Icon(TetherIcon.forTrend(result.trend), size: 13, color: TetherColor.muted)
                            Text(result.trend.displayName)
                                .font(TetherType.caption)
                                .foregroundStyle(TetherColor.muted)
                            Spacer()
                            Icon(.chevronRight, size: 15, color: TetherColor.faint)
                        }
                    }
                } else {
                    HStack(spacing: TetherSpace.m) {
                        IconDisc(icon: result.state.icon, size: 40, color: result.state.color)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Relationship Pulse")
                                .font(TetherType.caption)
                                .foregroundStyle(TetherColor.muted)
                            Text(result.state.displayName)
                                .font(TetherType.label)
                                .foregroundStyle(TetherColor.text)
                        }

                        Spacer(minLength: TetherSpace.s)

                        HStack(spacing: TetherSpace.xs) {
                            Icon(TetherIcon.forTrend(result.trend), size: 13, color: TetherColor.muted)
                            Text(result.trend.displayName)
                                .font(TetherType.caption)
                                .foregroundStyle(TetherColor.muted)
                        }
                        .layoutPriority(1)

                        Icon(.chevronRight, size: 15, color: TetherColor.faint)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Relationship Pulse. \(result.state.displayName). \(result.trend.displayName).")
    }
}

// MARK: - Detail

struct PulseView: View {
    @Bindable var profile: UserProfile
    /// When true the view is hosted in the tab bar — no Done button, large title.
    var isTab: Bool = false

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    private var result: PulseResult {
        PulseEngine.compute(entries: entries, ownerID: profile.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.xl) {
                    pulseBanner
                    hero
                    explanation
                    disclaimer
                }
                .padding(TetherSpace.margin)
                .readableFrame()
            }
            .background { TetherBackdrop() }
            .navigationTitle("Relationship Pulse")
            .navigationBarTitleDisplayMode(isTab ? .large : .inline)
            .toolbar {
                if !isTab {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }

    /// Lead with the state, then the three restrained stats. Describes, never
    /// predicts — the brief is "human, not dashboard".
    /// The relationship as a landscape — the sun rises when things are
    /// thriving and sinks toward the ridge when they are strained.
    private var pulseBanner: some View {
        ZStack(alignment: .bottomLeading) {
            PulseHorizon(state: result.state, score: result.score)

            LinearGradient(colors: [.clear, .black.opacity(0.30)],
                           startPoint: .center,
                           endPoint: .bottom)

            VStack(alignment: .leading, spacing: 2) {
                Text("Relationship pulse".uppercased())
                    .font(TetherType.micro)
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.78))
                Text(result.state.displayName)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                Text(stateDescription)
                    .font(TetherType.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, TetherSpace.margin)
            .padding(.bottom, TetherSpace.l)
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous))
        .padding(.horizontal, -TetherSpace.margin)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: TetherSpace.l) {
            TetherPulseViz(state: result.state)
                .frame(height: 80)
                .padding(.vertical, TetherSpace.xs)

            HStack(alignment: .top, spacing: 0) {
                statColumn("Avg Mood", value: avgMoodText, color: result.state.color)
                verticalDivider
                statColumn("Consistency",
                          value: "\(Int(result.consistency * 100))%",
                          color: result.state.color)
                verticalDivider
                statColumn("Active Days", value: "\(result.daysOfData)", color: result.state.color)
            }
        }
        .padding(TetherSpace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TetherColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous)
                .strokeBorder(TetherColor.border, lineWidth: 1)
        )
        .tetherShadow(.soft)
    }

    private var stateDescription: String {
        switch result.state {
        case .thriving: return "You're showing up, staying connected, and building something meaningful."
        case .drifting: return "You've been a little quiet. No judgement — re-entry is welcome."
        case .strained: return "Things feel heavy. A small check-in can make a difference."
        case .unknown:  return "A few more days of writing and your picture will come into focus."
        }
    }

    /// Average mood on the 1–5 scale across the last two weeks of entries.
    private var avgMoodText: String {
        let mine = entries.filter { $0.userID == profile.id }
        guard !mine.isEmpty else { return "—" }
        let recent = mine.suffix(14)
        let avg = Double(recent.map(\.mood).reduce(0, +)) / Double(recent.count)
        return String(format: "%.1f", avg)
    }

    private func statColumn(_ label: String, value: String, color: Color) -> some View {
        VStack(alignment: .center, spacing: TetherSpace.xs) {
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(TetherColor.ink)
            Text(label.uppercased())
                .font(TetherType.micro)
                .foregroundStyle(TetherColor.muted)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(TetherColor.border)
            .frame(width: 1, height: 36)
            .padding(.horizontal, TetherSpace.s)
    }

    private var explanation: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                Text("What this is")
                    .font(TetherType.label)
                Text("A read on the last two weeks, not a verdict. It looks at three things: how you have been feeling, how often you showed up, and how steady it has been.")
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Text(PulseEngine.focusSuggestion(for: result))
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, TetherSpace.xs)
            }
        }
    }

    private var disclaimer: some View {
        Text("Tether is not therapy. If things feel unsafe or overwhelming, please talk to someone qualified.")
            .font(TetherType.caption)
            .foregroundStyle(TetherColor.muted)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Pulse visualization

/// A slack Tether curve with three dots, tinted by the pulse state. The
/// line is the trend; the dots are the signals that compose it.
private struct TetherPulseViz: View {
    let state: PulseState

    var body: some View {
        ZStack {
            TetherSlackCurve(sag: 22)
                .stroke(state.color.opacity(0.45),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .padding(.horizontal, 6)

            HStack(alignment: .top) {
                Circle()
                    .fill(state.color)
                    .frame(width: 12, height: 12)
                    .shadow(color: state.color.opacity(0.4), radius: 5, y: 2)
                Spacer(minLength: 0)
                Circle()
                    .fill(state.color)
                    .frame(width: 12, height: 12)
                    .shadow(color: state.color.opacity(0.4), radius: 5, y: 2)
                Spacer(minLength: 0)
                Circle()
                    .fill(state.color)
                    .frame(width: 12, height: 12)
                    .shadow(color: state.color.opacity(0.4), radius: 5, y: 2)
            }
            .padding(.horizontal, 6)
            .offset(y: -2)
        }
        .frame(height: 80)
        .accessibilityElement(children: .ignore)
    }
}

// MARK: - Weekly recap

struct WeeklyRecapView: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    private var mine: [JournalEntry] { entries.filter { $0.userID == profile.id } }

    private var thisWeek: [JournalEntry] {
        let start = Calendar.current.date(byAdding: .day, value: -6,
                                          to: Calendar.current.startOfDay(for: Date())) ?? Date()
        return mine.filter { $0.entryDate >= start }
    }

    private var streak: Int { Streaks.current(from: mine.map(\.entryDate)) }

    private var result: PulseResult {
        PulseEngine.compute(entries: entries, ownerID: profile.id)
    }

    private var highlight: JournalEntry? {
        thisWeek.max { $0.mood < $1.mood }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.l) {
                    Text("Your week together")
                        .font(TetherType.title)
                        .foregroundStyle(TetherColor.ink)
                        .padding(.top, TetherSpace.l)

                    HStack(spacing: TetherSpace.m) {
                        statCard("\(streak)", "day streak")
                        statCard("\(thisWeek.count)", "entries")
                        statCard(avgMoodLabel, "avg mood")
                    }

                    if let highlight {
                        TetherCard {
                            VStack(alignment: .leading, spacing: TetherSpace.s) {
                                Text("One to remember")
                                    .font(TetherType.label)
                                Text(SecureContent.read(highlight.body))
                                    .font(TetherType.callout)
                                    .foregroundStyle(TetherColor.text)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(highlight.entryDate.shortDisplay)
                                    .font(TetherType.caption)
                                    .foregroundStyle(TetherColor.muted)
                            }
                        }
                    }

                    TetherCard {
                        VStack(alignment: .leading, spacing: TetherSpace.s) {
                            Text("One focus for next week")
                                .font(TetherType.label)
                            Text(PulseEngine.focusSuggestion(for: result))
                                .font(TetherType.callout)
                                .foregroundStyle(TetherColor.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if thisWeek.isEmpty {
                        TetherCard {
                            Text("Nothing logged this week. No guilt — start again today.")
                                .font(TetherType.callout)
                                .foregroundStyle(TetherColor.muted)
                        }
                    }
                }
                .padding(TetherSpace.margin)
            }
            .background { TetherBackdrop() }
            .navigationTitle("Weekly recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var avgMoodLabel: String {
        guard !thisWeek.isEmpty else { return "—" }
        let avg = Double(thisWeek.map(\.mood).reduce(0, +)) / Double(thisWeek.count)
        return String(format: "%.1f", avg)
    }

    private func statCard(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: TetherSpace.xs) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(TetherColor.ink)
            Text(label)
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TetherSpace.m)
        .background(TetherColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium))
    }
}
