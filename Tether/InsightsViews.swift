import SwiftUI
import SwiftData

// MARK: - Insights tab
//
// A look back, not a verdict. Everything here is computed locally from the
// journal already on device — no new data type, no sync, no accounts.

struct InsightsView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var ctx
    @Environment(\.dynamicTypeSize) private var typeSize

    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]

    @State private var window: Int = 30

    private var mine: [JournalEntry] { entries.filter { $0.userID == profile.id } }
    private var hasData: Bool { !mine.isEmpty }

    /// The last `window` calendar days, oldest first.
    private var windowDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<window)
            .compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
            .reversed()
    }

    private func avgMood(on day: Date) -> Double? {
        let dayMine = mine.filter { Calendar.current.isDate($0.entryDate, inSameDayAs: day) }
        guard !dayMine.isEmpty else { return nil }
        return Double(dayMine.map(\.mood).reduce(0, +)) / Double(dayMine.count)
    }

    /// One optional value per window day — the ribbon the chart draws.
    private var ribbon: [Double?] { windowDays.map { avgMood(on: $0) } }

    private var activeDays: Int { ribbon.compactMap { $0 }.count }
    private var totalEntries: Int { mine.count }

    private var avgMoodValue: Double? {
        let vals = ribbon.compactMap { $0 }
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0, +) / Double(vals.count)
    }

    private var streak: Int { Streaks.current(from: mine.map(\.entryDate)) }

    /// Mood 1..5 -> count, for the distribution bars.
    private var distribution: [Int: Int] {
        var d: [Int: Int] = [:]
        for e in mine { d[e.mood, default: 0] += 1 }
        return d
    }

    private var bestDay: (date: Date, value: Double, entry: JournalEntry)? {
        guard let scored = rankedDays(), let best = scored.max(by: { $0.value < $1.value }) else { return nil }
        return best
    }

    private var lowestDay: (date: Date, value: Double, entry: JournalEntry)? {
        guard let scored = rankedDays(), let low = scored.min(by: { $0.value < $1.value }) else { return nil }
        return low
    }

    /// Days that actually have an entry, with their average mood and a sample entry.
    private func rankedDays() -> [(date: Date, value: Double, entry: JournalEntry)]? {
        let grouped = Dictionary(grouping: mine) { Calendar.current.startOfDay(for: $0.entryDate) }
        let scored = grouped.compactMap { (day, dayEntries) -> (date: Date, value: Double, entry: JournalEntry)? in
            guard let avg = avgMood(on: day), let sample = dayEntries.first else { return nil }
            return (day, avg, sample)
        }
        return scored.isEmpty ? nil : scored
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.xl) {
                    if hasData {
                        header
                        rangeToggle
                        trendCard
                        statsRow
                        distributionCard
                        if let love = LoveLanguageStore.get(for: profile.id) { loveCard(love) }
                        highsAndLows
                    } else {
                        emptyState
                    }
                }
                .padding(TetherSpace.margin)
                .readableFrame()
            }
            .background { TetherBackdrop() }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: TetherSpace.xs) {
            Text("A look back")
                .font(TetherType.largeTitle)
                .foregroundStyle(TetherColor.ink)
            Text("How things have been going, drawn from your own journal.")
                .font(TetherType.callout)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, TetherSpace.s)
    }

    private var rangeToggle: some View {
        HStack(spacing: 0) {
            ForEach([7, 14, 30], id: \.self) { days in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { window = days }
                } label: {
                    Text(days == 7 ? "7 days" : days == 14 ? "14 days" : "30 days")
                        .font(TetherType.label)
                        .foregroundStyle(window == days ? .white : TetherColor.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, TetherSpace.s)
                        .background(window == days ? TetherColor.brand : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(TetherColor.surfaceSunken)
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small + 3))
    }

    // MARK: - Trend

    private var trendCard: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                HStack {
                    Text("Your mood over time")
                        .font(TetherType.label)
                    Spacer()
                    Text("\(window) days")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                }
                InsightsMoodChart(values: ribbon)
                HStack(spacing: TetherSpace.s) {
                    Text("Higher is better")
                        .font(TetherType.micro)
                        .foregroundStyle(TetherColor.faint)
                    Spacer()
                    Text("1 Strained → 5 Thriving")
                        .font(TetherType.micro)
                        .foregroundStyle(TetherColor.faint)
                }
            }
        }
        .tetherAppear(delay: 0.1)
    }

    // MARK: - Stats

    private var statsRow: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: TetherSpace.m),
                            GridItem(.flexible(), spacing: TetherSpace.m)],
                  spacing: TetherSpace.m) {
            InsightsStatTile(value: "\(streak)", label: "day streak", icon: .streak)
            InsightsStatTile(value: "\(activeDays)", label: "active days", icon: .calendar)
            InsightsStatTile(value: "\(totalEntries)", label: "entries", icon: .journal)
            InsightsStatTile(value: avgMoodValue.map { String(format: "%.1f", $0) } ?? "—",
                             label: "avg mood", icon: .pulse)
        }
    }

    // MARK: - Distribution

    private var distributionCard: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                Text("Mood mix")
                    .font(TetherType.label)
                let maxCount = max(distribution.values.max() ?? 1, 1)
                VStack(spacing: TetherSpace.s) {
                    ForEach(1...5, id: \.self) { lvl in
                        HStack(spacing: TetherSpace.s) {
                            Text(Mood.label(for: lvl))
                                .font(TetherType.caption)
                                .foregroundStyle(TetherColor.muted)
                                .frame(width: 62, alignment: .leading)
                            GeometryReader { geo in
                                let count = distribution[lvl] ?? 0
                                ZStack(alignment: .leading) {
                                    Capsule().fill(TetherColor.border)
                                    Capsule()
                                        .fill(Mood.color(for: lvl))
                                        .frame(width: count > 0
                                               ? max(geo.size.width * CGFloat(count) / CGFloat(maxCount), 6)
                                               : 0)
                                }
                            }
                            .frame(height: 8)
                            Text("\(distribution[lvl] ?? 0)")
                                .font(TetherType.micro)
                                .foregroundStyle(TetherColor.faint)
                                .frame(width: 26, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .tetherAppear(delay: 0.2)
    }

    // MARK: - Love language

    private func loveCard(_ love: LoveLanguage) -> some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                HStack(spacing: TetherSpace.s) {
                    Image(systemName: love.symbol)
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(TetherColor.brand)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your love language")
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                        Text(love.displayName)
                            .font(TetherType.label)
                            .foregroundStyle(TetherColor.text)
                    }
                }
                Text(loveIdea(for: love))
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tetherAppear(delay: 0.3)
    }

    private func loveIdea(for love: LoveLanguage) -> String {
        switch love {
        case .words:
            return "This week, leave one unexpected note — a midday text, a line on the mirror — naming something you appreciate about them."
        case .acts:
            return "Pick one small thing they mentioned and just do it before they ask. For you two, action lands louder than words."
        case .gifts:
            return "A tiny, thoughtful something — their favourite snack, a single flower — shows you were thinking of them. The thought, not the price."
        case .time:
            return "Protect one device-free block together this week. Undivided attention is the gift that matters most to you."
        case .touch:
            return "A hug that lasts a few seconds longer, a hand on the shoulder while you talk — small contact that says you are here."
        }
    }

    // MARK: - Highs and lows

    private var highsAndLows: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            Text("Highs and lows")
                .font(TetherType.label)
            if let best = bestDay {
                highlightRow(title: "Your brightest day",
                             color: TetherColor.thriving,
                             date: best.date,
                             text: SecureContent.read(best.entry.body))
            }
            if let low = lowestDay, low.date != bestDay?.date {
                highlightRow(title: "A heavier day",
                             color: TetherColor.strained,
                             date: low.date,
                             text: SecureContent.read(low.entry.body))
            }
        }
        .tetherAppear(delay: 0.35)
    }

    private func highlightRow(title: String, color: Color, date: Date, text: String) -> some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                HStack(spacing: TetherSpace.s) {
                    Circle().fill(color).frame(width: 9, height: 9)
                    Text(title)
                        .font(TetherType.label)
                        .foregroundStyle(TetherColor.text)
                    Spacer()
                    Text(date.shortDisplay)
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                }
                Text(text)
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: TetherSpace.l) {
            Spacer(minLength: TetherSpace.xl)
            ZStack {
                Circle()
                    .fill(TetherGradient.dawn)
                    .frame(width: 100, height: 100)
                IconDisc(icon: .pulse, size: 54, color: TetherColor.brand)
            }
            Text("Your insights start with one entry")
                .font(TetherType.title)
                .foregroundStyle(TetherColor.ink)
            Text("Answer today's prompt on the home screen. After a few days, this page fills in with your mood over time, your streak, and the moments worth remembering.")
                .font(TetherType.callout)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: TetherSpace.xl)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, TetherSpace.xl)
    }
}

