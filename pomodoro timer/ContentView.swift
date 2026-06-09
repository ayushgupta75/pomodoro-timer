import SwiftUI

struct ContentView: View {
    @State private var viewModel = PomodoroViewModel()

    var body: some View {
        TabView {
            Tab("Timer", systemImage: "timer") {
                NavigationStack {
                    TimerView()
                        .navigationTitle("Pomodoro")
                        .navigationBarTitleDisplayMode(.inline)
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
    }
}

#Preview {
    ContentView()
}
