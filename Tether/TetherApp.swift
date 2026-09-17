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

    var body: some View {
        Group {
            if let profile = profiles.first {
                if profile.onboardingDone {
                    HomeView(profile: profile)
                } else {
                    OnboardingFlow(profile: profile)
                }
            } else {
                ProgressView()
                    .tint(TetherColor.brand)
            }
        }
        .task { ensureProfile() }
        .animation(.easeOut(duration: 0.25), value: profiles.first?.onboardingDone)
    }

    private func ensureProfile() {
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
