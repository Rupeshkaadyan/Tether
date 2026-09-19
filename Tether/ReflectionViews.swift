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

// MARK: - Memory echo

/// Surfaces something written a while back. This is the cure for an app that
/// feels empty today: it makes Tether feel like it has a past with you, rather
/// than being a form you fill in each morning.
struct MemoryEchoCard: View {
    let entry: JournalEntry
    let monthsBack: Int

    var body: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                HStack(spacing: TetherSpace.xs) {
                    TetherHeroMark(width: 26,
                                   color: TetherColor.brand.opacity(0.5),
                                   sag: 4,
                                   lineWidth: 1.5,
                                   dotRadius: 2)
                    Text(label)
                        .font(TetherType.micro)
                        .foregroundStyle(TetherColor.faint)
                        .tracking(1)
                    Spacer(minLength: 0)
                }

                Text(SecureContent.read(entry.body))
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)

                Text(entry.entryDate.formatted(date: .abbreviated, time: .omitted))
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label). \(SecureContent.read(entry.body))")
    }

    private var label: String {
        switch monthsBack {
        case 1:  return "ONE MONTH AGO"
        case 12: return "ONE YEAR AGO"
        default: return "\(monthsBack) MONTHS AGO"
        }
    }

    /// Finds an entry written in the window ending `monthsBack` months ago.
    static func find(in entries: [JournalEntry],
                     userID: UUID,
                     monthsBack: Int) -> JournalEntry? {
        let cal = Calendar.current
        let now = Date()
        guard let lower = cal.date(byAdding: .month, value: -(monthsBack + 1), to: now),
              let upper = cal.date(byAdding: .month, value: -monthsBack, to: now) else { return nil }
        return entries
            .filter { $0.userID == userID && $0.entryDate >= lower && $0.entryDate <= upper }
            .sorted { $0.entryDate > $1.entryDate }
            .first
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

    @Environment(\.modelContext) private var ctx
    @State private var revealed = false
    /// The one line they can send back. This is the point of the whole screen.
    @State private var replyText = ""
    @State private var replySent = false

    var body: some View {
        ZStack {
            TetherBackdrop(style: .dusk).ignoresSafeArea()

            // Two ridges rising from opposite sides and meeting in the middle.
            // The two of you, in one gesture.
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    Ridge(peaks: [0.66, 0.38, 0.18, 0.06], crest: 0.94)
                        .fill(Color.white.opacity(0.11))
                    Ridge(peaks: [0.06, 0.18, 0.38, 0.66], crest: 0.94)
                        .fill(Color.white.opacity(0.11))
                }
                .frame(height: 168)
                .opacity(revealed ? 1 : 0)
                .animation(.easeOut(duration: 1.6), value: revealed)
            }
            .ignoresSafeArea()

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

                    if let theirEntry = partnerEntry {
                        VStack(alignment: .leading, spacing: TetherSpace.s) {
                            revealCard(label: partnerName, entry: theirEntry)

                            // The reply: one line, only on shared entries.
                            if theirEntry.visibility == .shared {
                                if let existing = theirEntry.replyBody, !existing.isEmpty {
                                    HStack(alignment: .top, spacing: TetherSpace.xs) {
                                        Icon(.send, size: 13, color: .white.opacity(0.6))
                                        Text(existing)
                                            .font(TetherType.caption)
                                            .foregroundStyle(.white.opacity(0.85))
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(TetherSpace.m)
                                    .background(.white.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium,
                                                                style: .continuous))
                                } else {
                                    HStack(spacing: TetherSpace.s) {
                                        TextField("Say one thing back…", text: $replyText, axis: .vertical)
                                            .lineLimit(1...3)
                                            .font(TetherType.callout)
                                            .foregroundStyle(.white)
                                            .tint(.white)
                                        Button {
                                            sendReply(to: theirEntry)
                                        } label: {
                                            Icon(.send, size: 17,
                                                 color: replyText.trimmed.isEmpty ? .white.opacity(0.4) : .white)
                                        }
                                        .disabled(replyText.trimmed.isEmpty)
                                    }
                                    .padding(TetherSpace.m)
                                    .background(.white.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium,
                                                                style: .continuous))
                                }
                            }
                        }
                    }
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

    /// Saves the one-line reply onto THEIR shared entry. Never touches a
    /// private entry — the guard is the privacy promise.
    private func sendReply(to entry: JournalEntry) {
        let text = replyText.trimmed
        guard !text.isEmpty, entry.visibility == .shared else { return }
        entry.replyBody = text
        entry.replyBy = myEntry?.userID
        entry.replyAt = Date()
        try? ctx.save()
        replyText = ""
        replySent = true
        TetherHaptics.success()
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

// MARK: - Wisdom track detail

/// The person's own track as its own screen. Abstract glyph, colour and words
/// only — never a religious symbol.
struct WisdomTrackDetailView: View {
    let track: WisdomTrack
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.xl) {
                    header
                    TetherCard {
                        VStack(alignment: .leading, spacing: TetherSpace.s) {
                            Text("This is yours alone")
                                .font(TetherType.label)
                                .foregroundStyle(TetherColor.ink)
                            Text("Your partner chooses their own path. The relationship is shared; the worldview is personal.")
                                .font(TetherType.callout)
                                .foregroundStyle(TetherColor.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    promptNote
                }
                .padding(TetherSpace.margin)
                .readableFrame()
            }
            .background { TetherBackdrop() }
            .navigationTitle("Wisdom track")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            ZStack {
                Circle()
                    .fill(track.accent.opacity(0.12))
                    .frame(width: 96, height: 96)
                Icon(track.icon, size: 42, color: track.accent)
            }
            Text(track.displayName)
                .font(TetherType.largeTitle)
                .foregroundStyle(TetherColor.ink)
            Text(track.blurb)
                .font(TetherType.callout)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, TetherSpace.s)
    }

    private var promptNote: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            Text("Prompts in this track")
                .font(TetherType.title)
                .foregroundStyle(TetherColor.ink)
            Text("\(PromptLibrary.prompts(for: track).count) questions, written to be answered honestly in one sentence.")
                .font(TetherType.callout)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Private chat

/// A private conversation between the two of you. Separate from the journal:
/// the journal is a practice with a shape, this is just talking. Local and
/// offline like everything else.
struct PrivateChatView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ChatMessage.createdAt, order: .forward) private var messages: [ChatMessage]
    @Query private var profiles: [UserProfile]

    @State private var draft = ""

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return profiles.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if messages.isEmpty {
                    TetherEmptyState(
                        title: "Just the two of you",
                        message: "Nothing here yet. Say anything — this is your private conversation."
                    )
                } else {
                    thread
                }
                composer
            }
            .background { TetherBackdrop() }
            .navigationTitle(partner?.displayName ?? "Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var thread: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: TetherSpace.s) {
                    ForEach(messages) { message in
                        bubble(message).id(message.id)
                    }
                }
                .padding(.horizontal, TetherSpace.margin)
                .padding(.vertical, TetherSpace.m)
                .readableFrame()
            }
            .onChange(of: messages.count) { _, _ in
                guard let last = messages.last else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        let mine = message.senderID == profile.id
        return HStack {
            if mine { Spacer(minLength: 48) }
            VStack(alignment: mine ? .trailing : .leading, spacing: 2) {
                Text(message.body)
                    .font(TetherType.callout)
                    .foregroundStyle(mine ? Color.white : TetherColor.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(TetherType.micro)
                    .foregroundStyle(mine ? Color.white.opacity(0.7) : TetherColor.faint)
            }
            .padding(.horizontal, TetherSpace.m)
            .padding(.vertical, TetherSpace.s)
            .background(mine ? AnyShapeStyle(TetherGradient.brand)
                             : AnyShapeStyle(TetherColor.surface))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(mine ? Color.clear : TetherColor.border, lineWidth: 1)
            )
            if !mine { Spacer(minLength: 48) }
        }
        .accessibilityElement(children: .combine)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: TetherSpace.s) {
            TextField("Message…", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .font(TetherType.body)
                .foregroundStyle(TetherColor.text)
                .tint(TetherColor.brand)
                .padding(TetherSpace.m)
                .background(TetherColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(TetherColor.border, lineWidth: 1)
                )

            Button {
                send()
            } label: {
                Icon(.send, size: 18, color: .white)
                    .frame(width: 44, height: 44)
                    .background(draft.trimmed.isEmpty
                                ? AnyShapeStyle(TetherColor.faint)
                                : AnyShapeStyle(TetherGradient.brand))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmed.isEmpty)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, TetherSpace.margin)
        .padding(.vertical, TetherSpace.m)
        .background(.ultraThinMaterial)
    }

    private func send() {
        let text = draft.trimmed
        guard !text.isEmpty else { return }
        ctx.insert(ChatMessage(senderID: profile.id, body: text))
        try? ctx.save()
        draft = ""
        TetherHaptics.success()
    }
}

