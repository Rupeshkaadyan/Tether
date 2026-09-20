import SwiftData
import SwiftUI

/// Writing an entry, from inside the journal.
///
/// This did not exist. Entries could only be created from Home's daily prompt
/// or by releasing an Unsent note, so the journal — the place you go to write —
/// had no way to write anything. Everything had to happen somewhere else first.
struct JournalComposer: View {
    @Bindable var profile: UserProfile
    /// Which tab the person was on when they opened this. If they were looking
    /// at Shared, they probably mean to write a shared entry.
    var initialScope: JournalView.Scope = .onlyMe
    /// Called with the saved entry so the journal can switch to whichever tab
    /// it actually landed in. Without this, writing a shared entry from the
    /// Shared tab saved it, closed the sheet, and the screen looked unchanged
    /// — the entry existed, but under the other tab.
    var onSaved: ((JournalEntry) -> Void)? = nil

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var text = ""
    @State private var mood = 3
    @State private var isShared = false
    @FocusState private var focused: Bool

    private var partner: UserProfile? {
        guard let id = profile.partnerID else { return nil }
        return profiles.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TetherSpace.xl) {
                    VStack(alignment: .leading, spacing: TetherSpace.s) {
                        SectionHeader(title: "How are you?")
                        MoodRow(selection: $mood)
                    }

                    VStack(alignment: .leading, spacing: TetherSpace.s) {
                        SectionHeader(title: "What happened?")
                        // Bottom-anchored so the field grows with the text
                        // instead of scrolling it out of view while typing.
                        TextField("A line is enough.", text: $text, axis: .vertical)
                            .lineLimit(4...14)
                            .tetherField()
                            .focused($focused)
                    }

                    // ALWAYS shown, even with no partner.
                    //
                    // It was hidden entirely unless a partner existed, so an
                    // unpaired person wrote into Shared, saw nothing appear,
                    // and reasonably concluded the button was broken. The
                    // entry was being saved — as private, silently, because
                    // there was nobody to share it with and no way to say so.
                    //
                    // The control is visible either way; Shared is simply not
                    // selectable until there is someone to share with.
                    VisibilityPicker(isShared: $isShared,
                                     partnerName: partner?.displayName,
                                     canShare: partner != nil)
                }
                .padding(TetherSpace.margin)
                .padding(.bottom, TetherSpace.xxl)
            }
            .background { TetherBackdrop() }
            .navigationTitle("New entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                // ToolbarItem (singular) wrapping an HStack, NOT
                // ToolbarItemGroup with a Spacer child. In a Group every child
                // becomes its own UIBarButtonItem, so the Spacer became a
                // zero-width bar item — which is the "ItemWrapperView.width ==
                // 0" constraint break. Inside an HStack it is just layout.
                ToolbarItem(placement: .keyboard) {
                Button("Done") { focused = false }
            }
                ToolbarItem(placement: .confirmationAction) {
                    // The button names the destination. "Save" alone gave no
                    // confirmation of where the entry was about to go, so a
                    // person could write in Shared, save, and reasonably
                    // believe it had vanished when it landed somewhere else.
                    Button(isShared ? "Save to Shared" : "Save privately") { save() }
                        .disabled(text.trimmed.isEmpty)
                }
            }
            .onAppear {
                isShared = (initialScope == .shared) && partner != nil
                focused = true
            }
        }
    }

    private func save() {
        let body = text.trimmed
        let verdict = SafetyClassifier.classify(body)

        let entry = JournalEntry(userID: profile.id,
                                 body: SecureContent.seal(body),
                                 mood: mood,
                                 source: .journal)
        entry.visibility = (isShared && partner != nil) ? .shared : .private
        entry.safetyFlagged = verdict.isCrisis
        ctx.insert(entry)
        ctx.insert(MoodLog(userID: profile.id, mood: mood))

        if verdict.isCrisis {
            // Never distilled into retrievable memory, and never shared.
            entry.visibility = .private
        } else {
            ctx.insert(CoachEngine.makeMemory(from: body,
                                              ownerID: profile.id,
                                              source: .journal,
                                              sourceID: entry.id,
                                              visibility: entry.visibility))
        }

        try? ctx.save()
        TetherHaptics.success()
        onSaved?(entry)
        dismiss()
    }
}
