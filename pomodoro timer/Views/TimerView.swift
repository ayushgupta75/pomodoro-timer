import SwiftUI

struct TimerView: View {
    @Environment(PomodoroViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 52) {
            sessionHeader

            timerRing

            controls
        }
        .padding(.horizontal)
        .task {
            await NotificationService.requestPermission()
        }
    }

    private var sessionHeader: some View {
        VStack(spacing: 10) {
            Text(viewModel.sessionType.rawValue.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .kerning(1.5)

            HStack(spacing: 8) {
                ForEach(0..<viewModel.settings.sessionsPerCycle, id: \.self) { index in
                    Circle()
                        .fill(index < viewModel.sessionsInCurrentCycle ? Color.accentColor : Color(.systemGray5))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: viewModel.sessionsInCurrentCycle)
                }
            }
        }
    }

    private var timerRing: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.progress)

                VStack(spacing: 4) {
                    Text(viewModel.formattedTime)
                        .font(.system(size: 60, weight: .thin, design: .rounded))
                        .monospacedDigit()

                    Text(viewModel.todayTimerLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .frame(width: 260, height: 260)

            dailyGoalBar
        }
    }

    private var dailyGoalBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(viewModel.dailyGoalReached ? Color.green : Color.accentColor)
                        .frame(width: geo.size.width * viewModel.dailyGoalProgress, height: 6)
                        .animation(.easeInOut, value: viewModel.dailyGoalProgress)
                }
            }
            .frame(height: 6)

            if viewModel.dailyGoalReached {
                Text("Daily goal reached! Tap play to keep going.")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 8)
    }

    private var controls: some View {
        HStack(spacing: 40) {
            Button(action: viewModel.reset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 52, height: 52)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }

            Button {
                viewModel.timerState == .running ? viewModel.pause() : viewModel.start()
            } label: {
                Image(systemName: viewModel.timerState == .running ? "pause.fill" : "play.fill")
                    .font(.system(size: 26))
                    .frame(width: 72, height: 72)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }

            Button(action: viewModel.skip) {
                Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 52, height: 52)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    TimerView()
        .environment(PomodoroViewModel())
}
