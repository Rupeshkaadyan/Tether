import Foundation

// MARK: - Result

struct CoachResponse {
    let text: String
    let usedMemory: Bool
    let verdict: SafetyVerdict
    let memoriesUsed: [AIMemory]
}

// MARK: - Memory retrieval

protocol MemoryRetrieving {
    func retrieve(query: String, ownerID: UUID, from memories: [AIMemory], limit: Int) -> [AIMemory]
}

/// Keyword-overlap scoring with a recency tiebreak. Deliberately swappable —
/// when the backend lands, a pgvector cosine search replaces this and nothing
/// else in the app changes.
struct KeywordMemoryRetriever: MemoryRetrieving {

    func retrieve(query: String, ownerID: UUID, from memories: [AIMemory], limit: Int = 3) -> [AIMemory] {
        let queryTerms = Set(TextTerms.significant(in: query))
        guard !queryTerms.isEmpty else { return [] }

        let scored: [(AIMemory, Double)] = memories
            .filter { $0.ownerID == ownerID }
            .map { memory in
                let memoryTerms = Set(memory.keywordList)
                let overlap = queryTerms.intersection(memoryTerms).count
                let recency = max(0, 1 - Date().timeIntervalSince(memory.createdAt) / (60 * 60 * 24 * 60))
                return (memory, Double(overlap) + recency * 0.5)
            }
            .filter { $0.1 > 0.5 }
            .sorted { $0.1 > $1.1 }

        return scored.prefix(limit).map(\.0)
    }
}

// MARK: - Text helpers

enum TextTerms {
    static let stopwords: Set<String> = [
        "the", "and", "for", "are", "but", "not", "you", "your", "with", "that",
        "this", "have", "has", "had", "was", "were", "his", "her", "him", "she",
        "he", "they", "them", "our", "ours", "about", "from", "what", "when",
        "how", "why", "who", "will", "would", "could", "should", "just", "like",
        "feel", "feels", "feeling", "really", "very", "much", "more", "some",
        "been", "being", "get", "got", "did", "does", "doing", "there", "here"
    ]

    static func significant(in text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 && !stopwords.contains($0) }
    }
}

// MARK: - Provider

protocol CoachProviding {
    func reply(to message: String,
               track: WisdomTrack,
               memories: [AIMemory],
               history: [AIMessage]) async -> String
}

/// On-device stand-in. Shaped exactly like the Claude call will be, so
/// `ClaudeCoachProvider` can replace it with no changes to the UI or engine.
///
/// The bar this must clear: competitors get criticised for generic content.
/// Every branch here names something concrete rather than offering a platitude.
struct LocalCoachProvider: CoachProviding {

    func reply(to message: String,
               track: WisdomTrack,
               memories: [AIMemory],
               history: [AIMessage]) async -> String {
        try? await Task.sleep(nanoseconds: 350_000_000)

        let intent = Intent.detect(message)
        let opener = memoryOpener(memories)
        let core = core(intent: intent, track: track, message: message)
        let close = followUp(intent)

        return [opener, core, close].compactMap { $0 }.joined(separator: "\n\n")
    }

    private func memoryOpener(_ memories: [AIMemory]) -> String? {
        guard let memory = memories.first else { return nil }
        let days = Int(Date().timeIntervalSince(memory.createdAt) / (60 * 60 * 24))
        let when: String
        switch days {
        case ..<1: when = "earlier today"
        case 1: when = "yesterday"
        case 2...6: when = "\(days) days ago"
        case 7...13: when = "last week"
        default: when = "\(days / 7) weeks ago"
        }
        let plain = SecureContent.read(memory.text)
        let trimmed = plain.count > 90 ? String(plain.prefix(90)) + "…" : plain
        return "You wrote \(when): “\(trimmed)”"
    }

