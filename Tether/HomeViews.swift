import PhotosUI
import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var ctx

    @Bindable var profile: UserProfile
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \Warmth.createdAt, order: .reverse) private var warmths: [Warmth]
    @Query private var rituals: [Ritual]
    @Query private var jarNotes: [JarNote]
    @Query(sort: \PromptReply.createdAt, order: .reverse) private var replies: [PromptReply]
    @Query(sort: \MoodLog.createdAt, order: .reverse) private var moods: [MoodLog]
    @Query private var allProfiles: [UserProfile]

    @State private var mood = 3
    @State private var reply = ""
    @State private var showSettings = false
    @State private var showSaved = false
    @State private var showPairing = false
    @State private var showRecap = false
    @State private var showTogether = false
    @State private var showCooldown = false
    @State private var showMemoryLane = false
    @State private var showRitual = false
    @State private var showChat = false
    @State private var showJar = false
    @State private var showMilestones = false
    @State private var showUnsent = false
    @State private var showQuiz = false
    @State private var showWrapped = false
    @State private var debugOpened = false
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var voiceNotes = VoiceNoteService.shared
    @State private var voiceData: Data?
    @State private var showNotifExplainer = false
    @State private var showComposer = false
    @State private var milestoneToast: String?
    @AppStorage("tether.notifAsked") private var notifAsked = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var voice = VoiceInput.shared

    private var pulse: PulseResult {
        PulseEngine.compute(entries: entries, ownerID: profile.id)
    }

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return allProfiles.first { $0.id == id }
    }

    private var isPaired: Bool { partner != nil }

    private var partnerAnsweredToday: Bool {
        guard let partner else { return false }
        return entries.contains { $0.userID == partner.id && Calendar.current.isDateInToday($0.entryDate) }
    }

    /// Called when the user taps the Pulse card — the shell switches tabs.
    var onOpenPulse: () -> Void = {}
    var onOpenCoach: () -> Void = {}

    private var todayPrompt: Prompt {
        PromptLibrary.prompt(for: profile.track,
                             dayIndex: PromptLibrary.dayIndex(since: profile.createdAt))
    }

    private var myEntries: [JournalEntry] {
        entries.filter { $0.userID == profile.id }
    }

    /// Past entries, excluding today's (which is already shown in the composer /
    /// answered state above) so the feed never duplicates the same day.
    private var olderEntries: [JournalEntry] {
        Array(myEntries.dropFirst(todayAnswered ? 1 : 0).prefix(10))
    }

    private var streak: Int {
        Streaks.current(from: myEntries.map(\.entryDate) + replies.map(\.forDate))
    }

    private var todayAnswered: Bool {
        guard let today = myEntries.first else { return false }
        return Calendar.current.isDateInToday(today.entryDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.l) {
                    header
                    if session.safetyBanner != nil { safetyBannerCard }
                    connectionCard
                        .tetherAppear(delay: 0.05)
                    togetherCard
                        .tetherAppear(delay: 0.08)
                    Button {
                        showMilestones = true
                    } label: {
                        MilestoneCard(milestones: milestones)
                    }
                    .buttonStyle(.plain)
                    .tetherAppear(delay: 0.082)

                    ritualCard
                        .tetherAppear(delay: 0.085)
                    warmthCard
                        .tetherAppear(delay: 0.09)
                    theirReplyCard
                        .tetherAppear(delay: 0.11)
                    PulseCard(result: pulse) { onOpenPulse() }
                        .tetherAppear(delay: 0.1)
                    PromptCard(prompt: todayPrompt, dayLabel: Date().weekdayDisplay)
                        .tetherAppear(delay: 0.15)

                    if todayAnswered && !showComposer {
                        answeredToday
                    } else {
                        composer
                    }

                    careNudgeCard
                        .tetherAppear(delay: 0.18)

                    if let echo = memoryEcho {
                        MemoryEchoCard(entry: echo.entry, monthsBack: echo.months)
                            .tetherAppear(delay: 0.2)
                    }

                    if !olderEntries.isEmpty {
                        SectionHeader(title: "Recent")
                        recentList
                    }

                    Button("Ask the coach") { onOpenCoach() }
                        .tetherButton()
                        .padding(.top, TetherSpace.s)

                    if isPaired {
                        Button("Private chat") { showChat = true }
                            .tetherButton(.secondary)
                    }

                    Button("Unsent") { showUnsent = true }
                        .tetherButton(.secondary)

                    Button("How well do you know them?") { showQuiz = true }
                        .tetherButton(.secondary)

                    Button("Your year") { showWrapped = true }
                        .tetherButton(.secondary)

                    Button("Wisdom Jar") { showJar = true }
                        .tetherButton(.secondary)

                    Button("Memory Lane") { showMemoryLane = true }
                        .tetherButton(.secondary)

                    Button("Gratitude & Us") { showTogether = true }
                        .tetherButton(.secondary)

                    Button("We're in a hard moment") { showCooldown = true }
                        .tetherButton(.tertiary)

                    Button("View weekly recap") { showRecap = true }
                        .tetherButton(.secondary)
                }
                .padding(TetherSpace.margin)
                .readableFrame()
            }
            // Sky first so it sits in front of the paper backdrop, pinned to
            // the top edge. This is what removes the gap.
            .background(alignment: .top) { mastheadSky }
            .background { TetherBackdrop() }
            .overlay(alignment: .top) {
                if let toast = milestoneToast {
                    MilestoneToast(text: toast)
                        .padding(.top, TetherSpace.l)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: milestoneToast)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showReveal) {
                RevealMomentView(
                    myEntry: myEntries.first,
                    partnerEntry: partnerTodayEntry,
                    partnerName: partner?.displayName ?? "Your partner"
                ) {
                    showReveal = false
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(profile: profile)
            }
            .sheet(isPresented: $showTogether) {
                TogetherThreadView(profile: profile)
            }
            .sheet(isPresented: $showCooldown) {
                CooldownView()
            }
            .sheet(isPresented: $showMemoryLane) {
                MemoryLaneView(profile: profile)
            }
            .sheet(isPresented: $showRitual) {
                RitualSheet(existing: ritual)
            }
            .sheet(isPresented: $showChat) {
                PrivateChatView(profile: profile)
            }
            .sheet(isPresented: $showJar) {
                WisdomJarView(profile: profile)
            }
            .sheet(isPresented: $showMilestones) {
                MilestonesView(milestones: milestones)
            }
            .sheet(isPresented: $showUnsent) {
                UnsentView(profile: profile)
            }
            .sheet(isPresented: $showQuiz) {
                QuizView(profile: profile)
            }
            .sheet(isPresented: $showWrapped) {
                WrappedView(profile: profile,
                            stats: WrappedBuilder.stats(profile: profile,
                                                        partner: partner,
                                                        entries: entries))
            }
            .onAppear {
                // DEBUG-only deep link, so a screenshot can reach a sheet that
                // otherwise needs a tap. Never compiled into a release build.
                #if DEBUG
                guard !debugOpened else { return }
                debugOpened = true
                let args = ProcessInfo.processInfo.arguments
                if args.contains("-openJar") { showJar = true }
                if args.contains("-openMemoryLane") { showMemoryLane = true }
                #endif
            }
            .sheet(isPresented: $showPairing) {
                PairingView(profile: profile)
            }
            .sheet(isPresented: $showRecap) {
                WeeklyRecapView(profile: profile)
            }
            .sheet(isPresented: $showNotifExplainer) {
                NotificationPermissionSheet(
                    onAllow: {
                        Task {
                            if await NotificationService.shared.requestAuthorization() {
                                await NotificationService.shared.reschedule(for: profile)
                            }
                        }
                    },
                    onDecline: { }
                )
            }
            .onChange(of: voice.transcript) { _, spoken in
                guard voice.isRecording, !spoken.isEmpty else { return }
                reply = spoken
            }
            .onDisappear { voice.stop() }
        }
    }

    // MARK: - Header

    /// The masthead: a drawn landscape with the greeting set over it. The
    /// scene changes with the time of day, so the app looks different at
    /// breakfast and at midnight.
    /// Just the words. The sky behind them is a fixed layer on the screen
    /// itself (see `mastheadSky`), which is what guarantees no gap at the top.
    private var header: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            HStack(spacing: TetherSpace.s) {
                Spacer(minLength: 0)
                StreakRing(count: streak)
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                    .accessibilityLabel("Settings")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(greetingWord) · \(Date().shortDisplay)".uppercased())
                    .font(TetherType.micro)
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.78))
                Text(profile.displayName)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                Text(continuitySubtitle)
                    .font(TetherType.caption)
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        // Clears the status bar, which the sky now runs behind.
        .padding(.top, 52)
        .padding(.bottom, TetherSpace.m)
    }

    /// The sky, pinned to the top of the screen and ignoring the safe area, so
    /// it always meets the very top edge. Content scrolls over it.
    private var mastheadSky: some View {
        ZStack(alignment: .bottom) {
            TetherScene(timeOfDay: .current)
            LinearGradient(colors: [.clear, .black.opacity(0.34)],
                           startPoint: .center,
                           endPoint: .bottom)
        }
        .frame(height: 330)
        .ignoresSafeArea(edges: .top)
    }

    /// A small continuity line under the name — "Day 12 of your practice"
    /// or "X-day streak" — so the practice feels like a practice, not a form.
    private var continuitySubtitle: String {
        let days = max(1, Calendar.current.dateComponents([.day],
            from: Calendar.current.startOfDay(for: profile.createdAt),
            to: Calendar.current.startOfDay(for: Date())).day ?? 1)
        if streak >= 1 {
            return "Day \(days) · \(streak)-day streak"
        }
        return "Day \(days) of your practice"
    }

    private var greetingWord: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    // MARK: - Solo banner

    private var connectionCard: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                // Stacks at accessibility text sizes, where the horizontal
                // pairing row squeezes the text into hyphenated fragments.
                AdaptiveRow(stacked: typeSize.isAccessibility) {
                    PairedAvatars(left: profile.displayName,
                                  right: partner?.displayName,
                                  size: 42,
                                  converged: isPaired)
                } trailing: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isPaired
                             ? "You and \(partner?.displayName ?? "your partner")"
                             : "Just you, for now")
                            .font(TetherType.label)
                            .foregroundStyle(TetherColor.text)
                        Text(statusLine)
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if !isPaired {
                    Button("Invite your partner") { showPairing = true }
                        .tetherButton(.secondary)
                }

                if let love = LoveLanguageStore.get(for: profile.id) {
                    HStack(spacing: TetherSpace.s) {
                        Image(systemName: love.symbol)
                            .font(.system(size: 12))
                            .foregroundStyle(TetherColor.brand)
                        Text("You feel loved through \(love.displayName.lowercased())")
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var safetyBannerCard: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            Label("Support is available", systemImage: "heart.text.square")
                .font(TetherType.label)
                .foregroundStyle(TetherColor.strained)

            Text(session.safetyBanner ?? "")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.text)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(SafetyResources.us.prefix(2)) { resource in
                HStack(spacing: TetherSpace.s) {
                    Text(resource.name)
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                    Spacer()
                    if let phone = resource.phone {
                        Text(phone)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(TetherColor.brand)
                    }
                }
            }

            Text("Your partner is not shown this.")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
        }
        .padding(TetherSpace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TetherColor.strained.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: TetherRadius.medium)
                .strokeBorder(TetherColor.strained.opacity(0.35), lineWidth: 1)
        )
    }

    private var statusLine: String {
        guard isPaired else {
            return "Everything you write syncs the moment your partner joins."
        }
        if todayAnswered && partnerAnsweredToday {
            return "You have both answered today."
        }
        if todayAnswered {
            return "Saved. It reveals when you have both answered."
        }
        return "Your partner answered. Yours unlocks together."
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(alignment: .leading, spacing: TetherSpace.l) {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                HStack(spacing: TetherSpace.s) {
                    BreathingOrb(size: 26)
                    Text("How are you today?")
                        .font(TetherType.label)
                }
                MoodRow(selection: $mood)
                Text(Mood.label(for: mood))
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
            }

            VStack(alignment: .leading, spacing: TetherSpace.s) {
                HStack {
                    Text("Your response")
                        .font(TetherType.label)
                        .foregroundStyle(TetherColor.text)
                    Spacer()
                    Button {
                        Task { await voice.toggle() }
                    } label: {
                        HStack(spacing: 5) {
                            Icon(.mic, size: 15,
                                 color: voice.isRecording ? TetherColor.strained : TetherColor.muted)
                            Text(voice.isRecording ? "Listening…" : "Dictate")
                                .font(TetherType.micro)
                                .foregroundStyle(voice.isRecording ? TetherColor.strained : TetherColor.muted)
                        }
                        .padding(.horizontal, TetherSpace.m)
                        .padding(.vertical, 5)
                        .background(voice.isRecording ? TetherColor.strainedSoft : TetherColor.surfaceSunken)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(voice.isRecording ? "Stop dictation" : "Dictate your response")

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack(spacing: 5) {
                            Image(systemName: "photo")
                            .accessibilityHidden(true)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(TetherColor.muted)
                            Text(photoData == nil ? "Photo" : "Added")
                                .font(TetherType.micro)
                                .foregroundStyle(TetherColor.muted)
                        }
                        .padding(.horizontal, TetherSpace.m)
                        .padding(.vertical, 5)
                        .background(TetherColor.surfaceSunken)
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("Attach a photo")

                    Button {
                        Task {
                            if voiceNotes.isRecording {
                                voiceData = voiceNotes.stopRecording()
                            } else {
                                await voiceNotes.toggleRecording()
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: voiceNotes.isRecording ? "stop.circle.fill" : "waveform")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(voiceNotes.isRecording ? TetherColor.strained
                                                                        : TetherColor.muted)
                            Text(voiceNotes.isRecording ? "Stop"
                                                        : (voiceData == nil ? "Voice" : "Recorded"))
                                .font(TetherType.micro)
                                .foregroundStyle(voiceNotes.isRecording ? TetherColor.strained
                                                                        : TetherColor.muted)
                        }
                        .padding(.horizontal, TetherSpace.m)
                        .padding(.vertical, 5)
                        .background(voiceNotes.isRecording ? TetherColor.strainedSoft
                                                           : TetherColor.surfaceSunken)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(voiceNotes.isRecording ? "Stop recording"
                                                               : "Record a voice note")
                }
                TextField("One sentence is enough", text: $reply, axis: .vertical)
                    .lineLimit(2...6)
                    .tetherField()
                    .onChange(of: photoItem) { _, item in
                        guard let item else { return }
                        Task {
                            photoData = try? await item.loadTransferable(type: Data.self)
                        }
                    }
                if let photoData, let image = UIImage(data: photoData) {
                    HStack(spacing: TetherSpace.s) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 76, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small,
                                                        style: .continuous))
                        Button("Remove") {
                            self.photoData = nil
                            photoItem = nil
                        }
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .buttonStyle(.plain)
                        Spacer(minLength: 0)
                    }
                }
                if let message = voice.errorMessage {
                    Text(message)
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.strained)
                }
            }

            Button("Save today's entry") { save() }
                .tetherButton()
                .disabled(reply.trimmed.isEmpty)
                .opacity(reply.trimmed.isEmpty ? 0.5 : 1)
        }
    }

    // MARK: - Answered state

    private var answeredToday: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            HStack(spacing: TetherSpace.s) {
                Image(systemName: "checkmark.circle.fill")
                .accessibilityHidden(true)
                    .foregroundStyle(TetherColor.thriving)
                Text("Saved for today")
                    .font(TetherType.label)
                    .foregroundStyle(TetherColor.thriving)
            }

            // Waiting indicator: you are done, they are not. Gentle, and it
            // disappears the moment they answer.
            if isPaired, !partnerAnsweredToday, let partner {
                HStack(spacing: TetherSpace.xs) {
                    TetherHeroMark(width: 22,
                                   color: TetherColor.faint,
                                   sag: 3,
                                   lineWidth: 1.5,
                                   dotRadius: 2)
                    Text("Waiting for \(partner.displayName)")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                }
            }
            if let entry = myEntries.first {
                TetherCard {
                    VStack(alignment: .leading, spacing: TetherSpace.s) {
                        HStack(spacing: TetherSpace.s) {
                            Circle()
                                .fill(Mood.color(for: entry.mood))
                                .frame(width: 8, height: 8)
                            Text(Mood.label(for: entry.mood))
                                .font(TetherType.caption)
                                .foregroundStyle(TetherColor.muted)
                        }
                        Text(SecureContent.read(entry.body))
                            .font(TetherType.body)
                            .foregroundStyle(TetherColor.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            // A light text action rather than another bordered box — the
            // screen already has enough card chrome.
            Button {
                reply = ""
                showComposer = true
            } label: {
                HStack(spacing: TetherSpace.xs) {
                    Text("Add a note, photo or voice")
                    Icon(.chevronRight, size: 14, color: TetherColor.brand)
                }
                .font(TetherType.label)
                .foregroundStyle(TetherColor.brand)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add a note, photo or voice")
        }
    }

    // MARK: - Reveal moment

    @State private var showReveal = false
    /// Day the reveal was last shown, so it appears once per day rather than
    /// every time the screen opens.
    @AppStorage("tether.revealedOn") private var revealedOn = ""

    private var bothAnswered: Bool { todayAnswered && partnerAnsweredToday }

    /// A memory from a while back, if there is one. Shown on Home so the app
    /// feels like it has a past with you instead of being an empty form.
    /// Tries one month, then three, six and twelve.
    private var memoryEcho: (entry: JournalEntry, months: Int)? {
        // Cheap guard first: this is evaluated on every body pass, including
        // every keystroke in the composer, and there is nothing to find
        // without history.
        guard entries.count >= 2 else { return nil }
        for months in [1, 3, 6, 12] {
            if let entry = MemoryEchoCard.find(in: entries,
                                               userID: profile.id,
                                               monthsBack: months) {
                return (entry, months)
            }
        }
        return nil
    }

    private var partnerTodayEntry: JournalEntry? {
        guard let partner else { return nil }
        return entries.first {
            $0.userID == partner.id && Calendar.current.isDateInToday($0.entryDate)
        }
    }

    /// Consecutive days, counting back from today, where BOTH of you wrote.
    /// Today being unfinished does not break it — the day is not over yet.
    private var sharedStreak: Int {
        guard isPaired, let partner else { return 0 }
        let cal = Calendar.current
        let mine = Set(myEntries.map { cal.startOfDay(for: $0.entryDate) })
        let theirs = Set(entries.filter { $0.userID == partner.id }
                                .map { cal.startOfDay(for: $0.entryDate) })
        let both = mine.intersection(theirs)

        var day = cal.startOfDay(for: Date())
        if !both.contains(day),
           let yesterday = cal.date(byAdding: .day, value: -1, to: day) {
            day = yesterday
        }
        var count = 0
        while both.contains(day) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    /// Days since the earlier of the two of you started.
    private var daysTogether: Int {
        guard isPaired, let partner else { return 0 }
        let cal = Calendar.current
        let start = min(profile.createdAt, partner.createdAt)
        let days = cal.dateComponents([.day],
                                      from: cal.startOfDay(for: start),
                                      to: cal.startOfDay(for: Date())).day ?? 0
        return max(1, days + 1)
    }

    /// The couple's shared state — the "we", which the rest of Home does not
    /// really show. Both streaks, how long you have been at this, and what
    /// today looks like on their side.
    @ViewBuilder
    private var togetherCard: some View {
        if isPaired, let partner {
            TetherCard {
                VStack(alignment: .leading, spacing: TetherSpace.m) {
                    HStack(spacing: TetherSpace.xs) {
                        TetherHeroMark(width: 26,
                                       color: TetherColor.brand.opacity(0.55),
                                       sag: 4,
                                       lineWidth: 1.5,
                                       dotRadius: 2)
                        Text("TOGETHER")
                            .font(TetherType.micro)
                            .tracking(1)
                            .foregroundStyle(TetherColor.faint)
                        Spacer(minLength: 0)
                    }

                    Text(sharedStreakLine(partner: partner))
                        .font(TetherType.callout)
                        .foregroundStyle(TetherColor.text)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: TetherSpace.s) {
                        Circle()
                            .fill(partnerTodayEntry.map { Mood.color(for: $0.mood) } ?? TetherColor.faint)
                            .frame(width: 8, height: 8)
                        Text(partnerTodayLine(partner: partner))
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text("\(daysTogether) day\(daysTogether == 1 ? "" : "s") of showing up together.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.faint)
                }
            }
        }
    }

    private func sharedStreakLine(partner: UserProfile) -> String {
        if sharedStreak == 0 {
            return "You have not both written on the same day yet. Today could be the first."
        }
        return "You have both shown up \(sharedStreak) day\(sharedStreak == 1 ? "" : "s") in a row."
    }

    private func partnerTodayLine(partner: UserProfile) -> String {
        guard let entry = partnerTodayEntry else {
            return "\(partner.displayName) has not answered yet today."
        }
        return "\(partner.displayName) answered today — feeling \(Mood.label(for: entry.mood).lowercased())."
    }

    // MARK: - Milestones

    /// Reuses the existing computation from the Grow tab — there is no second
    /// definition of what a milestone is. This card only surfaces the next one
    /// on Home, where it will actually be seen.
    private var milestones: [Milestone] {
        Milestones.compute(profile: profile,
                           entries: entries,
                           replies: replies,
                           isPaired: isPaired)
    }

    // MARK: - Ritual

    private var ritual: Ritual? { rituals.first }

    /// The couple's standing appointment, with a countdown. A recurring
    /// commitment is what turns a daily habit into something you show up for.
    private var ritualCard: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                HStack(spacing: TetherSpace.xs) {
                    TetherHeroMark(width: 26,
                                   color: TetherColor.brand.opacity(0.55),
                                   sag: 4,
                                   lineWidth: 1.5,
                                   dotRadius: 2)
                    Text("YOUR RITUAL")
                        .font(TetherType.micro)
                        .tracking(1)
                        .foregroundStyle(TetherColor.faint)
                    Spacer(minLength: 0)
                    Button(ritual == nil ? "Set" : "Change") { showRitual = true }
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.brand)
                        .buttonStyle(.plain)
                }

                if let ritual {
                    Text(countdownLine(for: ritual))
                        .font(TetherType.callout)
                        .foregroundStyle(TetherColor.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(ritual.weekdayName)s at \(ritual.timeLabel)")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                } else {
                    Text("Pick a time you will both show up. A standing appointment beats good intentions.")
                        .font(TetherType.callout)
                        .foregroundStyle(TetherColor.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func countdownLine(for ritual: Ritual) -> String {
        guard let next = ritual.nextOccurrence() else { return ritual.name }
        let cal = Calendar.current
        let days = cal.dateComponents([.day],
                                      from: cal.startOfDay(for: Date()),
                                      to: cal.startOfDay(for: next)).day ?? 0
        switch days {
        case 0:  return "\(ritual.name) is today."
        case 1:  return "\(ritual.name) is tomorrow."
        default: return "\(ritual.name) is in \(days) days."
        }
    }

    // MARK: - Warmth

    /// The most recent signal they sent that you have not acknowledged.
    private var unseenWarmth: Warmth? {
        guard let partner else { return nil }
        return warmths.first { $0.fromID == partner.id && !$0.seen }
    }

    /// What you already sent today, so the row can reflect it.
    private var sentToday: WarmthKind? {
        let cal = Calendar.current
        return warmths.first {
            $0.fromID == profile.id && cal.isDateInToday($0.createdAt)
        }?.kind
    }

    private func sendWarmth(_ kind: WarmthKind) {
        guard let partner else { return }
        ctx.insert(Warmth(fromID: profile.id, toID: partner.id, kind: kind))
        try? ctx.save()
        TetherHaptics.success()
    }

    /// One tap, no writing required — the smallest possible act of care, and
    /// the thing that makes Home feel like it is about two people.
    @ViewBuilder
    private var warmthCard: some View {
        if isPaired, let partner {
            TetherCard {
                VStack(alignment: .leading, spacing: TetherSpace.m) {
                    if let received = unseenWarmth {
                        HStack(alignment: .top, spacing: TetherSpace.s) {
                            TetherHeroMark(width: 26,
                                           color: TetherColor.brand,
                                           sag: 3,
                                           lineWidth: 1.5,
                                           dotRadius: 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(partner.displayName) sent you something")
                                    .font(TetherType.label)
                                    .foregroundStyle(TetherColor.text)
                                Text(received.kind.label)
                                    .font(TetherType.callout)
                                    .foregroundStyle(TetherColor.brand)
                            }
                            Spacer(minLength: 0)
                            Button {
                                received.seen = true
                                try? ctx.save()
                            } label: {
                                Text("Thanks")
                                    .font(TetherType.caption)
                                    .foregroundStyle(TetherColor.muted)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text(sentToday == nil
                         ? "Send \(partner.displayName) something. No words needed."
                         : "You sent: \(sentToday!.label)")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: TetherSpace.s) {
                            ForEach(WarmthKind.allCases) { kind in
                                Button {
                                    sendWarmth(kind)
                                } label: {
                                    Text(kind.short)
                                        .font(TetherType.caption)
                                        .foregroundStyle(TetherColor.brand)
                                        .padding(.horizontal, TetherSpace.m)
                                        .padding(.vertical, TetherSpace.s)
                                        .background(TetherColor.brandSoft)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }
            }
        }
    }

    /// What helped them last time. Finds a past low day immediately followed
    /// by a better one, and surfaces what THEY wrote once things lifted.
    ///
    /// This is the point of the feature: not advice from us, and not a
    /// template — their own words, handed back at the moment they are useful.
    /// It gets better the longer a couple uses the app.
    private var recoveryMemory: (lowDate: Date, nextDate: Date, body: String)? {
        // Evaluated on every body pass, so bail before sorting anything.
        guard entries.count >= 2, let partner else { return nil }
        let cal = Calendar.current
        let theirs = entries
            .filter { $0.userID == partner.id }
            .sorted { $0.entryDate < $1.entryDate }
        guard theirs.count >= 2 else { return nil }

        // Most recent first, so the freshest memory wins.
        for i in stride(from: theirs.count - 1, through: 1, by: -1) {
            let later = theirs[i]
            let earlier = theirs[i - 1]
            let gap = cal.dateComponents(
                [.day],
                from: cal.startOfDay(for: earlier.entryDate),
                to: cal.startOfDay(for: later.entryDate)
            ).day ?? 0
            guard gap == 1 else { continue }
            guard earlier.mood <= 2, later.mood > earlier.mood else { continue }
            let text = SecureContent.read(later.body).trimmed
            guard !text.isEmpty else { continue }
            return (earlier.entryDate, later.entryDate, text)
        }
        return nil
    }

    /// The most recent line they left in reply to something you wrote — so it
    /// is not buried in the journal.
    private var theirLastReply: (entry: JournalEntry, text: String)? {
        guard let partner else { return nil }
        let replied = myEntries
            .filter { $0.replyBy == partner.id && !($0.replyBody ?? "").trimmed.isEmpty }
            .sorted { ($0.replyAt ?? $0.entryDate) > ($1.replyAt ?? $1.entryDate) }
        guard let latest = replied.first, let text = latest.replyBody else { return nil }
        return (latest, text)
    }

    @ViewBuilder
    private var theirReplyCard: some View {
        if let reply = theirLastReply, let partner {
            TetherCard {
                VStack(alignment: .leading, spacing: TetherSpace.s) {
                    HStack(spacing: TetherSpace.xs) {
                        TetherHeroMark(width: 26,
                                       color: TetherColor.brand.opacity(0.55),
                                       sag: 4,
                                       lineWidth: 1.5,
                                       dotRadius: 2)
                        Text("\(partner.displayName.uppercased()) REPLIED")
                            .font(TetherType.micro)
                            .tracking(1)
                            .foregroundStyle(TetherColor.faint)
                        Spacer(minLength: 0)
                    }
                    Text("“\(reply.text)”")
                        .font(TetherType.callout)
                        .foregroundStyle(TetherColor.text)
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)
                    Text("On: \(SecureContent.read(reply.entry.body))")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .lineLimit(2)
                }
            }
        }
    }

    /// Care nudge: when their mood is low, say so gently and offer one line.
    /// This is what turns the mood data we already collect into care.
    @ViewBuilder
    private var careNudgeCard: some View {
        if let entry = partnerTodayEntry, entry.mood <= 2, let name = partner?.displayName {
            TetherCard {
                VStack(alignment: .leading, spacing: TetherSpace.s) {
                    HStack(spacing: TetherSpace.xs) {
                        TetherHeroMark(width: 26,
                                       color: TetherColor.rose,
                                       sag: 4,
                                       lineWidth: 1.5,
                                       dotRadius: 2)
                        Text("A HARD DAY")
                            .font(TetherType.micro)
                            .foregroundStyle(TetherColor.rose)
                            .tracking(1)
                        Spacer(minLength: 0)
                    }
                    Text("\(name) had a hard day. One line from you might land.")
                        .font(TetherType.callout)
                        .foregroundStyle(TetherColor.text)
                        .fixedSize(horizontal: false, vertical: true)

                    // Their own words from last time, not advice from us.
                    if let memory = recoveryMemory {
                        Divider().overlay(TetherColor.border)

                        VStack(alignment: .leading, spacing: TetherSpace.xs) {
                            Text("THE DAY AFTER LAST TIME")
                                .font(TetherType.micro)
                                .tracking(1)
                                .foregroundStyle(TetherColor.faint)
                            Text("“\(memory.body)”")
                                .font(TetherType.callout)
                                .foregroundStyle(TetherColor.text)
                                .italic()
                                .fixedSize(horizontal: false, vertical: true)
                            Text(memory.nextDate.formatted(date: .abbreviated, time: .omitted))
                                .font(TetherType.caption)
                                .foregroundStyle(TetherColor.muted)
                        }
                    }
                }
            }
        }
    }

    /// The reveal only fires when both have answered, and at most once a day.
    private func maybeReveal() {
        guard bothAnswered else { return }
        let today = String(Int(Calendar.current.startOfDay(for: Date())
            .timeIntervalSince1970))
        guard revealedOn != today else { return }
        revealedOn = today
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showReveal = true }
    }

    // MARK: - Recent

    @ViewBuilder
    private var recentList: some View {
        if olderEntries.isEmpty {
            TetherCard {
                VStack(alignment: .leading, spacing: TetherSpace.m) {
                    IconDisc(icon: .journal, size: 40, color: TetherColor.brand)
                    Text("Your recent entries start here")
                        .font(TetherType.label)
                    Text("A day at a time. Past entries will appear here as you go.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } else {
            ForEach(olderEntries) { entry in
                TetherCard {
                    VStack(alignment: .leading, spacing: TetherSpace.xs) {
                        HStack {
                            Circle()
                                .fill(Mood.color(for: entry.mood))
                                .frame(width: 8, height: 8)
                            Text(entry.entryDate.shortDisplay)
                                .font(TetherType.caption)
                                .foregroundStyle(TetherColor.muted)
                            Spacer()
                            if entry.visibility == .private {
                                Image(systemName: "lock")
                                .accessibilityHidden(true)
                                    .font(.system(size: 11))
                                    .foregroundStyle(TetherColor.muted)
                            }
                        }
                        Text(SecureContent.read(entry.body))
                            .font(TetherType.callout)
                            .foregroundStyle(TetherColor.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func save() {
        let text = reply.trimmed
        let verdict = SafetyClassifier.classify(text)

        let entry = JournalEntry(userID: profile.id,
                                 body: SecureContent.seal(text),
                                 mood: mood,
                                 source: .prompt)
        entry.safetyFlagged = verdict.isCrisis
        entry.photoData = photoData
        entry.voiceData = voiceData
        ctx.insert(entry)
        ctx.insert(MoodLog(userID: profile.id, mood: mood))

        // Crisis entries are never distilled into retrievable memory, and the
        // couple-facing surface is suppressed entirely.
        if verdict.isCrisis {
            session.safetyBanner = SafetyResources.headline(for: verdict.category)
        } else {
            ctx.insert(CoachEngine.makeMemory(from: text,
                                              ownerID: profile.id,
                                              source: .prompt,
                                              sourceID: entry.id,
                                              visibility: entry.visibility))
        }

        try? ctx.save()
        reply = ""
        photoData = nil
        photoItem = nil
        voiceData = nil
        showComposer = false
        TetherHaptics.success()

        // Celebrate weekly milestones without nagging: only on the day the
        // streak first reaches a multiple of seven.
        let newStreak = Streaks.current(from: myEntries.map(\.entryDate)
                                         + replies.map(\.forDate)
                                         + [entry.entryDate])
        if newStreak > 0 && newStreak % 7 == 0 {
            milestoneToast = "\(newStreak)-day streak"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { milestoneToast = nil }
        }

        // If they already answered, today is complete — show the reveal.
        maybeReveal()

        // First value moment reached — this is the right time to ask.
        if !notifAsked {
            notifAsked = true
            showNotifExplainer = true
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    @State private var store = PurchaseService.shared
    @State private var notifService = NotificationService.shared
    @State private var showPaywall = false
    @State private var showLoveQuiz = false
    @State private var showDeleteConfirm = false
    @State private var showTrack = false
    @State private var exportUnlocked = false
    @State private var exportMessage: String?
    @State private var switchingLanguage = false
    @State private var showScenes = false
    @State private var scene = SceneManager.shared
    @Environment(\.syncService) private var sync
    @Environment(LanguageManager.self) private var language
    @Environment(ThemeManager.self) private var theme
    @Environment(AppLockManager.self) private var lock
    @State private var sharesAnon = ReflectionSettings.sharesAnonymizedSummary

    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var allEntries: [JournalEntry]
    @Query private var allMessages: [AIMessage]
    @Query private var allMemories: [AIMemory]
    @Query private var allProfiles: [UserProfile]

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return allProfiles.first { $0.id == id }
    }

    /// Face ID before the export. If the device has no passcode set, this
    /// refuses rather than quietly allowing it — an unguarded export of every
    /// entry is the single worst thing this app could do.
    private func unlockExport() async {
        exportMessage = nil
        let granted = await AppLockManager.shared.authenticate(
            reason: "Confirm it is you before exporting your journal"
        )
        if granted {
            exportUnlocked = true
        } else {
            exportMessage = "Export locked. Set a device passcode to enable it."
        }
    }

    private var exportDocument: String {
        ExportService.markdown(profile: profile,
                               partner: partner,
                               entries: allEntries,
                               messages: allMessages,
                               memories: allMemories)
    }

    /// Kept as its own property: inlining this Picker inside the Settings List
    /// pushed the body past what the type-checker could resolve in reasonable
    /// time. Each option is shown in its own script so it stays readable.
    /// A preview dot of each Feel's gradient, so the choice is visible rather
    /// than described.
    private func swatch(for feel: FeelManager.Feel) -> AnyShapeStyle {
        switch feel {
        case .classic:
            return AnyShapeStyle(LinearGradient(
                colors: [Color(hex: "6A57D6"), Color(hex: "4A3AA8")],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        case .warm:
            return AnyShapeStyle(LinearGradient(
                colors: [Color(hex: "C4608A"), Color(hex: "8E3A61")],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    /// Light / dark / system. Same manual-binding approach as the language
    /// picker — @Environment has no $ projection for an @Observable class.
    private var themePicker: some View {
        Picker("Appearance", selection: Binding(
            get: { theme.modeRaw },
            set: { theme.modeRaw = $0 }
        )) {
            ForEach(ThemeManager.Mode.allCases) { mode in
                Text(mode.displayName).tag(mode.rawValue)
            }
        }
        .font(TetherType.body)
    }

    private var languagePicker: some View {
        // @Environment does not expose a $ projection for an @Observable
        // class, so the binding is built by hand.
        //
        // Changing locale re-resolves every string in the app and re-lays out
        // the whole tree, which takes a beat and used to look like a freeze.
        // The overlay is shown first, given a frame to draw, and only then is
        // the language changed — so it reads as work being done rather than a
        // hang.
        Picker("Language", selection: Binding(
            get: { language.code },
            set: { newValue in
                guard newValue != language.code else { return }
                Task { @MainActor in
                    withAnimation(.easeOut(duration: 0.15)) { switchingLanguage = true }
                    try? await Task.sleep(for: .milliseconds(180))
                    language.code = newValue
                    try? await Task.sleep(for: .milliseconds(700))
                    withAnimation(.easeOut(duration: 0.2)) { switchingLanguage = false }
                }
            }
        )) {
            ForEach(LanguageManager.available, id: \.code) { option in
                Text(option.name).tag(option.code)
            }
        }
        .font(TetherType.body)
    }

    @ViewBuilder
    private var syncStatusLabel: some View {
        switch sync.status {
        case .localOnly:
            Text("This device only")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
        case .checking:
            Text("Checking…")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
        case .available:
            Text("iCloud")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.thriving)
        case .noAccount:
            Text("Sign in to iCloud")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.strained)
        case .error:
            Text("Off")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Name", text: $profile.displayName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(TetherColor.text)
                            .tint(TetherColor.brand)
                    }
                }

                Section("Wisdom track") {
                    ForEach(WisdomTrack.allCases.filter(\.isLive)) { track in
                        Button {
                            profile.track = track
                        } label: {
                            HStack {
                                Icon(track.icon, size: 20, color: track.accent)
                                Text(track.displayName)
                                    .foregroundStyle(TetherColor.text)
                                Spacer()
                                if profile.track == track {
                                    Image(systemName: "checkmark")
                                    .accessibilityHidden(true)
                                        .foregroundStyle(TetherColor.brand)
                                }
                            }
                        }
                    }
                }

                Section("About you") {
                    if let love = LoveLanguageStore.get(for: profile.id) {
                        HStack(spacing: TetherSpace.m) {
                            Image(systemName: love.symbol)
                                .font(.system(size: 16))
                                .foregroundStyle(TetherColor.brand)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your love language")
                                    .font(TetherType.label)
                                Text(love.displayName)
                                    .font(TetherType.caption)
                                    .foregroundStyle(TetherColor.muted)
                            }
                        }
                        Button("Retake the quiz") { showLoveQuiz = true }
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.brand)
                    } else {
                        Text("Not set yet — take the quiz to personalise your insights.")
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                        Button("Take the quiz") { showLoveQuiz = true }
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.brand)
                    }
                }

                Section("Reminders") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(notifService.isAuthorized ? "On" : "Off")
                            .font(TetherType.caption)
                            .foregroundStyle(notifService.isAuthorized ? TetherColor.thriving : TetherColor.muted)
                    }
                    Stepper("Send at \(profile.notifyHour):00",
                            value: $profile.notifyHour, in: 6...23)
                    if !notifService.isAuthorized {
                        Button("Turn on reminders") {
                            Task {
                                if await NotificationService.shared.requestAuthorization() {
                                    await NotificationService.shared.reschedule(for: profile)
                                }
                            }
                        }
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.brand)
                    }
                }
                .task { await notifService.refreshStatus() }
                .onChange(of: profile.notifyHour) { _, _ in
                    Task { await NotificationService.shared.reschedule(for: profile) }
                }

                Section("Subscription") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.statusLabel)
                                .font(TetherType.label)
                            Text("Covers both partners")
                                .font(TetherType.caption)
                                .foregroundStyle(TetherColor.muted)
                        }
                        Spacer()
                        if !store.hasAccess {
                            Button("Upgrade") { showPaywall = true }
                                .font(TetherType.caption)
                                .foregroundStyle(TetherColor.brand)
                        }
                    }
                }

                Section("Your data") {
                    // Gated behind Face ID. The export is plain text and leaves
                    // the encrypted store, so it is the one action in the app
                    // that can leak everything at once.
                    if exportUnlocked {
                    ShareLink(item: exportDocument,
                              preview: SharePreview("Your Tether export")) {
                        HStack {
                            Label("Export everything", systemImage: "square.and.arrow.up")
                                .font(TetherType.label)
                            Spacer()
                            Icon(.download, size: 17, color: TetherColor.faint)
                        }
                    }
                    } else {
                        Button {
                            Task { await unlockExport() }
                        } label: {
                            HStack {
                                Label("Export everything", systemImage: "square.and.arrow.up")
                                    .font(TetherType.label)
                                Spacer()
                                Icon(.download, size: 17, color: TetherColor.faint)
                            }
                        }
                    }

                    Text("A readable copy of your journal, coach conversations, and memories. It leaves the encrypted store, so it is locked behind Face ID.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)

                    if let exportMessage {
                        Text(exportMessage)
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.strained)
                    }
                }

                Section("Sync") {
                    HStack {
                        Label("Backup & sync", systemImage: "icloud")
                            .font(TetherType.label)
                        Spacer()
                        syncStatusLabel
                    }
                    if case .available(_) = sync.status {
                        Button("Sync now") { sync.requestSync() }
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.brand)
                    }
                    Text("With iCloud on, your entries are mirrored across your own devices. They are sealed before they leave this phone.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                }

                Section("Weekly reflection") {
                    Toggle("Deeper reflections", isOn: $sharesAnon)
                        .font(TetherType.label)
                        .onChange(of: sharesAnon) { _, newValue in
                            ReflectionSettings.sharesAnonymizedSummary = newValue
                        }
                    Text("Off by default. When on, only anonymized counts, mood averages and themes are sent for a richer weekly summary — never your actual words.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section("Wisdom track") {
                    Button {
                        showTrack = true
                    } label: {
                        HStack(spacing: TetherSpace.m) {
                            Icon(profile.track.icon, size: 20, color: profile.track.accent)
                            Text(profile.track.displayName)
                                .font(TetherType.body)
                                .foregroundStyle(TetherColor.text)
                            Spacer(minLength: 0)
                            Icon(.chevronRight, size: 15, color: TetherColor.faint)
                        }
                    }
                }

                Section("Feel") {
                    ForEach(FeelManager.Feel.allCases) { option in
                        Button {
                            FeelManager.shared.raw = option.rawValue
                        } label: {
                            HStack(spacing: TetherSpace.m) {
                                Circle()
                                    .fill(swatch(for: option))
                                    .frame(width: 26, height: 26)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(option.title)
                                        .font(TetherType.body)
                                        .foregroundStyle(TetherColor.text)
                                    Text(option.blurb)
                                        .font(TetherType.caption)
                                        .foregroundStyle(TetherColor.muted)
                                }
                                Spacer(minLength: 0)
                                if FeelManager.shared.feel == option {
                                    Image(systemName: "checkmark")
                                    .accessibilityHidden(true)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(TetherColor.brand)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Text("A tone, not a rule. Pick whichever feels like you — you can change it any time.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section("Theme") {
                    Button {
                        showScenes = true
                    } label: {
                        HStack(spacing: TetherSpace.m) {
                            ZStack {
                                LinearGradient(colors: scene.theme.backdrop,
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                                Image(systemName: scene.theme.symbol)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.92))
                            }
                            .frame(width: 38, height: 38)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Scene")
                                    .font(TetherType.body)
                                    .foregroundStyle(TetherColor.text)
                                Text(scene.theme.title)
                                    .font(TetherType.caption)
                                    .foregroundStyle(TetherColor.muted)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                            .accessibilityHidden(true)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(TetherColor.faint)
                        }
                    }
                    .buttonStyle(.plain)

                    Text("Changes the backdrop and light across the whole app. Your accent stays yours.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // The old Appearance picker (Light/Dark/System) is gone.
                //
                // It fought the Theme picker: with Appearance on "System" the
                // scene decided the scheme, so choosing Dawn forced light mode
                // on a phone set to dark. Two controls for one decision, and
                // the wrong one won. "Match phone" in the Theme picker is what
                // "System" was supposed to mean, and it is now the default.

                Section("Language") {
                    languagePicker
                }

                Section("Security") {
                    // @Environment has no $ projection for an @Observable
                    // class — same manual binding as the pickers above.
                    Toggle("Lock with Face ID", isOn: Binding(
                        get: { lock.isEnabled },
                        set: { lock.isEnabled = $0 }
                    ))
                        .font(TetherType.body)
                    Text("Requires your device passcode or Face ID when Tether is opened. Nobody else can read your journal.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section("Privacy") {
                    HStack {
                        Label("Encryption", systemImage: "lock.shield")
                            .font(TetherType.label)
                        Spacer()
                        Text(CryptoService.shared.hasKey ? "On" : "Off")
                            .font(TetherType.caption)
                            .foregroundStyle(CryptoService.shared.hasKey ? TetherColor.thriving : TetherColor.muted)
                    }
                    VStack(alignment: .leading, spacing: TetherSpace.s) {
                        Text("Your journal, coach conversations, and memories are sealed with a key that lives only in this device's Keychain. We cannot read them.")
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Because of that, there is no recovery if you lose every device. That is the cost of us not being able to read your words.")
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, TetherSpace.xs)
                }

                Section {
                    Button("Delete all my data", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                       to: nil, from: nil, for: nil)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showLoveQuiz) {
                LoveLanguageStep(profile: profile) { showLoveQuiz = false }
                    .background { TetherBackdrop() }
            }
            .sheet(isPresented: $showTrack) {
                WisdomTrackDetailView(track: profile.track)
            }
            .sheet(isPresented: $showScenes) {
                SceneSheet(theme: scene)
                    .presentationDetents([.medium])
            }
            .overlay {
                if switchingLanguage {
                    ZStack {
                        TetherColor.bg.opacity(0.92).ignoresSafeArea()
                        VStack(spacing: TetherSpace.m) {
                            TetherHeroMark(width: 64,
                                           color: TetherColor.brand,
                                           sag: 8,
                                           lineWidth: 4,
                                           dotRadius: 5)
                                .tetherBreathing()
                            Text("Changing language…")
                                .font(TetherType.label)
                                .foregroundStyle(TetherColor.muted)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .alert("Delete all data?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { deleteEverything() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes every entry on this device and destroys the encryption key. It cannot be undone.")
            }
        }
    }

    private func deleteEverything() {
        func purge<T: PersistentModel>(_ type: T.Type) {
            for item in (try? ctx.fetch(FetchDescriptor<T>())) ?? [] { ctx.delete(item) }
        }
        purge(JournalEntry.self)
        purge(MoodLog.self)
        purge(PromptReply.self)
        purge(AIMessage.self)
        purge(AIConversation.self)
        purge(AIMemory.self)
        purge(RelationshipPulse.self)
        purge(Invite.self)
        try? ctx.save()

        // Destroying the key makes any residual ciphertext permanently unreadable.
        CryptoService.shared.destroyKey()
        NotificationService.shared.cancelAll()
        dismiss()
    }
}
