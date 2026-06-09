import SwiftUI

struct StatsView: View {
    @Environment(PomodoroViewModel.self) private var viewModel

    @State private var showMonthly = false

    private var todayDuration: String {
        let seconds = viewModel.todaysSessions.reduce(0.0) {
            $0 + $1.completedAt.timeIntervalSince($1.startedAt)
        }
        let minutes = Int(seconds) / 60
        if minutes == 0 { return "0m" }
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private var goalDaysThisMonth: Int {
        let cal = Calendar.current
        let byDay = viewModel.sessionsByDay(in: .now)
        let daysInMonth = cal.range(of: .day, in: .month, for: .now)?.count ?? 30
        return (1...daysInMonth).filter { (byDay[$0]?.count ?? 0) >= viewModel.settings.dailyGoal }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 0) {
                        StatCard(value: todayDuration, label: "Today")
                        Divider().frame(height: 44)
                        Button {
                            showMonthly = true
                        } label: {
                            StatCard(
                                value: "\(goalDaysThisMonth)d",
                                label: "Monthly",
                                isInteractive: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowInsets(.init())
                    .listRowBackground(Color.clear)
                }
                .sheet(isPresented: $showMonthly) {
                    MonthlyStatsView()
                        .environment(viewModel)
                }

                Section {
                    DailyGoalRow(
                        completed: viewModel.todaysSessions.count,
                        goal: viewModel.settings.dailyGoal,
                        progress: viewModel.dailyGoalProgress
                    )
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color.clear)
                }

                if viewModel.sessionLog.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No sessions yet",
                            systemImage: "clock",
                            description: Text("Completed sessions will appear here.")
                        )
                        .listRowBackground(Color.clear)
                    }
                } else {
                    Section("Recent Sessions") {
                        ForEach(viewModel.sessionLog.reversed()) { record in
                            SessionRow(record: record)
                        }
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }
}

private struct DailyGoalRow: View {
    let completed: Int
    let goal: Int
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Daily Goal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(completed) / \(goal) sessions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progress >= 1.0 ? Color.green : Color.accentColor)
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)

            if progress >= 1.0 {
                Text("Goal reached!")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    var isInteractive: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 32, weight: .thin, design: .rounded))
                .monospacedDigit()
            HStack(spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if isInteractive {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

private struct SessionRow: View {
    let record: SessionRecord

    private var icon: String {
        switch record.sessionType {
        case .work:       return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer"
        case .longBreak:  return "figure.walk"
        }
    }

    private var color: Color {
        switch record.sessionType {
        case .work:       return .accentColor
        case .shortBreak: return .green
        case .longBreak:  return .orange
        }
    }

    private var timeRange: String {
        let fmt = Date.FormatStyle().hour(.defaultDigits(amPM: .abbreviated)).minute(.twoDigits)
        return "\(record.startedAt.formatted(fmt)) – \(record.completedAt.formatted(fmt))"
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.sessionType.rawValue)
                    .font(.subheadline)
                Text(timeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer()

            Text(record.completedAt.formatted(.relative(presentation: .named)))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    StatsView()
        .environment(PomodoroViewModel())
}
