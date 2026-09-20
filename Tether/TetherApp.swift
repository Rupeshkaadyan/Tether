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
    @State private var scene = SceneManager.shared

    @Environment(\.scenePhase) private var scenePhase
    // Required for Home Screen quick actions to do anything. Installing the
    // items alone just opens the app — the tap has to be received here.
    @UIApplicationDelegateAdaptor(ShortcutDelegate.self) private var shortcutDelegate

    let container: ModelContainer

    init() {
        let container = Persistence.make()
        self.container = container
        let service: any SyncService = Persistence.useCloudKit
            ? CloudKitSyncService(containerID: Persistence.cloudKitContainerID)
            : LocalSyncService()
        _sync = State(initialValue: service)

        // Lock on COLD LAUNCH, not only on background.
        //
        // isLocked starts false and lock() was only called from
        // scenePhase == .background. So quitting the app and reopening it —
        // as opposed to switching back to it from the app switcher — opened
        // straight into the journal with no Face ID at all. For an app
        // holding someone's private writing, that is the whole protection
        // gone at exactly the moment it is most needed.
        //
        // Locking here means every entry point asks: cold start, and return
        // from background.
        if AppLockManager.shared.isEnabled {
            AppLockManager.shared.lock()
        }
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
                // SettingsView reads AppLockManager from the environment. It
                // was never injected, so opening Settings crashed on the
                // @Environment lookup before the view could draw.
                .environment(lock)
                // THE root decision, and it used to be wrong.
                //
                // Previously: `theme.colorScheme ?? scene.theme.scheme`. With
                // Appearance on "System" that meant the SCENE decided, so
                // picking Dawn forced light mode on a phone set to dark. The
                // phone was being ignored.
                //
                // Now there is one control, not two. `.automatic` passes nil
                // and lets iOS drive, so dark mode gets Night and light mode
                // gets Dawn. An explicit scene pins the scheme it needs, which
                // is what makes a dark backdrop readable.
                .preferredColorScheme(scene.choice == .automatic
                                      ? nil
                                      : scene.choice.scheme)
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
                // Long-press the icon and you get three ways in: write
                // something, answer today's question, or start a quiet week.
                // Re-installed whenever the app becomes active — the system
                // can drop them, and a shortcut that silently disappears is
                // worse than none.
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { AppShortcuts.install() }
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
