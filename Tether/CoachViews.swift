import SwiftUI
import SwiftData
import UIKit

struct CoachView: View {
    @Bindable var profile: UserProfile
    /// When true the view is hosted in the tab bar, so it drops the modal
    /// chrome (Close button, inline title) and presents as a full screen.
    var isTab: Bool = false

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \AIMessage.createdAt) private var allMessages: [AIMessage]
    @Query private var allMemories: [AIMemory]

    @State private var conversation: AIConversation?
    @State private var draft = ""
    @State private var isThinking = false
    @State private var crisis: SafetyVerdict?
    @State private var showPrivacy = false
    @State private var store = PurchaseService.shared
    @State private var showPaywall = false
    @State private var voice = VoiceInput.shared

    private var freeMessagesUsed: Int {
        let start = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return messages.filter { $0.role == .user && $0.createdAt >= start }.count
    }

    private var isBlocked: Bool {
        !store.hasAccess && freeMessagesUsed >= 5
    }

    private var messages: [AIMessage] {
        guard let conversation else { return [] }
        return allMessages.filter { $0.conversationID == conversation.id }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: TetherSpace.m) {
                            introCard

                            if messages.isEmpty {
                                suggestionRow
                                    .tetherAppear(delay: 0.05)
                            }

                            ForEach(messages) { message in
                                CoachBubble(message: message,
                                            track: profile.track)
                                    .id(message.id)
                            }

                            if let crisis {
                                SafetyResourceCard(verdict: crisis)
                                    .id("crisis")
                            }

                            if isThinking {
                                HStack(spacing: TetherSpace.s) {
                                    ProgressView().tint(TetherColor.brand)
                                    Text("Thinking…")
                                        .font(TetherType.caption)
                                        .foregroundStyle(TetherColor.muted)
                                }
                                .padding(.vertical, TetherSpace.s)
                                .id("thinking")
                            }
                        }
                    .padding(TetherSpace.margin)
                    .readableFrame()
                }
                .scrollDismissesKeyboard(.interactively)
                    .onChange(of: messages.count) { _, _ in
                        scrollToEnd(proxy)
                    }
                    .onChange(of: crisis != nil) { _, _ in
                        scrollToEnd(proxy)
                    }
                }

                inputBar
            }
            .background { TetherBackdrop() }
            .navigationTitle("Coach")
            .navigationBarTitleDisplayMode(isTab ? .large : .inline)
            .toolbar {
                if !isTab {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showPrivacy = true
                    } label: {
                        Icon(.privacy, size: 20, color: TetherColor.muted)
                    }
                    .accessibilityLabel("Privacy")
                }
            }
            .sheet(isPresented: $showPrivacy) { privacySheet }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: voice.transcript) { _, spoken in
                guard voice.isRecording, !spoken.isEmpty else { return }
                draft = spoken
            }
            .onDisappear { voice.stop() }
            .task { ensureConversation() }
        }
    }

    // MARK: - Pieces

    /// The Coach's presence header: whose voice it speaks in, what it currently
    /// holds, and how many messages are left. Stops the screen reading as a
    /// blank chat window — it should feel like a quiet guide who knows context.
    private var introCard: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                HStack(alignment: .top, spacing: TetherSpace.m) {
                    VStack(alignment: .leading, spacing: TetherSpace.xs) {
                        Text("A coach, not a therapist")
                            .font(TetherType.label)
                            .foregroundStyle(TetherColor.ink)
                        Text("It speaks from your \(profile.track.shortName) track, and it remembers what you have written.")
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    // Track identity — whose voice this is.
                    TetherHeroMark(width: 52, color: profile.track.accent, sag: 7)
                }

                // What the coach is currently holding.
                HStack(spacing: TetherSpace.s) {
                    TetherHeroMark(width: 30, color: TetherColor.brand, sag: 4,
                                   lineWidth: 1.5, dotRadius: 2.5)
                    Text(memorySummary)
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                    Spacer(minLength: 0)
                }

                if !store.hasAccess {
                    Text(isBlocked
                         ? "You have used your 5 free messages this month."
                         : "\(max(0, 5 - freeMessagesUsed)) free messages left this month.")
                        .font(TetherType.caption)
                        .foregroundStyle(isBlocked ? TetherColor.strained : TetherColor.muted)
                }
            }
        }
    }

    private var memorySummary: String {
        let count = allMemories.filter { $0.ownerID == profile.id }.count
        guard count > 0 else { return "Nothing remembered yet" }
        return "Remembering \(count) \(count == 1 ? "thing" : "things") you have told me"
    }

    // MARK: - Suggested openings

    /// Ways in, so a first-time conversation never starts from a blank box.
    private let suggestions = [
        "How do I bring up something that's been bothering me?",
        "We keep having the same argument — what actually helps?",
        "I want to feel closer. Where do I start?"
    ]

    private var suggestionRow: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            Text("TRY ASKING")
                .font(TetherType.micro)
                .foregroundStyle(TetherColor.faint)
                .tracking(1)

            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    draft = suggestion
                    TetherHaptics.tap()
                } label: {
                    HStack(spacing: TetherSpace.m) {
                        Text(suggestion)
                            .font(TetherType.callout)
                            .foregroundStyle(TetherColor.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        TetherHeroMark(width: 26, color: TetherColor.faint, sag: 4,
                                       lineWidth: 1.5, dotRadius: 2)
                    }
                    .padding(TetherSpace.m)
                    .background(TetherColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium,
                                                style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: TetherRadius.medium, style: .continuous)
                            .strokeBorder(TetherColor.border, lineWidth: 1)
                    )
                    .tetherShadow(.soft)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ask: \(suggestion)")
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: TetherSpace.s) {
                TextField("Ask anything", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .font(TetherType.body)
                    .foregroundStyle(TetherColor.text)
                    .tint(TetherColor.brand)
                    .padding(.horizontal, TetherSpace.m)
                    .padding(.vertical, TetherSpace.s)
                    .background(TetherColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium))

                Button {
                    Task { await voice.toggle() }
                } label: {
                    ZStack {
                        if voice.isRecording {
                            Circle()
                                .fill(TetherColor.strained.opacity(0.14 + voice.level * 0.30))
                                .frame(width: 40 + voice.level * 10,
                                       height: 40 + voice.level * 10)
                        }
                        Icon(.mic, size: 19,
                             color: voice.isRecording ? TetherColor.strained : TetherColor.muted)
                    }
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .animation(.easeOut(duration: 0.12), value: voice.level)
                .accessibilityLabel(voice.isRecording ? "Stop dictation" : "Start dictation")

                Button {
                    Task { await send() }
                } label: {
                    Icon(.send, size: 19, color: canSend ? .white : TetherColor.faint)
                        .frame(width: 40, height: 40)
                        .background(canSend ? AnyShapeStyle(TetherGradient.brand)
                                            : AnyShapeStyle(TetherColor.border))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .accessibilityLabel("Send")
            }
            .padding(.horizontal, TetherSpace.margin)
            .padding(.vertical, TetherSpace.s)

            Text("Tether is not therapy and not a crisis service.")
                .font(.system(size: 11))
                .foregroundStyle(TetherColor.muted)
                .padding(.bottom, TetherSpace.s)
        }
        .background(TetherColor.surface)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { dismissKeyboard() }
            }
        }
    }

    private var privacySheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.m) {
                    Label("Your conversations are private", systemImage: "lock.shield")
                        .font(TetherType.label)
                    Text("Your coach conversations are never shown to your partner, and never sent to analytics. Encryption is on the roadmap and ships before any sync exists.")
                        .font(TetherType.callout)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    Divider()
                    Text("A safety check runs on everything you type. If it detects a crisis, the app stops generating a normal reply and shows you support lines instead. Your partner is never told.")
                        .font(TetherType.callout)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(TetherSpace.margin)
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showPrivacy = false }
                }
            }
        }
    }

    // MARK: - Logic

    private var canSend: Bool {
        !draft.trimmed.isEmpty && !isThinking
    }

    /// Resigns the first responder so the keyboard can be dismissed from the
    /// input bar — there is no other "back" affordance while typing in Coach.
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    private func ensureConversation() {
        guard conversation == nil else { return }
        let existing = (try? ctx.fetch(FetchDescriptor<AIConversation>())) ?? []
        if let mine = existing.first(where: { $0.ownerID == profile.id }) {
            conversation = mine
        } else {
            let new = AIConversation(ownerID: profile.id, title: "Coach")
            ctx.insert(new)
            try? ctx.save()
            conversation = new
        }
    }

    private func send() async {
        guard !isThinking else { return }
        guard let conversation, canSend else { return }
        if isBlocked {
            showPaywall = true
            return
        }
        TetherHaptics.light()
        let text = draft.trimmed
        draft = ""

        let userMessage = AIMessage(conversationID: conversation.id,
                                    role: .user,
                                    body: SecureContent.seal(text))
        ctx.insert(userMessage)
        conversation.lastMessageAt = Date()
        try? ctx.save()

        // The user's own words become memory for future retrieval.
        let memory = CoachEngine.makeMemory(from: text,
                                            ownerID: profile.id,
                                            source: .coach,
                                            sourceID: userMessage.id,
                                            visibility: .private)
        ctx.insert(memory)
        try? ctx.save()

        isThinking = true
        let history = messages
        let memories = allMemories.filter { $0.ownerID == profile.id }

        let response = await CoachEngine.respond(to: text,
                                                ownerID: profile.id,
                                                track: profile.track,
                                                memories: memories,
                                                history: history)
        isThinking = false

        if response.verdict.isCrisis {
            userMessage.safetyFlagged = true
            crisis = response.verdict
            try? ctx.save()
            return
        }

        let assistant = AIMessage(conversationID: conversation.id,
                                  role: .assistant,
                                  body: SecureContent.seal(response.text),
                                  usedMemory: response.usedMemory)
        ctx.insert(assistant)
        conversation.lastMessageAt = Date()
        try? ctx.save()
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            if crisis != nil {
                proxy.scrollTo("crisis", anchor: .bottom)
            } else if let last = messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Bubble

struct CoachBubble: View {
    let message: AIMessage
    let track: WisdomTrack

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            VStack(alignment: message.role == .user ? .trailing : .leading,
                   spacing: TetherSpace.xs) {
                if message.role == .assistant && message.usedMemory {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                        .accessibilityHidden(true)
                            .font(.system(size: 10))
                        Text("Remembering")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(TetherColor.brand)
                }

                Text(SecureContent.read(message.body))
                    .font(TetherType.callout)
                    .foregroundStyle(message.role == .user ? .white : TetherColor.text)
                    .padding(TetherSpace.m)
                    .background(message.role == .user ? TetherColor.brand : TetherColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium, style: .continuous))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if message.role == .assistant { Spacer(minLength: 40) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.role == .user
                            ? "You said: \(SecureContent.read(message.body))"
                            : "Coach said: \(SecureContent.read(message.body))")
    }
}

// MARK: - Safety card

struct SafetyResourceCard: View {
    let verdict: SafetyVerdict

    var body: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            Text(SafetyResources.headline(for: verdict.category))
                .font(TetherType.headline)
                .foregroundStyle(TetherColor.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(SafetyResources.body(for: verdict.category))
                .font(TetherType.callout)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(SafetyResources.forCategory(verdict.category)) { resource in
                VStack(alignment: .leading, spacing: 2) {
                    Text(resource.name)
                        .font(TetherType.label)
                        .foregroundStyle(TetherColor.text)
                    Text(resource.detail)
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if let phone = resource.phone {
                        Text(phone)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(TetherColor.brand)
                            .padding(.top, 2)
                    }
                }
                .padding(TetherSpace.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TetherColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small))
            }

            Text("Your partner is not told about this.")
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Crisis support resources")
    }
}
