import UserNotifications

struct NotificationService {
    private static let timerNotificationID = "com.pomodoro.timer.end"

    static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    // Schedule a future notification for when the current session ends.
    static func scheduleTimerNotification(in seconds: Int, for session: SessionType) {
        cancelPendingTimerNotification()
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        switch session {
        case .work:
            content.title = "Time for a break!"
            content.body = "Great focus session. Take a breather."
        case .shortBreak, .longBreak:
            content.title = "Break's over!"
            content.body = "Ready to focus again? Let's go."
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: timerNotificationID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelPendingTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [timerNotificationID])
    }

    // Fired immediately when a session ends while the app is in the foreground.
    static func scheduleSessionEndNotification(for session: SessionType) {
        let content = UNMutableNotificationContent()
        switch session {
        case .work:
            content.title = "Time for a break!"
            content.body = "Great focus session. Take a breather."
        case .shortBreak, .longBreak:
            content.title = "Break's over!"
            content.body = "Ready to focus again? Let's go."
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
