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

    var symbol: String {
        switch self {
        case .secular:  return "brain.head.profile"
        case .biblical: return "book.closed"
        case .vedic:    return "flame"
        case .quranic:  return "moon.stars"
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

    var symbol: String {
        switch self {
        case .thriving: return "leaf.fill"
        case .drifting: return "waveform.path"
        case .strained: return "exclamationmark.circle"
        case .unknown:  return "circle.dashed"
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
    var id: UUID
    var displayName: String
    var trackRaw: String
    var locale: String
    var timeZoneID: String
    var notifyHour: Int
    var onboardingStep: Int
    var onboardingDone: Bool
    var isSolo: Bool
    var partnerID: UUID?
    var pairedAt: Date?
    var createdAt: Date

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

@Model
final class MoodLog {
    var id: UUID
    var userID: UUID
    var loggedDate: Date
    var mood: Int
    var createdAt: Date

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
    var id: UUID
    var userID: UUID
    var entryDate: Date
    /// Holds ciphertext once the encryption layer ships. Plaintext for now.
    var body: String
    var mood: Int
    var visibilityRaw: String
    var sourceRaw: String
    var safetyFlagged: Bool
    var createdAt: Date

    init(userID: UUID, body: String, mood: Int, source: EntrySource = .journal) {
        self.id = UUID()
        self.userID = userID
        self.entryDate = Date()
        self.body = body
        self.mood = mood
        self.visibilityRaw = Visibility.shared.rawValue
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
    var id: UUID
    var userID: UUID
    var promptID: String
    var forDate: Date
    /// Holds ciphertext once the encryption layer ships.
    var body: String
    var mood: Int
    var isVoice: Bool
    var createdAt: Date

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
    var id: UUID
    var inviterID: UUID
    var code: String
    var token: UUID
    var statusRaw: String
    var createdAt: Date
    var expiresAt: Date
    var nudgeCount: Int
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
    var id: UUID
    var ownerID: UUID
    var computedOn: Date
    var stateRaw: String
    var score: Double
    var trendRaw: String
    var cadenceScore: Double
    var moodScore: Double
    var consistencyScore: Double

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
