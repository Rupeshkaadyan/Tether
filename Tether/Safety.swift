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
    /// 0 none · 1 watch (logged, no card) · 2 urgent · 3 immediate danger.
    /// The card fires at 2 and above.
    let severity: Int
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

    // MARK: Patterns

    /// Direct ideation. Severity 3 — always a crisis card.
    private static let selfHarmDirect = [
        "kill myself", "killing myself", "end my life", "ending my life",
        "take my own life", "taking my own life", "want to die", "wanna die",
        "wish i was dead", "wish i were dead", "better off dead",
        "better off without me", "no reason to live", "nothing to live for",
        "do not want to be here", "do not want to be alive", "do not want to wake up",
        "cannot go on", "can not go on", "end it all", "not want to exist",
        "suicidal", "suicide", "kill myself tonight", "overdose on"
    ]

    /// Self-directed harm and preparation. Severity 3.
    private static let selfHarmIndirect = [
        "hurt myself", "hurting myself", "harm myself", "harming myself",
        "cutting myself", "cut myself", "self harm", "self-harm",
        "starving myself", "punish myself", "made a plan to"
    ]

    /// Hopelessness without explicit ideation. Severity 1 — watch, no card.
    /// Flagging these as crisis would fire on ordinary bad days and train
    /// people to ignore the card when it matters.
    private static let despair = [
        "what is the point", "no point anymore", "cannot do this anymore",
        "can not do this anymore", "cannot take it anymore", "give up on everything",
        "everyone would be better off", "i am a burden", "nothing matters anymore"
    ]

    /// Physical violence by a partner. Matched as subject + verb + object so it
    /// catches "my husband hit me", "he has been hitting me", "he grabbed me".
    private static let abuserSubjects = [
        "he", "she", "they", "my husband", "my wife", "my partner",
        "my boyfriend", "my girlfriend", "my ex", "my fiance", "my fiancee"
    ]

    private static let violentVerbs = [
        "hit", "hits", "hitting", "punched", "punching", "slapped", "slapping",
        "choked", "choking", "strangled", "strangling", "kicked", "kicking",
        "dragged", "dragging", "grabbed", "grabbing", "shoved", "shoving",
        "pushed", "pushing", "threw", "throwing", "beat", "beating",
        "burned", "burning", "bit", "biting", "cornered", "pinned"
    ]

    /// Explicit statements of fear or threat. Severity 3 on their own.
    private static let abuseDirect = [
        "afraid of him", "afraid of her", "afraid of them", "afraid of my",
        "scared of him", "scared of her", "scared of them", "scared of my",
        "frightened of him", "frightened of her", "frightened of my",
        "threatened me", "threatening me", "threatens me",
        "threatened to kill me", "said he would kill me", "said she would kill me",
        "will not let me leave", "will not let me go", "forces me to",
        "forced me to", "makes me have sex", "forces me to have sex",
        "raped me", "sexually assaulted me", "hurt me on purpose",
        "i am not safe at home", "i do not feel safe at home"
    ]

    /// Coercive control. Severity 2 — surfaces resources but is not framed as
    /// immediate danger, because it is usually ongoing rather than acute.
    private static let coerciveControl = [
        "controls my money", "controls all the money", "takes my money",
        "took my money", "will not let me work", "will not let me have a job",
        "checks my phone", "goes through my phone", "tracks my location",
        "tracking my phone", "follows me everywhere", "monitors me",
        "will not let me see my friends", "will not let me see my family",
        "isolated me", "isolating me", "cut me off from",
        "i am not allowed to", "i am not allowed any", "he decides everything",
        "she decides everything", "threatens to take the kids",
        "threatens to leave with", "said he would take the children",
        "hides my keys", "hides my passport", "controls what i wear"
    ]

    /// Threats toward the partner. Severity 3.
    private static let harmToOthers = [
        "kill him", "kill her", "kill them", "killing him", "killing her",
        "hurt him", "hurt her", "hurt them", "want to hurt him",
        "want to hurt her", "make him pay", "make her pay",
        "going to hurt", "i will hurt", "i want him dead", "i want her dead"
    ]

    // MARK: Normalisation

    /// Expands contractions and unifies curly quotes and apostrophes, so a
    /// single canonical phrase list covers "won't", "wont" and "will not".
    private static func normalise(_ text: String) -> String {
        var s = text.lowercased()
        s = s.replacingOccurrences(of: "\u{2019}", with: "'")
        s = s.replacingOccurrences(of: "\u{2018}", with: "'")
        s = s.replacingOccurrences(of: "\u{02BC}", with: "'")

        let contractions = [
            "won't": "will not", "wont": "will not",
            "can't": "cannot", "cant": "cannot", "can not": "cannot",
            "don't": "do not", "dont": "do not",
            "doesn't": "does not", "doesnt": "does not",
            "didn't": "did not", "didnt": "did not",
            "isn't": "is not", "isnt": "is not",
            "i'm": "i am", "im ": "i am ",
            "i've": "i have", "ive": "i have",
            "i'll": "i will", "i'd": "i would",
            "he's": "he is", "she's": "she is", "they're": "they are",
            "hasn't": "has not", "haven't": "have not",
            "wouldn't": "would not", "wouldnt": "would not",
            "wasn't": "was not", "weren't": "were not"
        ]
        for (short, long) in contractions {
            s = s.replacingOccurrences(of: short, with: long)
        }
        return s
    }

    /// Guards against negated hypotheticals. "My partner would never hit me"
    /// and "I would never kill myself" are statements of safety, not crisis —
    /// firing a helpline card at them is alarming and teaches people to
    /// distrust the card.
    /// Guards the abuse *pattern* matcher only.
    ///
    /// The curated phrase lists deliberately skip this check: they are written
    /// to be unambiguous, and a blanket "not" rule breaks genuine disclosures —
    /// "I do not want to be here", "I cannot do this anymore" and "I am not
    /// allowed to see my friends" all contain "not" and all must still fire.
    /// Only subject+verb+object constructions have a real negation problem,
    /// because "my partner would never hit me" is a statement of safety.
    private static func isNegated(_ haystack: String, at range: Range<String.Index>) -> Bool {
        let windowStart = haystack.index(range.lowerBound,
                                        offsetBy: -20,
                                        limitedBy: haystack.startIndex) ?? haystack.startIndex
        let before = haystack[windowStart..<range.lowerBound]
        let within = haystack[range]
        let negators = ["never", "would not", "would never", "not ever",
                        "has not", "have not", "no one would", "nobody would"]
        return negators.contains { before.contains($0) || within.contains($0) }
    }

    /// Ordinary hyperbole that reads like ideation to a phrase matcher.
    /// Firing a helpline card at a joke is alarming, and it teaches people to
    /// distrust the card on the day it matters. Neutralised before matching.
    private static let idioms: [(String, String)] = [
        ("die laughing", "be very amused"),
        ("died laughing", "was very amused"),
        ("dying of laughter", "very amused"),
        ("die of laughter", "very amused"),
        ("die of embarrassment", "be very embarrassed"),
        ("dying of embarrassment", "very embarrassed"),
        ("dying to see", "eager to see"),
        ("dying to know", "eager to know"),
        ("dying to tell", "eager to tell"),
        ("kill for a", "really want a"),
        ("killing time", "passing time"),
        ("kill time", "pass time"),
        ("shoot myself in the foot", "make a mistake"),
        ("scared to death", "very frightened"),
        ("worried sick", "very worried")
    ]

    private static func neutraliseIdioms(_ text: String) -> String {
        var s = text
        for (idiom, replacement) in idioms {
            s = s.replacingOccurrences(of: idiom, with: replacement)
        }
        return s
    }

    /// Curated phrases, matched literally, with only the narrow negation guard
    /// from `isNegated` — which catches "I would never kill myself" without
    /// breaking "I do not want to be here".
    private static func firstMatch(_ text: String, _ phrases: [String]) -> String? {
        for phrase in phrases {
            guard let range = text.range(of: phrase) else { continue }
            if isNegated(text, at: range) { continue }
            return phrase
        }
        return nil
    }

    /// Subject + violent verb + "me", allowing words in between. Catches the
    /// many ways people actually describe being hit.
    private static func matchAbusePattern(_ text: String) -> String? {
        for subject in abuserSubjects {
            for verb in violentVerbs {
                let pattern = "\(subject) [a-z ]{0,18}\(verb) [a-z ]{0,12}me"
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: text,
                                                range: NSRange(text.startIndex..., in: text)),
                   let range = Range(match.range, in: text) {
                    if isNegated(text, at: range) { continue }
                    return String(text[range])
                }
            }
        }
        return nil
    }

    // MARK: Classify

    static func classify(_ text: String) -> SafetyVerdict {
        let t = neutraliseIdioms(normalise(text))

        if let hit = firstMatch(t, selfHarmDirect) {
            return SafetyVerdict(category: .selfHarm, severity: 3, matchedPhrase: hit)
        }
        if let hit = firstMatch(t, abuseDirect) {
            return SafetyVerdict(category: .abuse, severity: 3, matchedPhrase: hit)
        }
        if let hit = matchAbusePattern(t) {
            return SafetyVerdict(category: .abuse, severity: 3, matchedPhrase: hit)
        }
        if let hit = firstMatch(t, selfHarmIndirect) {
            return SafetyVerdict(category: .selfHarm, severity: 3, matchedPhrase: hit)
        }
        if let hit = firstMatch(t, harmToOthers) {
            return SafetyVerdict(category: .harmToOthers, severity: 2, matchedPhrase: hit)
        }
        if let hit = firstMatch(t, coerciveControl) {
            return SafetyVerdict(category: .coerciveControl, severity: 2, matchedPhrase: hit)
        }
        if let hit = firstMatch(t, despair) {
            return SafetyVerdict(category: .selfHarm, severity: 1, matchedPhrase: hit)
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