    private func core(intent: Intent, track: WisdomTrack, message: String) -> String {
        switch intent {
        case .conflict:
            return track == .biblical
                ? "Conflict is not the failure. What matters is what happens in the first three minutes of the repair. Before you raise it again, decide one thing you are willing to concede — not to end the argument, but to show you are on the same side."
                : "Most recurring arguments are not about the topic. Gottman called it a perpetual problem — roughly seven in ten are never fully solved. The goal is not to win it, it is to talk about it without contempt creeping in."
        case .distance:
            return "Distance usually shows up as fewer bids, not bigger fights. One small bid answered — a text returned, a question asked about their day — moves this more than a long conversation would."
        case .appreciation:
            return "Say it specifically. Not “you are great” but what they did and what it meant to you. Specific praise is far harder to dismiss than general praise."
        case .decision:
            return "Before deciding, check whether you actually disagree about the decision or about what it means. Those need completely different conversations."
        case .aboutPartner:
            return "You can only control your half of this. The useful question is not “why do they do that” but “what do I do next, regardless of what they choose.”"
        case .lonely:
            return "Feeling alone inside a relationship is different from being alone, and it usually goes unsaid because saying it feels like an accusation. Try naming the feeling without naming a culprit: “I have been missing you,” not “you have been distant.”"
        case .general:
            return track == .biblical
                ? "What would it look like to act toward them today in a way that does not depend on how they respond? That is usually where the shift starts."
                : "What is the smallest next step that is entirely within your control? Start there — it is more useful than trying to fix the whole thing at once."
        }
    }

    private func followUp(_ intent: Intent) -> String {
        switch intent {
        case .conflict: return "What would you want them to understand, if they could only hear one sentence?"
        case .distance: return "When did you last feel close? What was different that day?"
        case .appreciation: return "What is one thing from this week you have not told them yet?"
        case .decision: return "What is the fear underneath the decision?"
        case .aboutPartner: return "What is the part of this that is actually yours to carry?"
        case .lonely: return "What would you want to hear from them right now?"
        case .general: return "What would you like to be different a month from now?"
        }
    }

    enum Intent {
        case conflict, distance, appreciation, decision, aboutPartner, lonely, general

        static func detect(_ text: String) -> Intent {
            let t = text.lowercased()
            func has(_ words: [String]) -> Bool { words.contains { t.contains($0) } }

            if has(["fight", "argue", "argument", "shouting", "angry", "resent", "unfair", "blame"]) { return .conflict }
            if has(["distant", "apart", "disconnect", "withdrawn", "ignore", "cold", "busy lately"]) { return .distance }
            if has(["grateful", "thank", "appreciate", "proud", "lucky"]) { return .appreciation }
            if has(["should we", "decide", "decision", "whether to", "choice", "move", "job"]) { return .decision }
            if has(["why does he", "why does she", "why do they", "my partner", "my husband", "my wife"]) { return .aboutPartner }
            if has(["lonely", "alone", "unseen", "invisible", "nobody"]) { return .lonely }
            return .general
        }
    }
}

// MARK: - Engine

enum CoachEngine {

    static let retriever: MemoryRetrieving = KeywordMemoryRetriever()
    static let provider: CoachProviding = LocalCoachProvider()

    /// The full pipeline. Order matters and mirrors the TRD:
    /// safety first, then retrieval, then generation.
    static func respond(to message: String,
                        ownerID: UUID,
                        track: WisdomTrack,
                        memories: [AIMemory],
                        history: [AIMessage]) async -> CoachResponse {

        let verdict = SafetyClassifier.classify(message)
        if verdict.isCrisis {
            return CoachResponse(text: "", usedMemory: false, verdict: verdict, memoriesUsed: [])
        }

        let retrieved = retriever.retrieve(query: message, ownerID: ownerID, from: memories, limit: 3)
        let text = await provider.reply(to: message, track: track, memories: retrieved, history: history)

        return CoachResponse(text: text,
                             usedMemory: !retrieved.isEmpty,
                             verdict: verdict,
                             memoriesUsed: retrieved)
    }

    /// Distils an entry into a memory record. Called when a journal entry or
    /// prompt reply is saved.
    static func makeMemory(from text: String,
                           ownerID: UUID,
                           source: EntrySource,
                           sourceID: UUID,
                           visibility: Visibility) -> AIMemory {
        AIMemory(ownerID: ownerID,
                 source: source,
                 sourceID: sourceID,
                 text: SecureContent.seal(text),
                 keywords: Array(Set(TextTerms.significant(in: text))).sorted(),
                 visibility: visibility)
    }
}
