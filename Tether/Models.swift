import Foundation
import SwiftData
import SwiftUI

// MARK: - Enums

enum WisdomTrack: String, Codable, CaseIterable, Identifiable {
    case secular, biblical, vedic, quranic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .secular:  return "Secular & Psychology"
        case .biblical: return "Biblical"
        case .vedic:    return "Vedic & Dharmic"
        case .quranic:  return "Quranic"
        }
    }

    var shortName: String {
        switch self {
        case .secular:  return "Secular"
        case .biblical: return "Biblical"
        case .vedic:    return "Vedic"
        case .quranic:  return "Quranic"
        }
    }

    var blurb: String {
        switch self {
        case .secular:  return "Evidence-based tools from relationship science."
        case .biblical: return "Scripture-grounded guidance for Christian couples."
        case .vedic:    return "Dharmic wisdom for Hindu couples."
        case .quranic:  return "Quranic guidance for Muslim couples."
        }
    }

    /// Custom glyph from the icon pack. Abstract, never a religious symbol —
    /// see the note on `TetherIcon`.
    var icon: TetherIcon {
        switch self {
        case .secular:  return .trackSecular
        case .biblical: return .trackBiblical
        case .vedic:    return .trackVedic
        case .quranic:  return .trackQuranic
        }
    }

    /// Each track gets its own identity colour. Distinct enough that a partner
    /// can tell at a glance whose content they are looking at.
    var accent: Color {
        switch self {
        case .secular:  return Color(hex: "4A7DBF")
        case .biblical: return Color(hex: "7B6BD6")
        case .vedic:    return Color(hex: "D98A2B")
        case .quranic:  return Color(hex: "2E9E7B")
        }
    }

    /// All four tracks are available. A couple must never open this app and find
    /// their own tradition marked "coming soon" — that is the whole point of the
    /// product. Kept as a property so a track can be pulled in an emergency
    /// without touching every call site.
    var isLive: Bool { true }
}

enum Visibility: String, Codable {
    case shared, `private`
}

/// Who you are, asked once at the start and never again.
///
/// This only sets the DEFAULT accent. It is not a gate and not a judgement —
/// anyone can change the accent in Settings afterwards. Picking "Woman" simply
/// starts you on the rose palette instead of the indigo one, because that is
/// what most people who pick it turn out to want, and expecting them to go and
/// find it in Settings is expecting them to know it exists.
enum Gender: String, CaseIterable, Identifiable {
    // Declaration order IS display order — CaseIterable follows it. Man,
    // Woman, then the rest.
    case man, woman, nonbinary, undisclosed

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .woman:       return "Woman"
        case .man:         return "Man"
        case .nonbinary:   return "Non-binary"
        case .undisclosed: return "Prefer not to say"
        }
    }

    var symbol: String {
        switch self {
        case .woman:       return "person.fill"
        case .man:         return "person.fill"
        case .nonbinary:   return "person.fill"
        case .undisclosed: return "person.crop.circle"
        }
    }

    /// The accent this choice starts you on.
    ///
    /// Woman gets the rose palette across the whole app. Man gets Bold — a
    /// deep steel blue, which reads as weight rather than decoration. The
    /// others start on the neutral indigo. All three stay selectable
    /// afterwards; this is only which one is pre-chosen.
    var preferredFeel: FeelManager.Feel {
        switch self {
        case .woman: return .warm
        case .man:   return .bold
        default:     return .classic
        }
    }
}

enum EntrySource: String, Codable {
    case prompt, journal, coach
}

enum PulseState: String, Codable, CaseIterable {
    case thriving, drifting, strained, unknown

    var displayName: String {
        switch self {
        case .thriving: return "Thriving"
        case .drifting: return "Drifting"
        case .strained: return "Strained"
        case .unknown:  return "Getting to know you"
        }
    }

    var color: Color {
        switch self {
        case .thriving: return TetherColor.thriving
        case .drifting: return TetherColor.drifting
        case .strained: return TetherColor.strained
        case .unknown:  return TetherColor.muted
        }
    }

    var icon: TetherIcon {
        switch self {
        case .thriving: return .pulse
        case .drifting: return .trendFlat
        case .strained: return .alert
        case .unknown:  return .pulse
        }
    }
}

