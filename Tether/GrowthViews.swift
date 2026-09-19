import SwiftUI
import SwiftData

// MARK: - Milestones

/// A small, earned proof that someone keeps showing up. Deliberately cumulative
/// rather than competitive — there is no "behind" here, only "not yet".
struct Milestone: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let tint: Color
    let current: Int
    let goal: Int

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(current) / Double(goal))
    }

    var isEarned: Bool { goal > 0 && current >= goal }
}

enum Milestones {
    /// Computed from on-device data only — nothing here needs a backend.
    static func compute(profile: UserProfile,
                        entries: [JournalEntry],
                        replies: [PromptReply],
                        isPaired: Bool) -> [Milestone] {
        let mine = entries.filter { $0.userID == profile.id }
        let myReplies = replies.filter { $0.userID == profile.id }
        let reflections = mine.count + myReplies.count
        let streak = Streaks.current(from: mine.map(\.entryDate) + myReplies.map(\.forDate))

        var out: [Milestone] = [
            Milestone(id: "first",
                      title: "First note",
                      detail: "You wrote something down. That is the whole beginning.",
                      symbol: "leaf.fill",
                      tint: TetherColor.thriving,
                      current: reflections, goal: 1),
            Milestone(id: "ten",
                      title: "Ten reflections",
                      detail: "Ten moments you chose to notice.",
                      symbol: "sparkles",
                      tint: TetherColor.brand,
                      current: reflections, goal: 10),
            Milestone(id: "fifty",
                      title: "Fifty moments",
                      detail: "A real record of a real relationship.",
                      symbol: "books.vertical.fill",
                      tint: TetherColor.brand,
                      current: reflections, goal: 50),
            Milestone(id: "streak3",
                      title: "Three in a row",
                      detail: "Three days of showing up.",
                      symbol: "flame.fill",
                      tint: TetherColor.thriving,
                      current: streak, goal: 3),
            Milestone(id: "streak7",
                      title: "One week strong",
                      detail: "A full week of one minute a day.",
                      symbol: "flame.fill",
                      tint: TetherColor.thriving,
                      current: streak, goal: 7),
            Milestone(id: "streak30",
                      title: "A month of showing up",
                      detail: "Thirty days. This is a habit now.",
                      symbol: "flame.fill",
                      tint: TetherColor.thriving,
                      current: streak, goal: 30)
        ]

        // Anniversaries only appear once two people are actually connected.
        if isPaired, let pairedAt = profile.pairedAt {
            let days = Calendar.current.dateComponents([.day], from: pairedAt, to: Date()).day ?? 0
            out.append(Milestone(id: "paired",
                                 title: "Connected",
                                 detail: "You are in this together now.",
                                 symbol: "link",
                                 tint: TetherColor.brand,
                                 current: 1, goal: 1))
            out.append(Milestone(id: "monthTogether",
                                 title: "One month together",
                                 detail: "Thirty days since you connected.",
                                 symbol: "calendar",
                                 tint: TetherColor.brand,
                                 current: days, goal: 30))
            out.append(Milestone(id: "yearTogether",
                                 title: "One year together",
                                 detail: "A year of choosing each other on purpose.",
                                 symbol: "calendar",
                                 tint: TetherColor.brand,
                                 current: days, goal: 365))
        }

        return out
    }
}

// MARK: - 7-day challenge

struct ChallengeDay: Identifiable {
    let id: Int
    let title: String
    let action: String
}

