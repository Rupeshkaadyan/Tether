import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable {
    case welcome, track, loveLanguages, firstPrompt

    var title: String {
        switch self {
        case .welcome:       return "Two people. One practice."
        case .track:         return "What wisdom speaks to you?"
        case .loveLanguages: return "How do you feel loved?"
        case .firstPrompt:   return "Your first prompt"
        }
    }
}

struct OnboardingFlow: View {
    @Bindable var profile: UserProfile
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var ctx
    @State private var step: OnboardingStep = .welcome

    var body: some View {
        VStack(spacing: 0) {
            if step != .welcome {
                progressBar
            }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(TetherColor.bg)
        .animation(.easeOut(duration: 0.25), value: step)
    }

    private var progressBar: some View {
        ProgressView(value: Double(step.rawValue + 1),
                     total: Double(OnboardingStep.allCases.count))
            .tint(TetherColor.brand)
            .padding(.horizontal, TetherSpace.margin)
            .padding(.top, TetherSpace.m)
            .accessibilityLabel("Step \(step.rawValue + 1) of \(OnboardingStep.allCases.count)")
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:       WelcomeStep(profile: profile) { advance() }
        case .track:         TrackStep(profile: profile) { advance() }
        case .loveLanguages: LoveLanguageStep { advance() }
        case .firstPrompt:   FirstPromptStep(profile: profile) { finish() }
        }
    }

    private func advance() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { finish(); return }
        profile.onboardingStep = next.rawValue
        try? ctx.save()
        step = next
    }

    private func finish() {
        profile.onboardingDone = true
        profile.onboardingStep = OnboardingStep.allCases.count
        try? ctx.save()
    }
}

// MARK: - Step 1: Welcome

struct WelcomeStep: View {
    @Bindable var profile: UserProfile
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            hero

            VStack(alignment: .leading, spacing: TetherSpace.xl) {
                Text("A quiet daily ritual you share with one person. You can begin on your own — everything is here waiting when they join.")
                    .font(TetherType.body)
                    .foregroundStyle(TetherColor.muted)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: TetherSpace.s) {
                    Text("What should we call you?")
                        .font(TetherType.label)
                        .foregroundStyle(TetherColor.text)
                    TextField("Your name", text: $profile.displayName)
                        .font(TetherType.body)
                        .padding(TetherSpace.l)
                        .background(TetherColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: TetherRadius.medium, style: .continuous)
                                .strokeBorder(TetherColor.border, lineWidth: 1)
                        )
                        .tetherShadow(.soft)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                }

                Spacer(minLength: TetherSpace.l)

                Button("Get started", action: onNext)
                    .tetherButton()
                    .disabled(profile.displayName.trimmed.isEmpty)
                    .opacity(profile.displayName.trimmed.isEmpty ? 0.45 : 1)
            }
            .padding(TetherSpace.margin)
        }
        .background(TetherColor.bg)
        .ignoresSafeArea(edges: .bottom)
    }

    private var hero: some View {
        ZStack {
            TetherBackdrop(style: .dusk)

            VStack(spacing: TetherSpace.xl) {
                TetherMark(size: 148,
                           lineColor: .white.opacity(0.92),
                           dotColor: .white,
                           lineWidth: 15)

                VStack(spacing: 6) {
                    Text("Tether")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Two people. One practice.")
                        .font(TetherType.callout)
                        .foregroundStyle(.white.opacity(0.82))
                }
            }
            .padding(.top, TetherSpace.xxxl)
            .padding(.bottom, TetherSpace.xxl)
        }
        .frame(height: 400)
        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 44,
                                          bottomTrailingRadius: 44,
                                          style: .continuous))
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Step 2: Wisdom track

struct TrackStep: View {
    @Bindable var profile: UserProfile
    let onNext: () -> Void

    @State private var selection: WisdomTrack?

    var body: some View {
        VStack(alignment: .leading, spacing: TetherSpace.l) {
            VStack(alignment: .leading, spacing: TetherSpace.s) {
                Text("What wisdom speaks to you?")
                    .font(TetherType.title)
                    .foregroundStyle(TetherColor.ink)
                Text("This is yours alone. Your partner chooses their own.")
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.muted)
            }
            .padding(.top, TetherSpace.xxl)

            VStack(spacing: TetherSpace.m) {
                ForEach(WisdomTrack.allCases) { track in
                    WisdomTrackCard(track: track, isSelected: selection == track) {
                        guard track.isLive else { return }
                        selection = track
                    }
                }
            }

            Text("You can change this anytime in Settings.")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)

            Spacer()

