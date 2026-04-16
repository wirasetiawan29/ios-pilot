# Tasks: User Login

## TASK-01 — Scaffold: Xcode Project Config
- **File**: `project.yml`
- **Depends on**: none
- **AC coverage**: —
- **Contract**: xcodegen spec — app name: LoginExample, bundle ID: com.example.login, iOS 17 target, Sources/ + Tests/ paths

## TASK-02 — Scaffold: Info.plist
- **File**: `SupportingFiles/Info.plist`
- **Depends on**: none
- **AC coverage**: —
- **Contract**: minimal iOS Info.plist with UILaunchScreen and portrait orientation

## TASK-DS — DesignSystem: Theme
- **File**: `Sources/DesignSystem/Theme.swift`
- **Depends on**: none
- **AC coverage**: — (infrastructure)
- **Contract**: `Color` extensions: `appPrimary (#1A73E8)`, `appSurface (#FFFFFF)`, `appError (#D93025)`, `appSubtle (#5F6368)`; `Font` extensions: `appTitle (28pt semibold)`, `appBody (16pt regular)`, `appCaption (13pt regular)`; `AppSpacing` enum: `pagePadding (24)`, `fieldGap (16)`, `sectionGap (32)`

## TASK-03 — Model: Login Credentials + Auth Session
- **File**: `Sources/Features/Login/LoginModels.swift`
- **Depends on**: none
- **AC coverage**: AC-1, AC-2, AC-3
- **Contract**: `struct LoginCredentials: Sendable, Equatable` with email, password; `struct AuthSession: Sendable, Equatable` with userId, token, expiresAt

## TASK-04 — Protocol: Auth Service
- **File**: `Sources/Features/Login/AuthServiceProtocol.swift`
- **Depends on**: TASK-03
- **AC coverage**: AC-1, AC-2, AC-5
- **Contract**: `protocol AuthServiceProtocol` with `func login(credentials: LoginCredentials) async throws -> AuthSession`; typed errors: `AuthError.invalidCredentials`, `AuthError.networkUnavailable`, `AuthError.timeout`

## TASK-05 — Repository: Auth Repository
- **File**: `Sources/Features/Login/AuthRepository.swift`
- **Depends on**: TASK-03, TASK-04
- **AC coverage**: AC-1, AC-2, AC-5
- **Contract**: `final class AuthRepository: AuthServiceProtocol` — calls network, maps response to `AuthSession`, maps HTTP errors to `AuthError`; timeout via `Task.timeout(seconds: 30)` (AC-3 edge case)

## TASK-06 — ViewModel: Login
- **File**: `Sources/Features/Login/LoginViewModel.swift`
- **Depends on**: TASK-03, TASK-04
- **AC coverage**: AC-1, AC-2, AC-3, AC-4, AC-5
- **Contract**: `@Observable @MainActor final class LoginViewModel`; properties: `email: String`, `password: String`, `isLoading: Bool`, `errorMessage: String?`, `isLoginEnabled: Bool` (computed); method: `func login() async`; on success: set `isAuthenticated = true`; error clearing: `errorMessage = nil` on field change

## TASK-07 — View: Login
- **File**: `Sources/Features/Login/LoginView.swift`
- **Depends on**: TASK-06, TASK-DS
- **AC coverage**: AC-1, AC-2, AC-3, AC-4
- **Contract**: `struct LoginView: View` with `@Binding var showLogin: Bool`; VStack layout: logo/title → email TextField → password SecureField → error Text (conditional) → Sign In Button; loading overlay with ProgressView (AC-3); uses Theme tokens; no NavigationStack; `#Preview` block required
- **Navigation role**: fullScreenCover presented by RootView; dismissed via `showLogin = false` on successful login; no back button (Rule N-3, N-4)

## TASK-08 — Tests: Login ViewModel
- **File**: `Tests/Features/Login/LoginViewModelTests.swift`
- **Depends on**: TASK-06
- **AC coverage**: AC-1, AC-2, AC-3, AC-4, AC-5
- **Contract**: `@Suite struct LoginViewModelTests`; `makeSUT(authService:)` factory; `MockAuthService: AuthServiceProtocol`; tests: happy path login, invalid credentials, empty fields disable button, error cleared on re-type, network error message, timeout error

---

## ⚑ Dependency Graph

| Wave | Tasks | Can start when |
|---|---|---|
| 1 | TASK-01, TASK-02, TASK-DS, TASK-03 | immediately |
| 2 | TASK-04, TASK-05 | TASK-03 complete |
| 3 | TASK-06 | TASK-04, TASK-05 complete |
| 4 | TASK-07, TASK-08 | TASK-06 complete (both independent of each other) |

> Wave 4: TASK-07 (View) and TASK-08 (Tests) are independent — spawn simultaneously.

---

## ⚑ AC Coverage Matrix

| AC | Covered by |
|---|---|
| AC-1 | TASK-03, TASK-04, TASK-05, TASK-06, TASK-07, TASK-08 |
| AC-2 | TASK-04, TASK-05, TASK-06, TASK-07, TASK-08 |
| AC-3 | TASK-03, TASK-05, TASK-06, TASK-07, TASK-08 |
| AC-4 | TASK-06, TASK-07, TASK-08 |
| AC-5 | TASK-04, TASK-05, TASK-06, TASK-08 |