// MARK: - Ritual

/// Set the standing appointment. A recurring commitment is worth more than
/// good intentions, so the app asks for a day and a time and then counts down.
struct RitualSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let existing: Ritual?

    @State private var name = "Our check-in"
    @State private var weekday = 1
    @State private var time = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("What do you call it?") {
                    TextField("Our check-in", text: $name)
                }
                Section("When") {
                    Picker("Day", selection: $weekday) {
                        ForEach(1...7, id: \.self) { day in
                            Text(Calendar.current.weekdaySymbols[day - 1]).tag(day)
                        }
                    }
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                }
                Section {
                    Text("Both of you see this countdown. It is an appointment, not a notification.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                }
            }
            .navigationTitle(existing == nil ? "Set a ritual" : "Change ritual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                guard let existing else { return }
                name = existing.name
                weekday = existing.weekday
                var comps = DateComponents()
                comps.hour = existing.hour
                comps.minute = existing.minute
                time = Calendar.current.date(from: comps) ?? Date()
            }
        }
    }

    private func save() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trimmed = name.trimmed.isEmpty ? "Our check-in" : name.trimmed
        if let existing {
            existing.name = trimmed
            existing.weekday = weekday
            existing.hour = comps.hour ?? 19
            existing.minute = comps.minute ?? 0
        } else {
            ctx.insert(Ritual(name: trimmed,
                              weekday: weekday,
                              hour: comps.hour ?? 19,
                              minute: comps.minute ?? 0))
        }
        try? ctx.save()
        dismiss()
    }
}

