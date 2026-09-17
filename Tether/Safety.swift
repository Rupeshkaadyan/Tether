import Foundation

// MARK: - Categories

enum SafetyCategory: String, Codable {
    case none
    case selfHarm
    case harmToOthers
    case abuse
    case coerciveControl
}

struct SafetyResource: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let phone: String?
}

struct SafetyVerdict {
    let category: SafetyCategory
    let severity: Int          // 0 none, 1 watch, 2 urgent
    let matchedPhrase: String?

    var isCrisis: Bool { category != .none && severity >= 2 }

    /// Any crisis verdict suppresses couple-facing output entirely.
    /// The partner must never learn that the other person is in crisis.
    var suppressCoupleOutput: Bool { isCrisis }
}

// MARK: - Classifier

/// Local pre-screen. Deliberately conservative: it errs toward flagging.
///
/// This is NOT the production classifier. The TRD requires a server-side model
/// classifier in front of storage and generation before launch. This exists so
/// the pipeline shape, the suppression behaviour, and the resource card are all
/// real and testable from day one.
enum SafetyClassifier {

    private static let selfHarmPhrases = [
        "kill myself", "end my life", "ending my life", "want to die",
        "better off dead", "no reason to live", "hurt myself", "harm myself",
        "suicidal", "suicide", "take my own life", "not want to be here anymore"
    ]

    private static let harmToOthersPhrases = [
        "kill him", "kill her", "kill them", "hurt him", "hurt her",
        "want to hurt", "make him pay", "make her pay"
    ]

    private static let abusePhrases = [
        "he hit me", "she hit me", "he hits me", "she hits me",
        "he pushed me", "she pushed me", "afraid of him", "afraid of her",
        "scared of him", "scared of her", "threatened me", "choked me",
        "forces me", "forced me to", "won't let me leave", "wont let me leave"
    ]

    private static let coercivePhrases = [
        "controls my money", "checks my phone", "won't let me see",
        "wont let me see", "isolates me", "isolating me", "threatens to leave with"
    ]

    static func classify(_ text: String) -> SafetyVerdict {
        let normalised = text
            .lowercased()
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{2018}", with: "'")

        func firstMatch(_ phrases: [String]) -> String? {
            phrases.first { normalised.contains($0) }
        }

        if let hit = firstMatch(selfHarmPhrases) {
            return SafetyVerdict(category: .selfHarm, severity: 2, matchedPhrase: hit)
        }
        if let hit = firstMatch(abusePhrases) {
            return SafetyVerdict(category: .abuse, severity: 2, matchedPhrase: hit)
        }
        if let hit = firstMatch(harmToOthersPhrases) {
            return SafetyVerdict(category: .harmToOthers, severity: 2, matchedPhrase: hit)
        }
        if let hit = firstMatch(coercivePhrases) {
            return SafetyVerdict(category: .coerciveControl, severity: 1, matchedPhrase: hit)
        }

        return SafetyVerdict(category: .none, severity: 0, matchedPhrase: nil)
    }
}

// MARK: - Resources

enum SafetyResources {

    static let us: [SafetyResource] = [
        SafetyResource(name: "988 Suicide & Crisis Lifeline",
                       detail: "Call or text 988. Free, confidential, 24/7.",
                       phone: "988"),
        SafetyResource(name: "National Domestic Violence Hotline",
                       detail: "Confidential support, safety planning, and local referrals.",
                       phone: "1-800-799-7233"),
        SafetyResource(name: "Crisis Text Line",
                       detail: "Text HOME to 741741 to reach a trained crisis counsellor.",
                       phone: nil)
    ]

    static func forCategory(_ category: SafetyCategory) -> [SafetyResource] {
        switch category {
        case .abuse, .coerciveControl:
            return Array(us.suffix(from: 1)) + [us[0]]
        default:
            return us
        }
    }

    static func headline(for category: SafetyCategory) -> String {
        switch category {
        case .selfHarm:
            return "It sounds like you are carrying something very heavy."
        case .abuse, .coerciveControl:
            return "What you are describing matters, and you deserve support."
        case .harmToOthers:
            return "It sounds like you are at the end of your rope."
        case .none:
            return ""
        }
    }

    static func body(for category: SafetyCategory) -> String {
        switch category {
        case .abuse, .coerciveControl:
            return "Tether is not a crisis service, and this is not something an app should help you work through alone. These lines are confidential, and they will not contact anyone on your behalf."
        default:
            return "Tether is not a crisis service. These lines are free, confidential, and available right now."
        }
    }
}
