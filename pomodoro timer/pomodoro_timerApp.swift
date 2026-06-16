import SwiftUI

@main
struct pomodoro_timerApp: App {
    @State private var viewModel = PomodoroViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .onOpenURL { url in
                    if url.scheme == "pomodoro", url.host == "toggle" {
                        viewModel.toggleTimer()
                    }
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                viewModel.handleForeground()
            case .background:
                viewModel.handleBackground()
            default:
                break
            }
        }
    }
}