// MARK: - Memory lane

/// The couple's own history, in one place. Ties the memory echo, on-this-day
/// and the best moments into a single screen, so a long practice feels like it
/// has accumulated into something rather than just being stored.
struct MemoryLaneView: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var profiles: [UserProfile]
    @State private var pdfURL: URL?

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return profiles.first { $0.id == id }
    }

    /// Both partners' entries when paired.
    private var story: [JournalEntry] {
        guard let partner else { return entries.filter { $0.userID == profile.id } }
        return entries.filter { $0.userID == profile.id || $0.userID == partner.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.xl) {
                    banner
                    if story.isEmpty {
                        TetherEmptyState(
                            title: "Nothing here yet",
                            message: "Memory Lane fills as you write. Come back in a month."
                        )
                    } else {
                        stats
                        onThisDay
                        bestMoments
                        photoTimeline
                        monthStrip
                        yearBook
                    }
                }
                .padding(TetherSpace.margin)
                .readableFrame()
                .padding(.bottom, TetherSpace.xxl)
            }
            .background { TetherBackdrop() }
            .navigationTitle("Memory Lane")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: Banner

    private var banner: some View {
        ZStack(alignment: .bottomLeading) {
            TetherScene(timeOfDay: .dusk)
            LinearGradient(colors: [.clear, .black.opacity(0.32)],
                           startPoint: .center,
                           endPoint: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                Text("Memory lane".uppercased())
                    .font(TetherType.micro)
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.78))
                Text("Your story so far")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(-0.6)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, TetherSpace.margin)
            .padding(.bottom, TetherSpace.l)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.large, style: .continuous))
        .padding(.horizontal, -TetherSpace.margin)
    }

    // MARK: Stats

    private var stats: some View {
        HStack(alignment: .top, spacing: 0) {
            statBlock("\(story.count)", "entries")
            statBlock("\(daysWritten)", daysWritten == 1 ? "day" : "days")
            statBlock("\(longestStreak)", "best streak")
        }
    }

    private func statBlock(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(TetherColor.ink)
            Text(label.uppercased())
                .font(TetherType.micro)
                .tracking(1)
                .foregroundStyle(TetherColor.faint)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: On this day

    @ViewBuilder
    private var onThisDay: some View {
        if !onThisDayEntries.isEmpty {
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                SectionHeader(title: "On this day")
                ForEach(onThisDayEntries) { entry in
                    echoRow(entry)
                }
            }
        }
    }

    /// Same day-of-month, one or more months back. The same idea as the memory
    /// echo, but it can return several at once.
    private var onThisDayEntries: [JournalEntry] {
        let cal = Calendar.current
        let today = cal.dateComponents([.day, .month, .year], from: Date())
        return story.filter { entry in
            let c = cal.dateComponents([.day, .month, .year], from: entry.entryDate)
            guard c.day == today.day else { return false }
            guard let y = c.year, let ty = today.year, y < ty else { return false }
            return true
        }
        .sorted { $0.entryDate > $1.entryDate }
        .prefix(3)
        .map { $0 }
    }

    private func echoRow(_ entry: JournalEntry) -> some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.xs) {
                Text(entry.entryDate.formatted(.dateTime.month(.wide).year()).uppercased())
                    .font(TetherType.micro)
                    .tracking(1)
                    .foregroundStyle(TetherColor.faint)
                Text(SecureContent.read(entry.body))
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Best moments

    @ViewBuilder
    private var bestMoments: some View {
        if !bestMoments_entries.isEmpty {
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                SectionHeader(title: "Moments worth keeping")
                ForEach(bestMoments_entries) { entry in
                    TetherCard {
                        VStack(alignment: .leading, spacing: TetherSpace.xs) {
                            HStack(spacing: TetherSpace.xs) {
                                Circle()
                                    .fill(Mood.color(for: entry.mood))
                                    .frame(width: 8, height: 8)
                                Text(Mood.label(for: entry.mood))
                                    .font(TetherType.caption)
                                    .foregroundStyle(TetherColor.muted)
                                Spacer(minLength: 0)
                                Text(entry.entryDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(TetherType.caption)
                                    .foregroundStyle(TetherColor.faint)
                            }
                            Text(SecureContent.read(entry.body))
                                .font(TetherType.callout)
                                .foregroundStyle(TetherColor.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    /// The brightest entries — mood 5 or 4, most recent first, capped so this
    /// stays a highlight reel rather than a second journal.
    private var bestMoments_entries: [JournalEntry] {
        story.filter { $0.mood >= 4 }
            .sorted { $0.entryDate > $1.entryDate }
            .prefix(3)
            .map { $0 }
    }

    // MARK: Month strip

    private var monthStrip: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            SectionHeader(title: "Month by month")
            HStack(alignment: .bottom, spacing: TetherSpace.s) {
                ForEach(monthBuckets, id: \.month) { bucket in
                    VStack(spacing: TetherSpace.xs) {
                        Text("\(bucket.count)")
                            .font(TetherType.micro)
                            .foregroundStyle(TetherColor.faint)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(TetherGradient.brand)
                            .frame(height: max(6, CGFloat(bucket.count) / CGFloat(maxCount) * 74))
                        Text(bucket.month.formatted(.dateTime.month(.abbreviated)))
                            .font(TetherType.micro)
                            .foregroundStyle(TetherColor.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 116, alignment: .bottom)
        }
    }

    private var monthBuckets: [(month: Date, count: Int)] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: story) { entry -> Date in
            let c = cal.dateComponents([.year, .month], from: entry.entryDate)
            return cal.date(from: c) ?? entry.entryDate
        }
        return grouped
            .map { (month: $0.key, count: $0.value.count) }
            .sorted { $0.month < $1.month }
            .suffix(6)
            .map { $0 }
    }

    private var maxCount: Int { max(1, monthBuckets.map(\.count).max() ?? 1) }

    // MARK: Photo timeline

    /// Entries with a photo, newest first. Photos and Memory Lane already both
    /// existed — this is the seam between them, which was missing.
    private var photoEntries: [JournalEntry] {
        story.filter { $0.photoData != nil }
             .sorted { $0.entryDate > $1.entryDate }
    }

    @ViewBuilder
    private var photoTimeline: some View {
        if !photoEntries.isEmpty {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                SectionHeader(title: "In pictures")
                    .padding(.horizontal, TetherSpace.margin)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: TetherSpace.m) {
                        ForEach(photoEntries) { entry in
                            photoCard(entry)
                        }
                    }
                    .padding(.horizontal, TetherSpace.margin)
                }
            }
        }
    }

    private func photoCard(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let data = entry.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 156, height: 196)
                    .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small,
                                                style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: TetherRadius.small,
                                        style: .continuous)
                            .strokeBorder(TetherColor.border, lineWidth: 1)
                    )
            }

            Text(entry.entryDate.formatted(date: .abbreviated, time: .omitted))
                .font(TetherType.micro)
                .foregroundStyle(TetherColor.faint)

            Text(Mood.label(for: entry.mood))
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
        }
        .frame(width: 156, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: Year book

    /// Renders the whole story to a printable PDF and offers it to the share
    /// sheet. Generated on demand — it is only worth building if they want it.
    private var yearBook: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            SectionHeader(title: "Keepsake")

            if let pdfURL {
                ShareLink(item: pdfURL) {
                    Text("Share your year book")
                        .font(TetherType.label)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(TetherGradient.brand)
                        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small,
                                                    style: .continuous))
                }
            } else {
                Button("Make a year book") {
                    pdfURL = YearBook.makePDF(profile: profile,
                                              partner: partner,
                                              entries: story)
                }
                .tetherButton()
            }

            Text("A printable PDF of everything you have both written. It leaves the encrypted store, so keep it somewhere safe.")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Derived

    private var daysWritten: Int {
        let cal = Calendar.current
        return Set(story.map { cal.startOfDay(for: $0.entryDate) }).count
    }

    /// Longest run of consecutive days with at least one entry.
    private var longestStreak: Int {
        let cal = Calendar.current
        let days = Set(story.map { cal.startOfDay(for: $0.entryDate) })
            .sorted()
        guard !days.isEmpty else { return 0 }
        var best = 1
        var run = 1
        for i in 1..<days.count {
            let gap = cal.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 0
            if gap == 1 {
                run += 1
                best = max(best, run)
            } else {
                run = 1
            }
        }
        return best
    }
}