            Button("Continue") {
                if let selection { profile.track = selection }
                onNext()
            }
            .tetherButton()
            .disabled(selection == nil)
            .opacity(selection == nil ? 0.5 : 1)
        }
        .padding(TetherSpace.margin)
        .onAppear { selection = profile.track }
    }
}

// MARK: - Step 3: Love languages

struct LoveLanguageStep: View {
    let onNext: () -> Void

    @State private var index = 0
    @State private var picks: [LoveLanguage] = []
    @State private var result: LoveLanguage?

    private let questions = LoveLanguageQuiz.questions

    var body: some View {
        Group {
            if let result {
                resultView(result)
            } else {
                questionView
            }
        }
        .padding(TetherSpace.margin)
        .animation(.easeOut(duration: 0.25), value: result != nil)
    }

    private var questionView: some View {
        VStack(alignment: .leading, spacing: TetherSpace.xl) {
            Spacer(minLength: TetherSpace.xxl)

            Text("How do you feel loved?")
                .font(TetherType.title)
                .foregroundStyle(TetherColor.ink)

            Text("Question \(index + 1) of \(questions.count)")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)

            Text(questions[index].prompt)
                .font(TetherType.headline)
                .foregroundStyle(TetherColor.text)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: TetherSpace.m) {
                optionButton(questions[index].left)
                optionButton(questions[index].right)
            }

            Spacer()

            Button("Skip") {
                result = .words
            }
            .tetherButton(.tertiary)
        }
    }

    private func optionButton(_ language: LoveLanguage) -> some View {
        Button {
            picks.append(language)
            if index + 1 < questions.count {
                index += 1
            } else {
                result = LoveLanguageQuiz.result(from: picks)
            }
        } label: {
            HStack {
                Image(systemName: language.symbol)
                Text(language.displayName)
                Spacer()
            }
            .font(TetherType.label)
            .foregroundStyle(TetherColor.ink)
            .padding()
            .frame(maxWidth: .infinity)
            .background(TetherColor.tint)
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium))
        }
        .buttonStyle(.plain)
    }

    private func resultView(_ language: LoveLanguage) -> some View {
        VStack(alignment: .leading, spacing: TetherSpace.xl) {
            Spacer(minLength: TetherSpace.xxl)

            Image(systemName: language.symbol)
                .font(.system(size: 40))
                .foregroundStyle(TetherColor.brand)

            Text("Your primary love language")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)

            Text(language.displayName)
                .font(TetherType.display)
                .foregroundStyle(TetherColor.ink)

            Text("This is a lens, not a verdict. It is a starting point for noticing what actually lands.")
                .font(TetherType.body)
                .foregroundStyle(TetherColor.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button("Continue", action: onNext)
                .tetherButton()
        }
    }
}

// MARK: - Step 4: First prompt

struct FirstPromptStep: View {
    @Bindable var profile: UserProfile
    let onFinish: () -> Void

    @Environment(\.modelContext) private var ctx
    @State private var mood = 3
    @State private var reply = ""

    private var prompt: Prompt {
        PromptLibrary.prompt(for: profile.track, dayIndex: 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TetherSpace.l) {
                Text("Your first prompt")
                    .font(TetherType.title)
                    .foregroundStyle(TetherColor.ink)
                    .padding(.top, TetherSpace.xxl)

                PromptCard(prompt: prompt, dayLabel: "Today")

                VStack(alignment: .leading, spacing: TetherSpace.s) {
                    Text("How are you today?")
                        .font(TetherType.label)
                    MoodRow(selection: $mood)
                }

                VStack(alignment: .leading, spacing: TetherSpace.s) {
                    Text("Your response")
                        .font(TetherType.label)
                    TextField("One sentence is enough", text: $reply, axis: .vertical)
                        .lineLimit(3...6)
                        .font(TetherType.body)
                        .padding()
                        .background(TetherColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: TetherRadius.medium)
                                .strokeBorder(TetherColor.border, lineWidth: 1)
                        )
                }

                Button("Begin") { save() }
                    .tetherButton()
                    .disabled(reply.trimmed.isEmpty)
                    .opacity(reply.trimmed.isEmpty ? 0.5 : 1)

                Text("You can do this in under a minute. That is the whole point.")
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
            }
        }
        .padding(TetherSpace.margin)
        .scrollDismissesKeyboard(.interactively)
    }

    private func save() {
        let entry = JournalEntry(userID: profile.id,
                                 body: reply.trimmed,
                                 mood: mood,
                                 source: .prompt)
        ctx.insert(entry)
        let log = MoodLog(userID: profile.id, mood: mood)
        ctx.insert(log)
        try? ctx.save()
        onFinish()
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
