import AppIntents
import ActivityKit
import SharedTypes

struct ToggleTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Timer"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.stackforge.pomodoro-timer")

        for activity in Activity<PomodoroActivityAttributes>.activities {
            var state = activity.content.state
            if state.isRunning {
                let remaining = max(1, Int(state.sessionEndDate.timeIntervalSince(Date())))
                state.isRunning = false
                state.pausedRemainingSeconds = remaining
                defaults?.set(false, forKey: "liveActivityIsRunning")
                defaults?.set(remaining, forKey: "liveActivityPausedSeconds")
            } else {
                state.isRunning = true
                state.sessionEndDate = Date().addingTimeInterval(Double(state.pausedRemainingSeconds))
                defaults?.set(true, forKey: "liveActivityIsRunning")
            }
            defaults?.set(Date(), forKey: "liveActivityLastToggle")
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
        return .result()
    }
}
