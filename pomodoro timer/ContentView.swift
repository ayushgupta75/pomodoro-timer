import SwiftUI

struct ContentView: View {
    @State private var viewModel = PomodoroViewModel()
    @Environment(AuthService.self) private var authService

    var body: some View {
        TabView {
            Tab("Timer", systemImage: "timer") {
                NavigationStack {
                    TimerView()
                        .navigationTitle("Pomodoro")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { syncStatusItem }
                }
            }

            Tab("Stats", systemImage: "chart.bar") {
                StatsView()
            }

            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .environment(viewModel)
        .task {
            // Initial sync on launch when already signed in
            await viewModel.syncIfNeeded(token: authService.jwtToken)
        }
    }

    @ToolbarContentBuilder
    private var syncStatusItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.syncService.isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthService.shared)
}
