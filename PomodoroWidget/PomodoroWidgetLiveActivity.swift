import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents
import SharedTypes

private func formatSeconds(_ seconds: Int) -> String {
    String(format: "%02d:%02d", max(0, seconds) / 60, max(0, seconds) % 60)
}

struct PomodoroWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            // Lock screen banner
            HStack(alignment: .center) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Group {
                        if context.state.isRunning {
                            Text(timerInterval: Date.now...context.state.sessionEndDate, countsDown: true)
                                .monospacedDigit()
                        } else {
                            Text(formatSeconds(context.state.pausedRemainingSeconds))
                                .monospacedDigit()
                        }
                    }
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                    Text(context.state.sessionType)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .offset(y: -6)
                }

                Spacer()

                Button(intent: ToggleTimerIntent()) {
                    Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.accentColor, in: Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .activityBackgroundTint(Color(.systemBackground))
            .activitySystemActionForegroundColor(.primary)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Group {
                            if context.state.isRunning {
                                Text(timerInterval: Date.now...context.state.sessionEndDate, countsDown: true)
                                    .monospacedDigit()
                            } else {
                                Text(formatSeconds(context.state.pausedRemainingSeconds))
                                    .monospacedDigit()
                            }
                        }
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)

                        Text(context.state.sessionType)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Button(intent: ToggleTimerIntent()) {
                        Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.accentColor, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(.blue)
                    .font(.caption.bold())
            } compactTrailing: {
                Group {
                    if context.state.isRunning {
                        Text(timerInterval: Date.now...context.state.sessionEndDate, countsDown: true)
                            .monospacedDigit()
                    } else {
                        Text(formatSeconds(context.state.pausedRemainingSeconds))
                            .monospacedDigit()
                    }
                }
                .font(.caption2.monospacedDigit())
                .frame(width: 42)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(.blue)
            }
        }
    }
}
