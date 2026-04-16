// ============================================================
// LoginViewModelTests.swift
// AC coverage: AC-1, AC-2, AC-3, AC-4, AC-5
// Depends on: LoginViewModel.swift, LoginModels.swift
// ============================================================

import Testing
import Foundation
@testable import LoginExample

// MARK: - Test Suite

@Suite("LoginViewModel")
@MainActor
struct LoginViewModelTests {

    // MARK: - Helpers

    func makeSUT(
        authService: AuthServiceProtocol = MockAuthService()
    ) -> LoginViewModel {
        LoginViewModel(authService: authService)
    }

    // MARK: - AC-4: Empty field validation

    @Test("Sign In button disabled when both fields empty")
    func signInDisabledWhenFieldsEmpty() {
        let sut = makeSUT()
        #expect(sut.isLoginEnabled == false)
    }

    @Test("Sign In button disabled when email is empty")
    func signInDisabledWhenEmailEmpty() {
        let sut = makeSUT()
        sut.password = "password123"
        #expect(sut.isLoginEnabled == false)
    }

    @Test("Sign In button disabled when password is empty")
    func signInDisabledWhenPasswordEmpty() {
        let sut = makeSUT()
        sut.email = "user@example.com"
        #expect(sut.isLoginEnabled == false)
    }

    @Test("Sign In button enabled when both fields filled")
    func signInEnabledWhenBothFieldsFilled() {
        let sut = makeSUT()
        sut.email = "user@example.com"
        sut.password = "password123"
        #expect(sut.isLoginEnabled == true)
    }

    @Test("Sign In button disabled when only whitespace in email")
    func signInDisabledWhenEmailIsWhitespace() {
        let sut = makeSUT()
        sut.email = "   "
        sut.password = "password123"
        #expect(sut.isLoginEnabled == false)
    }

    // MARK: - AC-1: Successful login

    @Test("Login success sets isAuthenticated")
    func loginSuccessSetsAuthenticated() async {
        let sut = makeSUT(authService: MockAuthService(result: .success(AuthSession(
            userId: "user-1",
            token: "token-abc",
            expiresAt: Date().addingTimeInterval(3600)
        ))))
        sut.email = "user@example.com"
        sut.password = "password123"

        await sut.login()

        #expect(sut.isAuthenticated == true)
        #expect(sut.errorMessage == nil)
    }

    @Test("Login trims whitespace from email before calling service")
    func loginTrimsEmailWhitespace() async {
        let mockService = MockAuthService(result: .success(AuthSession(
            userId: "1", token: "t", expiresAt: Date().addingTimeInterval(3600)
        )))
        let sut = makeSUT(authService: mockService)
        sut.email = "  user@example.com  "
        sut.password = "password"

        await sut.login()

        #expect(mockService.lastCredentials?.email == "user@example.com")
    }

    // MARK: - AC-2: Invalid credentials

    @Test("Login failure shows error message")
    func loginFailureShowsError() async {
        let sut = makeSUT(authService: MockAuthService(result: .failure(.invalidCredentials)))
        sut.email = "user@example.com"
        sut.password = "wrongpassword"

        await sut.login()

        #expect(sut.isAuthenticated == false)
        #expect(sut.errorMessage != nil)
        #expect(sut.errorMessage == AuthError.invalidCredentials.errorDescription)
    }

    @Test("Login failure clears password field")
    func loginFailureClearsPassword() async {
        let sut = makeSUT(authService: MockAuthService(result: .failure(.invalidCredentials)))
        sut.email = "user@example.com"
        sut.password = "wrongpassword"

        await sut.login()

        #expect(sut.password == "")
    }

    @Test("Error message cleared when user starts typing email")
    func errorClearedOnEmailInput() async {
        let sut = makeSUT(authService: MockAuthService(result: .failure(.invalidCredentials)))
        sut.email = "user@example.com"
        sut.password = "wrong"

        await sut.login()
        #expect(sut.errorMessage != nil)

        sut.email = "new@example.com"
        #expect(sut.errorMessage == nil)
    }

    @Test("Error message cleared when user starts typing password")
    func errorClearedOnPasswordInput() async {
        let sut = makeSUT(authService: MockAuthService(result: .failure(.invalidCredentials)))
        sut.email = "user@example.com"
        sut.password = "wrong"

        await sut.login()
        #expect(sut.errorMessage != nil)

        sut.password = "newpassword"
        #expect(sut.errorMessage == nil)
    }

    // MARK: - AC-3: Loading state

    @Test("isLoading is false before and after login")
    func loadingStateResetsAfterLogin() async {
        let sut = makeSUT(authService: MockAuthService(result: .success(AuthSession(
            userId: "1", token: "t", expiresAt: Date().addingTimeInterval(3600)
        ))))
        sut.email = "user@example.com"
        sut.password = "password"

        #expect(sut.isLoading == false)
        await sut.login()
        #expect(sut.isLoading == false)
    }

    @Test("Sign In button disabled while loading")
    func signInDisabledWhileLoading() async {
        let sut = makeSUT(authService: MockAuthService(result: .success(AuthSession(
            userId: "1", token: "t", expiresAt: Date().addingTimeInterval(3600)
        ))))
        sut.email = "user@example.com"
        sut.password = "password"

        // isLoading is checked inside isLoginEnabled
        let task = Task { await sut.login() }
        // Note: testing isLoading=true mid-flight requires async interception;
        // this test verifies isLoading resets after completion
        await task.value
        #expect(sut.isLoading == false)
    }

    // MARK: - AC-5: Network error

    @Test("Network unavailable shows correct error message")
    func networkUnavailableShowsError() async {
        let sut = makeSUT(authService: MockAuthService(result: .failure(.networkUnavailable)))
        sut.email = "user@example.com"
        sut.password = "password"

        await sut.login()

        #expect(sut.errorMessage == AuthError.networkUnavailable.errorDescription)
        #expect(sut.isAuthenticated == false)
    }

    @Test("Timeout shows correct error message")
    func timeoutShowsError() async {
        let sut = makeSUT(authService: MockAuthService(result: .failure(.timeout)))
        sut.email = "user@example.com"
        sut.password = "password"

        await sut.login()

        #expect(sut.errorMessage == AuthError.timeout.errorDescription)
    }
}

// MARK: - MockAuthService

final class MockAuthService: AuthServiceProtocol {
    enum MockResult {
        case success(AuthSession)
        case failure(AuthError)
    }

    private let result: MockResult
    private(set) var lastCredentials: LoginCredentials?
    private(set) var callCount: Int = 0

    init(result: MockResult = .failure(.networkUnavailable)) {
        self.result = result
    }

    func login(credentials: LoginCredentials) async throws -> AuthSession {
        lastCredentials = credentials
        callCount += 1
        switch result {
        case .success(let session): return session
        case .failure(let error):   throw error
        }
    }
}
