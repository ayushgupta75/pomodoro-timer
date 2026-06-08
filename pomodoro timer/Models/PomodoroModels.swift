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

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let sessionType: SessionType
    let completedAt: Date
}
