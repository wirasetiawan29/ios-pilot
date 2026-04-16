# Pattern: Analytics

**Apply when:** Spec mentions tracking, events, screen views, user behavior, or analytics.

No third-party SDK is assumed — the pattern uses a protocol that any provider can implement
(Firebase Analytics, Mixpanel, Amplitude, custom backend).

---

## Architecture

```
View / ViewModel → AnalyticsService (protocol)
                        → FirebaseAnalyticsProvider  (or Mixpanel, etc.)
                        → DebugAnalyticsProvider     (prints events in debug)
```

---

## AnalyticsService Protocol

```swift
// Core/Analytics/AnalyticsServiceProtocol.swift
protocol AnalyticsServiceProtocol: Sendable {
    func track(_ event: AnalyticsEvent)
    func screen(_ screen: AnalyticsScreen)
    func identify(userID: String, properties: [String: String])
    func reset()  // call on logout
}
```

---

## Event Model

```swift
// Core/Analytics/AnalyticsEvent.swift
struct AnalyticsEvent: Sendable {
    let name: String
    let properties: [String: String]

    init(_ name: EventName, properties: [String: String] = [:]) {
        self.name = name.rawValue
        self.properties = properties
    }

    enum EventName: String {
        // Auth
        case loginSuccess         = "login_success"
        case loginFailed          = "login_failed"
        case logoutSuccess        = "logout_success"
        case signupStarted        = "signup_started"
        case signupCompleted      = "signup_completed"

        // Navigation
        case screenViewed         = "screen_viewed"
        case tabSelected          = "tab_selected"

        // Errors
        case errorShown           = "error_shown"
        case networkError         = "network_error"

        // Feature-specific: add per feature in Features/<Name>/Analytics+<Name>.swift
    }
}

struct AnalyticsScreen: Sendable {
    let name: String
    let properties: [String: String]

    init(_ name: ScreenName, properties: [String: String] = [:]) {
        self.name = name.rawValue
        self.properties = properties
    }

    enum ScreenName: String {
        case login           = "Login"
        case home            = "Home"
        case profile         = "Profile"
        case settings        = "Settings"
        // Feature-specific: add per feature
    }
}
```

---

## Providers

### Firebase (production)

```swift
// Core/Analytics/FirebaseAnalyticsProvider.swift
import FirebaseAnalytics

final class FirebaseAnalyticsProvider: AnalyticsServiceProtocol {
    func track(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.properties)
    }

    func screen(_ screen: AnalyticsScreen) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screen.name
        ])
    }

    func identify(userID: String, properties: [String: String]) {
        Analytics.setUserID(userID)
        properties.forEach { Analytics.setUserProperty($1, forName: $0) }
    }

    func reset() {
        Analytics.setUserID(nil)
    }
}
```

### Debug (development — uses Logger, no SDK needed)

```swift
// Core/Analytics/DebugAnalyticsProvider.swift
final class DebugAnalyticsProvider: AnalyticsServiceProtocol {
    func track(_ event: AnalyticsEvent) {
        Logger.analytics.debug("📊 EVENT: \(event.name, privacy: .public) \(event.properties.description, privacy: .public)")
    }

    func screen(_ screen: AnalyticsScreen) {
        Logger.analytics.debug("📊 SCREEN: \(screen.name, privacy: .public)")
    }

    func identify(userID: String, properties: [String: String]) {
        Logger.analytics.debug("📊 IDENTIFY: \(userID, privacy: .private)")
    }

    func reset() {
        Logger.analytics.debug("📊 RESET")
    }
}
```

### Composite (run multiple providers simultaneously)

```swift
// Core/Analytics/CompositeAnalyticsProvider.swift
final class CompositeAnalyticsProvider: AnalyticsServiceProtocol {
    private let providers: [any AnalyticsServiceProtocol]

    init(providers: [any AnalyticsServiceProtocol]) {
        self.providers = providers
    }

    func track(_ event: AnalyticsEvent) {
        providers.forEach { $0.track(event) }
    }

    func screen(_ screen: AnalyticsScreen) {
        providers.forEach { $0.screen(screen) }
    }

    func identify(userID: String, properties: [String: String]) {
        providers.forEach { $0.identify(userID: userID, properties: properties) }
    }

    func reset() {
        providers.forEach { $0.reset() }
    }
}
```

---

## Wiring in App Entry Point

```swift
// Core/Analytics/AnalyticsServiceFactory.swift
enum AnalyticsServiceFactory {
    static func make() -> any AnalyticsServiceProtocol {
        #if DEBUG
        return DebugAnalyticsProvider()
        #else
        return CompositeAnalyticsProvider(providers: [
            FirebaseAnalyticsProvider()
            // Add more providers here
        ])
        #endif
    }
}
```

---

## Screen Tracking with ViewModifier

```swift
// Core/Analytics/AnalyticsViewModifier.swift
struct TrackScreenModifier: ViewModifier {
    let screen: AnalyticsScreen
    @Environment(\.analyticsService) private var analytics

    func body(content: Content) -> some View {
        content.onAppear { analytics.screen(screen) }
    }
}

extension View {
    func trackScreen(_ screen: AnalyticsScreen) -> some View {
        modifier(TrackScreenModifier(screen: screen))
    }
}

// Usage in every View:
struct LoginView: View {
    var body: some View {
        VStack { … }
            .trackScreen(.init(.login))
    }
}
```

---

## Event Tracking in ViewModels

```swift
// Inject analytics via init — never access AnalyticsServiceFactory in ViewModel
@Observable @MainActor final class LoginViewModel {
    private let analytics: any AnalyticsServiceProtocol

    init(loginService: LoginServiceProtocol,
         analytics: any AnalyticsServiceProtocol) {
        self.analytics = analytics
    }

    func login() async {
        do {
            try await loginService.login(credentials: credentials)
            analytics.track(.init(.loginSuccess))
        } catch {
            analytics.track(.init(.loginFailed, properties: [
                "error": error.localizedDescription   // no PII here
            ]))
            errorMessage = errorMessage(for: error)
        }
    }
}
```

---

## PII Rules

Never track PII in event properties:

| ❌ Never track | ✅ Track instead |
|---|---|
| Email address | User ID (opaque) |
| Phone number | — |
| Full name | — |
| Device identifier | Session ID (ephemeral) |
| Exact location | City / country only |

---

## Logger extension

```swift
extension Logger {
    static let analytics = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "analytics")
}
```

---

## Spec Parser Integration

When brief mentions tracking, add to `01-spec.md`:

```markdown
## Analytics Events
| Event | Trigger | Properties |
|---|---|---|
| `login_success` | User logs in successfully | — |
| `login_failed` | Login fails | `error_type` |
| `screen_viewed` | Auto — all screens | `screen_name` |
```

---

## Self-check

- [ ] `AnalyticsServiceProtocol` injected via init — never accessed as singleton in ViewModel
- [ ] `DebugAnalyticsProvider` used in `#if DEBUG` builds
- [ ] Screen tracking via `.trackScreen(…)` on every root View
- [ ] No PII in event properties
- [ ] Feature-specific events defined in `Features/<Name>/Analytics+<Name>.swift`
- [ ] `analytics.reset()` called on logout