enum LoveLanguage: String, Codable, CaseIterable, Identifiable {
    case words, acts, gifts, time, touch

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .words: return "Words of Affirmation"
        case .acts:  return "Acts of Service"
        case .gifts: return "Receiving Gifts"
        case .time:  return "Quality Time"
        case .touch: return "Physical Touch"
        }
    }

    var symbol: String {
        switch self {
        case .words: return "text.bubble"
        case .acts:  return "hands.sparkles"
        case .gifts: return "gift"
        case .time:  return "clock"
        case .touch: return "hand.raised"
        }
    }
}

// MARK: - Mood helper

enum Mood {
    static let range = 1...5

    static func label(for value: Int) -> String {
        switch value {
        case 1: return "Strained"
        case 2: return "Low"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Thriving"
        default: return "—"
        }
    }

    static func color(for value: Int) -> Color {
        switch value {
        case 1: return TetherColor.strained
        case 2: return TetherColor.strained.opacity(0.7)
        case 3: return TetherColor.drifting
        case 4: return TetherColor.thriving.opacity(0.7)
        case 5: return TetherColor.thriving
        default: return TetherColor.border
        }
    }
}

// MARK: - SwiftData models

@Model
final class UserProfile {
    var id: UUID = UUID()
    var displayName: String = ""
    /// A small avatar, shown next to your name and beside your partner's when
    /// you are connected. External storage keeps it out of the main store.
    @Attribute(.externalStorage) var photoData: Data?
    /// Asked once during onboarding. Sets the starting accent only — see
    /// `Gender` for why it is not a gate.
    var genderRaw: String = ""
    var trackRaw: String = ""
    var locale: String = ""
    var timeZoneID: String = ""
    var notifyHour: Int = 0
    var onboardingStep: Int = 0
    var onboardingDone: Bool = false
    var isSolo: Bool = false
    var partnerID: UUID?
    var pairedAt: Date?
    var createdAt: Date = Date()

    init(displayName: String, track: WisdomTrack) {
        self.id = UUID()
        self.displayName = displayName
        self.trackRaw = track.rawValue
        self.locale = "en-US"
        self.timeZoneID = TimeZone.current.identifier
        self.notifyHour = 20
        self.onboardingStep = 0
        self.onboardingDone = false
        self.isSolo = true
        self.partnerID = nil
        self.pairedAt = nil
        self.createdAt = Date()
    }

    var track: WisdomTrack {
        get { WisdomTrack(rawValue: trackRaw) ?? .secular }
        set { trackRaw = newValue.rawValue }
    }
}

/// A stated pause. "I need a quiet week."
///
/// Every other couples app is built to maximise engagement, which is exactly
/// why none of them has this: a pause button works against the business model.
/// But the alternative is what already happens everywhere — one person quietly
/// goes silent, and the other spends the week not knowing why.
///
/// This turns a withdrawal into a message. Nothing is broken; something was
/// simply said. The app stops nudging BOTH people, because a reminder to
/// "show up for each other" is the last thing either of them needs.
@Model
final class Pause {
    var id: UUID = UUID()
    /// Who asked for it. Never shown as blame — just as whose request it is.
    var startedByID: UUID = UUID()
    var startsOn: Date = Date()
    var endsOn: Date = Date()
    var createdAt: Date = Date()
    /// Optional, and shown to the partner. "Work is heavy." "I'm not well."
    var note: String = ""

    init(startedByID: UUID, days: Int = 7, note: String = "") {
        self.id = UUID()
        self.startedByID = startedByID
        let now = Date()
        self.startsOn = now
        self.endsOn = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        self.createdAt = now
        self.note = note
    }

    var isActive: Bool { Date() < endsOn }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day],
                                               from: Date(),
                                               to: endsOn).day ?? 0)
    }
}

/// Something written but not sent. A private place to think before speaking.
///
/// The category leader is criticised for exactly this gap: answers are shared,
/// so there is nowhere to work out a feeling before raising it. This is that
/// place. Nothing here is ever shown to anyone.
@Model
final class UnsentNote {
    var id: UUID = UUID()
    var authorID: UUID = UUID()
    var body: String = ""
    var createdAt: Date = Date()
    /// Set when the person decides what to do with it.
    var resolvedAt: Date?
    /// "kept", "released", or "journalled" — see `Resolution`.
    var resolutionRaw: String?

    init(authorID: UUID, body: String) {
        self.id = UUID()
        self.authorID = authorID
        self.body = body
        self.createdAt = Date()
        self.resolvedAt = nil
        self.resolutionRaw = nil
    }

    enum Resolution: String {
        /// Still sitting here, unread by anyone.
        case open
        /// Decided it did not need saying. Kept as a record.
        case kept
        /// Let go. The text is gone; the fact of it remains.
        case released
        /// Moved into the private journal as an entry.
        case journalled
    }