// MARK: - Chart

/// Drawn with SwiftUI `Canvas` — a single drawing closure rather than a deep
/// nest of `@ViewBuilder` Path/ForEach expressions, which keeps the compiler from
/// choking on the expression when the data set is large.
struct InsightsMoodChart: View {
    let values: [Double?]        // each 1...5, or nil for a day with no entry
    let height: CGFloat = 200

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let top: CGFloat = 12
            let bottom: CGFloat = 12
            let plotH = h - top - bottom
            let n = values.count
            let stepX: CGFloat = n > 1 ? w / CGFloat(n - 1) : 0

            func x(at i: Int) -> CGFloat { n > 1 ? CGFloat(i) * stepX : w / 2 }
            func y(for v: Double) -> CGFloat {
                let c = min(max(v, 1), 5)
                return top + plotH * (1 - (c - 1) / 4)
            }

            // Reference lines for each mood level.
            for lvl in 1...5 {
                let yy = y(for: Double(lvl))
                var grid = Path()
                grid.move(to: CGPoint(x: 0, y: yy))
                grid.addLine(to: CGPoint(x: w, y: yy))
                context.stroke(grid, with: .color(TetherColor.border),
                               style: StrokeStyle(lineWidth: 1, dash: lvl == 3 ? [] : [3, 4]))
            }

