# Pattern: Swift Concurrency

## Triggers
Load this pattern when:
- Keywords: `async`, `await`, `actor`, `@MainActor`, `Task`, `structured concurrency`, `continuation`, `withCheckedThrowingContinuation`, `Swift 6`, `strict concurrency`, `Sendable`, `nonisolated`, `async let`, `TaskGroup`
- Phases: Phase 3 Code Gen — ViewModel, Repository, Service files
- Task types: any async operation, network calls, background work, timer-based work

---

## Core Rules

**R-1 — ViewModel is always `@MainActor` — with `nonisolated init()`**
Every `@Observable` ViewModel must be marked `@MainActor`. Because `@State` initializes properties before the main actor context is available, a `@MainActor` class MUST declare `nonisolated init()` explicitly — otherwise SwiftUI throws a compile error: *"call to main actor-isolated initializer in a synchronous nonisolated context"*.

```swift
// ✅ CORRECT
@Observable
@MainActor
final class LoginViewModel {
    var email = ""

    nonisolated init() {}  // required — @State initialization is nonisolated
}

// Used in View:
@State private var viewModel = LoginViewModel()  // compiles ✅
```

```swift
// ❌ WRONG — missing nonisolated init()
@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    // no init declared → synthesized init is @MainActor → @State fails
}
```

**R-2 — async functions on the call site, not the definition**
Repository and Service protocols define `async throws` functions. The ViewModel calls them inside `Task { }` or `async let`.

**R-3 — No `DispatchQueue.main.async` in SwiftUI code**
`@MainActor` replaces all `DispatchQueue.main.async` calls. Never mix the two.

**R-4 — Structured concurrency over raw `Task` where possible**
Prefer `async let` for parallel independent calls. Use `TaskGroup` for dynamic fan-out.

**R-5 — `Sendable` conformance on data types crossing actor boundaries**
All types passed between actors (model types, DTOs) must conform to `Sendable`. Use `struct` — structs are implicitly `Sendable` if all stored properties are `Sendable`.

---

## Correct Patterns

### ViewModel calling async service
```swift
@Observable
@MainActor
final class LoginViewModel {
    var isLoading = false
    var errorMessage: String?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await authService.login(
                credentials: LoginCredentials(email: email, password: password)
            )
            // handle session
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = AuthError.unknown(error.localizedDescription).errorDescription
        }
    }
}
```

### Parallel independent calls with async let
```swift
func loadDashboard() async {
    async let profile = profileService.fetchProfile()
    async let orders = orderService.fetchRecentOrders()

    do {
        let (userProfile, recentOrders) = try await (profile, orders)
        self.profile = userProfile
        self.orders = recentOrders
    } catch {
        // handle
    }
}
```

### Repository protocol — correct async throws signature
```swift
protocol AuthServiceProtocol: Sendable {
    func login(credentials: LoginCredentials) async throws -> AuthSession
    func logout() async throws
}
```

### Timeout pattern (no external dependencies)
```swift
func loginWithTimeout(credentials: LoginCredentials) async throws -> AuthSession {
    try await withThrowingTaskGroup(of: AuthSession.self) { group in
        group.addTask { try await self.performLogin(credentials: credentials) }
        group.addTask {
            try await Task.sleep(for: .seconds(30))
            throw AuthError.timeout
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
```

---

## Anti-Patterns

### ❌ DispatchQueue.main in SwiftUI code
```swift
// WRONG — use @MainActor instead
DispatchQueue.main.async {
    self.isLoading = false
}
```

### ❌ ViewModel missing @MainActor
```swift
// WRONG — state mutation from background thread possible
@Observable
final class LoginViewModel {  // missing @MainActor
    var isLoading = false
}
```

### ❌ Non-Sendable type crossing actor boundary
```swift
// WRONG — class is not Sendable
class LoginCredentials {  // use struct instead
    var email: String
    var password: String
}
```

### ❌ Unstructured Task detached from actor context
```swift
// WRONG — detached Task loses @MainActor isolation
Task.detached {
    await self.login()  // runs off main actor — UI mutations are unsafe
}

// CORRECT
Task {  // inherits @MainActor from enclosing context
    await self.login()
}
```

### ❌ Continuation misuse (balance required)
```swift
// WRONG — continuation resumed twice (or never)
withCheckedThrowingContinuation { continuation in
    someCallback { result in
        continuation.resume(returning: result)
        continuation.resume(returning: result)  // crash
    }
}
```

---

## Gate Behavior

No dedicated compliance check, but Phase 3 self-validation (`.agent/patterns/self-validation.md`) catches:
- Missing `@MainActor` on ViewModel
- `DispatchQueue.main` usage in Sources/

If a subagent produces concurrency warnings or errors in Phase 3.5 Build Validator → escalate diagnosis to Opus (override rule in model-routing.md).
