# Pattern: Push Notifications

---

## Architecture

```
APNS → AppDelegate.didReceiveRemoteNotification
         → NotificationRouter
             → DeepLinkHandler (if payload has deep link)
             → NotificationHandler (per notification type)
                 → ViewModel update
```

---

## Permission Request

Always request permission at a contextually appropriate moment — never on app launch.

```swift
// Core/Notifications/NotificationPermissionService.swift
import UserNotifications

protocol NotificationPermissionServiceProtocol: Sendable {
    func requestPermission() async -> Bool
    func currentStatus() async -> UNAuthorizationStatus
}

final class NotificationPermissionService: NotificationPermissionServiceProtocol {
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            Logger.notifications.error("Permission request failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func currentStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
}
```

### Permission request UI pattern

```swift
// Show permission prompt in context, not on launch
Button(L10n.Action.enableNotifications) {
    Task {
        let granted = await viewModel.requestNotificationPermission()
        if !granted { viewModel.showPermissionDeniedAlert = true }
    }
}
.alert(L10n.Notification.permissionDeniedTitle,
       isPresented: $viewModel.showPermissionDeniedAlert) {
    Button(L10n.Action.openSettings) {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
    Button(L10n.Action.cancel, role: .cancel) {}
} message: {
    Text(L10n.Notification.permissionDeniedMessage)
}
```

---

## Device Token Registration

```swift
// App entry point (@main)
import UIKit

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup { RootView() }
    }
}

// Core/Notifications/AppDelegate.swift
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Logger.notifications.info("Device token registered")
        // Send token to your backend
        Task { await NotificationTokenService.shared.register(token: token) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Logger.notifications.error("Token registration failed: \(error.localizedDescription, privacy: .public)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            await NotificationRouter.shared.route(userInfo: userInfo)
            completionHandler(.newData)
        }
    }
}
```

---

## Notification Payload Model

```swift
// Core/Notifications/NotificationPayload.swift
struct NotificationPayload: Decodable, Sendable {
    let type: NotificationType
    let title: String
    let body: String
    let deepLink: String?
    let data: [String: String]

    enum NotificationType: String, Decodable, Sendable {
        case orderUpdate   = "order_update"
        case promotion     = "promotion"
        case systemAlert   = "system_alert"
        case unknown
    }

    init(from decoder: Decoder) throws {
        // … standard decoding
    }

    // Parse from APNS userInfo dict
    static func parse(from userInfo: [AnyHashable: Any]) -> NotificationPayload? {
        guard let data = try? JSONSerialization.data(withJSONObject: userInfo),
              let payload = try? JSONDecoder().decode(NotificationPayload.self, from: data)
        else { return nil }
        return payload
    }
}
```

---

## Notification Router

```swift
// Core/Notifications/NotificationRouter.swift
@MainActor
final class NotificationRouter: Sendable {
    static let shared = NotificationRouter()

    func route(userInfo: [AnyHashable: Any]) async {
        guard let payload = NotificationPayload.parse(from: userInfo) else {
            Logger.notifications.error("Failed to parse notification payload")
            return
        }

        // Handle deep link if present
        if let deepLink = payload.deepLink,
           let url = URL(string: deepLink) {
            DeepLinkHandler.shared.handle(url: url)
            return
        }

        // Route by type
        switch payload.type {
        case .orderUpdate:   NotificationCenter.default.post(name: .orderUpdateReceived, object: payload)
        case .promotion:     NotificationCenter.default.post(name: .promotionReceived, object: payload)
        case .systemAlert:   NotificationCenter.default.post(name: .systemAlertReceived, object: payload)
        case .unknown:       Logger.notifications.info("Unknown notification type received")
        }
    }
}

extension Notification.Name {
    static let orderUpdateReceived  = Notification.Name("orderUpdateReceived")
    static let promotionReceived    = Notification.Name("promotionReceived")
    static let systemAlertReceived  = Notification.Name("systemAlertReceived")
}
```

---

## Info.plist additions

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

Add to `project.yml` target settings:
```yaml
settings:
  base:
    PUSH_NOTIFICATIONS: YES
```

---

## project.yml — entitlements

```yaml
targets:
  <AppName>:
    entitlements:
      path: SupportingFiles/<AppName>.entitlements
      properties:
        aps-environment: development   # change to "production" for App Store
```

---

## Spec Parser Integration

When brief mentions push notifications, add to `01-spec.md`:

```markdown
## Push Notifications
| Type key | Trigger | Deep link? | Background? |
|---|---|---|---|
| `order_update` | Order status changes | Yes → `/orders/:id` | Yes |
| `promotion` | Marketing campaign | No | No |
```

---

## Self-check

- [ ] Permission requested in context, not on app launch
- [ ] `UIBackgroundModes: remote-notification` in Info.plist
- [ ] Device token sent to backend after registration
- [ ] Payload decoded into typed `NotificationPayload` model
- [ ] All notification types routed via `NotificationRouter`
- [ ] Deep links from notifications go through `DeepLinkHandler`
- [ ] `AppDelegate` wired via `@UIApplicationDelegateAdaptor`