/// Seven small, concrete things to do together. Written to be comfortable for
/// any couple in any tradition — no assumptions about how affection is shown.
enum ChallengeLibrary {
    static let days: [ChallengeDay] = [
        ChallengeDay(id: 1, title: "Notice one thing",
                     action: "Tell your partner one specific thing you noticed about them today."),
        ChallengeDay(id: 2, title: "Ask a real question",
                     action: "Ask something you do not already know the answer to. Then just listen."),
        ChallengeDay(id: 3, title: "Twenty undivided minutes",
                     action: "Put the phones away and sit together for twenty minutes."),
        ChallengeDay(id: 4, title: "One small thing, unasked",
                     action: "Do one small chore for them without being asked and without mentioning it."),
        ChallengeDay(id: 5, title: "Remember out loud",
                     action: "Bring up one good memory you shared and describe it to them."),
        ChallengeDay(id: 6, title: "Ask what was hard",
                     action: "Ask what made today difficult. Listen without trying to fix it."),
        ChallengeDay(id: 7, title: "Plan something to look forward to",
                     action: "Pick one thing, however small, to do together next week.")
    ]
}

/// Persisted in UserDefaults rather than SwiftData: this is personal progress
/// state, not relationship data, so it stays out of the synced store.
@Observable
final class ChallengeStore {
    static let shared = ChallengeStore()

    private let daysKey = "tether.challenge.days"
    private let startKey = "tether.challenge.start"

    var completed: Set<Int> = []
    var startDate: Date?

    init() {
        let saved = UserDefaults.standard.array(forKey: daysKey) as? [Int] ?? []
        completed = Set(saved)
        let ts = UserDefaults.standard.double(forKey: startKey)
        startDate = ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }

    var doneCount: Int { completed.count }
    var isComplete: Bool { completed.count >= ChallengeLibrary.days.count }
    var progressFraction: Double {
        Double(completed.count) / Double(ChallengeLibrary.days.count)
    }

    /// The first day not yet ticked — what "today" means in the challenge.
    var nextDay: ChallengeDay? {
        ChallengeLibrary.days.first { !completed.contains($0.id) }
    }

    func startIfNeeded() {
        guard startDate == nil else { return }
        startDate = Date()
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: startKey)
    }

    func toggle(_ day: Int) {
        if completed.contains(day) {
            completed.remove(day)
            TetherHaptics.tap()
        } else {
            completed.insert(day)
            TetherHaptics.success()
        }
        UserDefaults.standard.set(Array(completed), forKey: daysKey)
    }

    func reset() {
        completed = []
        startDate = nil
        UserDefaults.standard.removeObject(forKey: daysKey)
        UserDefaults.standard.removeObject(forKey: startKey)
    }
}

// MARK: - Grow screen

