import SwiftUI
import SwiftData

/// The order matters more than it looks.
///
/// It used to run welcome → track → loveLanguages → firstPrompt, which meant a
/// new person answered a love-language quiz BEFORE they ever saw the product
/// do its one job. Four steps of setup to reach the first moment of value.
///
/// Now the first real question comes as soon as it honestly can — it needs the
/// wisdom track, so it cannot precede that — and the optional quiz moves to
/// the end, where skipping it costs nothing.
///
/// Note: reordering shifts the raw values, and `onboardingStep` is persisted.
/// Only affects someone mid-onboarding at upgrade time, which at this point is
/// nobody.
enum OnboardingStep: Int, CaseIterable {
    case welcome, track, firstPrompt, loveLanguages

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
        .background { TetherBackdrop() }
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
        // firstPrompt now advances rather than finishing, because the optional
        // quiz follows it. Leaving it as finish() would have skipped the last
        // step entirely — the reorder would have silently dropped a screen.
        case .welcome:       WelcomeStep(profile: profile) { advance() }
        case .track:         TrackStep(profile: profile) { advance() }
        case .firstPrompt:   FirstPromptStep(profile: profile) { advance() }
        case .loveLanguages: LoveLanguageStep(profile: profile) { finish() }
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

            // Scrollable, because a fixed VStack here overflowed: the 400pt
            // hero plus the form exceeded the screen and 'Get started' fell
            // off the bottom edge entirely.
            ScrollView {
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
                        .tetherField()
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                }

                // Asked because it is the fastest way to a right-looking app:
                // it sets the DEFAULT accent below. It does not replace that
                // picker and it does not gate anything — every option is one
                // tap from every other, and "Prefer not to say" is a real
                // answer that changes nothing.
                VStack(alignment: .leading, spacing: TetherSpace.s) {
                    Text("About you")
                        .font(TetherType.label)
                        .foregroundStyle(TetherColor.text)
                    Text("This only picks your starting colour. Change it any time.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    // Two columns, because four stacked rows push the tone
                    // picker and the button off the bottom of the screen —
                    // the exact overflow this ScrollView exists to prevent.
                    LazyVGrid(columns: [GridItem(.flexible()),
                                        GridItem(.flexible())],
                              spacing: TetherSpace.s) {
                        ForEach(Gender.allCases) { option in
                            Button {
                                profile.genderRaw = option.rawValue
                                FeelManager.shared.raw = option.preferredFeel.rawValue
                                TetherHaptics.light()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: option.symbol)
                                        .font(.system(size: 12))
                                    Text(option.title)
                                        .font(TetherType.caption)
                                }
                                .foregroundStyle(profile.genderRaw == option.rawValue
                                                 ? .white : TetherColor.text)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(profile.genderRaw == option.rawValue
                                            ? AnyShapeStyle(TetherGradient.brand)
                                            : AnyShapeStyle(TetherColor.surface))
                                .clipShape(RoundedRectangle(
                                    cornerRadius: TetherRadius.small,
                                    style: .continuous))
                                .overlay(
                                    RoundedRectangle(
                                        cornerRadius: TetherRadius.small,
                                        style: .continuous)
                                        .strokeBorder(
                                            profile.genderRaw == option.rawValue
                                            ? .clear : TetherColor.border,
                                            lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(
                                profile.genderRaw == option.rawValue
                                ? [.isSelected] : [])
                        }
                    }
                }

                // The tone. Gender above sets this by default; this is where
                // anyone overrides it, and it includes people who do not fit
                // either box — which is why it stays.
                VStack(alignment: .leading, spacing: TetherSpace.s) {
                    Text("How should it feel?")
                        .font(TetherType.label)
                        .foregroundStyle(TetherColor.text)
                    Text("You can change this any time in Settings.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: TetherSpace.s) {
                        ForEach(FeelManager.Feel.allCases) { option in
                            let selected = FeelManager.shared.feel == option
                            Button {
                                FeelManager.shared.raw = option.rawValue
                            } label: {
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(option == .warm
                                              ? AnyShapeStyle(LinearGradient(
                                                    colors: [Color(hex: "C4608A"), Color(hex: "8E3A61")],
                                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                              : AnyShapeStyle(LinearGradient(
                                                    colors: [Color(hex: "6A57D6"), Color(hex: "4A3AA8")],
                                                    startPoint: .topLeading, endPoint: .bottomTrailing)))
                                        .frame(width: 28, height: 28)
                                    Text(option.title)
                                        .font(TetherType.label)
                                        .foregroundStyle(selected ? TetherColor.text : TetherColor.muted)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, TetherSpace.m)
                                .background(TetherColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small,
                                                            style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: TetherRadius.small,
                                                    style: .continuous)
                                        .strokeBorder(selected ? TetherColor.brand : TetherColor.border,
                                                      lineWidth: selected ? 2 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(selected ? [.isSelected] : [])
                        }
                    }
                }

                Button("Get started", action: onNext)
                    .tetherButton()
                    .disabled(profile.displayName.trimmed.isEmpty)
                    .opacity(profile.displayName.trimmed.isEmpty ? 0.45 : 1)
                    .padding(.top, TetherSpace.s)
                }
                .padding(TetherSpace.margin)
                .padding(.bottom, TetherSpace.xl)
                .readableFrame()
            }
        }
        .background { TetherBackdrop() }
    }

    private var hero: some View {
        ZStack {
            // The real landscape, so the first thing anyone sees is the world
            // the app actually lives in — not a flat backdrop.
            TetherScene(timeOfDay: .dusk)

            // Scrim, so the mark and the wordmark hold against the sky.
            LinearGradient(colors: [.black.opacity(0.18), .clear, .black.opacity(0.28)],
                           startPoint: .top,
                           endPoint: .bottom)

            VStack(spacing: TetherSpace.xl) {
                TetherMark(size: 148,
                           lineColor: .white.opacity(0.92),
                           dotColor: .white,
                           lineWidth: 15)

                VStack(spacing: 6) {
                    Text("Tether")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .tracking(-0.9)
                        .foregroundStyle(.white)
                    Text("Two people. One practice.")
                        .font(TetherType.callout)
                        .foregroundStyle(.white.opacity(0.82))
                }
            }
            .padding(.top, TetherSpace.xxxl)
            .padding(.bottom, TetherSpace.xxl)
        }
        // Shorter than it was: at 400pt the hero alone ate half the screen,
        // which is what pushed the form off the bottom.
        .frame(height: 288)
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
        // Scrollable: four track cards plus the header exceeded a short screen
        // and clipped the Continue button.
        ScrollView {
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
            .padding(.bottom, TetherSpace.xl)
            .readableFrame()
        }
        .onAppear { selection = profile.track }
    }
}

// MARK: - Step 3: Love languages

struct LoveLanguageStep: View {
    let profile: UserProfile
    let onNext: () -> Void

