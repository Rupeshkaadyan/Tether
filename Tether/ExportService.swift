import Foundation

/// Builds a human-readable export of everything the user has written.
///
/// Settings promises "export everything", and under GDPR / CCPA a user is
/// entitled to a portable copy of their own data. Entries are decrypted on the
/// way out — this is the one place the plaintext legitimately leaves the sealed
/// store, and it only ever goes where the user sends it.
enum ExportService {

    static func markdown(profile: UserProfile,
                         partner: UserProfile?,
                         entries: [JournalEntry],
                         messages: [AIMessage],
                         memories: [AIMemory]) -> String {

        var out: [String] = []
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .none

        out.append("# Tether export")
        out.append("")
        out.append("**Name:** \(profile.displayName)")
        out.append("**Wisdom track:** \(profile.track.displayName)")
        if let partner {
            out.append("**Partner:** \(partner.displayName) — \(partner.track.displayName)")
        }
        out.append("**Exported:** \(df.string(from: Date()))")
        out.append("")
        out.append("Your entries are sealed on device with AES-256-GCM. This file is")
        out.append("the decrypted copy, so treat it as carefully as you would a diary.")
        out.append("")

        // Journal
        out.append("## Journal")
        out.append("")
        let mine = entries
            .filter { $0.userID == profile.id }
            .sorted { $0.entryDate > $1.entryDate }
        if mine.isEmpty {
            out.append("_No entries yet._")
        } else {
            for entry in mine {
                out.append("### \(df.string(from: entry.entryDate))")
                out.append("")
                out.append("Mood: \(moodWord(entry.mood)) · \(entry.visibility == .private ? "Private" : "Shared")")
                out.append("")
                out.append(SecureContent.read(entry.body))
                out.append("")
            }
        }

        // Shared entries from the partner
        if let partner {
            let theirs = entries
                .filter { $0.userID == partner.id && $0.visibility == .shared }
                .sorted { $0.entryDate > $1.entryDate }
            if !theirs.isEmpty {
                out.append("## \(partner.displayName)'s shared entries")
                out.append("")
                for entry in theirs {
                    out.append("### \(df.string(from: entry.entryDate))")
                    out.append("")
                    out.append(SecureContent.read(entry.body))
                    out.append("")
                }
            }
        }

        // Coach
        let convo = messages.sorted { $0.createdAt < $1.createdAt }
        if !convo.isEmpty {
            out.append("## Coach conversations")
            out.append("")
            for message in convo {
                let who = message.role == .user ? "You" : "Coach"
                out.append("**\(who):** \(SecureContent.read(message.body))")
                out.append("")
            }
        }

        // Memories
        if !memories.isEmpty {
            out.append("## What the coach remembers")
            out.append("")
            for memory in memories where memory.ownerID == profile.id {
                out.append("- \(SecureContent.read(memory.text))")
            }
            out.append("")
        }

        out.append("---")
        out.append("")
        out.append("Tether is not therapy and not a crisis service.")
        return out.joined(separator: "\n")
    }

    static func filename(for profile: UserProfile) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let safe = profile.displayName
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
        return "tether-\(safe.isEmpty ? "export" : safe)-\(df.string(from: Date())).md"
    }

    private static func moodWord(_ value: Int) -> String {
        switch value {
        case 1:  return "Very low"
        case 2:  return "Low"
        case 3:  return "Okay"
        case 4:  return "Good"
        default: return "Great"
        }
    }
}
