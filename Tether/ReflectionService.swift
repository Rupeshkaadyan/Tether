import Foundation

// MARK: - Model

/// A week in review, computed entirely on this device.
struct WeeklyReflection: Equatable {
    var checkIns: Int
    var avgMood: Double?
    var previousAvgMood: Double?
    var bestDay: Date?
    var hardestDay: Date?
    var themes: [String]
    var streak: Int
    var summary: String

    static let empty = WeeklyReflection(checkIns: 0,
                                        avgMood: nil,
                                        previousAvgMood: nil,
                                        bestDay: nil,
                                        hardestDay: nil,
                                        themes: [],
                                        streak: 0,
                                        summary: "Write your first entry and this space will fill with your week.")
}

// MARK: - On-device engine

/// Reads the last seven days and writes a plain, honest summary in your own
/// voice. No network, no key, no cost — and nothing leaves the device.
enum WeeklyReflectionEngine {

    /// Words too common to say anything about someone's week.
    private static let stopwords: Set<String> = [
        "about", "after", "again", "against", "also", "always", "because", "been",
        "before", "being", "below", "between", "both", "came", "could", "didn",
        "doesn", "doing", "done", "down", "each", "even", "ever", "every", "felt",
        "from", "gave", "gets", "getting", "have", "haven", "here", "hers",
        "himself", "into", "isn", "itself", "just", "keep", "kept", "know",
        "like", "little", "looked", "made", "make", "many", "more", "most",
        "much", "must", "myself", "need", "never", "nothing", "once", "only",
        "other", "over", "really", "said", "same", "she", "should", "since",
        "some", "still", "such", "sure", "take", "than", "that", "that's",
        "their", "them", "then", "there", "these", "they", "thing", "think",
        "this", "those", "though", "through", "time", "told", "too", "under",
        "until", "very", "want", "wasn", "well", "went", "were", "what",
        "when", "where", "which", "while", "who", "will", "with", "without",
        "would", "your", "you're", "yours", "yourself"
    ]

    static func compute(entries: [JournalEntry],
                        replies: [PromptReply],
                        userID: UUID) -> WeeklyReflection {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let weekAgo = cal.date(byAdding: .day, value: -7, to: today),
              let twoWeeksAgo = cal.date(byAdding: .day, value: -14, to: today) else {
            return .empty
        }

        let mine = entries.filter { $0.userID == userID }
        let myReplies = replies.filter { $0.userID == userID }

        // Moods by day, for this week and the one before it.
        var thisWeek: [Date: [Int]] = [:]
        var lastWeek: [Date: [Int]] = [:]
        var texts: [String] = []

        for entry in mine {
            let day = cal.startOfDay(for: entry.entryDate)
            if day >= weekAgo {
                thisWeek[day, default: []].append(entry.mood)
                texts.append(SecureContent.read(entry.body))
            } else if day >= twoWeeksAgo {
                lastWeek[day, default: []].append(entry.mood)
            }
        }
        for reply in myReplies {
            let day = cal.startOfDay(for: reply.forDate)
            if day >= weekAgo {
                thisWeek[day, default: []].append(reply.mood)
                texts.append(SecureContent.read(reply.body))
            } else if day >= twoWeeksAgo {
                lastWeek[day, default: []].append(reply.mood)
            }
        }

        let checkIns = thisWeek.values.reduce(0) { $0 + $1.count }
        guard checkIns > 0 else { return .empty }

        let avg = average(of: thisWeek)
        let prev = average(of: lastWeek)

        // Best and hardest days, by the day's own average mood.
        let ranked = thisWeek
            .map { (day: $0.key, mood: Double($0.value.reduce(0, +)) / Double($0.value.count)) }
            .sorted { $0.mood > $1.mood }
        let bestDay = ranked.first?.day
        let hardestDay = ranked.count > 1 ? ranked.last?.day : nil

        let themes = topThemes(from: texts)
        let streak = Streaks.current(from: mine.map(\.entryDate) + myReplies.map(\.forDate))

        let summary = prose(checkIns: checkIns,
                            avg: avg,
                            prev: prev,
                            bestDay: bestDay,
                            hardestDay: hardestDay,
                            themes: themes,
                            streak: streak)

        return WeeklyReflection(checkIns: checkIns,
                                avgMood: avg,
                                previousAvgMood: prev,
                                bestDay: bestDay,
                                hardestDay: hardestDay,
                                themes: themes,
                                streak: streak,
                                summary: summary)
    }

