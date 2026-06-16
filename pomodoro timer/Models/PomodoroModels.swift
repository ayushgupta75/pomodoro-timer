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
    var dailyGoalHours: Int = 4
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
    let durationSeconds: Int
    var syncState: SyncState

    enum CodingKeys: String, CodingKey {
        case id, sessionType, startedAt, completedAt, durationSeconds, syncState
    }

    init(id: UUID, sessionType: SessionType, startedAt: Date, completedAt: Date, durationSeconds: Int, syncState: SyncState = .pending) {
        self.id = id
        self.sessionType = sessionType
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
        self.syncState = syncState
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self, forKey: .id)
        sessionType = try c.decode(SessionType.self, forKey: .sessionType)
        completedAt = try c.decode(Date.self, forKey: .completedAt)
        startedAt   = try c.decodeIfPresent(Date.self, forKey: .startedAt) ?? completedAt
        // Old records without durationSeconds fall back to wall-clock delta
        durationSeconds = try c.decodeIfPresent(Int.self, forKey: .durationSeconds)
            ?? max(0, Int(completedAt.timeIntervalSince(startedAt)))
        syncState   = try c.decodeIfPresent(SyncState.self, forKey: .syncState) ?? .pending
    }
}
