import Foundation

/// The Secular / Psychology track — 90 days.
///
/// Grounded in Gottman Method, Emotionally Focused Therapy, attachment theory,
/// and nonviolent communication. Love Languages is deliberately NOT used here;
/// its evidence base is thin and it belongs in the engagement layer, not the
/// daily curriculum.
///
/// Quality bar: every prompt must be answerable honestly in one sentence, and
/// must be specific enough that a generic answer would feel evasive. If a prompt
/// could appear in any app, it gets cut.
///
/// The arc is deliberate. Days 1–14 build attention before asking for anything
/// vulnerable. Conflict work does not begin until day 43 — asking couples to
/// discuss fights before they have practised noticing is why most programs lose
/// people in week two.
enum SecularPrompts {

    private static func p(_ n: Int, _ body: String, _ category: String) -> Prompt {
        Prompt(String(format: "s%02d", n), .secular, body, category)
    }

    // MARK: - Arc 1 · Noticing (days 1–14)

    static let arc1: [Prompt] = [
        p(1, "What is one small thing your partner did today that you noticed but did not mention?", "noticing"),
        p(2, "Where did you feel most at ease with them this week?", "noticing"),
        p(3, "What is something about them you have stopped noticing because it is always there?", "noticing"),
        p(4, "Name a moment today when you were glad it was them you were with.", "noticing"),
        p(5, "What did they do recently that made your day slightly easier?", "appreciation"),
        p(6, "When did you last laugh together? What set it off?", "play"),
        p(7, "What is one ordinary thing they do that you would miss?", "appreciation"),
        p(8, "Who did they show up for this week — you, or someone else? How did that land?", "noticing"),
        p(9, "What is something they are better at than you, and you are glad they are?", "appreciation"),
        p(10, "When did you feel proud of them this week?", "appreciation"),
        p(11, "What is one thing they said recently that stuck with you?", "noticing"),
        p(12, "Where did you see them try this week, even if it did not land?", "repair"),
        p(13, "What are you looking forward to about seeing them today?", "connection"),
        p(14, "Name one thing you appreciate about them that you have never actually said out loud.", "appreciation")
    ]

    // MARK: - Arc 2 · Knowing each other (days 15–28)

    static let arc2: [Prompt] = [
        p(15, "When you are stressed, do you want space or company? Does that match what you usually get?", "needs"),
        p(16, "When you are upset, what helps — and what makes it worse?", "needs"),
        p(17, "What did you learn about love from the house you grew up in?", "history"),
        p(18, "What is something you are afraid to need?", "vulnerability"),
        p(19, "How do you know when you are at your limit?", "self-awareness"),
        p(20, "What does feeling safe actually feel like for you?", "safety"),
        p(21, "What is a need you have quietly stopped asking for?", "needs"),
        p(22, "When did you last feel truly understood by them?", "connection"),
        p(23, "What is something about your day you never get to tell them?", "disclosure"),
        p(24, "What drains you that they might not realise?", "self-awareness"),
        p(25, "What recharges you that they might not realise?", "self-awareness"),
        p(26, "What small ritual makes you feel close to them?", "rituals"),
        p(27, "When do you feel most like yourself around them?", "identity"),
        p(28, "What is one thing you wish they asked you about more often?", "needs")
    ]

    // MARK: - Arc 3 · Being heard (days 29–42)

    static let arc3: [Prompt] = [
        p(29, "What is something you have been saying indirectly that you could say plainly?", "expression"),
        p(30, "When did you reach for them this week and it went unnoticed?", "bids"),
        p(31, "What is a conversation the two of you keep postponing?", "avoidance"),
        p(32, "How do you want hard things told to you?", "expression"),
        p(33, "What is something they said this week that you have not acknowledged?", "listening"),
        p(34, "When do you find it hardest to really listen to them?", "listening"),
        p(35, "What would you want them to understand without you having to explain it?", "needs"),
        p(36, "What is a question you would like to ask them but have not?", "curiosity"),
        p(37, "Where do you soften a real feeling just to keep the peace?", "avoidance"),
        p(38, "What do you need to say out loud, even if nothing changes as a result?", "expression"),
        p(39, "When did you last tell them something true and difficult? How did it go?", "honesty"),
        p(40, "What is one thing you would like them to stop assuming about you?", "identity"),
        p(41, "What do you wish you had said in a recent argument?", "conflict"),
        p(42, "What is one small thing they could do that would make you feel heard?", "needs")
    ]