    // MARK: Helpers

    private static func average(of days: [Date: [Int]]) -> Double? {
        let all = days.values.flatMap { $0 }
        guard !all.isEmpty else { return nil }
        return Double(all.reduce(0, +)) / Double(all.count)
    }

    /// Most-used meaningful words. Crude, but enough to name a theme honestly.
    private static func topThemes(from texts: [String], limit: Int = 3) -> [String] {
        var counts: [String: Int] = [:]
        for text in texts {
            let words = text.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 4 && !stopwords.contains($0) }
            for word in words { counts[word, default: 0] += 1 }
        }
        return counts
            .filter { $0.value > 1 }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map(\.key)
    }

    private static func prose(checkIns: Int,
                              avg: Double?,
                              prev: Double?,
                              bestDay: Date?,
                              hardestDay: Date?,
                              themes: [String],
                              streak: Int) -> String {
        var parts: [String] = []

        parts.append("You checked in \(checkIns) \(checkIns == 1 ? "time" : "times") this week.")

        if let avg {
            let rounded = String(format: "%.1f", avg)
            if let prev {
                let delta = avg - prev
                if delta > 0.2 {
                    parts.append("Your mood averaged \(rounded), up from \(String(format: "%.1f", prev)) last week.")
                } else if delta < -0.2 {
                    parts.append("Your mood averaged \(rounded), down from \(String(format: "%.1f", prev)) last week.")
                } else {
                    parts.append("Your mood averaged \(rounded), about the same as last week.")
                }
            } else {
                parts.append("Your mood averaged \(rounded).")
            }
        }

        if let bestDay {
            parts.append("\(bestDay.weekdayName) was your brightest day.")
        }
        if let hardestDay {
            parts.append("\(hardestDay.weekdayName) was harder.")
        }
        if !themes.isEmpty {
            let listed = themes.map { "'\($0)'" }.joined(separator: ", ")
            parts.append("\(listed) came up most.")
        }
        if streak > 1 {
            parts.append("Your streak is \(streak) days.")
        }

        return parts.joined(separator: " ")
    }
}

private extension Date {
    var weekdayName: String {
        formatted(.dateTime.weekday(.wide))
    }
}

// MARK: - Consent

/// Off by default. Tether's promise is that words never leave the device, so a
/// deeper (server) reflection is something a person opts into, deliberately.
enum ReflectionSettings {
    private static let key = "tether.reflection.shareAnonymized"

    static var sharesAnonymizedSummary: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

// MARK: - Optional deeper reflection (server)

/// Talks to *your own* proxy, which is the only place an AI key should ever
/// live. Shipping a key inside the app binary means anyone can extract it.
///
/// Until you set an endpoint this is inert and the on-device summary is used.
/// Only anonymized aggregates are ever sent — never raw entry text.
struct RemoteReflectionProvider {

    /// Point this at your proxy (Claude, OpenAI, or Gemini behind it).
    /// Empty means disabled.
    static var endpoint: String {
        UserDefaults.standard.string(forKey: "tether.reflection.endpoint") ?? ""
    }

    static var isConfigured: Bool { !endpoint.isEmpty }

    /// Facts about a week, with no words attached. This is the most a server
    /// ever learns about someone using Tether.
    struct AnonymizedPayload: Codable {
        let checkIns: Int
        let avgMood: Double?
        let moodDelta: Double?
        let themes: [String]
        let streak: Int
        let track: String
    }

    private struct Response: Codable {
        let reflection: String
    }

    static func deeperReflection(for reflection: WeeklyReflection,
                                 track: String) async -> String? {
        guard isConfigured, let url = URL(string: endpoint) else { return nil }

        let delta: Double? = {
            guard let now = reflection.avgMood, let before = reflection.previousAvgMood else { return nil }
            return now - before
        }()

        let payload = AnonymizedPayload(checkIns: reflection.checkIns,
                                        avgMood: reflection.avgMood,
                                        moodDelta: delta,
                                        themes: reflection.themes,
                                        streak: reflection.streak,
                                        track: track)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(payload)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else { return nil }
            if let decoded = try? JSONDecoder().decode(Response.self, from: data) {
                return decoded.reflection
            }
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