    @State private var index = 0
    @State private var picks: [LoveLanguage] = []
    @State private var result: LoveLanguage?
    @State private var skipped = false

    private let questions = LoveLanguageQuiz.questions

    var body: some View {
        // Scrollable: the question view carries five answer rows plus its own
        // button, which did not fit on a short screen.
        ScrollView {
            Group {
                if skipped {
                    skipView
                } else if let result {
                    resultView(result)
                } else {
                    questionView
                }
            }
            .padding(TetherSpace.margin)
            .padding(.bottom, TetherSpace.xl)
            .readableFrame()
        }
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
                skipped = true
            }
            .tetherButton(.tertiary)
        }
    }

    private func optionButton(_ language: LoveLanguage) -> some View {
        Button {
            TetherHaptics.light()
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

            Button {
                if let result { LoveLanguageStore.set(result, for: profile.id) }
                onNext()
            } label: {
                Text("Continue")
            }
            .tetherButton()
        }
    }

    private var skipView: some View {
        VStack(alignment: .leading, spacing: TetherSpace.xl) {
            Spacer(minLength: TetherSpace.xxl)

            Image(systemName: "heart")
            .accessibilityHidden(true)
                .font(.system(size: 40))
                .foregroundStyle(TetherColor.brand)

            Text("No love language for now")
                .font(TetherType.display)
                .foregroundStyle(TetherColor.ink)

            Text("That's completely fine. You can take the quiz any time from Settings to personalise your insights.")
                .font(TetherType.body)
                .foregroundStyle(TetherColor.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button { onNext() } label: {
                Text("Continue")
            }
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
                        .tetherField()
                }

                Button("Begin") { save() }
                    .tetherButton()
                    .disabled(reply.trimmed.isEmpty)
                    .opacity(reply.trimmed.isEmpty ? 0.5 : 1)

                // An exit. Requiring a first answer with no way past it is a
                // dead end for anyone staring at a blank field and not knowing
                // what to say — and that is a large share of people on the
                // first screen of a journal.
                if reply.trimmed.isEmpty {
                    Button("Skip for now") { save() }
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .underline()
                        .buttonStyle(.plain)
                }

                Text("You can do this in under a minute. That is the whole point.")
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
            }
        }
        .padding(TetherSpace.margin)
        .scrollDismissesKeyboard(.interactively)
    }

    private func save() {
        let text = reply.trimmed
        let verdict = SafetyClassifier.classify(text)

        ctx.insert(MoodLog(userID: profile.id, mood: mood))

        // Only written when there is something to write. Skipping must not
        // leave an empty entry behind — an empty card in your journal is
        // worse than no card, and it would count toward your streak.
        if !text.isEmpty {
            let entry = JournalEntry(userID: profile.id,
                                     body: SecureContent.seal(text),
                                     mood: mood,
                                     source: .prompt)
            entry.safetyFlagged = verdict.isCrisis
            ctx.insert(entry)

            // Mirror HomeView.save(): crisis entries are never distilled into
            // retrievable memory.
            if !verdict.isCrisis {
                ctx.insert(CoachEngine.makeMemory(from: text,
                                                  ownerID: profile.id,
                                                  source: .prompt,
                                                  sourceID: entry.id,
                                                  visibility: entry.visibility))
            }
        }

        try? ctx.save()
        onFinish()
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
