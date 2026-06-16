import Foundation
import Observation
import ActivityKit
import SharedTypes

@Observable
final class PomodoroViewModel {
    var settings: PomodoroSettings
    private(set) var sessionType: SessionType = .work
    private(set) var timerState: TimerState = .idle
    private(set) var remainingSeconds: Int
    private(set) var completedSessions: Int = 0
    private(set) var sessionLog: [SessionRecord] = []

    private var workPeriodsCompleted: Int = 0
    private var workSessionRunningSeconds: Int = 0
    private var timerTask: Task<Void, Never>?
    private var workSessionStartedAt: Date = .now
    private var sessionEndDate: Date?
    private var appBackgroundedAt: Date = .distantPast
    private var liveActivity: Activity<PomodoroActivityAttributes>?
    private let sharedDefaults = UserDefaults(suiteName: "group.com.stackforge.pomodoro-timer")
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

    var sessionsInCurrentCycle: Int {
        completedSessions % settings.sessionsPerCycle
    }

    var todaysSessions: [SessionRecord] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return sessionLog.filter { $0.completedAt >= startOfDay }
    }

    var todayTimerLabel: String {
        let seconds = todaysTotalSeconds
        let minutes = seconds / 60
        if minutes == 0 { return "0m / \(settings.dailyGoalHours)h" }
        if minutes < 60 { return "\(minutes)m / \(settings.dailyGoalHours)h" }
        let h = minutes / 60
        let m = minutes % 60
        let worked = m == 0 ? "\(h)h" : "\(h)h \(m)m"
        return "\(worked) / \(settings.dailyGoalHours)h"
    }

    var todaysTotalSeconds: Int {
        todaysSessions.reduce(0) { $0 + $1.durationSeconds }
    }

    var dailyGoalProgress: Double {
        let goal = settings.dailyGoalHours * 3600
        guard goal > 0 else { return 0 }
        return min(Double(todaysTotalSeconds) / Double(goal), 1.0)
    }

    var dailyGoalReached: Bool {
        todaysTotalSeconds >= settings.dailyGoalHours * 3600
    }

    func start() {
        timerTask?.cancel()
        if sessionType == .work && timerState != .paused {
            workSessionStartedAt = Date()
        }
        timerState = .running
        sessionEndDate = Date().addingTimeInterval(Double(remainingSeconds))
        if sessionType == .work {
            ambientSound.play(settings.ambientSound)
        } else {
            ambientSound.stop()
        }
        NotificationService.scheduleTimerNotification(in: remainingSeconds, for: sessionType)
        startTimerTask()
        updateLiveActivity()
    }

    func pause() {
        timerTask?.cancel()
        timerTask = nil
        timerState = .paused
        sessionEndDate = nil
        ambientSound.stop()
        NotificationService.cancelPendingTimerNotification()
        updateLiveActivity()
    }

    func reset() {
        timerTask?.cancel()
        timerTask = nil
        timerState = .idle
        remainingSeconds = totalSeconds(for: sessionType)
        workSessionStartedAt = .now
        workSessionRunningSeconds = 0
        sessionEndDate = nil
        ambientSound.stop()
        NotificationService.cancelPendingTimerNotification()
        endLiveActivity()
    }

    func toggleTimer() {
        if timerState == .running {
            pause()
        } else if timerState == .paused {
            start()
        }
    }

    func skip() {
        timerTask?.cancel()
        timerTask = nil
        advanceSession()
    }

    // Called when app returns to foreground
    func handleForeground() {
        // Recalculate timer first in case it expired while backgrounded
        if timerState == .running, let endDate = sessionEndDate {
            let remaining = endDate.timeIntervalSince(Date())
            if remaining <= 0 {
                timerTask?.cancel()
                remainingSeconds = 0
                advanceSession()
                return
            } else {
                remainingSeconds = max(1, Int(remaining))
                timerTask?.cancel()
                startTimerTask()
                if sessionType == .work {
                    ambientSound.play(settings.ambientSound)
                }
            }
        }

        // Apply any lock screen toggle that happened while backgrounded
        syncLockScreenToggle()
    }

    // Called when app goes to background
    func handleBackground() {
        appBackgroundedAt = Date()
        timerTask?.cancel()
        timerTask = nil
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
        workSessionRunningSeconds = 0
        sessionType = .work
        timerState = .idle
        remainingSeconds = settings.workMinutes * 60
        sessionEndDate = nil
        endLiveActivity()
    }

    func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: "pomodoroSettings")
        if timerState == .running && sessionType == .work {
            ambientSound.play(settings.ambientSound)
        }
    }

    // MARK: - Private

    private func startTimerTask() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { return }
                self.tick()
            }
        }
    }

    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            if sessionType == .work { workSessionRunningSeconds += 1 }
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
            workPeriodsCompleted += 1
            sessionType = workPeriodsCompleted % settings.sessionsPerCycle == 0 ? .longBreak : .shortBreak
        } else {
            completedSessions += 1
            let record = SessionRecord(id: UUID(), sessionType: .work, startedAt: workSessionStartedAt, completedAt: Date(), durationSeconds: workSessionRunningSeconds)
            sessionLog.append(record)
            saveSessionLog()
            workSessionRunningSeconds = 0
            sessionType = .work
        }

        remainingSeconds = totalSeconds(for: sessionType)

        if sessionType == .work && dailyGoalReached {
            timerState = .idle
            sessionEndDate = nil
            ambientSound.stop()
            endLiveActivity()
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

    // MARK: - Lock Screen Sync

    private func syncLockScreenToggle() {
        guard liveActivity != nil else { return }
        guard let lastToggle = sharedDefaults?.object(forKey: "liveActivityLastToggle") as? Date,
              lastToggle > appBackgroundedAt else { return }

        sharedDefaults?.removeObject(forKey: "liveActivityLastToggle")

        if timerState == .running {
            pause()
        } else if timerState == .paused {
            start()
        }
    }

    // MARK: - Live Activity

    private func updateLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = PomodoroActivityAttributes.ContentState(
            isRunning: timerState == .running,
            sessionEndDate: sessionEndDate ?? Date().addingTimeInterval(Double(remainingSeconds)),
            sessionType: sessionType == .work ? "Work" : "Break",
            pausedRemainingSeconds: remainingSeconds
        )

        if let activity = liveActivity {
            Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
        } else if timerState == .running {
            liveActivity = try? Activity.request(
                attributes: PomodoroActivityAttributes(),
                content: ActivityContent(state: state, staleDate: nil)
            )
        }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        liveActivity = nil
        sharedDefaults?.removeObject(forKey: "liveActivityLastToggle")
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    // MARK: - Persistence

    func sessionsByDay(in month: Date) -> [Int: [SessionRecord]] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: month)
        let inMonth = sessionLog.filter {
            let c = cal.dateComponents([.year, .month], from: $0.completedAt)
            return c.year == comps.year && c.month == comps.month
        }
        return Dictionary(grouping: inMonth) {
            cal.component(.day, from: $0.completedAt)
        }
    }

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