    // MARK: - Arc 4 · Conflict and repair (days 43–56)

    static let arc4: [Prompt] = [
        p(43, "What is the argument the two of you keep having? What do you think it is really about?", "perpetual"),
        p(44, "In a disagreement, do you move toward them or away? Which do you wish you did?", "pursue-withdraw"),
        p(45, "What is the first sign for you that a conversation is going badly?", "escalation"),
        p(46, "What do you need in the first minute of a disagreement?", "needs"),
        p(47, "What is something you have said in anger that you regret?", "repair"),
        p(48, "How do you know when you need to step away from a conversation?", "self-awareness"),
        p(49, "What would a good repair look like after a hard conversation?", "repair"),
        p(50, "What is a criticism you have made that was really about something else?", "criticism"),
        p(51, "Where do you find it hardest to let go of being right?", "contempt"),
        p(52, "What is something you have never fully forgiven, even if you said you had?", "forgiveness"),
        p(53, "What do you do when you feel attacked?", "defensiveness"),
        p(54, "What is one thing you could concede in the next argument, and why does it matter?", "repair"),
        p(55, "When did you last feel like a team during a disagreement?", "teamwork"),
        p(56, "What is one thing you want them to know about how you fight?", "disclosure")
    ]

    // MARK: - Arc 5 · Closeness (days 57–70)

    static let arc5: [Prompt] = [
        p(57, "When did you last feel close to them without anything physical happening?", "closeness"),
        p(58, "What do you miss about how the two of you used to be?", "nostalgia"),
        p(59, "What makes you feel wanted?", "desire"),
        p(60, "When do you feel most disconnected? What usually comes just before it?", "distance"),
        p(61, "What is a small gesture that means more to you than a grand one?", "appreciation"),
        p(62, "What would you like more of — time, touch, talk, or quiet together?", "needs"),
        p(63, "What is something you would like to do together that you never have?", "novelty"),
        p(64, "When do you feel most playful with them?", "play"),
        p(65, "What is one way they could make an ordinary evening better?", "rituals"),
        p(66, "What do you miss doing together?", "nostalgia"),
        p(67, "What does a good evening look like to you?", "rituals"),
        p(68, "What is something you want to protect from your busiest weeks?", "priorities"),
        p(69, "When did you last feel chosen by them?", "connection"),
        p(70, "What would make you feel closer to them this week?", "connection")
    ]

    // MARK: - Arc 6 · Shared meaning (days 71–82)

    static let arc6: [Prompt] = [
        p(71, "What does a good life look like to you in five years?", "vision"),
        p(72, "What do you want to be true about how the two of you treat each other?", "values"),
        p(73, "What matters more to you than money?", "values"),
        p(74, "What do you want to pass on, and what do you want to leave behind?", "legacy"),
        p(75, "What tradition from your family do you want to keep?", "culture"),
        p(76, "What tradition from your family would you rather let go of?", "culture"),
        p(77, "What do you want your home to feel like to someone who visits?", "home"),
        p(78, "What is a value you two share that you rarely name out loud?", "values"),
        p(79, "What are you both willing to sacrifice for?", "commitment"),
        p(80, "What does commitment mean to you on an ordinary Tuesday?", "commitment"),
        p(81, "What would you want people who know you to say about your relationship?", "identity"),
        p(82, "What is something you are building together, even if it is slow?", "vision")
    ]

    // MARK: - Arc 7 · Looking forward (days 83–90)

    static let arc7: [Prompt] = [
        p(83, "What has changed between you this year — for better, and for worse?", "reflection"),
        p(84, "What is one thing you want to keep doing?", "reflection"),
        p(85, "What is one thing you want to stop doing?", "reflection"),
        p(86, "What has been harder than you expected?", "reflection"),
        p(87, "What are you grateful for that you have never told them?", "gratitude"),
        p(88, "What do you want to be different a month from now?", "intention"),
        p(89, "What do you want to remember about this season of your life?", "reflection"),
        p(90, "What is one thing you want to say to them that you still have not?", "disclosure")
    ]

    /// All 90 days in order. Index 0 is day 1.
    static let all: [Prompt] = arc1 + arc2 + arc3 + arc4 + arc5 + arc6 + arc7
}
