// ============================================================
// AuthServiceProtocol.swift
// AC coverage: AC-1, AC-2, AC-5
// Depends on: LoginModels.swift
// ============================================================

import Foundation

// MARK: - Protocol

protocol AuthServiceProtocol: Sendable {
    /// Authenticates the user with the given credentials.
    /// - Throws: `AuthError.invalidCredentials` on 401
    /// - Throws: `AuthError.networkUnavailable` on no connection
    /// - Throws: `AuthError.timeout` if request exceeds 30 seconds
    func login(credentials: LoginCredentials) async throws -> AuthSession
}
