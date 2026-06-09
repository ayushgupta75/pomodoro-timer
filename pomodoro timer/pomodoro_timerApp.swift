import SwiftUI

@main
struct pomodoro_timerApp: App {
    @State private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if !Config.backendEnabled || authService.isSignedIn {
                    ContentView()
                } else {
                    SignInView()
                }
            }
            .environment(authService)
            .animation(.easeInOut(duration: 0.3), value: authService.isSignedIn)
        }
    }
}
