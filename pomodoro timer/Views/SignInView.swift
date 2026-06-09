import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "timer")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(.orange)

                Text("Pomodoro")
                    .font(.system(size: 36, weight: .bold))

                Text("Focus. Rest. Repeat.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                if authService.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(height: 50)
                } else {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            guard let credential = authorization.credential
                                    as? ASAuthorizationAppleIDCredential else { return }
                            Task { await authService.handleAppleCredential(credential) }
                        case .failure(let error):
                            // User cancelled — no action needed
                            let nsError = error as NSError
                            if nsError.code != ASAuthorizationError.canceled.rawValue {
                                print("[SignIn] Apple auth error: \(error)")
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(10)
                }

                if let message = authService.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthService.shared)
}
