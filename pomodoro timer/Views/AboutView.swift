import SwiftUI

struct AboutView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "timer")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.accentColor)

                        Text("Pomodoro Timer")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Version \(appVersion) (\(build))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .listRowBackground(Color.clear)
                }

                Section("About") {
                    Text("A clean, distraction-free Pomodoro timer built for deep work. Work in focused sessions, take structured breaks, and track your daily progress — all without leaving the app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }

                Section("Features") {
                    FeatureRow(icon: "timer", color: .blue, title: "Seamless Sessions", description: "Auto-advances between work, short break, and long break")
                    FeatureRow(icon: "chart.bar", color: .green, title: "Daily Goal Tracking", description: "Set a session target and track progress on the main screen")
                    FeatureRow(icon: "speaker.wave.2", color: .orange, title: "Ambient Sound", description: "Brown, pink, or white noise to help you focus")
                    FeatureRow(icon: "bell", color: .purple, title: "Notifications", description: "Get alerted when sessions end, even in background")
                    FeatureRow(icon: "gearshape", color: .gray, title: "Fully Customizable", description: "Set your own work, break, cycle, and daily goal lengths")
                }

                Section("Developer") {
                    LabeledContent("Built by", value: "Ayush Gupta")
                    Link(destination: URL(string: "https://github.com/ayushgupta75/pomodoro-timer")!) {
                        HStack {
                            Text("Source Code")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Text("Built with SwiftUI and Swift 6. No backend, no tracking, no accounts — your data stays on your device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AboutView()
}
