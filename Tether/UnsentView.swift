import SwiftData
import SwiftUI

// MARK: - Unsent
//
// The place to work out a feeling before raising it.
//
// This exists because of a gap in the category rather than a feature request:
// the leading app's answers are shared, so reviewers note there is nowhere to
// process a frustration you are not ready to say out loud yet. Tether's whole
// design is private-until-you-both-answer, but that still means the answer is
// eventually read. This is the one surface that is never read by anyone.
//
// There is no "send" button. Sending needs a partner and a shared store, and
// more importantly it is not the point — the point is having somewhere to put
// the sentence until you know what it is for.

struct UnsentView: View {
    @Bindable var profile: UserProfile
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UnsentNote.createdAt, order: .reverse) private var notes: [UnsentNote]

    @State private var draft = ""
    @State private var releasing: UnsentNote?
    @State private var justReleased = false

    private var open: [UnsentNote] { notes.filter { $0.resolution == .open } }
    private var settled: [UnsentNote] { notes.filter { $0.resolution != .open } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.xl) {
                    promise
                    composer
                    if !open.isEmpty { openSection }
                    if !settled.isEmpty { settledSection }
                }
                .padding(TetherSpace.margin)
                .readableFrame()
                .padding(.bottom, TetherSpace.xxl)
            }
            .background { TetherBackdrop() }
            .navigationTitle("Unsent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Let it go?", isPresented: Binding(
                get: { releasing != nil },
                set: { if !$0 { releasing = nil } }
            )) {
                Button("Cancel", role: .cancel) { releasing = nil }
                Button("Let it go", role: .destructive) { release() }
            } message: {
                Text("The words will be deleted for good. You keep only the fact that you wrote them.")
            }
            .overlay {
                if justReleased {
                    releasedOverlay
                }
            }
        }
    }

    // MARK: Copy

    private var promise: some View {
        VStack(alignment: .leading, spacing: TetherSpace.s) {
            Text("Nobody reads this. Not your partner, not us.")
                .font(TetherType.callout)
                .foregroundStyle(TetherColor.text)
                .fixedSize(horizontal: false, vertical: true)
            Text("Some things need to be said out loud. Others just need to be written down first. This is for the second kind.")
                .font(TetherType.caption)
                .foregroundStyle(TetherColor.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var composer: some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                TextField("What you haven't said…", text: $draft, axis: .vertical)
                    .lineLimit(3...10)
                    .tetherField()

                Button("Put it here") { save() }
                    .tetherButton()
                    .disabled(draft.trimmed.isEmpty)
                    .opacity(draft.trimmed.isEmpty ? 0.45 : 1)
            }
        }
    }

    // MARK: Lists

    private var openSection: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            SectionHeader(title: "Sitting here")
            ForEach(open) { note in
                noteCard(note)
            }
        }
    }

    private var settledSection: some View {
        VStack(alignment: .leading, spacing: TetherSpace.m) {
            SectionHeader(title: "Settled")
            ForEach(settled) { note in
                HStack(spacing: TetherSpace.s) {
                    Image(systemName: note.resolution == .released
                          ? "wind" : "checkmark.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(TetherColor.faint)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(note.resolution == .released
                             ? "Let go" : "Moved to your journal")
                            .font(TetherType.caption)
                            .foregroundStyle(TetherColor.muted)
                        Text(note.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(TetherType.micro)
                            .foregroundStyle(TetherColor.faint)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func noteCard(_ note: UnsentNote) -> some View {
        TetherCard {
            VStack(alignment: .leading, spacing: TetherSpace.m) {
                Text(note.body)
                    .font(TetherType.body)
                    .foregroundStyle(TetherColor.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(TetherType.micro)
                    .foregroundStyle(TetherColor.faint)

                HStack(spacing: TetherSpace.s) {
                    Button("Move to journal") { journal(note) }
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.brand)
                        .buttonStyle(.plain)

                    Spacer(minLength: 0)

                    Button("Let it go") { releasing = note }
                        .font(TetherType.caption)
                        .foregroundStyle(TetherColor.muted)
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private var releasedOverlay: some View {
        ZStack {
            TetherColor.bg.opacity(0.94).ignoresSafeArea()
            VStack(spacing: TetherSpace.m) {
                Image(systemName: "wind")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(TetherColor.brand)
                Text("Gone.")
                    .font(TetherType.title)
                    .foregroundStyle(TetherColor.ink)
                Text("You wrote it. That was the part that mattered.")
                    .font(TetherType.caption)
                    .foregroundStyle(TetherColor.muted)
            }
        }
        .transition(.opacity)
    }

    // MARK: Actions

    private func save() {
        let text = draft.trimmed
        guard !text.isEmpty else { return }
        ctx.insert(UnsentNote(authorID: profile.id, body: text))
        try? ctx.save()
        draft = ""
        TetherHaptics.success()
    }

    /// Deletes the words outright. Keeps the row so "Settled" can show that
    /// something was let go without preserving what it said.
    private func release() {
        guard let note = releasing else { return }
        note.body = ""
        note.resolution = .released
        note.resolvedAt = Date()
        try? ctx.save()
        releasing = nil
        TetherHaptics.success()
        withAnimation(.easeOut(duration: 0.2)) { justReleased = true }
        Task {
            try? await Task.sleep(for: .milliseconds(1400))
            withAnimation(.easeOut(duration: 0.3)) { justReleased = false }
        }
    }

    private func journal(_ note: UnsentNote) {
        let entry = JournalEntry(userID: profile.id,
                                 body: SecureContent.seal(note.body),
                                 mood: 3,
                                 source: .journal)
        // Qualified: `private` is a backtick-escaped case, so the leading-dot
        // form does not infer here.
        entry.visibility = Visibility.private
        ctx.insert(entry)
        note.resolution = .journalled
        note.resolvedAt = Date()
        try? ctx.save()
        TetherHaptics.success()
    }
}
