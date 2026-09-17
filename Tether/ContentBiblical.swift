import Foundation

/// The Biblical track — 90 days.
///
/// ⚠️ REQUIRES REVIEW. Every prompt in this file must be read by a practising
/// Christian counsellor or pastor before it ships. It is written to be
/// denominationally neutral (paraphrase rather than quote, no translation
/// preference, no contested doctrinal positions), but it is not a substitute
/// for a reviewer who knows the tradition.
///
/// Deliberate editorial decisions:
/// 1. Scripture is referenced and paraphrased, not quoted at length. This avoids
///    translation-copyright issues and avoids implying a preferred translation.
/// 2. **No headship or submission language anywhere in the conflict arc.**
///    Those passages are real and important within many traditions, but they are
///    also the most common thing weaponised in coercive marriages. Tether ships
///    an abuse detector. It must not, in the same product, hand a controlling
///    partner a verse. Mutual yielding is used instead.
/// 3. The arc mirrors the Secular track so couples on different tracks share the
///    same shape of conversation. Conflict work still begins at day 43.
enum BiblicalPrompts {

    private static func p(_ n: Int, _ body: String, _ category: String) -> Prompt {
        Prompt(String(format: "b%02d", n), .biblical, body, category)
    }

    // MARK: - Arc 1 · Noticing (days 1–14)

    static let arc1: [Prompt] = [
        p(1, "Where did you notice grace this week — something good you did not earn?", "grace"),
        p(2, "What is one thing your partner did today that you have not thanked them for?", "gratitude"),
        p(3, "Where did you see God at work in your home this week?", "presence"),
        p(4, "What is something about them you have stopped noticing because it is always there?", "noticing"),
        p(5, "What did they do recently that made your day lighter?", "gratitude"),
        p(6, "When did you last laugh together? What set it off?", "joy"),
        p(7, "What ordinary thing they do would you miss if it stopped?", "gratitude"),
        p(8, "Who did they serve this week — you, or someone else? How did that land?", "service"),
        p(9, "What is something they are better at than you, and you are thankful for it?", "gratitude"),
        p(10, "When did you feel proud of them this week?", "gratitude"),
        p(11, "What is one thing they said recently that stayed with you?", "noticing"),
        p(12, "Where did you see them try this week, even if it did not land?", "repair"),
        p(13, "What are you looking forward to about them today?", "hope"),
        p(14, "Name one thing you thank God for in them that you have never said aloud.", "blessing")
    ]

    // MARK: - Arc 2 · Knowing each other (days 15–28)

    static let arc2: [Prompt] = [
        p(15, "When you are stressed, do you want space or company? Does that match what you usually get?", "needs"),
        p(16, "When you are hurting, what helps — and what makes it worse?", "needs"),
        p(17, "What did you learn about love from the house you grew up in?", "history"),
        p(18, "What is something you are afraid to need?", "vulnerability"),
        p(19, "How do you know when you are at your limit?", "self-awareness"),
        p(20, "What does feeling safe actually feel like for you?", "safety"),
        p(21, "What is a need you have quietly stopped asking for?", "needs"),
        p(22, "When did you last feel truly known by them?", "connection"),
        p(23, "What is something about your day you never get to tell them?", "disclosure"),
        p(24, "What drains you that they might not realise?", "self-awareness"),
        p(25, "What restores you that they might not realise?", "self-awareness"),
        p(26, "What small ritual makes you feel close to them?", "rituals"),
        p(27, "When do you feel most like yourself around them?", "identity"),
        p(28, "What is one thing you wish they asked you about more often?", "needs")
    ]

    // MARK: - Arc 3 · Being heard (days 29–42)

    static let arc3: [Prompt] = [
        p(29, "What have you been saying indirectly that you could say plainly?", "expression"),
        p(30, "When did you reach for them this week and it went unnoticed?", "bids"),
        p(31, "What is a conversation the two of you keep postponing?", "avoidance"),
        p(32, "How do you want hard things told to you?", "expression"),
        p(33, "Scripture says be quick to listen and slow to speak. Where did you get that backwards this week?", "listening"),
        p(34, "What is something they said this week that you have not acknowledged?", "listening"),
        p(35, "When do you find it hardest to really listen to them?", "listening"),
        p(36, "What would you want them to understand without you having to explain it?", "needs"),
        p(37, "What is a question you would like to ask them but have not?", "curiosity"),
        p(38, "Where do you soften a true feeling just to keep the peace?", "avoidance"),
        p(39, "What do you need to say out loud, even if nothing changes as a result?", "honesty"),
        p(40, "What is one thing you would like them to stop assuming about you?", "identity"),
        p(41, "What do you wish you had said in a recent argument?", "conflict"),
        p(42, "What is one small thing they could do that would make you feel heard?", "needs")
    ]

