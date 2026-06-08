import SwiftUI

struct TimerView: View {
    @State private var viewModel = PomodoroViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 52) {
                sessionHeader

                timerRing

                controls
            }
            .padding(.horizontal)
            .navigationTitle("Pomodoro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
            .task {
                await NotificationService.requestPermission()
            }
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
                ForEach(0..<viewModel.settings.sessionsBeforeLongBreak, id: \.self) { index in
                    Circle()
                        .fill(index < viewModel.sessionsInCurrentCycle ? Color.accentColor : Color(.systemGray5))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: viewModel.sessionsInCurrentCycle)
                }
            }
        }
    }

    private var timerRing: some View {
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

                Text("\(viewModel.completedSessions) completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 260, height: 260)
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

            Color.clear.frame(width: 52, height: 52)
        }
    }
}

#Preview {
    TimerView()
}
