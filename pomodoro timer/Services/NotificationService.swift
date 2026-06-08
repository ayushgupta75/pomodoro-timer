import UserNotifications

struct NotificationService {
    static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

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
