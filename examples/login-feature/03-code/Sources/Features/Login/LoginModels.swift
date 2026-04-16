// ============================================================
// LoginModels.swift
// AC coverage: AC-1, AC-2, AC-3
// Depends on: none
// ============================================================

import Foundation

// MARK: - Login Credentials

/// Input model for the login form.
/// Trimming of whitespace is the caller's responsibility (LoginViewModel).
struct LoginCredentials: Sendable, Equatable {
    let email: String
    let password: String
}

// MARK: - Auth Session

/// Represents an active authenticated session.
/// Persisted to Keychain — never stored in UserDefaults.
struct AuthSession: Sendable, Equatable {
    let userId: String
    let token: String
    let expiresAt: Date

    var isExpired: Bool {
        expiresAt < Date()
    }
}

// MARK: - Auth Errors

/// Typed errors for authentication flow.
/// Maps HTTP/network failures to domain-specific cases.
enum AuthError: LocalizedError, Equatable {
    case invalidCredentials     // AC-2: 401 from server
    case networkUnavailable     // AC-5: no connectivity
    case timeout                // AC-3 edge case: request > 30s
    case unknown(String)        // fallback — surface raw message in dev builds

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .networkUnavailable:
            return "No internet connection. Please try again."
        case .timeout:
            return "Request timed out. Please try again."
        case .unknown(let message):
            return message
        }
    }
}
