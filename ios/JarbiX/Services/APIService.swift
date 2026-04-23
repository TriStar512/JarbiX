import Foundation

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:              return "Invalid server URL — check Settings."
        case .networkError(let e):     return "Network: \(e.localizedDescription)"
        case .decodingError(let e):    return "Data error: \(e.localizedDescription)"
        case .serverError(let code):   return "Server returned \(code)"
        }
    }
}

// MARK: - Service

final class APIService {
    static let shared = APIService()
    private init() {}

    private(set) var baseURL: String = UserDefaults.standard.string(forKey: "serverURL") ?? "http://localhost:5000"

    func updateBaseURL(_ url: String) {
        var clean = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasSuffix("/") { clean.removeLast() }
        baseURL = clean
        UserDefaults.standard.set(clean, forKey: "serverURL")
    }

    // MARK: Generic fetch

    private func fetch<T: Decodable>(_ path: String,
                                     method: String = "GET",
                                     body: Data? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.invalidURL }

        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        req.httpMethod = method
        if let body {
            req.httpBody = body
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                throw APIError.serverError(http.statusCode)
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch let e as APIError { throw e
        } catch let e as DecodingError { throw APIError.decodingError(e)
        } catch { throw APIError.networkError(error)
        }
    }

    // MARK: Endpoints

    func getStatus()  async throws -> BotStatus      { try await fetch("/api/status") }
    func getSignals() async throws -> SignalsResponse { try await fetch("/api/signals") }
    func getMetrics() async throws -> Metrics         { try await fetch("/api/metrics") }
    func getConfig()  async throws -> BotConfig       { try await fetch("/api/config") }

    func getTrades(limit: Int = 50) async throws -> TradesResponse {
        try await fetch("/api/trades?limit=\(limit)")
    }

    func toggleBot() async throws -> ToggleResponse {
        try await fetch("/api/toggle", method: "POST")
    }

    func emergencyFlatten() async throws -> FlattenResponse {
        try await fetch("/api/flatten", method: "POST")
    }

    func updateConfig(_ config: BotConfig) async throws {
        let body = try JSONEncoder().encode(config)
        let _: GenericResponse = try await fetch("/api/config", method: "POST", body: body)
    }
}
