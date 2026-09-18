import SwiftUI
import Observation
import SwiftData
import Foundation

// MARK: - SyncStatus Enum

public enum SyncStatus: Equatable {
    case localOnly
    case checking
    case available(Bool)
    case noAccount
    case error
}

// MARK: - SyncService Protocol

public protocol SyncService: Observable, AnyObject {
    var status: SyncStatus { get }
    func requestSync()
}

// MARK: - Environment Key and Values Extension

private struct SyncServiceKey: EnvironmentKey {
    static let defaultValue: any SyncService = LocalSyncService()
}

public extension EnvironmentValues {
    var syncService: any SyncService {
        get { self[SyncServiceKey.self] }
        set { self[SyncServiceKey.self] = newValue }
    }
}

// MARK: - LocalSyncService Implementation

public final class LocalSyncService: SyncService, Observable {
    public private(set) var status: SyncStatus = .localOnly

    public init() {}

    public func requestSync() {
        // no-op
    }
}

// MARK: - CloudKitSyncService Implementation

@MainActor
public final class CloudKitSyncService: SyncService, Observable {
    public private(set) var status: SyncStatus = .checking
    private let containerID: String

    public init(containerID: String) {
        self.containerID = containerID
        simulateSyncCheck()
    }

    public func requestSync() {
        // For this stub, no-op or simulate a sync request if needed
    }

    private func simulateSyncCheck() {
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            status = .available(true)
        }
    }
}

// MARK: - Persistence Helper

#if canImport(SwiftData)
public struct Persistence {
    public static let useCloudKit: Bool = false
    public static let cloudKitContainerID: String = "iCloud.com.example.tether"

    public static func make() -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            JournalEntry.self,
            MoodLog.self,
            PromptReply.self,
            AIMessage.self,
            AIConversation.self,
            AIMemory.self,
            RelationshipPulse.self,
            Invite.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }
}
#else
public struct Persistence {
    public static let useCloudKit: Bool = false
    public static let cloudKitContainerID: String = "iCloud.com.example.tether"

    public static func make() -> ModelContainer {
        fatalError("SwiftData is not available on this platform.")
    }
}
#endif
