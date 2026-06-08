import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: PomodoroViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Work") {
                    DurationStepper(
                        label: "Work Duration",
                        value: $viewModel.settings.workMinutes,
                        unit: "min",
                        range: 1...90
                    )
                    DurationStepper(
                        label: "Sessions before long break",
                        value: $viewModel.settings.sessionsBeforeLongBreak,
                        unit: "",
                        range: 1...8
                    )
                }
                Section("Breaks") {
                    DurationStepper(
                        label: "Short Break",
                        value: $viewModel.settings.shortBreakMinutes,
                        unit: "min",
                        range: 1...30
                    )
                    DurationStepper(
                        label: "Long Break",
                        value: $viewModel.settings.longBreakMinutes,
                        unit: "min",
                        range: 5...60
                    )
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct DurationStepper: View {
    let label: String
    @Binding var value: Int
    let unit: String
    let range: ClosedRange<Int>

    var body: some View {
        Stepper(value: $value, in: range) {
            HStack {
                Text(label)
                Spacer()
                Text(unit.isEmpty ? "\(value)" : "\(value) \(unit)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: PomodoroViewModel())
}
