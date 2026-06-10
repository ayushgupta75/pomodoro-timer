import ActivityKit
import Foundation

public struct PomodoroActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var isRunning: Bool
        public var sessionEndDate: Date
        public var sessionType: String
        public var pausedRemainingSeconds: Int

        public init(isRunning: Bool, sessionEndDate: Date, sessionType: String, pausedRemainingSeconds: Int) {
            self.isRunning = isRunning
            self.sessionEndDate = sessionEndDate
            self.sessionType = sessionType
            self.pausedRemainingSeconds = pausedRemainingSeconds
        }
    }

    public init() {}
}
