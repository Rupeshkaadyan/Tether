import SwiftData
import SwiftUI

// MARK: - A quiet week
//
// Every other couples app is built to maximise engagement, which is why none
// of them has this. A pause button works against the business model.
//
// But the alternative is what already happens everywhere: one person quietly
// goes silent and the other spends the week not knowing why, filling the gap
// with the worst story available. This turns a withdrawal into a message.
//
// Nothing here is a failure state. No streak breaks, no guilt, no "you missed
// 3 days". The app simply stops talking to both of them for a while.

struct PauseView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Pause.createdAt, order: .reverse) private var pauses: [Pause]
    @Query private var profiles: [UserProfile]

    @State private var note = ""
    @State private var days = 7
    @State private var confirming = false

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return profiles.first { $0.id == id }
    }

    private var active: Pause? { pauses.first { $0.isActive } }

    /// A pause the PARTNER asked for — the one you need to be told about.
    private var theirPause: Pause? {
        guard let p = active, p.startedByID != profile.id else { return nil }
        return p
    }

    private var myPause: Pause? {
        guard let p = active, p.startedByID == profile.id else { return nil }
        return p
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.xl) {
                    if let theirPause {
                        theirPauseCard(theirPause)
                    } else if let myPause {
                        myPauseCard(myPause)
                    } else {
                        explainer
                        lengthPicker
                        noteField
                        startButton
                    }
                }
                .padding(TetherSpace.margin)
                .readableFrame()
                .padding(.bottom, TetherSpace.xxl)
            }
            .background { TetherBackdrop() }
            .navigationTitle("Quiet week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Start a quiet week?", isPresented: $confirming) {
                Button("Cancel", role: .cancel) {}
                Button("Start it") { start() }
            } message: {
                Text(partner == nil
                     ? "Tether will stop reminding you until it ends."
                     : "\(partner?.displayName ?? "They") will see that you asked for quiet — not why you stopped. No reminders for either of you until it ends.")
            }
        }
    }

    // MARK: Yours

    private var explainer: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            Text("Not a fight. Not silence.")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(TetherColor.ink)

            Text("Sometimes a week is just too much. Saying so is kinder than disappearing — the other person gets to know it is not about them, instead of guessing.")
                .font(TetherType.body)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var lengthPicker: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            SectionHeader(title: "How long")
            HStack(spacing: TetherSpace.s) {
                ForEach([3, 7, 14], id: \.self) { option in
                    Button {
                        days = option
                        TetherHaptics.light()
                    } label: {
                        Text("\(option) days")
                            .font(TetherType.label)
                            .foregroundStyle(days == option ? .white : TetherColor.text)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(days == option
                                        ? AnyShapeStyle(TetherGradient.brand)
                                        : AnyShapeStyle(TetherColor.surface))
                            .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small,
                                                        style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            SectionHeader(title: "Anything they should know?")
            TextField("Optional. \"Work is heavy.\" \"I'm not well.\"",
                      text: $note, axis: .vertical)
                .lineLimit(2...5)
                .tetherField()
            Text("Shown to them. Keep it to what you want them to hold.")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.faint)
        }
    }

    private var startButton: some View {
        Button("Ask for a quiet week") { confirming = true }
            .tetherButton()
    }

    // MARK: Theirs

    private func theirPauseCard(_ pause: Pause) -> some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            HStack(spacing: TetherSpace.s) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 18))
                    .foregroundStyle(TetherColor.brand)
                Text("\(partner?.displayName ?? "They") asked for quiet")
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.text)
            }

            Text("This is not about you. They asked for space, and told you so — which is the opposite of disappearing.")
                .font(TetherType.body)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)

            if !pause.note.isEmpty {
                Text("“\(pause.note)”")
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundStyle(TetherColor.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(TetherSpace.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TetherColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TetherRadius.small,
                                                style: .continuous))
            }

            Text(pause.daysRemaining == 1
                 ? "Ends tomorrow."
                 : "\(pause.daysRemaining) days left.")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.faint)

            Text("Tether will not remind either of you until then.")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.faint)
        }
    }

    private func myPauseCard(_ pause: Pause) -> some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            HStack(spacing: TetherSpace.s) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 18))
                    .foregroundStyle(TetherColor.brand)
                Text("You asked for quiet")
                    .font(TetherType.callout)
                    .foregroundStyle(TetherColor.text)
            }

            Text("Nothing is expected of you until this ends. No reminders, no streaks at risk, nothing to catch up on.")
                .font(TetherType.body)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)

            Text(pause.daysRemaining == 1
                 ? "Ends tomorrow."
                 : "\(pause.daysRemaining) days left.")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.faint)

            Button("End it early") { end(pause) }
                .tetherButton(.secondary)
        }
    }

    // MARK: Actions

    private func start() {
        // One at a time — a second pause on top of an active one would just be
        // two people talking past each other.
        for existing in pauses where existing.isActive { end(existing) }
        ctx.insert(Pause(startedByID: profile.id,
                         days: days,
                         note: note.trimmed))
        try? ctx.save()
        note = ""
        TetherHaptics.success()
        dismiss()
    }

    private func end(_ pause: Pause) {
        pause.endsOn = Date()
        try? ctx.save()
    }
}

// MARK: - Home card

/// A quiet line on Home, so a pause is visible rather than a mystery.
struct PauseCard: View {
    let pause: Pause
    let isMine: Bool
    let partnerName: String?

    var body: some View {
        TetherCard {
            HStack(alignment: .top, spacing: TetherSpace.m) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 16))
                    .foregroundStyle(TetherColor.brand)

                VStack(alignment: .leading, spacing: 3) {
                    Text(isMine
                         ? "You asked for quiet"
                         : "\(partnerName ?? "They") asked for quiet")
                        .font(TetherType.label)
                        .foregroundStyle(TetherColor.text)

                    Text(pause.daysRemaining <= 1
                         ? "Back tomorrow. Nothing is expected until then."
                         : "\(pause.daysRemaining) days left. Nothing is expected until then.")
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }
}
