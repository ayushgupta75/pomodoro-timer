import UIKit

struct GitHubService {
    enum GitHubError: LocalizedError {
        case missingToken
        case apiError(Int)
        case networkError

        var errorDescription: String? {
            switch self {
            case .missingToken:   return "No GitHub token set. Add it in Settings."
            case .apiError(let code): return "GitHub API error (\(code)). Check your token."
            case .networkError:   return "Network error. Check your connection."
            }
        }
    }

    static func createIssue(title: String, description: String) async throws {
        let token = Config.githubToken
        guard !token.isEmpty, token != "PASTE_YOUR_TOKEN_HERE" else { throw GitHubError.missingToken }

        let url = URL(string: "https://api.github.com/repos/\(Config.githubRepo)/issues")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "title": "Bug: \(title)",
            "body": buildBody(description: description),
            "labels": ["bug"]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw GitHubError.networkError }
        guard http.statusCode == 201 else { throw GitHubError.apiError(http.statusCode) }
    }

    private static func buildBody(description: String) -> String {
        let device = UIDevice.current
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"

        return """
        ## Description
        \(description)

        ---
        **Device:** \(device.model)
        **iOS:** \(device.systemVersion)
        **App Version:** \(appVersion) (build \(build))
        **Reported:** \(Date().formatted(date: .long, time: .shortened))
        """
    }
}