    var resolution: Resolution {
        get { Resolution(rawValue: resolutionRaw ?? "") ?? .open }
        set { resolutionRaw = newValue.rawValue }
    }
}

/// A folded note kept in the Wisdom Jar.
///
/// Written on a good day, drawn on a hard one. The whole point is that the
/// person who needs it is often not the person who wrote it — and sometimes it
/// is. Both count.
@Model
final class JarNote {
    var id: UUID = UUID()
    var authorID: UUID = UUID()
    var body: String = ""
    var createdAt: Date = Date()
    /// How many times this note has been drawn. Shown as a small crease.
    var drawnCount: Int = 0
    var lastDrawnAt: Date?

    /// Whether this note is visible to the other person.
    ///
    /// Defaults to TRUE — a jar nobody can see is a diary, and the whole point
    /// is that the person who needs the note is usually not the one who wrote
    /// it. But a note can always be kept back, and the app must never make
    /// that feel like a betrayal. Nothing is shared silently in either
    /// direction: the choice is made at the moment of writing, and it is
    /// stated on the note afterwards.
    var sharedWithPartner: Bool = false

    init(authorID: UUID, body: String, sharedWithPartner: Bool = true) {
        self.id = UUID()
        self.authorID = authorID
        self.body = body
        self.createdAt = Date()
        self.drawnCount = 0
        self.lastDrawnAt = nil
        self.sharedWithPartner = sharedWithPartner
    }
}

/// A message in the couple's private conversation. Separate from the journal:
/// the journal is a practice, this is just the two of you talking.
@Model
final class ChatMessage {
    var id: UUID = UUID()
    var senderID: UUID = UUID()
    var body: String = ""
    var createdAt: Date = Date()
    var readAt: Date?

    init(senderID: UUID, body: String) {
        self.id = UUID()
        self.senderID = senderID
        self.body = body
        self.createdAt = Date()
        self.readAt = nil
    }
}

/// The couple's own recurring appointment — "Sunday evening check-in". Turns a
/// daily habit into something you have agreed to show up for together.
@Model
final class Ritual {
    var id: UUID = UUID()
    var name: String = ""
    /// 1 = Sunday … 7 = Saturday, matching Calendar's weekday numbering.
    var weekday: Int = 0
    var hour: Int = 0
    var minute: Int = 0
    var createdAt: Date = Date()

    init(name: String, weekday: Int, hour: Int, minute: Int) {
        self.id = UUID()
        self.name = name
        self.weekday = weekday
        self.hour = hour
        self.minute = minute
        self.createdAt = Date()
    }

    /// The next time this ritual comes around, from `now`.
    func nextOccurrence(after now: Date = Date()) -> Date? {
        let cal = Calendar.current
        var comps = DateComponents()
        comps.weekday = weekday
        comps.hour = hour
        comps.minute = minute
        return cal.nextDate(after: now,
                            matching: comps,
                            matchingPolicy: .nextTime)
    }

    var weekdayName: String {
        let cal = Calendar.current
        let symbols = cal.weekdaySymbols
        let index = max(0, min(symbols.count - 1, weekday - 1))
        return symbols[index]
    }

    var timeLabel: String {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let cal = Calendar.current
        guard let date = cal.date(from: comps) else { return "" }
        return date.formatted(date: .omitted, time: .shortened)
    }
}

/// A note written into a SHARED thread rather than a private journal.
/// Two threads use it: gratitude (what you appreciate) and "us" (a shared
/// space belonging to the couple). Both are visible to both partners.
@Model
final class SharedNote {
    var id: UUID = UUID()
    var authorID: UUID = UUID()
    var body: String = ""
    var kindRaw: String = ""
    var createdAt: Date = Date()

    init(authorID: UUID, body: String, kind: SharedNoteKind) {
        self.id = UUID()
        self.authorID = authorID
        self.body = body
        self.kindRaw = kind.rawValue
        self.createdAt = Date()
    }

    var kind: SharedNoteKind {
        get { SharedNoteKind(rawValue: kindRaw) ?? .gratitude }
        set { kindRaw = newValue.rawValue }
    }
}

