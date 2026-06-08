import Foundation
import Observation

@Observable
final class PomodoroViewModel {
    var settings: PomodoroSettings
    private(set) var sessionType: SessionType = .work
    private(set) var timerState: TimerState = .idle
    private(set) var remainingSeconds: Int
    private(set) var completedSessions: Int = 0  // full work+break pairs
    private(set) var sessionLog: [SessionRecord] = []

    // tracks work periods to determine when long break triggers
    private var workPeriodsCompleted: Int = 0
    private var timerTask: Task<Void, Never>?
    private let ambientSound = AmbientSoundService()

    init() {
        let saved = Self.loadSettings()
        self.settings = saved
        self.remainingSeconds = saved.workMinutes * 60
        self.sessionLog = Self.loadSessionLog()
    }

    var formattedTime: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    var progress: Double {
        let total = totalSeconds(for: sessionType)
        guard total > 0 else { return 0 }
        return Double(total - remainingSeconds) / Double(total)
    }

    // dots in timer view: sessions completed within the current cycle
    var sessionsInCurrentCycle: Int {
        completedSessions % settings.sessionsPerCycle
    }

    var todaysSessions: [SessionRecord] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return sessionLog.filter { $0.completedAt >= startOfDay }
    }

    var dailyGoalProgress: Double {
        guard settings.dailyGoal > 0 else { return 0 }
        return min(Double(todaysSessions.count) / Double(settings.dailyGoal), 1.0)
    }

    var dailyGoalReached: Bool {
        todaysSessions.count >= settings.dailyGoal
    }

    func start() {
        timerTask?.cancel()
        timerState = .running
        if sessionType == .work {
            ambientSound.play(settings.ambientSound)
        } else {
            ambientSound.stop()
        }
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                self.tick()
            }
        }
    }

    func pause() {
        timerTask?.cancel()
        timerTask = nil
        timerState = .paused
        ambientSound.stop()
    }

    func reset() {
        timerTask?.cancel()
        timerTask = nil
        timerState = .idle
        remainingSeconds = totalSeconds(for: sessionType)
        ambientSound.stop()
    }

    func skip() {
        timerTask?.cancel()
        timerTask = nil
        advanceSession()
    }

    func clearAllData() {
        timerTask?.cancel()
        timerTask = nil
        ambientSound.stop()

        UserDefaults.standard.removeObject(forKey: "pomodoroSettings")
        UserDefaults.standard.removeObject(forKey: "sessionLog")

        settings = PomodoroSettings()
        sessionLog = []
        completedSessions = 0
        workPeriodsCompleted = 0
        sessionType = .work
        timerState = .idle
        remainingSeconds = settings.workMinutes * 60
    }

    func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: "pomodoroSettings")
        if timerState == .running && sessionType == .work {
            ambientSound.play(settings.ambientSound)
        }
    }

    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            if remainingSeconds == 0 {
                SoundService.playComplete()
                advanceSession()
            } else if remainingSeconds <= 3 {
                SoundService.playUrgentTick()
            } else if remainingSeconds <= 7 {
                SoundService.playTick()
            }
        }
    }

    private func advanceSession() {
        NotificationService.scheduleSessionEndNotification(for: sessionType)

        if sessionType == .work {
            // Work ended — pick break type based on how many work periods done
            workPeriodsCompleted += 1
            sessionType = workPeriodsCompleted % settings.sessionsPerCycle == 0 ? .longBreak : .shortBreak
        } else {
            // Break ended — full session (work + break) complete
            completedSessions += 1
            let record = SessionRecord(id: UUID(), sessionType: .work, completedAt: Date())
            sessionLog.append(record)
            saveSessionLog()
            sessionType = .work
        }

        remainingSeconds = totalSeconds(for: sessionType)

        if sessionType == .work && dailyGoalReached {
            timerState = .idle
            ambientSound.stop()
        } else {
            start()
        }
    }

    private func totalSeconds(for session: SessionType) -> Int {
        switch session {
        case .work:        return settings.workMinutes * 60
        case .shortBreak:  return settings.shortBreakMinutes * 60
        case .longBreak:   return settings.longBreakMinutes * 60
        }
    }

    // MARK: - Persistence

    private static func loadSettings() -> PomodoroSettings {
        guard let data = UserDefaults.standard.data(forKey: "pomodoroSettings"),
              let decoded = try? JSONDecoder().decode(PomodoroSettings.self, from: data)
        else { return PomodoroSettings() }
        return decoded
    }

    private static func loadSessionLog() -> [SessionRecord] {
        guard let data = UserDefaults.standard.data(forKey: "sessionLog"),
              let decoded = try? JSONDecoder().decode([SessionRecord].self, from: data)
        else { return [] }
        return decoded
    }

    private func saveSessionLog() {
        guard let data = try? JSONEncoder().encode(sessionLog) else { return }
        UserDefaults.standard.set(data, forKey: "sessionLog")
    }
}
