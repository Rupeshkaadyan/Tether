import Foundation
import SwiftData

/// Centralised store construction. All model types live here so the CloudKit
/// switch is in exactly one place.
enum Persistence {
    /// Set to `true` ONLY after you enable the iCloud (CloudKit) capability in
    /// Xcode and add the entitlements file (see docs/CLOUDKIT_SETUP.md). Until
    /// then the app stays local-only so it always builds and runs.
    static let useCloudKit = false

    /// Must match the container identifier you create in the CloudKit dashboard
    /// AND the `com.apple.developer.icloud-container-identifiers` entitlement.
    static let cloudKitContainerID = "iCloud.Tether"

    static func make() -> ModelContainer {
        make(useCloudKit: useCloudKit)
    }

    /// Builds the app's `ModelContainer`.
    /// - If CloudKit is requested and initializes, the store is mirrored to the
    ///   user's **private** iCloud database — free, and already sealed by
    ///   `SecureContent`/`CryptoService` before it ever leaves the device.
    /// - If CloudKit cannot initialize (capability/entitlement missing, or a
    ///   model turns out incompatible), we fall back to a local store so the app
    ///   always launches. No crash, no blank screen.
    static func make(useCloudKit: Bool) -> ModelContainer {
        let schema = Schema([
            UserProfile.self, JournalEntry.self, MoodLog.self,
            PromptReply.self, Invite.self, RelationshipPulse.self,
            AIConversation.self, AIMessage.self, AIMemory.self,
            Warmth.self, SharedNote.self, Ritual.self, ChatMessage.self,
            JarNote.self, UnsentNote.self
        ])

        if useCloudKit {
            let config = ModelConfiguration(schema: schema,
                                            isStoredInMemoryOnly: false,
                                            cloudKitDatabase: .private(cloudKitContainerID))
            if let container = try? ModelContainer(for: schema, configurations: [config]) {
                return container
            }
            // Fall through to local store.
        }

        let local = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [local])
    }
}
