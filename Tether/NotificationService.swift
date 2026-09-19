import Foundation
import UserNotifications
import Observation

/// Local notifications only. No server push yet — when the backend lands,
/// remote pushes are added alongside these; the identifiers stay the same.
@Observable
final class NotificationService {

    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    var isAuthorized = false
    var authorizationDenied = false

    private enum ID {
        static let dailyPrompt = "tether.daily.prompt"
        static let streakRisk  = "tether.streak.risk"
    }

    private init() {}

    // MARK: - Permission

    /// Deliberately NOT called at launch. The PRD requires the ask to come after
    /// the first value moment — a prompt answered, a streak started — otherwise
    /// denial rates are far higher.
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isAuthorized = granted
                authorizationDenied = !granted
            }
            return granted
        } catch {
            await MainActor.run {
                isAuthorized = false
                authorizationDenied = true
            }
            return false
        }
    }

    func refreshStatus() async {
        let settings = await center.notificationSettings()
        let granted = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
        await MainActor.run { isAuthorized = granted }
    }

    // MARK: - Scheduling

    func reschedule(for profile: UserProfile) async {
        await refreshStatus()
        guard isAuthorized else { return }

        // The daily prompt is now seven separate requests, one per day, so the
        // removal has to clear all of them — leaving stale ones behind would
        // fire yesterday's question tomorrow.
        let dailyIDs = (0..<7).map { "\(ID.dailyPrompt).\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: dailyIDs + [ID.streakRisk])

        await scheduleDailyPrompt(hour: profile.notifyHour, profile: profile)
        await scheduleStreakRisk(hour: profile.notifyHour)
    }

    /// Carries the actual question, not a nudge to go and find it.
    ///
    /// "Today's prompt is ready" is a nag: it asks you to open an app to find
    /// out what it wants. The question itself is a gift — you can read it,
    /// answer it in your head, or reply straight from the lock screen.
    ///
    /// The prompts are deterministic by day index, so the next week can be
    /// scheduled up front with each day's real question. This replaces a
    /// single repeating trigger, which could only ever say the same thing
    /// every day forever.
    private func scheduleDailyPrompt(hour: Int, profile: UserProfile) async {
        let today = PromptLibrary.dayIndex(since: profile.createdAt)

        for offset in 0..<7 {
            guard let day = Calendar.current.date(byAdding: .day,
                                                  value: offset,
                                                  to: Date()) else { continue }
            let prompt = PromptLibrary.prompt(for: profile.track,
                                              dayIndex: today + offset)

            let content = UNMutableNotificationContent()
            content.title = prompt.body
            content.body = "One question. Under a minute."
            content.sound = .default
            content.userInfo = ["dayIndex": today + offset]

            var components = Calendar.current.dateComponents([.year, .month, .day],
                                                             from: day)
            components.hour = hour
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components,
                                                        repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(ID.dailyPrompt).\(offset)",
                content: content,
                trigger: trigger)
            try? await center.add(request)
        }
    }

    /// Evening nudge, only fires when nothing has been logged. Offers the freeze
    /// rather than threatening the streak — guilt drives churn, not retention.
    private func scheduleStreakRisk(hour: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Keep your streak?"
        content.body = "You have freezes available. No pressure either way."
        content.sound = nil

        var components = DateComponents()
        components.hour = min(hour + 3, 22)
        components.minute = 30

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: ID.streakRisk,
                                            content: content,
                                            trigger: trigger)
        try? await center.add(request)
    }

    /// Immediate, high-value. Sent when a partner answers and the reply unlocks.
    func notifyPartnerReplied(partnerName: String) async {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(partnerName) answered"
        content.body = "Your replies are unlocked."
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        try? await center.add(request)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Debug

    func pendingCount() async -> Int {
        await center.pendingNotificationRequests().count
    }
}
