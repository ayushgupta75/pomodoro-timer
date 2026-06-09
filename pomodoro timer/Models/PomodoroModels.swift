import Foundation

enum SessionType: String, CaseIterable, Codable {
    case work = "Work"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
}

enum TimerState {
    case idle
    case running
    case paused
}

enum AmbientSoundType: String, CaseIterable, Codable {
    case none       = "None"
    case brownNoise = "Brown Noise"
    case pinkNoise  = "Pink Noise"
    case whiteNoise = "White Noise"
}

struct PomodoroSettings: Codable, Equatable {
    var workMinutes: Int = 25
    var shortBreakMinutes: Int = 5
    var longBreakMinutes: Int = 15
    var sessionsPerCycle: Int = 4
    var dailyGoal: Int = 8
    var ambientSound: AmbientSoundType = .brownNoise
}

enum SyncState: String, Codable {
    case pending
    case synced
}

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let sessionType: SessionType
    let startedAt: Date
    let completedAt: Date
    var syncState: SyncState

    enum CodingKeys: String, CodingKey {
        case id, sessionType, startedAt, completedAt, syncState
    }

    init(id: UUID, sessionType: SessionType, startedAt: Date, completedAt: Date, syncState: SyncState = .pending) {
        self.id = id
        self.sessionType = sessionType
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.syncState = syncState
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self, forKey: .id)
        sessionType = try c.decode(SessionType.self, forKey: .sessionType)
        completedAt = try c.decode(Date.self, forKey: .completedAt)
        // Old records without startedAt fall back to completedAt
        startedAt   = try c.decodeIfPresent(Date.self, forKey: .startedAt) ?? completedAt
        syncState   = try c.decodeIfPresent(SyncState.self, forKey: .syncState) ?? .pending
    }
}
