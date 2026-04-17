# Pattern: Crash Reporting

Supported providers: Firebase Crashlytics (default), Sentry.

---

## Architecture

```
Unhandled exception / crash
    → CrashReporter (protocol)
        → CrashlyticsReporter  (production)
        → DebugCrashReporter   (development — logs only, no upload)

Handled errors / breadcrumbs
    → ViewModel / Service → CrashReporter.record(error:)
```

---

## Protocol

```swift
// Core/CrashReporting/CrashReporterProtocol.swift
protocol CrashReporterProtocol: Sendable {
    func configure()
    func record(error: Error, context: [String: String])
    func setUserID(_ id: String)
    func clearUserID()
    func log(_ message: String)    // breadcrumb
}
```

---

## Firebase Crashlytics

```swift
// Core/CrashReporting/CrashlyticsReporter.swift
import FirebaseCrashlytics

final class CrashlyticsReporter: CrashReporterProtocol {
    func configure() {
        // Crashlytics auto-configures via FirebaseApp.configure() in AppDelegate
        // Enable collection (disable in debug if needed)
        #if DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #else
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif
    }

    func record(error: Error, context: [String: String] = [:]) {
        context.forEach { Crashlytics.crashlytics().setCustomValue($1, forKey: $0) }
        Crashlytics.crashlytics().record(error: error)
    }

    func setUserID(_ id: String) {
        Crashlytics.crashlytics().setUserID(id)
    }

    func clearUserID() {
        Crashlytics.crashlytics().setUserID("")
    }

    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
}
```

---

## Debug Reporter (no upload in development)

```swift
// Core/CrashReporting/DebugCrashReporter.swift
final class DebugCrashReporter: CrashReporterProtocol {
    func configure() {
        Logger.crashReporting.debug("CrashReporter: debug mode — no uploads")
    }

    func record(error: Error, context: [String: String] = [:]) {
        Logger.crashReporting.error("CRASH RECORD: \(error.localizedDescription, privacy: .public) context: \(context.description, privacy: .public)")
    }

    func setUserID(_ id: String) {
        Logger.crashReporting.debug("CrashReporter: setUserID (redacted in debug)")
    }

    func clearUserID() {
        Logger.crashReporting.debug("CrashReporter: clearUserID")
    }

    func log(_ message: String) {
        Logger.crashReporting.debug("BREADCRUMB: \(message, privacy: .public)")
    }
}
```

---

## Factory

```swift
// Core/CrashReporting/CrashReporterFactory.swift
enum CrashReporterFactory {
    static func make() -> any CrashReporterProtocol {
        #if DEBUG
        return DebugCrashReporter()
        #else
        return CrashlyticsReporter()
        #endif
    }
}
```

---

## AppDelegate Setup

```swift
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        CrashReporterFactory.make().configure()
        return true
    }
}
```

---

## Usage in Services (non-fatal errors)

```swift
// Only record non-fatal errors in Service/Repository layer.
// ViewModels handle UX — Services record diagnostics.

final class OrderService: OrderServiceProtocol {
    private let crashReporter: any CrashReporterProtocol

    func fetchOrders() async throws -> [Order] {
        crashReporter.log("Fetching orders")
        do {
            return try await repository.fetchAll()
        } catch AppPersistenceError.fetchFailed(let underlying) {
            crashReporter.record(error: underlying, context: ["operation": "fetchOrders"])
            throw OrderError.loadFailed
        }
    }
}
```

---

## User ID Lifecycle

```swift
// Set after login — use opaque ID, never email or name
crashReporter.setUserID(user.id)

// Clear on logout
crashReporter.clearUserID()
```

---

## project.yml — Firebase SPM package

```yaml
packages:
  Firebase:
    url: https://github.com/firebase/firebase-ios-sdk
    exactVersion: "10.24.0"

targets:
  <AppName>:
    dependencies:
      - package: Firebase
        product: FirebaseCrashlytics
      - package: Firebase
        product: FirebaseAnalytics    # if analytics.md also used
```

---

## GoogleService-Info.plist

The `GoogleService-Info.plist` from Firebase Console must be placed in `SupportingFiles/`.
It is **not generated** by ios-pilot — the developer downloads it from Firebase Console.

Add to `.gitignore` if it contains sensitive project ID:
```gitignore
# Optional — GoogleService-Info.plist is safe to commit (not a secret),
# but some teams prefer to keep it private:
# SupportingFiles/GoogleService-Info.plist
```

Add `// ASSET-REQUIRED: GoogleService-Info.plist from Firebase Console` comment
in AppDelegate where `FirebaseApp.configure()` is called.

---

## Logger extension

```swift
extension Logger {
    static let crashReporting = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "crashReporting")
}
```

---

## Spec Parser Integration

When spec is for a production feature, add to `01-spec.md`:

```markdown
## Crash Reporting
Provider: Firebase Crashlytics
- Non-fatal errors recorded in Service layer with operation context
- User ID set on login, cleared on logout (opaque ID, no PII)
```

---

## Self-check

- [ ] `CrashlyticsReporter` disabled in `#if DEBUG` builds
- [ ] `FirebaseApp.configure()` called before any other Firebase usage
- [ ] `GoogleService-Info.plist` documented with `// ASSET-REQUIRED:`
- [ ] User ID is opaque (user.id), never email or name
- [ ] `clearUserID()` called on logout
- [ ] Non-fatal errors recorded only in Service/Repository layer — never in ViewModel or View
- [ ] Firebase SPM package version pinned in `project.yml`
