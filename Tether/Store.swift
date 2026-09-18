import Foundation
import Observation
import SwiftData

/// In-memory session state. Deliberately thin — all durable data lives in SwiftData.
@Observable
final class SessionStore {
    var profile: UserProfile?
    var showPaywall = false
    var safetyBanner: String?
}

// MARK: - Streaks

enum Streaks {
    /// Counts consecutive days ending today (or yesterday, so it survives
    /// a user opening the app late at night).
    static func current(from dates: [Date]) -> Int {
        let days = Set(dates.map { Calendar.current.startOfDay(for: $0) })
        guard !days.isEmpty else { return 0 }

        let cal = Calendar.current
        var cursor = cal.startOfDay(for: Date())
        if !days.contains(cursor) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }

        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }
}

// MARK: - Dates

extension Date {
    var shortDisplay: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    var weekdayDisplay: String {
        formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}

// MARK: - Pairing

/// Local-first pairing. Redeeming a code creates a second profile on this device
/// and links both sides. When the backend arrives only `redeem` changes — every
/// screen and state in the flow stays exactly as it is.
enum PairingService {

    static let inviteMessage =
        "Hey — I found something I would like us to try together. It is called Tether. One minute a day, that is it."

    @discardableResult
    static func createInvite(in ctx: ModelContext, inviterID: UUID) -> Invite {
        let all = (try? ctx.fetch(FetchDescriptor<Invite>())) ?? []
        all.filter { $0.inviterID == inviterID && $0.status == .pending }
           .forEach { $0.status = .revoked }

        let invite = Invite(inviterID: inviterID)
        ctx.insert(invite)
        try? ctx.save()
        return invite
    }

    static func pendingInvite(in ctx: ModelContext, inviterID: UUID) -> Invite? {
        let all = (try? ctx.fetch(FetchDescriptor<Invite>())) ?? []
        return all.filter { $0.inviterID == inviterID && $0.status == .pending }
                  .sorted { $0.createdAt > $1.createdAt }
                  .first
    }

    @discardableResult
    static func redeem(code: String,
                       in ctx: ModelContext,
                       me: UserProfile,
                       partnerName: String = "Partner") -> Bool {
        // Already paired — do not create a second partner or leave a dangling one.
        guard me.partnerID == nil else { return false }

        let all = (try? ctx.fetch(FetchDescriptor<Invite>())) ?? []
        guard let invite = all.first(where: { $0.code == code && $0.status == .pending }) else {
            return false
        }

        let partner = UserProfile(displayName: partnerName, track: .secular)
        partner.onboardingDone = true
        partner.isSolo = false
        partner.partnerID = me.id
        ctx.insert(partner)

        me.partnerID = partner.id
        me.isSolo = false
        me.pairedAt = Date()

        invite.status = .accepted
        try? ctx.save()
        return true
    }

    static func nudge(_ invite: Invite, in ctx: ModelContext) {
        guard invite.canNudge else { return }
        invite.nudgeCount += 1
        invite.lastNudgedAt = Date()
        try? ctx.save()
    }

    static func elapsedLabel(for invite: Invite) -> String {
        let hours = invite.hoursElapsed
        if hours < 1 { return "Sent just now" }
        if hours < 24 { return "Sent \(Int(hours))h ago" }
        let days = Int(hours / 24)
        return days == 1 ? "Sent yesterday" : "Sent \(days) days ago"
    }
}

// MARK: - Love language (local-first, no schema migration)

/// The onboarding love-language quiz result is stored here rather than on the
/// SwiftData model. It is a stable, optional user preference, and keeping it in
/// `UserDefaults` keyed by profile id means adding it requires no migration of
/// the persistent store — important while the schema is still moving.
enum LoveLanguageStore {
    private static let keyBase = "tether.loveLanguage"

    static func set(_ language: LoveLanguage, for profileID: UUID) {
        UserDefaults.standard.set(language.rawValue, forKey: "\(keyBase).\(profileID.uuidString)")
    }

    static func get(for profileID: UUID) -> LoveLanguage? {
        guard let raw = UserDefaults.standard.string(forKey: "\(keyBase).\(profileID.uuidString)") else {
            return nil
        }
        return LoveLanguage(rawValue: raw)
    }

    static func clear(for profileID: UUID) {
        UserDefaults.standard.removeObject(forKey: "\(keyBase).\(profileID.uuidString)")
    }
}
