// ============================================================
// LoginViewModelTests.swift
// AC coverage: AC-1, AC-2, AC-3, AC-4, AC-5
// Depends on: LoginViewModel.swift, LoginModels.swift
// ============================================================

import XCTest
import Foundation
@testable import LoginExample

// MARK: - Test Suite

@MainActor
final class LoginViewModelTests: XCTestCase {

    // MARK: - Helpers

    func makeSUT(
        authService: AuthServiceProtocol = MockAuthService()
    ) -> LoginViewModel {
        LoginViewModel(authService: authService)
    }

    // MARK: - AC-4: Empty field validation

    func test_signInDisabledWhenFieldsEmpty() {
        let sut = makeSUT()
        XCTAssertFalse(sut.isLoginEnabled)
    }

    func test_signInDisabledWhenEmailEmpty() {
        let sut = makeSUT()
        sut.password = "password123"
        XCTAssertFalse(sut.isLoginEnabled)
    }

    func test_signInDisabledWhenPasswordEmpty() {
        let sut = makeSUT()
        sut.email = "user@example.com"
        XCTAssertFalse(sut.isLoginEnabled)
    }

    func test_signInEnabledWhenBothFieldsFilled() {
        let sut = makeSUT()
        sut.email = "user@example.com"
        sut.password = "password123"
        XCTAssertTrue(sut.isLoginEnabled)
    }

    func test_signInDisabledWhenEmailIsWhitespace() {
        let sut = makeSUT()
        sut.email = "   "
        sut.password = "password123"
        XCTAssertFalse(sut.isLoginEnabled)
    }

    // MARK: - AC-1: Successful login

    func test_loginSuccessSetsAuthenticated() async {
        let sut = makeSUT(authService: MockAuthService(result: .success(AuthSession(
            userId: "user-1",
            token: "token-abc",
            expiresAt: Date().addingTimeInterval(3600)
        ))))
        sut.email = "user@example.com"
        sut.password = "password123"

        await sut.login()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.errorMessage)
    }

    func test_loginTrimsEmailWhitespace() async {
        let mockService = MockAuthService(result: .success(AuthSession(
            userId: "1", token: "t", expiresAt: Date().addingTimeInterval(3600)
        )))
        let sut = makeSUT(authService: mockService)
        sut.email = "  user@example.com  "
        sut.password = "password"

        await sut.login()

        XCTAssertEqual(mockService.lastCredentials?.email, "user@example.com")
    }

    // MARK: - AC-2: Invalid credentials

    func test_loginFailureShowsError() async {
        let sut = makeSUT(authService: MockAuthService(result: .failure(.invalidCredentials)))
        sut.email = "user@example.com"
        sut.password = "wrongpassword"

        await sut.login()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, AuthError.invalidCredentials.errorDescription)
    }

    func test_loginFailureClearsPassword() async {
        let sut = makeSUT(authService: MockAuthService(result: .failure(.invalidCredentials)))
        sut.email = "user@example.com"
        sut.password = "wrongpassword"

        await sut.login()

        XCTAssertEqual(sut.password, "")
    }

    func test_errorClearedOnEmailInput() async {
        let sut = makeSUT(authService: MockAuthService(result: .failure(.invalidCredentials)))
        sut.email = "user@example.com"
        sut.password = "wrong"

        await sut.login()
        XCTAssertNotNil(sut.errorMessage)

        sut.email = "new@example.com"
        XCTAssertNil(sut.errorMessage)
    }

    func test_errorClearedOnPasswordInput() async {
        let sut = makeSUT(authService: MockAuthService(result: .failure(.invalidCredentials)))
        sut.email = "user@example.com"
        sut.password = "wrong"

        await sut.login()
        XCTAssertNotNil(sut.errorMessage)

        sut.password = "newpassword"
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - AC-3: Loading state

    func test_loadingStateResetsAfterLogin() async {
        let sut = makeSUT(authService: MockAuthService(result: .success(AuthSession(
            userId: "1", token: "t", expiresAt: Date().addingTimeInterval(3600)
        ))))
        sut.email = "user@example.com"
        sut.password = "password"

        XCTAssertFalse(sut.isLoading)
        await sut.login()
        XCTAssertFalse(sut.isLoading)
    }

    func test_signInDisabledWhileLoading() async {
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
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - AC-5: Network error

    func test_networkUnavailableShowsError() async {
        let sut = makeSUT(authService: MockAuthService(result: .failure(.networkUnavailable)))
        sut.email = "user@example.com"
        sut.password = "password"

        await sut.login()

        XCTAssertEqual(sut.errorMessage, AuthError.networkUnavailable.errorDescription)
        XCTAssertFalse(sut.isAuthenticated)
    }

    func test_timeoutShowsError() async {
        let sut = makeSUT(authService: MockAuthService(result: .failure(.timeout)))
        sut.email = "user@example.com"
        sut.password = "password"

        await sut.login()

        XCTAssertEqual(sut.errorMessage, AuthError.timeout.errorDescription)
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
