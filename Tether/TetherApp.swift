import SwiftUI
import SwiftData

@main
struct TetherApp: App {
    @State private var session = SessionStore()

    let container: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            JournalEntry.self,
            MoodLog.self,
            PromptReply.self,
            Invite.self,
            RelationshipPulse.self,
            AIConversation.self,
            AIMessage.self,
            AIMemory.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [config]) }
        catch { fatalError("Tether store failed: \(error)") }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .modelContainer(container)
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