// MARK: - Cooldown

/// A guided pause for a hard moment. Not therapy and not mediation — just a
/// structured beat before anyone says something they cannot take back.
struct CooldownView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var note = ""

    private let steps: [(title: String, body: String)] = [
        ("Stop here", "You are activated. That is not a failure — it is a body doing its job. Nothing needs to be solved in the next ten minutes."),
        ("Breathe first", "Four in. Hold for four. Six out. Twice is enough to change what your body is doing."),
        ("Name the real thing", "Underneath the argument, what is actually at stake for you? Not the topic — the thing the topic is standing in for."),
        ("Say it plainly", "One sentence, starting with 'I'. No 'you always'. Write it here first so you can hear it before they do."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.xl) {
                    progress
                    content
                    Spacer(minLength: TetherSpace.l)
                    controls
                }
                .padding(TetherSpace.margin)
                .readableFrame()
                .padding(.bottom, TetherSpace.xl)
            }
            .background { TetherBackdrop() }
            .navigationTitle("A pause")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var progress: some View {
        HStack(spacing: TetherSpace.xs) {
            ForEach(steps.indices, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? TetherColor.brand : TetherColor.border)
                    .frame(height: 3)
            }
        }
        .padding(.top, TetherSpace.s)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            Text(steps[step].title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .tracking(-0.5)
                .foregroundStyle(TetherColor.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(steps[step].body)
                .font(TetherType.body)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)

            if step == 3 {
                TextField("I feel…", text: $note, axis: .vertical)
                    .lineLimit(2...5)
                    .font(TetherType.body)
                    .foregroundStyle(TetherColor.text)
                    .tint(TetherColor.brand)
                    .padding(TetherSpace.m)
                    .background(TetherColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small,
                                                style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: TetherRadius.small, style: .continuous)
                            .strokeBorder(TetherColor.border, lineWidth: 1)
                    )
            }
        }
    }

    private var controls: some View {
        VStack(spacing: TetherSpace.s) {
            if step < steps.count - 1 {
                Button("Next") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        step += 1
                    }
                }
                .tetherButton()
            } else {
                Button("Done") { dismiss() }
                    .tetherButton()
            }
            if step > 0 {
                Button("Back") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        step -= 1
                    }
                }
                .tetherButton(.tertiary)
            }
        }
    }
}

