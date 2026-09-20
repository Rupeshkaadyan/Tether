import SwiftUI
import UIKit

// MARK: - Home Screen quick actions
//
// Long-press the app icon. For a journal this matters more than for most
// apps: the thought you want to write down arrives while you are doing
// something else, and every screen between the icon and a blank page is a
// chance to lose it.

enum QuickAction: String {
    case newEntry
    case todayPrompt
    case quietWeek

    var type: String { "com.tethercouples.app.\(rawValue)" }

    var title: String {
        switch self {
        case .newEntry:    return "New entry"
        case .todayPrompt: return "Today's question"
        case .quietWeek:   return "Quiet week"
        }
    }

    var subtitle: String? {
        switch self {
        case .newEntry:    return "Write something down"
        case .todayPrompt: return "Answer in one line"
        case .quietWeek:   return "Pause the reminders"
        }
    }

    var symbol: String {
        switch self {
        case .newEntry:    return "square.and.pencil"
        case .todayPrompt: return "bubble.left"
        case .quietWeek:   return "moon.zzz"
        }
    }

    /// Quick actions accept any SF Symbol name as a String — there is no
    /// preset enum, so the real symbol name is used directly rather than a
    /// near-enough preset.
    var systemImageName: String {
        switch self {
        case .newEntry:    return "square.and.pencil"
        case .todayPrompt: return "bubble.left"
        case .quietWeek:   return "moon.zzz"
        }
    }
}

enum AppShortcuts {

    static func install() {
        UIApplication.shared.shortcutItems = QuickAction.allCases.map { action in
            UIApplicationShortcutItem(
                type: action.type,
                localizedTitle: action.title,
                localizedSubtitle: action.subtitle,
                icon: UIApplicationShortcutIcon(systemImageName: action.systemImageName))
        }
    }

    /// Called from the root when the app is launched or resumed by a shortcut.
    /// Returns the action if it was one of ours.
    static func handle(_ item: UIApplicationShortcutItem) -> QuickAction? {
        QuickAction.allCases.first { $0.type == item.type }
    }
}

extension QuickAction: CaseIterable {}