            let points: [(Int, CGPoint)] = values.enumerated().compactMap { i, v in
                guard let vv = v else { return nil }
                return (i, CGPoint(x: x(at: i), y: y(for: vv)))
            }
            guard !points.isEmpty else { return }

            if points.count >= 2 {
                var line = Path()
                line.move(to: points[0].1)
                for pt in points.dropFirst() { line.addLine(to: pt.1) }

                var area = Path()
                area.move(to: points[0].1)
                for pt in points.dropFirst() { area.addLine(to: pt.1) }
                area.addLine(to: CGPoint(x: points.last!.1.x, y: top + plotH))
                area.addLine(to: CGPoint(x: points[0].1.x, y: top + plotH))
                area.closeSubpath()

                let gradient = Gradient(colors: [TetherColor.brand.opacity(0.30),
                                                 TetherColor.brand.opacity(0.02)])
                let shading = GraphicsContext.Shading.linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 0, y: top),
                    endPoint: CGPoint(x: 0, y: top + plotH)
                )
                context.fill(area, with: shading)

                let style = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                context.stroke(line, with: .color(TetherColor.brand), style: style)

                for pt in points {
                    context.fill(Circle().path(in: CGRect(x: pt.1.x - 3, y: pt.1.y - 3,
                                                          width: 6, height: 6)),
                                 with: .color(TetherColor.brand))
                }
            } else if let pt = points.first {
                context.fill(Circle().path(in: CGRect(x: pt.1.x - 4.5, y: pt.1.y - 4.5,
                                                      width: 9, height: 9)),
                             with: .color(TetherColor.brand))
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mood trend over \(values.count) days")
        .accessibilityValue("\(values.compactMap { $0 }.count) day\(values.compactMap { $0 }.count == 1 ? "" : "s") logged")
        .overlay(
            Group {
                if values.compactMap({ $0 }).isEmpty {
                    Text("Log a few days to see your trend")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.faint)
                }
            }
        )
    }
}

// MARK: - Stat tile

struct InsightsStatTile: View {
    let value: String
    let label: String
    let icon: TetherIcon

    var body: some View {
        VStack(alignment: .leading, spacing: TetherSpace.xs) {
            IconDisc(icon: icon, size: 34, color: TetherColor.brand)
                .padding(.bottom, TetherSpace.xs)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(TetherColor.ink)
            Text(label)
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(TetherSpace.m)
        .background(TetherColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium))
        .tetherShadow(.soft)
    }
}