struct GrowView: View {
    @Bindable var profile: UserProfile
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \PromptReply.createdAt, order: .reverse) private var replies: [PromptReply]
    @Query private var allProfiles: [UserProfile]

    @State private var store = ChallengeStore.shared

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return allProfiles.first { $0.id == id }
    }

    private var milestones: [Milestone] {
        Milestones.compute(profile: profile,
                           entries: entries,
                           replies: replies,
                           isPaired: partner != nil)
    }

    /// Computed on-device from this week's entries — never sent anywhere.
    private var reflection: WeeklyReflection {
        WeeklyReflectionEngine.compute(entries: entries,
                                       replies: replies,
                                       userID: profile.id)
    }

    @State private var deeperReflection: String?
    @State private var deeperNote: String?
    @State private var isLoadingDeeper = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.l) {
                    growBanner
                    weekCard
                        .tetherAppear(delay: 0.03)
                    challengeCard
                        .tetherAppear(delay: 0.05)
                    challengeDays
                        .tetherAppear(delay: 0.12)
                    milestonesSection
                        .tetherAppear(delay: 0.2)
                    insightsLink
                        .tetherAppear(delay: 0.26)
                }
                .padding(TetherSpace.margin)
                .readableFrame()
                .padding(.bottom, TetherSpace.xl)
            }
            .background { TetherBackdrop() }
            .navigationTitle("Grow")
        }
        .onAppear { store.startIfNeeded() }
    }

    // MARK: Weekly reflection

    private var weekCard: some View {
        TetherCard {
            ZStack(alignment: .topTrailing) {
                // A soft wash behind the words — depth without noise.
                Circle()
                    .fill(TetherColor.brand.opacity(0.14))
                    .frame(width: 140, height: 140)
                    .blur(radius: 34)
                    .offset(x: 48, y: -44)
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: TetherSpace.m) {
                    HStack(spacing: TetherSpace.s) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 16))
                            .foregroundStyle(TetherColor.brand)
                        Text("This week")
                            .font(TetherType.label)
                            .foregroundStyle(TetherColor.ink)
                        Spacer(minLength: 0)
                    }

                    Text(deeperReflection ?? reflection.summary)
                        .font(TetherType.callout)
                        .foregroundStyle(TetherColor.text)
                        .fixedSize(horizontal: false, vertical: true)

                    if let deeperNote {
                        Text(deeperNote)
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if ReflectionSettings.sharesAnonymizedSummary {
                        Button {
                            Task { await loadDeeperReflection() }
                        } label: {
                            HStack(spacing: TetherSpace.xs) {
                                if isLoadingDeeper { ProgressView() }
                                Text(isLoadingDeeper ? "Reflecting…" : "Deeper reflection")
                                    .font(TetherType.caption)
                            }
                        }
                        .disabled(isLoadingDeeper)
                    }
                }
            }
        }
    }

    @MainActor
    private func loadDeeperReflection() async {
        isLoadingDeeper = true
        defer { isLoadingDeeper = false }
        let result = await RemoteReflectionProvider.deeperReflection(for: reflection,
                                                                    track: profile.trackRaw)
        if let result {
            deeperReflection = result
            deeperNote = nil
        } else {
            deeperNote = "Deeper reflections need a server connection. Showing your on-device summary."
        }
    }

    // MARK: Challenge

    private var challengeCard: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                HStack(alignment: .top, spacing: TetherSpace.m) {
                    VStack(alignment: .leading, spacing: TetherSpace.xs) {
                        Text("7-day connection challenge")
                            .font(TetherType.label)
                            .foregroundStyle(TetherColor.ink)
                        Text("\(store.doneCount) of \(ChallengeLibrary.days.count) done")
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                    }
                    Spacer(minLength: 0)
                    progressRing
                }

                if let next = store.nextDay {
                    VStack(alignment: .leading, spacing: TetherSpace.xs) {
                        Text("Today — \(next.title)")
                            .font(TetherType.callout)
                            .foregroundStyle(TetherColor.text)
                        Text(next.action)
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(TetherSpace.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TetherColor.brandSoft)
                    .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium,
                                                style: .continuous))
                } else {
                    Text("All seven done. Start again whenever you like.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                }
            }
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(TetherColor.border, lineWidth: 6)
            Circle()
                .trim(from: 0, to: store.progressFraction)
                .stroke(TetherColor.brand,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8),
                           value: store.progressFraction)
            Text("\(store.doneCount)")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.text)
        }
        .frame(width: 54, height: 54)
    }

    private var challengeDays: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                Text("The seven days")
                    .font(TetherType.label)
                    .foregroundStyle(TetherColor.ink)

                ForEach(ChallengeLibrary.days) { day in
                    let done = store.completed.contains(day.id)
                    Button { store.toggle(day.id) } label: {
                        HStack(alignment: .top, spacing: TetherSpace.m) {
                            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(done ? TetherColor.brand : TetherColor.faint)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Day \(day.id) — \(day.title)")
                                    .font(TetherType.callout)
                                    .foregroundStyle(TetherColor.text)
                                Text(day.action)
                                    .font(TetherType.caption)
                                    .foregroundStyle(TetherColor.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .strikethrough(done, color: TetherColor.muted)
                    .accessibilityLabel("Day \(day.id), \(day.title)")
                    .accessibilityValue(done ? "Done" : "Not done")
                }

                if store.isComplete {
                    Button("Start again") { store.reset() }
                        .tetherButton(.tertiary)
                        .padding(.top, TetherSpace.xs)
                }
            }
        }
    }

    // MARK: Insights link

    /// Insights stopped being a tab so the bar could stay at five. It is one
    /// tap from here instead.
    private var insightsLink: some View {
        NavigationLink {
            InsightsView(profile: profile)
        } label: {
            HStack(spacing: TetherSpace.m) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16))
                    .foregroundStyle(TetherColor.brand)
                Text("See your insights")
                    .font(TetherType.label)
                    .foregroundStyle(TetherColor.ink)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TetherColor.faint)
            }
            .padding(TetherSpace.l)
            .background(TetherColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous)
                    .strokeBorder(TetherColor.border, lineWidth: 1)
            )
            .tetherShadow(.soft)
        }
        .buttonStyle(.plain)
    }

    // MARK: Milestones

    /// A night sky that fills with stars as milestones are earned — so the
    /// practice looks like it is accumulating rather than merely being counted.
    private var growBanner: some View {
        let earned = milestones.filter { $0.progress >= 1 }.count

        return ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [Color(hex: "141126"),
                                    Color(hex: "2A2350"),
                                    Color(hex: "4A3A78")],
                           startPoint: .top,
                           endPoint: .bottom)

            Stars(count: 10 + earned * 5)

            Ridge(peaks: [0.34, 0.50, 0.36, 0.54, 0.40], crest: 0.84)
                .fill(Color(hex: "1C1738"))
                .frame(height: 230)

            VStack(alignment: .leading, spacing: 2) {
                Text("Your practice".uppercased())
                    .font(TetherType.micro)
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.75))
                Text("\(earned) of \(milestones.count) milestones")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(-0.6)
                    .foregroundStyle(.white)
                Text(earned == 0 ? "Your sky fills with the first one."
                                 : "Each one lights another star.")
                    .font(TetherType.caption)
                    .foregroundStyle(.white.opacity(0.80))
            }
            .padding(.horizontal, TetherSpace.margin)
            .padding(.bottom, TetherSpace.l)
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous))
        .padding(.horizontal, -TetherSpace.margin)
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            Text("Milestones")
                .font(TetherType.title)
                .foregroundStyle(TetherColor.ink)
            Text("Small proofs that you keep showing up.")
                .font(TetherType.callout)
                .foregroundStyle(TetherColor.muted)

            ForEach(milestones) { milestone in
                TetherCard {
                    HStack(alignment: .top, spacing: TetherSpace.m) {
                        ZStack {
                            Circle()
                                .fill(milestone.isEarned
                                      ? milestone.tint.opacity(0.16)
                                      : TetherColor.border.opacity(0.6))
                                .frame(width: 36, height: 36)
                            Image(systemName: milestone.symbol)
                                .font(.system(size: 15))
                                .foregroundStyle(milestone.isEarned
                                                 ? milestone.tint
                                                 : TetherColor.faint)
                        }
                        .frame(width: 36)
                        VStack(alignment: .leading, spacing: TetherSpace.xs) {
                            HStack {
                                Text(milestone.title)
                                    .font(TetherType.label)
                                    .foregroundStyle(TetherColor.ink)
                                Spacer()
                                Text(milestone.isEarned
                                     ? "Earned"
                                     : "\(milestone.current)/\(milestone.goal)")
                                    .font(TetherType.caption)
                                    .foregroundStyle(milestone.isEarned
                                                     ? TetherColor.thriving
                                                     : TetherColor.muted)
                            }
                            Text(milestone.detail)
                                .font(TetherType.caption)
                                .foregroundStyle(TetherColor.muted)
                                .fixedSize(horizontal: false, vertical: true)
                            if !milestone.isEarned {
                                ProgressView(value: milestone.progress)
                                    .tint(milestone.tint)
                            }
                        }
                    }
                }
            }
        }
    }
}
