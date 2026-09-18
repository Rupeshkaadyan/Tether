import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var ctx

    @Bindable var profile: UserProfile
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \PromptReply.createdAt, order: .reverse) private var replies: [PromptReply]
    @Query(sort: \MoodLog.createdAt, order: .reverse) private var moods: [MoodLog]
    @Query private var allProfiles: [UserProfile]

    @State private var mood = 3
    @State private var reply = ""
    @State private var showSettings = false
    @State private var showSaved = false
    @State private var showPairing = false
    @State private var showRecap = false
    @State private var showNotifExplainer = false
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
                    PulseCard(result: pulse) { onOpenPulse() }
                    PromptCard(prompt: todayPrompt, dayLabel: Date().weekdayDisplay)

                    if todayAnswered {
                        answeredToday
                    } else {
                        composer
                    }

                    Button("Ask the coach") { onOpenCoach() }
                        .tetherButton()
                        .padding(.top, TetherSpace.s)

                    Button("View weekly recap") { showRecap = true }
                        .tetherButton(.secondary)
                }
                .padding(TetherSpace.margin)
            }
            .background(TetherColor.bg)
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView(profile: profile)
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

    private var header: some View {
        HStack(alignment: .center, spacing: TetherSpace.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(greetingWord) · \(Date().shortDisplay)")
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
                Text(profile.displayName)
                    .font(TetherType.largeTitle)
                    .foregroundStyle(TetherColor.text)
            }
            Spacer(minLength: 0)
            StreakRing(count: streak)
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(TetherColor.muted)
                    .frame(width: 42, height: 42)
                    .background(TetherColor.surface)
                    .clipShape(Circle())
                    .tetherShadow(.soft)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.top, TetherSpace.s)
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
                Text("How are you today?")
                    .font(TetherType.label)
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
                }
                TextField("One sentence is enough", text: $reply, axis: .vertical)
                    .lineLimit(2...6)
                    .tetherField()
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
                    .foregroundStyle(TetherColor.thriving)
                Text("Saved for today")
                    .font(TetherType.label)
                    .foregroundStyle(TetherColor.thriving)
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
            Button("Add another note") { reply = "" }
                .tetherButton(.tertiary)
        }
    }

    // MARK: - Recent

    @ViewBuilder
    private var recentList: some View {
        if myEntries.isEmpty {
            TetherCard {
                VStack(alignment: .leading, spacing: TetherSpace.s) {
                    Text("Your journal starts here")
                        .font(TetherType.label)
                    Text("Mood and one line a day. Entries will appear here as you go.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                }
            }
        } else {
            ForEach(myEntries.prefix(10)) { entry in
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
    @State private var showDeleteConfirm = false

    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var allEntries: [JournalEntry]
    @Query private var allMessages: [AIMessage]
    @Query private var allMemories: [AIMemory]
    @Query private var allProfiles: [UserProfile]

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return allProfiles.first { $0.id == id }
    }

    private var exportDocument: String {
        ExportService.markdown(profile: profile,
                               partner: partner,
                               entries: allEntries,
                               messages: allMessages,
                               memories: allMemories)
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
                                        .foregroundStyle(TetherColor.brand)
                                }
                            }
                        }
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
                    ShareLink(item: exportDocument,
                              preview: SharePreview("Your Tether export")) {
                        HStack {
                            Label("Export everything", systemImage: "square.and.arrow.up")
                                .font(TetherType.label)
                            Spacer()
                            Icon(.download, size: 17, color: TetherColor.faint)
                        }
                    }
                    Text("A readable copy of your journal, coach conversations, and memories. It leaves the encrypted store, so keep it somewhere safe.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
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
