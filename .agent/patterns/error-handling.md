# Pattern: Error Handling

## Triggers
Load this pattern when:
- Keywords: `error`, `ErrorBanner`, `localizedDescription`, `alert`, `failure`, `throw`, `Result`, `network error`, `validation error`, `catch`, `async throws`
- Phases: Phase 3 Code Gen — any file with async calls, network calls, or user-facing error states
- Task types: ViewModel (error propagation), Repository/Service (typed error mapping), any View showing error feedback

---

## Error Hierarchy

```
AppError (top-level user-facing)
├── AppNetworkError    (HTTP, connectivity)
├── AppPersistenceError (SwiftData/CoreData)
├── AppAuthError       (auth/session)
└── AppValidationError (user input)
```

### AppNetworkError

```swift
// Core/Errors/AppNetworkError.swift
enum AppNetworkError: Error, Sendable {
    case invalidURL
    case invalidResponse
    case unauthorized                          // 401
    case notFound                              // 404
    case unprocessableEntity(data: Data)       // 422
    case serverError(statusCode: Int)          // 5xx
    case httpError(statusCode: Int, data: Data)
    case decodingFailed(underlying: Error)
    case noConnection
    case timeout
    case unknown
}
```

### AppPersistenceError

```swift
// Core/Errors/AppPersistenceError.swift
enum AppPersistenceError: Error, Sendable {
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case migrationFailed(underlying: Error)
    case notFound(id: String)
}
```

### AppValidationError

```swift
// Core/Errors/AppValidationError.swift
enum AppValidationError: Error, Sendable {
    case required(field: String)
    case invalidFormat(field: String, expected: String)
    case tooShort(field: String, minimum: Int)
    case tooLong(field: String, maximum: Int)
    case doesNotMatch(field: String, other: String)
}
```

---

## Error Mapping Strategy

Map low-level errors to domain errors in the **Repository layer**.
ViewModels receive domain errors and map them to user-facing messages.

```
URLError / HTTPError
    → AppNetworkError          (in Repository)
        → Domain error         (in Repository, e.g. LoginError.invalidCredentials)
            → String message   (in ViewModel, via errorMessage property)
```

### Repository mapping example

```swift
// Features/Login/LoginRepository.swift
func login(credentials: LoginCredentials) async throws -> AuthSession {
    do {
        return try await networkClient.request(
            Endpoint(path: "/auth/login", method: .post, body: credentials)
        )
    } catch AppNetworkError.unauthorized {
        throw LoginError.invalidCredentials
    } catch AppNetworkError.noConnection {
        throw LoginError.noConnection
    } catch AppNetworkError.serverError {
        throw LoginError.serverUnavailable
    } catch {
        throw LoginError.unknown(underlying: error)
    }
}
```

### ViewModel error presentation

```swift
// Features/Login/LoginViewModel.swift
@Observable @MainActor final class LoginViewModel {
    private(set) var errorMessage: String?
    private(set) var isLoading = false

    func login() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await loginService.login(credentials: credentials)
        } catch {
            errorMessage = errorMessage(for: error)
        }
    }

    // MARK: - Private

    private func errorMessage(for error: Error) -> String {
        switch error {
        case LoginError.invalidCredentials:
            return String(localized: "error.login.invalid_credentials")
        case LoginError.noConnection:
            return String(localized: "error.no_connection")
        case LoginError.serverUnavailable:
            return String(localized: "error.server_unavailable")
        default:
            return String(localized: "error.unknown")
        }
    }
}
```

---

## Recoverable vs Unrecoverable Errors

| Type | Examples | UI Behaviour |
|---|---|---|
| **Recoverable** | No connection, timeout, 5xx | Show retry button |
| **User-fixable** | Validation, 422, 401 | Show inline field error |
| **Unrecoverable** | Decoding failure, local DB corruption | Show error screen, offer restart |

```swift
extension Error {
    var isRecoverable: Bool {
        switch self {
        case AppNetworkError.noConnection,
             AppNetworkError.timeout,
             AppNetworkError.serverError:
            return true
        default:
            return false
        }
    }
}
```

### Retry button pattern in View

```swift
if let message = viewModel.errorMessage {
    VStack(spacing: AppSpacing.itemGap) {
        Text(message)
            .foregroundStyle(.appError)
            .multilineTextAlignment(.center)
        if viewModel.lastErrorIsRecoverable {
            Button(String(localized: "action.retry")) {
                Task { await viewModel.retry() }
            }
            .buttonStyle(.bordered)
        }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(message)
}
```

---

## Logging

Never use `print()`. Use structured logging via `Logger` (os.log):

```swift
// Core/Logging/AppLogger.swift
import os.log

extension Logger {
    static let network    = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "network")
    static let persistence = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "persistence")
    static let auth       = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "auth")
    static let ui         = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "ui")
}

// Usage (in Repository, never in ViewModel or View):
Logger.network.error("Login failed: \(error.localizedDescription, privacy: .public)")
Logger.network.debug("Request: \(endpoint.path, privacy: .public)")
```

**Rules:**
- Only Repository and Service layers log — ViewModels and Views never log
- Use `.private` privacy for PII (email, name, token) — never `.public`
- Use `.public` only for non-sensitive diagnostic info (endpoint path, status code)

---

## Code Gen Rules

1. Every feature with network calls needs a domain-specific error enum in `Features/<Feature>/`:
   ```swift
   enum <FeatureName>Error: Error, Sendable {
       case <case1>
       case <case2>
       case unknown(underlying: Error)
   }
   ```

2. Every ViewModel with `errorMessage: String?` must have a private `errorMessage(for:)` mapping function

3. Add to `project.yml` target sources — `Core/Errors/` and `Core/Logging/`

4. Localized error strings go in `Localizable.xcstrings` (see `localization.md`)

---

## Self-check (per file)

- [ ] No `error.localizedDescription` displayed directly to user — always mapped via `errorMessage(for:)`
- [ ] No `print(error)` — use `Logger`
- [ ] Recoverable errors show retry button
- [ ] Domain errors defined per feature, not reused across features
- [ ] `unknown(underlying: Error)` case present in every domain error enum
