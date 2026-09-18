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
        case .welcome:       WelcomeStep(profile: profile,
                                       onNext: { advance() },
                                       onSkip: { advance() })
        case .track:         TrackStep(profile: profile) { advance() }
        case .loveLanguages: LoveLanguageStep(profile: profile) { advance() }
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

/// The first screen: a quiet, atmospheric landing. The hero carries the
/// Tether mark with gradient spheres; the wordmark sets the voice; tracked
/// captions and a serif headline give the page its rhythm.
struct WelcomeStep: View {
    @Bindable var profile: UserProfile
    let onNext: () -> Void
    var onSkip: () -> Void = {}

    var body: some View {
        ZStack {
            // Atmospheric backdrop. The illustrated landscape is approximated
            // by warm paper + atmosphere + a soft "sunrise" glow.
            TetherBackdrop()
                .overlay {
                    // Warm sun at the horizon
                    Circle()
                        .fill(TetherGradient.celebration.opacity(0.32))
                        .frame(width: 320, height: 320)
                        .blur(radius: 90)
                        .offset(y: 220)
                        .allowsHitTesting(false)

                    // Cool dawn wash at the top
                    Circle()
                        .fill(Color(hex: "8B7BE8").opacity(0.10))
                        .frame(width: 360, height: 360)
                        .blur(radius: 100)
                        .offset(y: -160)
                        .allowsHitTesting(false)
                }

            // Side captions float in the negative space.
            VStack {
                Spacer().frame(height: 320)
                HStack(alignment: .top) {
                    tracked(["YOUR BELIEFS.", "YOUR WAY."], align: .leading)
                    Spacer()
                    tracked(["YOUR JOURNEY.", "TOGETHER."], align: .trailing)
                }
                .padding(.horizontal, TetherSpace.l)
                Spacer()
            }

            // Centre content.
            VStack(spacing: TetherSpace.l) {
                Spacer(minLength: TetherSpace.xxl)
                heroMotif
                wordmark
headline
                    introCopy
                    Spacer()
                buttons
            }
            .padding(.horizontal, TetherSpace.margin)
            .padding(.bottom, TetherSpace.l)

            // Top bar — tracked annotation on the left, Skip on the right.
            VStack {
                HStack(alignment: .top) {
                    tracked(["A DEEPER", "CONNECTION", "EVERYDAY"], align: .leading,
                            color: TetherColor.ink)
                    Spacer()
                    Button("Skip", action: onSkip)
                        .font(TetherType.callout)
                        .foregroundStyle(TetherColor.muted)
                }
                .padding(.horizontal, TetherSpace.l)
                .padding(.top, TetherSpace.xxxl)
                Spacer()
            }
        }
        .background { TetherBackdrop() }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: Pieces

    /// Two gradient spheres connected by a slack curve. The line is a little
    /// softer than the curve we use elsewhere so the hero reads as illustration.
    private var heroMotif: some View {
        ZStack {
            TetherSlackCurve(sag: 22)
                .stroke(TetherColor.brand.opacity(0.55),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .padding(.horizontal, 28)
                .frame(height: 70)

            HStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "B3A4F0"), Color(hex: "6A57D6")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(hex: "4A3AA8").opacity(0.40), radius: 18, y: 12)
                    .shadow(color: .white.opacity(0.4), radius: 1, y: 1)

                Spacer(minLength: 0)

                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "6A57D6"), Color(hex: "3B2C8A")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(hex: "3B2C8A").opacity(0.50), radius: 20, y: 14)
                    .shadow(color: .white.opacity(0.4), radius: 1, y: 1)
            }
            .padding(.horizontal, 28)
        }
        .frame(width: 280, height: 110)
        .accessibilityHidden(true)
    }

    private var wordmark: some View {
        VStack(spacing: TetherSpace.xs) {
            Text("Tether")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .tracking(-1.0)
                .foregroundStyle(TetherColor.ink)
            Text("Two people. One practice.")
                .font(TetherType.callout)
                .foregroundStyle(TetherColor.muted)
        }
    }

    /// "Different paths." (serif regular) and "A deeper connection." (serif italic,
    /// brand colour) — two rhythms on one line break.
    private var headline: some View {
        VStack(spacing: -2) {
            Text("Different paths.")
                .font(.system(size: 30, weight: .regular, design: .serif))
                .foregroundStyle(TetherColor.ink)
            Text("A deeper connection.")
                .font(.system(size: 30, weight: .regular, design: .serif).italic())
                .foregroundStyle(TetherColor.brand)
        }
        .multilineTextAlignment(.center)
    }

    private var introCopy: some View {
        Text("A private space for couples to reflect, understand and grow together — in your own way.")
            .font(TetherType.callout)
            .foregroundStyle(TetherColor.muted)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var buttons: some View {
        VStack(spacing: TetherSpace.s) {
            Button(action: onNext) {
                HStack {
                    Text("Get Started")
                    Spacer(minLength: 0)
                    Icon(.chevronRight, size: 17, color: .white)
                }
            }
            .tetherButton()

            Button(action: onSkip) {
                Text("I already have a code")
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.brand)
                    .frame(maxWidth: .infinity, minHeight: 54)
            }
            .buttonStyle(TetherSecondarySurfaceButtonStyle())
        }
    }

    /// Tracked-caps annotation, vertical, used for the corner labels.
    @ViewBuilder
    private func tracked(_ lines: [String],
                          align: HorizontalAlignment,
                          color: Color = TetherColor.faint) -> some View {
        VStack(alignment: align, spacing: 2) {
            ForEach(lines, id: \.self) { line in
                Text(line)
            }
        }
        .font(TetherType.micro)
        .tracking(1.6)
        .foregroundStyle(color)
    }
}

/// The "I already have a code" button — a white surface card with a soft border.
/// Defined here so the two steps that use it share one source of truth.
private struct TetherSecondarySurfaceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(TetherColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.medium,
                                        style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: TetherRadius.medium, style: .continuous)
                    .strokeBorder(TetherColor.border, lineWidth: 1)
            )
            .tetherShadow(.soft)
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
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
    let profile: UserProfile
    let onNext: () -> Void

    @State private var index = 0
    @State private var picks: [LoveLanguage] = []
    @State private var result: LoveLanguage?
    @State private var skipped = false

    private let questions = LoveLanguageQuiz.questions

    var body: some View {
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

        let entry = JournalEntry(userID: profile.id,
                                 body: SecureContent.seal(text),
                                 mood: mood,
                                 source: .prompt)
        entry.safetyFlagged = verdict.isCrisis
        ctx.insert(entry)
        ctx.insert(MoodLog(userID: profile.id, mood: mood))

        // Mirror HomeView.save(): crisis entries are never distilled into memory.
        if !verdict.isCrisis {
            ctx.insert(CoachEngine.makeMemory(from: text,
                                              ownerID: profile.id,
                                              source: .prompt,
                                              sourceID: entry.id,
                                              visibility: entry.visibility))
        }

        try? ctx.save()
        onFinish()
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
