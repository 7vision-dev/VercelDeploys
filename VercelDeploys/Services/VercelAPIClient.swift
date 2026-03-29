import Foundation

enum APIError: LocalizedError {
    case invalidToken
    case networkError(Error)
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidToken: return "Invalid access token"
        case .networkError(let error): return error.localizedDescription
        case .invalidResponse: return "Invalid response from Vercel"
        case .httpError(let code): return "HTTP error \(code)"
        }
    }
}

actor VercelAPIClient {
    private let baseURL = "https://api.vercel.com"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }

    func validateToken(_ token: String) async throws -> Bool {
        var request = URLRequest(url: URL(string: "\(baseURL)/v2/user")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        return http.statusCode == 200
    }

    func fetchDeployments(token: String, limit: Int = 25) async throws -> [Deployment] {
        var components = URLComponents(string: "\(baseURL)/v6/deployments")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        switch http.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let result = try decoder.decode(DeploymentsResponse.self, from: data)
            return result.deployments
        case 401, 403:
            throw APIError.invalidToken
        default:
            throw APIError.httpError(http.statusCode)
        }
    }
}