enum SharedNoteKind: String, CaseIterable, Identifiable {
    case gratitude, us

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gratitude: return "Gratitude"
        case .us:        return "Us"
        }
    }

    var blurb: String {
        switch self {
        case .gratitude:
            return "One thing you appreciate about them. Small and specific beats grand."
        case .us:
            return "A space that belongs to the two of you. Anything at all — no prompt, no shape."
        }
    }

    var placeholder: String {
        switch self {
        case .gratitude: return "One thing I appreciate…"
        case .us:        return "Write something for the two of us…"
        }
    }

    var emptyLine: String {
        switch self {
        case .gratitude: return "Nothing here yet. The first thank-you starts the thread."
        case .us:        return "Nothing here yet. Write the first line of your shared story."
        }
    }
}

/// A one-tap signal from one partner to the other — "thinking of you",
/// "proud of you". No writing required, which is the point: it is the
/// smallest possible act of care.
@Model
final class Warmth {
    var id: UUID = UUID()
    var fromID: UUID = UUID()
    var toID: UUID = UUID()
    var kindRaw: String = ""
    var createdAt: Date = Date()
    var seen: Bool = false

    init(fromID: UUID, toID: UUID, kind: WarmthKind) {
        self.id = UUID()
        self.fromID = fromID
        self.toID = toID
        self.kindRaw = kind.rawValue
        self.createdAt = Date()
        self.seen = false
    }

    var kind: WarmthKind {
        get { WarmthKind(rawValue: kindRaw) ?? .thinking }
        set { kindRaw = newValue.rawValue }
    }
}

enum WarmthKind: String, CaseIterable, Identifiable {
    case thinking, proud, miss, grateful, here

    var id: String { rawValue }

    /// Written in the first person — these are the words the sender means.
    var label: String {
        switch self {
        case .thinking: return "Thinking of you"
        case .proud:    return "Proud of you"
        case .miss:     return "Missing you"
        case .grateful: return "Grateful for you"
        case .here:     return "Here if you need me"
        }
    }

    /// Shown as the chip on the button.
    var short: String {
        switch self {
        case .thinking: return "Thinking of you"
        case .proud:    return "Proud of you"
        case .miss:     return "Missing you"
        case .grateful: return "Grateful"
        case .here:     return "I'm here"
        }
    }

    var symbol: String {
        switch self {
        case .thinking: return "sparkles"
        case .proud:    return "star.fill"
        case .miss:     return "moon.stars.fill"
        case .grateful: return "heart.fill"
        case .here:     return "hand.raised.fill"
        }
    }
}

@Model
final class MoodLog {
    var id: UUID = UUID()
    var userID: UUID = UUID()
    var loggedDate: Date = Date()
    var mood: Int = 0
    var createdAt: Date = Date()

    init(userID: UUID, mood: Int, loggedDate: Date = Date()) {
        self.id = UUID()
        self.userID = userID
        self.loggedDate = Calendar.current.startOfDay(for: loggedDate)
        self.mood = mood
        self.createdAt = Date()
    }
}

@Model
final class JournalEntry {
    var id: UUID = UUID()
    var userID: UUID = UUID()
    var entryDate: Date = Date()
    /// Holds ciphertext once the encryption layer ships. Plaintext for now.
    var body: String = ""
    var mood: Int = 0
    var visibilityRaw: String = ""
    var sourceRaw: String = ""
    var safetyFlagged: Bool = false
    var createdAt: Date = Date()

    /// An optional one-line response from the other person — the thing that
    /// turns Tether from a monologue into a conversation.
    /// Only ever set on SHARED entries. A private entry can never be replied
    /// to, which is what keeps the privacy promise intact.
    var replyBody: String?
    var replyBy: UUID?
    var replyAt: Date?

    /// An optional photo kept with the entry. External storage keeps the
    /// database small — SwiftData writes the bytes to a separate file and
    /// stores only a reference.
    @Attribute(.externalStorage) var photoData: Data?

    /// An optional voice note. Also external storage, for the same reason —
    /// audio is far bigger than the text it accompanies.
    @Attribute(.externalStorage) var voiceData: Data?

    init(userID: UUID, body: String, mood: Int, source: EntrySource = .journal) {
        self.id = UUID()
        self.userID = userID
        self.entryDate = Date()
        self.body = body
        self.mood = mood
        // PRIVATE BY DEFAULT.
        //
        // This was `.shared`, which meant every journal entry a person wrote
        // was visible to their partner unless something explicitly changed it.
        // Nothing did. So the "Only me" tab was always empty, the Shared tab
        // held everything, and the app quietly broke its own privacy promise
        // for anyone who did not go looking for a setting that did not exist.
        //
        // Sharing must be a deliberate act, not the absence of one.
        self.visibilityRaw = Visibility.private.rawValue
        self.sourceRaw = source.rawValue
        self.safetyFlagged = false
        self.createdAt = Date()
    }