    // MARK: - Arc 4 · Conflict and repair (days 43–56)

    static let arc4: [Prompt] = [
        p(43, "What is the argument the two of you keep having? What do you think it is really about?", "perpetual"),
        p(44, "When you are angry, do you move toward them or away? What would it take to not let the sun go down on it?", "anger"),
        p(45, "What is the first sign for you that a conversation is going badly?", "escalation"),
        p(46, "What do you need in the first minute of a disagreement?", "needs"),
        p(47, "What is something you have said in anger that you regret?", "repair"),
        p(48, "How do you know when you need to step away from a conversation?", "self-awareness"),
        p(49, "What would a good repair look like after a hard conversation?", "repair"),
        p(50, "What is a criticism you have made that was really about something else?", "criticism"),
        p(51, "Where do you find it hardest to let go of being right?", "humility"),
        p(52, "What is something you have never fully forgiven, even if you said you had?", "forgiveness"),
        p(53, "What do you do when you feel attacked?", "defensiveness"),
        p(54, "What is one thing you could yield on in the next disagreement — not because you were wrong, but to show you are for them?", "mutual-yielding"),
        p(55, "When did you last feel like one flesh during a disagreement?", "unity"),
        p(56, "What is one thing you want them to know about how you fight?", "disclosure")
    ]

    // MARK: - Arc 5 · Closeness (days 57–70)

    static let arc5: [Prompt] = [
        p(57, "What does it mean to delight in your partner? When did you last feel that?", "delight"),
        p(58, "What do you miss about how the two of you used to be?", "nostalgia"),
        p(59, "What makes you feel wanted?", "desire"),
        p(60, "When do you feel most disconnected? What usually comes just before it?", "distance"),
        p(61, "What is a small gesture that means more to you than a grand one?", "gratitude"),
        p(62, "What would you like more of — time, touch, talk, or quiet together?", "needs"),
        p(63, "What is something you would like to do together that you never have?", "novelty"),
        p(64, "When do you feel most playful with them?", "joy"),
        p(65, "What is one way they could make an ordinary evening better?", "rituals"),
        p(66, "What do you miss doing together?", "nostalgia"),
        p(67, "What does a good evening look like to you?", "rituals"),
        p(68, "What is something you want to protect from your busiest weeks?", "priorities"),
        p(69, "When did you last feel chosen by them?", "covenant"),
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
        p(77, "What do you want your home to feel like to someone who visits?", "hospitality"),
        p(78, "What is a conviction you two share that you rarely name out loud?", "values"),
        p(79, "What are you both willing to sacrifice for?", "calling"),
        p(80, "What does covenant mean to you on an ordinary Tuesday?", "covenant"),
        p(81, "What would you want people who know you to say about your marriage?", "witness"),
        p(82, "What is something you are building together, even if it is slow?", "vision")
    ]

    // MARK: - Arc 7 · Looking forward (days 83–90)

    static let arc7: [Prompt] = [
        p(83, "What has changed between you this year — for better, and for worse?", "reflection"),
        p(84, "What is one thing you want to keep doing?", "reflection"),
        p(85, "What is one thing you want to stop doing?", "repentance"),
        p(86, "What has been harder than you expected?", "reflection"),
        p(87, "What are you grateful for that you have never told them?", "gratitude"),
        p(88, "What do you want to be different a month from now?", "intention"),
        p(89, "What do you want to remember about this season of your life?", "reflection"),
        p(90, "What blessing do you want to speak over them as you finish these ninety days?", "blessing")
    ]

    /// All 90 days in order. Index 0 is day 1.
    static let all: [Prompt] = arc1 + arc2 + arc3 + arc4 + arc5 + arc6 + arc7
}
