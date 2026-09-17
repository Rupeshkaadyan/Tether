import SwiftUI

/// The custom icon set. These replace SF Symbols so the app reads as designed
/// rather than stock-iOS.
///
/// Every asset is registered with `template-rendering-intent: template`, so it
/// tints through `.foregroundStyle()` exactly like the source `currentColor`.
enum TetherIcon: String {
    // Tab bar — separate assets at 26pt intrinsic size, because `tabItem`
    // ignores `.resizable()` and sizes purely from the asset.
    case tabHome = "tab_home"
    case tabJournal = "tab_journal"
    case tabCoach = "tab_coach"
    case tabPulse = "tab_pulse"

    // Navigation
    case home = "navigation_home"
    case coach = "navigation_coach"
    case journal = "navigation_journal"
    case insights = "navigation_insights"
    case back = "navigation_back"
    case chevronLeft = "navigation_chevron_left"
    case chevronRight = "navigation_chevron_right"
    case close = "navigation_close"
    case menu = "navigation_menu"
    case more = "navigation_more"

    // Common
    case bell = "common_bell"
    case calendar = "common_calendar"
    case check = "common_check"
    case download = "common_download"
    case edit = "common_edit"
    case eye = "common_eye"
    case eyeOff = "common_eye_off"
    case link = "common_link"
    case lock = "common_lock"
    case mic = "common_mic"
    case minus = "common_minus"
    case plus = "common_plus"
    case search = "common_search"
    case send = "common_send"
    case settings = "common_settings"
    case share = "common_share"
    case trash = "common_trash"

    // Insights
    case pulse = "insights_pulse"
    case streak = "insights_streak"
    case trendUp = "insights_trend_up"
    case trendFlat = "insights_trend_flat"
    case trendDown = "insights_trend_down"

    // Journal
    case bookmark = "journal_bookmark"
    case memory = "journal_memory"
    case privateEntry = "journal_private"
    case sharedEntry = "journal_shared"

    // Mood
    case moodTerrible = "mood_terrible"
    case moodLow = "mood_low"
    case moodOkay = "mood_okay"
    case moodGood = "mood_good"
    case moodAmazing = "mood_amazing"

    // Pairing
    case code = "pairing_code"
    case connect = "pairing_connect"
    case qr = "pairing_qr"
    case sync = "pairing_sync"

    // Safety
    case alert = "safety_alert"
    case phone = "safety_phone"
    case privacy = "safety_privacy"
    case shield = "safety_shield"

    // Settings
    case data = "settings_data"
    case deleteAll = "settings_delete_all"
    case pause = "settings_pause"
    case profile = "settings_profile"
    case reminders = "settings_reminders"

    // Subscription
    case checkmarkCircle = "subscription_checkmark_circle"
    case couple = "subscription_couple"
    case star = "subscription_star"

    // Wisdom tracks
    case trackSecular = "tracks_secular_psychology"
    case trackBiblical = "tracks_biblical"
    case trackVedic = "tracks_vedic_dharmic"
    case trackQuranic = "tracks_quranic"

    var image: Image { Image(rawValue) }

    /// Maps a wisdom track to its glyph.
    static func forTrack(_ track: WisdomTrack) -> TetherIcon {
        switch track {
        case .secular:  return .trackSecular
        case .biblical: return .trackBiblical
        case .vedic:    return .trackVedic
        case .quranic:  return .trackQuranic
        }
    }

    /// Maps a 1–5 mood value to its glyph.
    static func forMood(_ value: Int) -> TetherIcon {
        switch value {
        case 1:  return .moodTerrible
        case 2:  return .moodLow
        case 3:  return .moodOkay
        case 4:  return .moodGood
        default: return .moodAmazing
        }
    }

    static func forTrend(_ trend: PulseTrend) -> TetherIcon {
        switch trend {
        case .rising:  return .trendUp
        case .steady:  return .trendFlat
        case .falling: return .trendDown
        case .unknown: return .trendFlat
        }
    }
}

/// Renders a `TetherIcon` at a given size and tint.
struct Icon: View {
    let icon: TetherIcon
    var size: CGFloat = 22
    var weight: Font.Weight = .regular
    var color: Color = TetherColor.text

    init(_ icon: TetherIcon, size: CGFloat = 22, color: Color = TetherColor.text) {
        self.icon = icon
        self.size = size
        self.color = color
    }

    var body: some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color)
            .accessibilityHidden(true)
    }
}

/// An icon inside a soft coloured disc — used for track cards and feature rows.
struct IconDisc: View {
    let icon: TetherIcon
    var size: CGFloat = 46
    var color: Color = TetherColor.brand
    var filled: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(filled ? color : color.opacity(0.13))
                .frame(width: size, height: size)
            Icon(icon, size: size * 0.46, color: filled ? .white : color)
        }
        .accessibilityHidden(true)
    }
}
