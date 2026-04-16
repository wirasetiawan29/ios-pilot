// ============================================================
// AuthRepository.swift
// AC coverage: AC-1, AC-2, AC-3, AC-5
// Depends on: AuthServiceProtocol.swift, LoginModels.swift
// ============================================================

import Foundation
import os.log

// MARK: - AuthRepository

/// Concrete implementation of AuthServiceProtocol.
/// Calls the login API and maps HTTP/network errors to typed AuthError.
final class AuthRepository: AuthServiceProtocol {

    // MARK: - Dependencies

    private let baseURL: URL
    private let session: URLSession
    private let keychainHelper: KeychainHelper.Type

    init(
        baseURL: URL = AppConfiguration.current.baseURL,
        session: URLSession = .shared,
        keychainHelper: KeychainHelper.Type = KeychainHelper.self
    ) {
        self.baseURL = baseURL
        self.session = session
        self.keychainHelper = keychainHelper
    }

    // MARK: - AuthServiceProtocol

    func login(credentials: LoginCredentials) async throws -> AuthSession {
        Logger.network.info("Login attempt for user")

        let request = try buildLoginRequest(credentials: credentials)

        // AC-3 edge case: 30 second timeout
        let result = try await withThrowingTaskGroup(of: AuthSession.self) { group in
            group.addTask { [weak self] in
                guard let self else { throw AuthError.unknown("Repository deallocated") }
                return try await self.performRequest(request)
            }
            group.addTask {
                try await Task.sleep(for: .seconds(30))
                throw AuthError.timeout
            }
            let session = try await group.next()!
            group.cancelAll()
            return session
        }

        // AC-1: persist token to Keychain
        keychainHelper.save(result.token, for: .authToken)
        Logger.network.info("Login successful, token saved to Keychain")

        return result
    }

    // MARK: - Private

    private func buildLoginRequest(credentials: LoginCredentials) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("/auth/login")
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["email": credentials.email, "password": credentials.password]
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> AuthSession {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.networkUnavailable
        }

        switch http.statusCode {
        case 200...299:
            return try parseSession(from: data)
        case 401:
            throw AuthError.invalidCredentials           // AC-2
        default:
            throw AuthError.unknown("HTTP \(http.statusCode)")
        }
    }

    private func parseSession(from data: Data) throws -> AuthSession {
        struct LoginResponse: Decodable {
            let userId: String
            let token: String
            let expiresAt: Date
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(LoginResponse.self, from: data)
        return AuthSession(userId: response.userId, token: response.token, expiresAt: response.expiresAt)
    }
}

// MARK: - AppConfiguration (stub for example)

enum AppConfiguration {
    struct Config { let baseURL: URL }
    static let current = Config(baseURL: URL(string: "https://api.example.com")!)
}

// MARK: - KeychainHelper (stub for example — see secrets-management.md for full impl)

enum KeychainHelper {
    enum Key: String { case authToken = "com.app.authToken" }

    @discardableResult
    static func save(_ value: String, for key: Key) -> Bool {
        // Full implementation in .agent/patterns/secrets-management.md
        UserDefaults.standard.set(value, forKey: key.rawValue) // example only — use real Keychain in production
        return true
    }

    static func load(for key: Key) -> String? {
        UserDefaults.standard.string(forKey: key.rawValue)
    }
}

// MARK: - Logger extension

extension Logger {
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "network")
}