    var visibility: Visibility {
        get { Visibility(rawValue: visibilityRaw) ?? .shared }
        set { visibilityRaw = newValue.rawValue }
    }

    var source: EntrySource {
        get { EntrySource(rawValue: sourceRaw) ?? .journal }
        set { sourceRaw = newValue.rawValue }
    }
}

@Model
final class PromptReply {
    var id: UUID = UUID()
    var userID: UUID = UUID()
    var promptID: String = ""
    var forDate: Date = Date()
    /// Holds ciphertext once the encryption layer ships.
    var body: String = ""
    var mood: Int = 0
    var isVoice: Bool = false
    var createdAt: Date = Date()

    init(userID: UUID, promptID: String, body: String, mood: Int, isVoice: Bool = false) {
        self.id = UUID()
        self.userID = userID
        self.promptID = promptID
        self.forDate = Calendar.current.startOfDay(for: Date())
        self.body = body
        self.mood = mood
        self.isVoice = isVoice
        self.createdAt = Date()
    }
}

// MARK: - Pairing

enum InviteStatus: String, Codable {
    case pending, accepted, expired, revoked
}

@Model
final class Invite {
    var id: UUID = UUID()
    var inviterID: UUID = UUID()
    var code: String = ""
    var token: UUID = UUID()
    var statusRaw: String = ""
    var createdAt: Date = Date()
    var expiresAt: Date = Date()
    var nudgeCount: Int = 0
    var lastNudgedAt: Date?

    init(inviterID: UUID) {
        self.id = UUID()
        self.inviterID = inviterID
        self.code = Invite.randomCode()
        self.token = UUID()
        self.statusRaw = InviteStatus.pending.rawValue
        self.createdAt = Date()
        self.expiresAt = Date().addingTimeInterval(7 * 24 * 60 * 60)
        self.nudgeCount = 0
        self.lastNudgedAt = nil
    }

    static func randomCode() -> String {
        let digits = "0123456789"
        return String((0..<6).compactMap { _ in digits.randomElement() })
    }

    var status: InviteStatus {
        get { InviteStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var isExpired: Bool { Date() > expiresAt }

    /// Hours since the invite went out. Drives the nudge and solo-fallback ladder.
    var hoursElapsed: Double {
        Date().timeIntervalSince(createdAt) / 3600
    }

    /// The 72-hour fallback. After three days of silence we stop waiting and
    /// hand the user their own product.
    var shouldOfferSolo: Bool {
        status == .pending && hoursElapsed >= 72
    }

    var canNudge: Bool {
        status == .pending && nudgeCount < 3
    }
}

// MARK: - Relationship Pulse

enum PulseTrend: String, Codable {
    case rising, steady, falling, unknown

    var displayName: String {
        switch self {
        case .rising:  return "Improving"
        case .steady:  return "Steady"
        case .falling: return "Slipping"
        case .unknown: return "Not enough data"
        }
    }

    var symbol: String {
        switch self {
        case .rising:  return "arrow.up.right"
        case .steady:  return "arrow.right"
        case .falling: return "arrow.down.right"
        case .unknown: return "questionmark"
        }
    }
}

@Model
final class RelationshipPulse {
    var id: UUID = UUID()
    var ownerID: UUID = UUID()
    var computedOn: Date = Date()
    var stateRaw: String = ""
    var score: Double = 0
    var trendRaw: String = ""
    var cadenceScore: Double = 0
    var moodScore: Double = 0
    var consistencyScore: Double = 0

    init(ownerID: UUID,
         state: PulseState,
         score: Double,
         trend: PulseTrend,
         cadence: Double,
         mood: Double,
         consistency: Double) {
        self.id = UUID()
        self.ownerID = ownerID
        self.computedOn = Date()
        self.stateRaw = state.rawValue
        self.score = score
        self.trendRaw = trend.rawValue
        self.cadenceScore = cadence
        self.moodScore = mood
        self.consistencyScore = consistency
    }

    var state: PulseState {
        get { PulseState(rawValue: stateRaw) ?? .unknown }
        set { stateRaw = newValue.rawValue }
    }

    var trend: PulseTrend {
        get { PulseTrend(rawValue: trendRaw) ?? .unknown }
        set { trendRaw = newValue.rawValue }
    }
}
