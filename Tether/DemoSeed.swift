#if DEBUG
import Foundation
import SwiftData

/// Seeds a populated state for screenshots and SwiftUI previews.
///
/// Entirely wrapped in `#if DEBUG` — this is never compiled into a release
/// build. Launch with `-seedDemo` to activate.
enum DemoSeed {

    static func runIfNeeded(_ ctx: ModelContext) {
        let existing = (try? ctx.fetch(FetchDescriptor<UserProfile>())) ?? []
        guard existing.isEmpty else { return }

        // Me
        let me = UserProfile(displayName: "Rupesh", track: .secular)
        me.onboardingDone = true
        me.isSolo = false
        me.pairedAt = Date()
        ctx.insert(me)

        // Partner
        let partner = UserProfile(displayName: "Priya", track: .vedic)
        partner.onboardingDone = true
        partner.isSolo = false
        partner.partnerID = me.id
        ctx.insert(partner)
        me.partnerID = partner.id

        // Entries across the last 11 days so the Pulse has something to read
        let mine: [(Int, String, Int)] = [
            (0,  "I noticed you made tea without being asked. Small thing, but it landed.", 5),
            (1,  "Long day. I wanted quiet and got it, and that was exactly right.", 4),
            (2,  "I have been carrying the thing about your parents and not saying it.", 3),
            (3,  "We laughed properly for the first time in weeks. I missed that.", 5),
            (4,  "I felt unseen when you left without saying goodbye. Still sitting with it.", 2),
            (5,  "Talked about the move and it did not turn into a fight. Progress.", 4),
            (6,  "Tired. Not about us, just tired.", 3),
            (7,  "You asked how the interview went. You remembered. Thank you.", 5),
            (8,  "I think we are both just busy and it is showing.", 3),
            (9,  "Hard conversation, but honest. Glad we had it.", 4),
            (10, "Quiet day together. Nothing happened and it was perfect.", 5)
        ]

        for (daysAgo, text, mood) in mine {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            let entry = JournalEntry(userID: me.id,
                                     body: SecureContent.seal(text),
                                     mood: mood,
                                     source: .prompt)
            entry.entryDate = date
            entry.createdAt = date
            ctx.insert(entry)
            ctx.insert(MoodLog(userID: me.id, mood: mood, loggedDate: date))
            ctx.insert(CoachEngine.makeMemory(from: text,
                                              ownerID: me.id,
                                              source: .prompt,
                                              sourceID: entry.id,
                                              visibility: .shared))
        }

        // A couple of the partner's shared entries so the Shared tab has content
        let theirs: [(Int, String, Int)] = [
            (1, "I know I have been distracted. It is not about you.", 3),
            (4, "I did not mean to leave like that. I am sorry.", 2),
            (9, "I am glad we talked. I feel lighter.", 4)
        ]
        for (daysAgo, text, mood) in theirs {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            let entry = JournalEntry(userID: partner.id,
                                     body: SecureContent.seal(text),
                                     mood: mood,
                                     source: .prompt)
            entry.entryDate = date
            entry.createdAt = date
            ctx.insert(entry)
        }

        // Notes in the Wisdom Jar, from both of us.
        let jarNotes: [(UUID, String, Int)] = [
            (partner.id, "You make ordinary days feel like somewhere I want to be.", 4),
            (me.id, "You are allowed to have a bad week and still be loved.", 6),
            (partner.id, "I noticed you carried the whole day quietly. Thank you.", 9),
            (me.id, "We are on the same side. Even when it does not feel like it.", 12),
            (partner.id, "Your patience with my family is a gift I do not say enough.", 18),
            (me.id, "Whatever this is, we have survived worse and been kinder after.", 25),
            (partner.id, "I chose you on purpose, not by accident.", 31),
            (me.id, "You do not have to be strong today.", 40),
        ]
        for (author, text, daysAgo) in jarNotes {
            let note = JarNote(authorID: author, body: text)
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            note.createdAt = date
            ctx.insert(note)
        }

        try? ctx.save()
    }
}
#endif
