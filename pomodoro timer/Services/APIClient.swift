import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case unauthorized
    case serverError(Int, String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:              return "Invalid server URL."
        case .noData:                  return "No data received."
        case .unauthorized:            return "Session expired. Please sign in again."
        case .serverError(let c, let m): return "Server error \(c): \(m)"
        case .decodingError(let e):    return "Decode error: \(e.localizedDescription)"
        }
    }
}

enum APIClient {
    private static var baseURL: String { "http://localhost" }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Auth

    static func signInWithApple(identityToken: String, email: String?) async throws -> String {
        struct Body: Encodable { let identityToken: String; let email: String? }
        struct Response: Decodable { let accessToken: String }

        let response: Response = try await post(
            path: "/auth/apple",
            body: Body(identityToken: identityToken, email: email),
            token: nil
        )
        return response.accessToken
    }

    // MARK: - Sessions

    static func syncSessions(_ sessions: [SessionRecord], token: String) async throws -> [UUID] {
        struct SessionIn: Encodable {
            let id: String
            let startedAt: Date
            let completedAt: Date
        }
        struct SyncRequest: Encodable { let sessions: [SessionIn] }
        struct SessionOut: Decodable { let id: String }
        struct SyncResponse: Decodable { let sessions: [SessionOut] }

        let body = SyncRequest(sessions: sessions.map {
            SessionIn(id: $0.id.uuidString, startedAt: $0.startedAt, completedAt: $0.completedAt)
        })
        let response: SyncResponse = try await post(path: "/sessions/sync", body: body, token: token)
        return response.sessions.compactMap { UUID(uuidString: $0.id) }
    }

    // MARK: - Goals

    static func syncGoal(_ goal: Int, for date: Date, token: String) async throws {
        struct GoalIn: Encodable { let date: String; let goal: Int }
        struct GoalRequest: Encodable { let goals: [GoalIn] }
        struct _Empty: Decodable {}

        let dateStr = ISO8601DateFormatter.dateOnly.string(from: date)
        let body = GoalRequest(goals: [GoalIn(date: dateStr, goal: goal)])
        let _: _Empty = try await post(path: "/goals/sync", body: body, token: token)
    }

    // MARK: - Generic POST

    private static func post<B: Encodable, R: Decodable>(
        path: String,
        body: B,
        token: String?
    ) async throws -> R {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        request.httpBody = try encoder.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.noData }

        switch http.statusCode {
        case 200...299:
            // empty body responses (e.g. 204)
            if data.isEmpty, let empty = try? decoder.decode(R.self, from: "{}".data(using: .utf8)!) {
                return empty
            }
            do {
                return try decoder.decode(R.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401, 403:
            throw APIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(http.statusCode, msg)
        }
    }
}

private extension ISO8601DateFormatter {
    static let dateOnly: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return f
    }()
}
