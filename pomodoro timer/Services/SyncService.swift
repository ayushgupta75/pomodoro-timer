import Foundation
import Network
import Observation

@Observable
final class SyncService {
    private(set) var isSyncing: Bool = false
    private(set) var lastSyncedAt: Date?

    // Called by the ViewModel when the network comes back up
    var onNetworkReconnect: (() -> Void)?

    private var monitor: NWPathMonitor?
    private var wasOffline = false

    func startMonitoring() {
        guard Config.backendEnabled else { return }
        let m = NWPathMonitor()
        m.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            DispatchQueue.main.async {
                if path.status == .satisfied && self.wasOffline {
                    self.onNetworkReconnect?()
                }
                self.wasOffline = path.status != .satisfied
            }
        }
        m.start(queue: .global(qos: .background))
        monitor = m
    }

    // Returns the IDs of sessions successfully synced to the server
    func syncSessions(_ sessions: [SessionRecord], token: String) async throws -> [UUID] {
        isSyncing = true
        defer { isSyncing = false }

        let syncedIDs = try await APIClient.syncSessions(sessions, token: token)
        lastSyncedAt = Date()
        return syncedIDs
    }

    func syncGoal(_ goal: Int, for date: Date = .now, token: String) async throws {
        isSyncing = true
        defer { isSyncing = false }

        try await APIClient.syncGoal(goal, for: date, token: token)
        lastSyncedAt = Date()
    }
}
