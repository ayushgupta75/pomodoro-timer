import SwiftUI

struct SettingsView: View {
    @Environment(PomodoroViewModel.self) private var viewModel

    @State private var showResetConfirm = false
    @State private var showBugReport = false
    @State private var showAbout = false

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    SettingsSection(title: "Session") {
                        WheelPickerRow(
                            label: "Session time",
                            value: $vm.settings.workMinutes,
                            range: Array(1...90),
                            unit: "min"
                        )
                        Divider()
                        WheelPickerRow(
                            label: "Sessions before long break",
                            value: $vm.settings.sessionsPerCycle,
                            range: Array(1...8),
                            unit: "sessions"
                        )
                        Divider()
                        WheelPickerRow(
                            label: "Daily goal",
                            value: $vm.settings.dailyGoalHours,
                            range: Array(1...12),
                            unit: "hr"
                        )
                    }

                    SettingsSection(title: "Sound") {
                        Menu {
                            ForEach(AmbientSoundType.allCases, id: \.self) { type in
                                Button {
                                    vm.settings.ambientSound = type
                                } label: {
                                    if vm.settings.ambientSound == type {
                                        Label(type.rawValue, systemImage: "checkmark")
                                    } else {
                                        Text(type.rawValue)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("Work Ambient Sound")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(vm.settings.ambientSound.rawValue)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }

                    SettingsSection(title: "Breaks") {
                        WheelPickerRow(
                            label: "Short Break",
                            value: $vm.settings.shortBreakMinutes,
                            range: Array(1...30),
                            unit: "min"
                        )
                        Divider()
                        WheelPickerRow(
                            label: "Long Break",
                            value: $vm.settings.longBreakMinutes,
                            range: Array(5...60),
                            unit: "min"
                        )
                    }
                    SettingsSection(title: "Developer") {
                        Button {
                            showBugReport = true
                        } label: {
                            HStack {
                                Image(systemName: "ladybug")
                                Text("Report a Bug")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }

                        Divider()

                        Button {
                            showAbout = true
                        } label: {
                            HStack {
                                Image(systemName: "info.circle")
                                Text("About")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }

                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Text("Reset All Data")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .onChange(of: viewModel.settings) {
                viewModel.saveSettings()
            }
            .sheet(isPresented: $showBugReport) { BugReportView() }
            .sheet(isPresented: $showAbout) { AboutView() }
            .alert("Reset All Data?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { viewModel.clearAllData() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will clear all session history and reset settings to defaults.")
            }
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .kerning(1)
                .padding(.leading, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct WheelPickerRow: View {
    let label: String
    @Binding var value: Int
    let range: [Int]
    let unit: String

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(label)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(value) \(unit)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            if isExpanded {
                Picker("", selection: $value) {
                    ForEach(range, id: \.self) { num in
                        Text("\(num) \(unit)").tag(num)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 140)
                .padding(.horizontal, 8)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(PomodoroViewModel())
}
