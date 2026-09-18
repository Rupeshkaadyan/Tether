import SwiftUI

/// The app shell once onboarding is done.
///
/// Four tabs rather than sheets: the daily loop, the journal, the coach, and
/// the Pulse are all destinations a person returns to, not modal tasks.
struct MainTabView: View {
    @Bindable var profile: UserProfile
    @State private var tab: Tab = .today

    enum Tab: Hashable { case today, journal, coach, pulse, insights }

    var body: some View {
        TabView(selection: $tab) {
            HomeView(profile: profile,
                     onOpenPulse: { tab = .pulse },
                     onOpenCoach: { tab = .coach })
                .tag(Tab.today)
                .tabItem { label("Today", .tabHome) }

            JournalView(profile: profile)
                .tag(Tab.journal)
                .tabItem { label("Journal", .tabJournal) }

            CoachView(profile: profile, isTab: true)
                .tag(Tab.coach)
                .tabItem { label("Coach", .tabCoach) }

            PulseView(profile: profile, isTab: true)
                .tag(Tab.pulse)
                .tabItem { label("Pulse", .tabPulse) }

            InsightsView(profile: profile)
                .tag(Tab.insights)
                .tabItem { label("Insights", "chart.line.uptrend.xyaxis") }
        }
        .tint(TetherColor.brand)
        // An explicit bar background. The default glass material let scrolled
        // content show through as a dark smear on the warm background.
        .toolbarBackground(TetherColor.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear(perform: applyLaunchTab)
    }

    /// DEBUG-only: lets screenshot runs open a specific tab directly.
    private func applyLaunchTab() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-tab-journal") { tab = .journal }
        else if args.contains("-tab-coach") { tab = .coach }
        else if args.contains("-tab-pulse") { tab = .pulse }
        else if args.contains("-tab-insights") { tab = .insights }
        #endif
    }

    /// `tabItem` renders the image at its intrinsic size, so an unconstrained
    /// asset would blow up to its full pixel dimensions. Both `resizable()` and
    /// an explicit frame are required here.
    private func label(_ title: String, _ icon: TetherIcon) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(icon.rawValue)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
        }
    }

    /// Overload for SF Symbols (used where a custom asset does not yet exist).
    private func label(_ title: String, _ systemName: String) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
    }
}
