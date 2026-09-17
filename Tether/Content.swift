import Foundation

struct Prompt: Identifiable, Hashable {
    let id: String
    let track: WisdomTrack
    let body: String
    let category: String

    init(_ id: String, _ track: WisdomTrack, _ body: String, _ category: String) {
        self.id = id
        self.track = track
        self.body = body
        self.category = category
    }
}

/// v0.1 ships Secular and Biblical. Vedic and Quranic arrive in v1.0.
/// Quality bar: every prompt must be specific enough to answer honestly in one sentence.
/// If it reads like a horoscope, it gets cut.
enum PromptLibrary {

    /// 90 days, authored in `ContentSecular.swift`.
    static let secular: [Prompt] = SecularPrompts.all

    /// 90 days, authored in `ContentBiblical.swift`. Needs faith review before ship.
    static let biblical: [Prompt] = BiblicalPrompts.all

    /// 90 days, authored in `ContentVedic.swift`. Needs dharmic review before ship.
    static let vedic: [Prompt] = VedicPrompts.all

    /// 90 days, authored in `ContentQuranic.swift`. Needs scholarly review before ship.
    static let quranic: [Prompt] = QuranicPrompts.all

    static func prompts(for track: WisdomTrack) -> [Prompt] {
        switch track {
        case .secular:  return secular
        case .biblical: return biblical
        case .vedic:    return vedic
        case .quranic:  return quranic
        }
    }

    /// Deterministic daily prompt. Cycles through the track library by day index
    /// so both partners land on the same question without a server round-trip.
    static func prompt(for track: WisdomTrack, dayIndex: Int) -> Prompt {
        let pool = prompts(for: track)
        guard !pool.isEmpty else { return secular[0] }
        let safe = abs(dayIndex) % pool.count
        return pool[safe]
    }

    /// Days since the user started, used as the day index.
    static func dayIndex(since start: Date) -> Int {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: start), to: cal.startOfDay(for: Date())).day
        return days ?? 0
    }
}

// MARK: - Love Languages assessment

struct LoveLanguageQuestion: Identifiable {
    let id = UUID()
    let prompt: String
    let left: LoveLanguage
    let right: LoveLanguage
}

enum LoveLanguageQuiz {
    /// Forced-choice pairs. Each answer awards one point to the chosen language.
    static let questions: [LoveLanguageQuestion] = [
        LoveLanguageQuestion(prompt: "I feel most loved when my partner tells me I matter to them, or when they do something helpful for me.", left: .words, right: .acts),
        LoveLanguageQuestion(prompt: "A thoughtful gift means more to me than an afternoon spent together.", left: .gifts, right: .time),
        LoveLanguageQuestion(prompt: "A long hug after a hard day comforts me more than reassuring words.", left: .touch, right: .words),
        LoveLanguageQuestion(prompt: "I would rather my partner take a chore off my plate than buy me something.", left: .acts, right: .gifts),
        LoveLanguageQuestion(prompt: "Undivided attention matters more to me than physical affection.", left: .time, right: .touch),
        LoveLanguageQuestion(prompt: "Hearing 'I am proud of you' lands deeper than any gift.", left: .words, right: .gifts),
        LoveLanguageQuestion(prompt: "I feel closest to my partner when we are doing something side by side.", left: .time, right: .acts),
        LoveLanguageQuestion(prompt: "Small physical gestures make me feel secure in the relationship.", left: .touch, right: .time),
        LoveLanguageQuestion(prompt: "When I am overwhelmed, practical help means more than a kind message.", left: .acts, right: .words),
        LoveLanguageQuestion(prompt: "A surprise, however small, makes me feel known.", left: .gifts, right: .touch)
    ]

    static func result(from selections: [LoveLanguage]) -> LoveLanguage {
        var tally: [LoveLanguage: Int] = [:]
        for pick in selections { tally[pick, default: 0] += 1 }
        return tally.max { $0.value < $1.value }?.key ?? .words
    }
}
