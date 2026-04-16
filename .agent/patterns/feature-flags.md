# Pattern: Feature Flags

**Apply when:** Spec mentions feature flags, A/B tests, gradual rollouts, or experimental features.
Also used in Pipeline B (Migration) to gate UIKit → SwiftUI switches.

---

## Architecture

```
View / ViewModel → FeatureFlagServiceProtocol
                        → LocalFeatureFlagService   (static JSON / plist — always available)
                        → RemoteFeatureFlagService  (Firebase Remote Config, LaunchDarkly, etc.)
                        → CompositeFeatureFlagService (local fallback + remote override)
```

---

## Flag Definition

```swift
// Core/FeatureFlags/FeatureFlag.swift
enum FeatureFlag: String, CaseIterable, Sendable {
    // UI/UX experiments
    case newCheckoutFlow     = "new_checkout_flow"
    case redesignedHomeTab   = "redesigned_home_tab"

    // Migration gates (Pipeline B)
    case useSwiftUILogin     = "use_swiftui_login"
    case useSwiftUIOrders    = "use_swiftui_orders"

    // Operational
    case maintenanceMode     = "maintenance_mode"
    case forceAppUpdate      = "force_app_update"

    // Default value when flag cannot be fetched
    var defaultValue: Bool {
        switch self {
        case .newCheckoutFlow:     return false
        case .redesignedHomeTab:   return false
        case .useSwiftUILogin:     return false
        case .useSwiftUIOrders:    return false
        case .maintenanceMode:     return false
        case .forceAppUpdate:      return false
        }
    }
}
```

---

## Service Protocol

```swift
// Core/FeatureFlags/FeatureFlagServiceProtocol.swift
protocol FeatureFlagServiceProtocol: Sendable {
    func isEnabled(_ flag: FeatureFlag) -> Bool
    func fetchRemote() async  // refresh from remote source
}
```

---

## Local Service (no network — always works)

```swift
// Core/FeatureFlags/LocalFeatureFlagService.swift
// Reads from flags.json in app bundle — use for defaults and testing.

final class LocalFeatureFlagService: FeatureFlagServiceProtocol {
    private var flags: [String: Bool]

    init() {
        guard let url = Bundle.main.url(forResource: "flags", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: Bool].self, from: data)
        else {
            self.flags = [:]
            return
        }
        self.flags = decoded
    }

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        flags[flag.rawValue] ?? flag.defaultValue
    }

    func fetchRemote() async {
        // No-op — local service, no remote fetch
    }
}
```

### flags.json (committed — safe defaults only)

```json
{
  "new_checkout_flow": false,
  "redesigned_home_tab": false,
  "use_swiftui_login": false,
  "maintenance_mode": false
}
```

---

## Remote Service (Firebase Remote Config example)

```swift
// Core/FeatureFlags/RemoteFeatureFlagService.swift
import FirebaseRemoteConfig

final class RemoteFeatureFlagService: FeatureFlagServiceProtocol {
    private let remoteConfig = RemoteConfig.remoteConfig()

    init() {
        // Set defaults from FeatureFlag.defaultValue
        var defaults: [String: NSObject] = [:]
        FeatureFlag.allCases.forEach { defaults[$0.rawValue] = NSNumber(value: $0.defaultValue) }
        remoteConfig.setDefaults(defaults)
    }

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        remoteConfig.configValue(forKey: flag.rawValue).boolValue
    }

    func fetchRemote() async {
        do {
            try await remoteConfig.fetch(withExpirationDuration: 3600)
            try await remoteConfig.activate()
        } catch {
            Logger.featureFlags.error("Remote config fetch failed: \(error.localizedDescription, privacy: .public)")
            // Silently fall back to cached/default values
        }
    }
}
```

---

## Composite Service (recommended for production)

```swift
// Core/FeatureFlags/CompositeFeatureFlagService.swift
// Remote overrides local. If remote fetch fails, local defaults are used.

final class CompositeFeatureFlagService: FeatureFlagServiceProtocol {
    private let local: LocalFeatureFlagService
    private let remote: RemoteFeatureFlagService

    init() {
        self.local = LocalFeatureFlagService()
        self.remote = RemoteFeatureFlagService()
    }

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        remote.isEnabled(flag)
    }

    func fetchRemote() async {
        await remote.fetchRemote()
    }
}
```

---

## Usage in Views (Migration Gate)

```swift
// RootView — Pipeline B migration gate
struct RootView: View {
    @Environment(\.featureFlags) private var featureFlags

    var body: some View {
        if featureFlags.isEnabled(.useSwiftUILogin) {
            LoginView()          // new SwiftUI version
        } else {
            LegacyLoginWrapper() // UIViewControllerRepresentable wrapping old UIKit
        }
    }
}
```

## Usage in ViewModels

```swift
@Observable @MainActor final class HomeViewModel {
    private let featureFlags: any FeatureFlagServiceProtocol

    init(featureFlags: any FeatureFlagServiceProtocol) {
        self.featureFlags = featureFlags
    }

    var showNewCheckout: Bool {
        featureFlags.isEnabled(.newCheckoutFlow)
    }
}
```

---

## Environment Key (SwiftUI injection)

```swift
// Core/FeatureFlags/FeatureFlagEnvironmentKey.swift
private struct FeatureFlagKey: EnvironmentKey {
    static let defaultValue: any FeatureFlagServiceProtocol = LocalFeatureFlagService()
}

extension EnvironmentValues {
    var featureFlags: any FeatureFlagServiceProtocol {
        get { self[FeatureFlagKey.self] }
        set { self[FeatureFlagKey.self] = newValue }
    }
}

// In App entry point:
WindowGroup { RootView() }
    .environment(\.featureFlags, CompositeFeatureFlagService())
```

---

## Mock for Tests

```swift
// Tests/Mocks/MockFeatureFlagService.swift
final class MockFeatureFlagService: FeatureFlagServiceProtocol {
    var enabledFlags: Set<FeatureFlag> = []

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        enabledFlags.contains(flag)
    }

    func fetchRemote() async {}
}
```

---

## Spec Parser Integration

When brief mentions feature flags, add to `01-spec.md`:

```markdown
## Feature Flags
| Flag | Default | Purpose | Rollout strategy |
|---|---|---|---|
| `new_checkout_flow` | false | New checkout UX | 10% → 50% → 100% |
| `use_swiftui_login` | false | Migration gate | After parity verified |
```

---

## Self-check

- [ ] Flags defined in `FeatureFlag` enum with default values
- [ ] `FeatureFlagServiceProtocol` injected via init or environment — never a global singleton
- [ ] `flags.json` in app bundle with safe `false` defaults
- [ ] `MockFeatureFlagService` in Tests/Mocks/
- [ ] No `if flag == "string"` comparisons — always use typed `FeatureFlag` enum
- [ ] Remote fetch failure is silent — local defaults always available