// MARK: - Shared threads

/// Gratitude and "us" — the two threads written by either partner and read by
/// both. Everywhere else in Tether a note is private unless you choose to
/// share it; these are shared by design.
struct TogetherThreadView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SharedNote.createdAt, order: .reverse) private var notes: [SharedNote]
    @Query private var profiles: [UserProfile]

    @State private var kind: SharedNoteKind = .gratitude
    @State private var draft = ""

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return profiles.first { $0.id == id }
    }

    private var thread: [SharedNote] { notes.filter { $0.kind == kind } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                kindPicker
                composer
                content
            }
            .background { TetherBackdrop() }
            .navigationTitle("Together")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var kindPicker: some View {
        HStack(spacing: TetherSpace.s) {
            ForEach(SharedNoteKind.allCases) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        kind = option
                    }
                } label: {
                    Text(option.title)
                        .font(TetherType.label)
                        .foregroundStyle(kind == option ? .white : TetherColor.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(kind == option
                                    ? AnyShapeStyle(TetherGradient.brand)
                                    : AnyShapeStyle(TetherColor.surface))
                        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small,
                                                    style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(kind == option ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, TetherSpace.margin)
        .padding(.top, TetherSpace.m)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            Text(kind.blurb)
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .bottom, spacing: TetherSpace.s) {
                TextField(kind.placeholder, text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .font(TetherType.body)
                    .foregroundStyle(TetherColor.text)
                    .tint(TetherColor.brand)
                    .padding(TetherSpace.m)
                    .background(TetherColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small,
                                                style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: TetherRadius.small, style: .continuous)
                            .strokeBorder(TetherColor.border, lineWidth: 1)
                    )

                Button {
                    add()
                } label: {
                    Icon(.send, size: 18, color: .white)
                        .frame(width: 44, height: 44)
                        .background(draft.trimmed.isEmpty
                                    ? AnyShapeStyle(TetherColor.faint)
                                    : AnyShapeStyle(TetherGradient.brand))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(draft.trimmed.isEmpty)
                .accessibilityLabel("Add to thread")
            }
        }
        .padding(TetherSpace.margin)
    }

    @ViewBuilder
    private var content: some View {
        if thread.isEmpty {
            TetherEmptyState(title: "Nothing yet", message: kind.emptyLine)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.m) {
                    ForEach(thread) { note in
                        noteRow(note)
                    }
                }
                .padding(.horizontal, TetherSpace.margin)
                .padding(.bottom, TetherSpace.xxl)
                .readableFrame()
            }
        }
    }

    private func noteRow(_ note: SharedNote) -> some View {
        let mine = note.authorID == profile.id
        return TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.xs) {
                HStack(spacing: TetherSpace.xs) {
                    Text(mine ? "You" : (partner?.displayName ?? "Your partner"))
                        .font(TetherType.caption)
                        .foregroundStyle(mine ? TetherColor.brand : TetherColor.muted)
                    Spacer(minLength: 0)
                    Text(note.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.faint)
                }
                Text(note.body)
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func add() {
        let text = draft.trimmed
        guard !text.isEmpty else { return }
        ctx.insert(SharedNote(authorID: profile.id, body: text, kind: kind))
        try? ctx.save()
        draft = ""
        TetherHaptics.success()
    }
}
