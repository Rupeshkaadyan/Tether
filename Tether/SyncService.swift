import CloudKit
import Foundation
import Observation
import SwiftUI

/// What the app needs to know from the backend layer, and nothing more.
/// Views read `status`; the concrete service decides what that means.
/// Swap the implementation (CloudKit, Supabase, custom) without touching a view.
protocol SyncService: AnyObject, Observable {
    var status: SyncStatus { get }
    func refreshStatus()
    func requestSync()
}

enum SyncStatus: Equatable {
    case localOnly
    case checking
    case available(lastSync: Date?)
    case noAccount
    case error(String)
}

/// Default backend: nothing leaves the device. Keeps every call site meaningful
/// while CloudKit is still being switched on.
@Observable
final class LocalSyncService: SyncService {
    var status: SyncStatus = .localOnly

    func refreshStatus() {
        status = .localOnly
    }

    func requestSync() {}
}

/// CloudKit-backed service. Once `Persistence` builds the container with a
/// `cloudKitDatabase`, SwiftData mirrors every save automatically — this class
/// reports the account state so the UI can tell the user what is happening.
///
/// Only instantiated when `Persistence.useCloudKit` is true (i.e. after the
/// iCloud capability is enabled), so it never runs without entitlements.
@Observable
final class CloudKitSyncService: SyncService {
    let containerID: String
    var status: SyncStatus = .checking

    init(containerID: String) {
        self.containerID = containerID
        refreshStatus()
    }

    func refreshStatus() {
        status = .checking
        CKContainer(identifier: containerID).accountStatus { [weak self] accountStatus, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    self.status = .error(error.localizedDescription)
                    return
                }
                switch accountStatus {
                case .available:
                    self.status = .available(lastSync: nil)
                case .noAccount:
                    self.status = .noAccount
                case .restricted, .couldNotDetermine:
                    self.status = .error("iCloud is unavailable on this device")
                @unknown default:
                    self.status = .error("Unknown iCloud status")
                }
            }
        }
    }

    /// Data sync is driven automatically by SwiftData on every save; this
    /// re-checks the account state so the UI can report it.
    func requestSync() {
        refreshStatus()
    }
}

// MARK: - Environment

private struct SyncServiceKey: EnvironmentKey {
    static let defaultValue: any SyncService = LocalSyncService()
}

extension EnvironmentValues {
    var syncService: any SyncService {
        get { self[SyncServiceKey.self] }
        set { self[SyncServiceKey.self] = newValue }
    }
}
