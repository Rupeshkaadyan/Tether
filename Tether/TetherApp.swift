import SwiftUI
import SwiftData
import Foundation

@main
struct TetherApp: App {
    @State private var session = SessionStore()
    @State private var sync: any SyncService
    @State private var language = LanguageManager.shared
    @State private var theme = ThemeManager.shared
    @State private var lock = AppLockManager.shared

    @Environment(\.scenePhase) private var scenePhase

    let container: ModelContainer

    init() {
        let container = Persistence.make()
        self.container = container
        let service: any SyncService = Persistence.useCloudKit
            ? CloudKitSyncService(containerID: Persistence.cloudKitContainerID)
            : LocalSyncService()
        _sync = State(initialValue: service)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(language)
                .environment(\.syncService, sync)
                // In-app language choice. Setting the locale here makes every
                // Text(\"literal\") resolve from the chosen .lproj immediately.
                .environment(\.locale, language.locale)
                .environment(theme)
                .preferredColorScheme(theme.colorScheme)
                .modelContainer(container)
                // Privacy: cover the app whenever it leaves the foreground.
                .overlay {
                    if lock.isLocked {
                        LockScreen { lock.unlock() }
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .background: lock.lock()
                    case .active: if lock.isLocked { lock.unlock() }
                    default: break
                    }
                }
        }
    }
}

struct RootView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.modelContext) private var ctx
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    @State private var showSplash = true

    var body: some View {
        ZStack {
            Group {
                if let profile = profiles.first {
                    if profile.onboardingDone {
                        MainTabView(profile: profile)
                    } else {
                        OnboardingFlow(profile: profile)
                    }
                } else {
                    TetherColor.bg.ignoresSafeArea()
                }
            }
            .task { ensureProfile() }
            .animation(.easeOut(duration: 0.25), value: profiles.first?.onboardingDone)

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            withAnimation(.easeOut(duration: 0.45)) { showSplash = false }
        }
    }

    private func ensureProfile() {
        #if DEBUG
        // Screenshot / preview helper. Never compiled into a release build.
        if ProcessInfo.processInfo.arguments.contains("-seedDemo") {
            DemoSeed.runIfNeeded(ctx)
            session.profile = profiles.first
            return
        }
        #endif

        if let existing = profiles.first {
            session.profile = existing
            return
        }
        let profile = UserProfile(displayName: "", track: .secular)
        ctx.insert(profile)
        try? ctx.save()
        session.profile = profile
    }
}
