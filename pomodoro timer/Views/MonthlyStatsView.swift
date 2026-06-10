import SwiftUI

struct MonthlyStatsView: View {
    @Environment(PomodoroViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayedMonth: Date = .now
    @State private var selectedDay: Int? = nil

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    // Use single-char weekday labels aligned to calendar's first weekday
    private var weekdayHeaders: [String] {
        let symbols = cal.veryShortWeekdaySymbols   // Sun-based: ["S","M","T","W","T","F","S"]
        let first = cal.firstWeekday - 1            // 0 = Sunday
        return Array(symbols[first...] + symbols[..<first])
    }

    private var sessionsByDay: [Int: [SessionRecord]] {
        viewModel.sessionsByDay(in: displayedMonth)
    }

    private var daysInMonth: Int {
        cal.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
    }

    // How many leading blank cells before day 1
    private var leadingBlanks: Int {
        let first = cal.firstWeekday - 1   // 0 = Sunday
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        let day1 = cal.date(from: comps)!
        let weekday = cal.component(.weekday, from: day1) - 1   // 0-based
        return (weekday - first + 7) % 7
    }

    private var goalDaysCount: Int {
        let goalSeconds = viewModel.settings.dailyGoalHours * 3600
        return (1...daysInMonth).filter { day in
            (sessionsByDay[day] ?? []).reduce(0) { $0 + $1.durationSeconds } >= goalSeconds
        }.count
    }

    private var selectedSessions: [SessionRecord] {
        guard let day = selectedDay else { return [] }
        return (sessionsByDay[day] ?? []).sorted { $0.completedAt < $1.completedAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    monthNavigator
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    summaryLine
                        .padding(.bottom, 16)

                    calendarGrid
                        .padding(.horizontal, 12)

                    legend
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    Divider()
                        .padding(.horizontal, 20)

                    sessionListSection
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Monthly")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sub-views

    private var monthNavigator: some View {
        HStack {
            Button { shiftMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
            }
            Spacer()
            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
            Spacer()
            Button { shiftMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(isFutureMonth ? Color.secondary.opacity(0.3) : .primary)
                    .frame(width: 36, height: 36)
            }
            .disabled(isFutureMonth)
        }
    }

    private var isFutureMonth: Bool {
        cal.isDate(displayedMonth, equalTo: .now, toGranularity: .month)
    }

    private var summaryLine: some View {
        HStack(spacing: 6) {
            Image(systemName: goalDaysCount > 0 ? "checkmark.seal.fill" : "seal")
                .foregroundStyle(goalDaysCount > 0 ? .green : .secondary)
            Text(goalDaysCount > 0
                 ? "Goal reached on **\(goalDaysCount)** day\(goalDaysCount == 1 ? "" : "s") this month"
                 : "No goal days yet this month")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            // Weekday header row — use index as ID to avoid dedup of T/S duplicates
            ForEach(weekdayHeaders.indices, id: \.self) { i in
                Text(weekdayHeaders[i])
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
            }

            // Single loop over all cells — avoids ID collision between blanks and day numbers
            ForEach(0..<(leadingBlanks + daysInMonth), id: \.self) { index in
                if index < leadingBlanks {
                    Color.clear.frame(height: cellSize)
                } else {
                    let day = index - leadingBlanks + 1
                    let daySeconds = (sessionsByDay[day] ?? []).reduce(0) { $0 + $1.durationSeconds }
                    DayCell(
                        day: day,
                        daySeconds: daySeconds,
                        goalSeconds: viewModel.settings.dailyGoalHours * 3600,
                        isToday: isToday(day),
                        isSelected: selectedDay == day
                    )
                    .onTapGesture {
                        selectedDay = selectedDay == day ? nil : day
                    }
                }
            }
        }
    }

    // Fixed cell height so the grid is stable regardless of content
    private var cellSize: CGFloat { 44 }

    private var legend: some View {
        HStack(spacing: 20) {
            LegendDot(color: .green, label: "Goal reached")
            LegendDot(color: .accentColor, label: "Below goal")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var sessionListSection: some View {
        Group {
            if let day = selectedDay {
                let sessions = selectedSessions
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(dayTitle(day))
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        if !sessions.isEmpty {
                            Text(daySummary(sessions))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 12)

                    if sessions.isEmpty {
                        Text("No sessions recorded")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(sessions) { record in
                            SessionRow(record: record)
                            if record.id != sessions.last?.id {
                                Divider().padding(.leading, 36)
                            }
                        }
                    }
                }
            } else {
                Text("Tap a day to see sessions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
    }

    // MARK: - Helpers

    private func shiftMonth(by value: Int) {
        selectedDay = nil
        if let shifted = cal.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = shifted
        }
    }

    private func isToday(_ day: Int) -> Bool {
        var comps = cal.dateComponents([.year, .month], from: displayedMonth)
        comps.day = day
        guard let date = cal.date(from: comps) else { return false }
        return cal.isDateInToday(date)
    }

    private func daySummary(_ sessions: [SessionRecord]) -> String {
        let count = sessions.count
        let minutes = sessions.reduce(0) { $0 + $1.durationSeconds } / 60
        let timeStr: String
        if minutes < 60 {
            timeStr = "\(minutes)m"
        } else {
            let h = minutes / 60
            let m = minutes % 60
            timeStr = m == 0 ? "\(h)h" : "\(h)h \(m)m"
        }
        return "\(count) session\(count == 1 ? "" : "s") · \(timeStr)"
    }

    private func dayTitle(_ day: Int) -> String {
        var comps = cal.dateComponents([.year, .month], from: displayedMonth)
        comps.day = day
        guard let date = cal.date(from: comps) else { return "" }
        return date.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let day: Int
    let daySeconds: Int
    let goalSeconds: Int
    let isToday: Bool
    let isSelected: Bool

    private var fillColor: Color? {
        if daySeconds == 0 { return nil }
        return daySeconds >= goalSeconds ? .green : .accentColor
    }

    var body: some View {
        ZStack {
            // Background circle
            if isSelected {
                Circle()
                    .fill(fillColor?.opacity(0.9) ?? Color.secondary.opacity(0.15))
            } else if let fill = fillColor {
                Circle()
                    .fill(fill.opacity(0.75))
            } else if isToday {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 1.5)
            }

            VStack(spacing: 1) {
                Text("\(day)")
                    .font(.system(size: 14, weight: isToday || isSelected ? .semibold : .regular))
                    .foregroundStyle(
                        (fillColor != nil || isSelected) ? .white : .primary
                    )

                if daySeconds > 0 {
                    Circle()
                        .fill(fillColor != nil ? .white.opacity(0.7) : fillColor ?? .clear)
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(height: 44)
        .contentShape(Rectangle())
    }
}

// MARK: - Session Row

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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(record.sessionType.rawValue)
                .font(.subheadline)
            Spacer()
            Text(timeRange)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Legend Dot

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color.opacity(0.8)).frame(width: 9, height: 9)
            Text(label)
        }
    }
}

#Preview {
    MonthlyStatsView()
        .environment(PomodoroViewModel())
}
