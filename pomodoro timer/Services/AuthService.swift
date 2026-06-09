import AuthenticationServices
import Foundation
import Observation

@Observable
final class AuthService: NSObject {
    static let shared = AuthService()

    private(set) var isSignedIn: Bool = false
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    private(set) var jwtToken: String?

    private enum Keys {
        static let jwt = "jwt_token"
    }

    override init() {
        super.init()
        if let stored = KeychainService.load(for: Keys.jwt) {
            jwtToken = stored
            isSignedIn = true
        }
    }

    func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async {
        guard let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            errorMessage = "Failed to read Apple identity token."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let jwt = try await APIClient.signInWithApple(
                identityToken: identityToken,
                email: credential.email
            )
            KeychainService.save(jwt, for: Keys.jwt)
            jwtToken = jwt
            isSignedIn = true
        } catch APIError.serverError(let code, _) where code == 422 {
            // Backend config issue (wrong bundle ID, missing Apple keys) — surface it clearly
            errorMessage = "Server configuration error. Check Apple bundle ID setup."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() {
        KeychainService.delete(for: Keys.jwt)
        jwtToken = nil
        isSignedIn = false
    }
}
