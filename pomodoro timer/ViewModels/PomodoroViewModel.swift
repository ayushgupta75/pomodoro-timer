import Foundation
import Observation

@Observable
final class PomodoroViewModel {
    var settings: PomodoroSettings
    private(set) var sessionType: SessionType = .work
    private(set) var timerState: TimerState = .idle
    private(set) var remainingSeconds: Int
    private(set) var completedSessions: Int = 0

    private var timer: Timer?

    init() {
        let saved = Self.loadSettings()
        self.settings = saved
        self.remainingSeconds = saved.workMinutes * 60
    }

    var formattedTime: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    var progress: Double {
        let total = totalSeconds(for: sessionType)
        guard total > 0 else { return 0 }
        return Double(total - remainingSeconds) / Double(total)
    }

    var sessionsInCurrentCycle: Int {
        completedSessions % settings.sessionsBeforeLongBreak
    }

    func start() {
        timerState = .running
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        timerState = .paused
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        timerState = .idle
        remainingSeconds = totalSeconds(for: sessionType)
    }

    func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: "pomodoroSettings")
    }

    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            advanceSession()
        }
    }

    private func advanceSession() {
        timer?.invalidate()
        timer = nil
        timerState = .idle

        NotificationService.scheduleSessionEndNotification(for: sessionType)

        if sessionType == .work {
            completedSessions += 1
            sessionType = completedSessions % settings.sessionsBeforeLongBreak == 0 ? .longBreak : .shortBreak
        } else {
            sessionType = .work
        }

        remainingSeconds = totalSeconds(for: sessionType)
    }

    private func totalSeconds(for session: SessionType) -> Int {
        switch session {
        case .work:        return settings.workMinutes * 60
        case .shortBreak:  return settings.shortBreakMinutes * 60
        case .longBreak:   return settings.longBreakMinutes * 60
        }
    }

    private static func loadSettings() -> PomodoroSettings {
        guard let data = UserDefaults.standard.data(forKey: "pomodoroSettings"),
              let decoded = try? JSONDecoder().decode(PomodoroSettings.self, from: data)
        else { return PomodoroSettings() }
        return decoded
    }
}
