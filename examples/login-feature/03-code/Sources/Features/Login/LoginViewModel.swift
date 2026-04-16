// ============================================================
// LoginViewModel.swift
// AC coverage: AC-1, AC-2, AC-3, AC-4, AC-5
// Depends on: LoginModels.swift, AuthServiceProtocol.swift
// ============================================================

import Foundation
import Observation

// MARK: - LoginViewModel

@Observable
@MainActor
final class LoginViewModel {

    // MARK: - Input

    var email: String = "" {
        didSet { clearErrorIfNeeded() }     // AC-2 edge case: clear error on re-type
    }

    var password: String = "" {
        didSet { clearErrorIfNeeded() }
    }

    // MARK: - Output

    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String? = nil
    private(set) var isAuthenticated: Bool = false

    // MARK: - Computed

    /// AC-4: button disabled when either field is empty
    var isLoginEnabled: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        !isLoading
    }

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    // MARK: - Actions

    /// AC-1, AC-2, AC-3, AC-5
    func login() async {
        guard isLoginEnabled else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }         // always re-enable form

        let credentials = LoginCredentials(
            email: email.trimmingCharacters(in: .whitespaces),  // AC-1 edge case
            password: password
        )

        do {
            _ = try await authService.login(credentials: credentials)
            isAuthenticated = true          // AC-1: triggers navigation in View via binding
        } catch let error as AuthError {
            password = ""                           // AC-2: clear first (errorMessage still nil, didSet no-ops)
            errorMessage = error.errorDescription   // AC-2, AC-5: then set error so didSet won't clear it
        } catch {
            errorMessage = AuthError.unknown(error.localizedDescription).errorDescription
        }
    }

    // MARK: - Private

    private func clearErrorIfNeeded() {
        guard errorMessage != nil else { return }
        errorMessage = nil
    }
}
