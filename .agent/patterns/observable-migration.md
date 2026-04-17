# Pattern: Observable Migration

## Triggers
Load this pattern when:
- Keywords: `@Observable`, `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `Observation framework`, `iOS 17`, `migrate to Observable`
- Phases: Phase 0 Codebase Reader (detect legacy patterns), Phase 3 Code Gen (all ViewModel files), Pipeline B Migration (any UIKit → SwiftUI conversion)
- Task types: any ViewModel, any View that receives a ViewModel

---

## The Rule

All ViewModels MUST use `@Observable` (iOS 17+). `ObservableObject` / `@Published` are forbidden in generated code (Compliance Check C-6).

---

## Migration Reference

| Old (ObservableObject) | New (@Observable) |
|---|---|
| `class VM: ObservableObject` | `@Observable class VM` |
| `@Published var x = ""` | `var x = ""` (no wrapper needed) |
| `@StateObject var vm = VM()` | `@State var vm = VM()` |
| `@ObservedObject var vm: VM` | `var vm: VM` (passed as parameter) |
| `@EnvironmentObject var vm: VM` | `@Environment(VM.self) var vm` |

---

## Correct Patterns

### ViewModel definition
```swift
// ✅ CORRECT — iOS 17+
@Observable
@MainActor
final class LoginViewModel {
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?
    var isAuthenticated = false

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = AuthRepository()) {
        self.authService = authService
    }
}
```

### Owning View — @State
```swift
// ✅ CORRECT — owner creates and holds the ViewModel
struct LoginContainerView: View {
    @State private var viewModel = LoginViewModel()

    var body: some View {
        LoginView(viewModel: viewModel)
    }
}
```

### Child View — plain parameter
```swift
// ✅ CORRECT — child receives ViewModel as plain property
struct LoginView: View {
    var viewModel: LoginViewModel  // no property wrapper needed

    var body: some View {
        TextField("Email", text: $viewModel.email)
    }
}
```

### Environment injection
```swift
// ✅ CORRECT — inject via .environment(_:)
ContentView()
    .environment(appState)  // AppState is @Observable

// Reading from environment
struct ChildView: View {
    @Environment(AppState.self) private var appState
}
```

---

## Anti-Patterns

### ❌ ObservableObject in new code
```swift
// WRONG — C-6 violation
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
}
```

### ❌ @StateObject / @ObservedObject
```swift
// WRONG — C-6 violation
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    // or
    @ObservedObject var viewModel: LoginViewModel
}
```

### ❌ @EnvironmentObject (legacy)
```swift
// WRONG — use @Environment(Type.self) instead
@EnvironmentObject var settings: AppSettings
```

### ❌ @Observable class with @Published (mixed)
```swift
// WRONG — @Published has no effect inside @Observable, causes confusion
@Observable
class LoginViewModel {
    @Published var email = ""  // remove @Published
}
```

---

## Bindable — for two-way binding to @Observable properties

When a child View needs `$viewModel.someProperty` binding syntax, use `@Bindable`:

```swift
struct LoginFormView: View {
    @Bindable var viewModel: LoginViewModel  // enables $viewModel.email syntax

    var body: some View {
        TextField("Email", text: $viewModel.email)
    }
}
```

Use `@Bindable` only when the View needs to write back to the ViewModel via `$binding`. For read-only child Views, plain `var viewModel: LoginViewModel` is sufficient.

---

## Gate Behavior

**Compliance Check C-6** (in `.agent/patterns/compliance-checker.md`):
```bash
grep -rn "ObservableObject\|@Published" Sources/ --include="*.swift"
```
- Pass: no output
- Fail: `[BLOCKER]` — pipeline stops until fixed
- Fix: apply migration table above
