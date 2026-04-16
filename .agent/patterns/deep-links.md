# Pattern: Deep Links

**Apply when:** Spec mentions deep links, Universal Links, URL schemes, or navigation from
push notifications / external sources.

---

## Architecture

```
External URL / Push payload
    → DeepLinkHandler (parse URL → DeepLink enum)
        → NavigationRouter (execute navigation)
            → View state update
```

---

## DeepLink Enum

```swift
// Core/DeepLinks/DeepLink.swift
enum DeepLink: Equatable, Sendable {
    case home
    case orderDetail(id: String)
    case productDetail(id: String)
    case profile
    case settings
    case promotionDetail(id: String)
    case unknown(url: URL)
}
```

---

## DeepLinkParser

```swift
// Core/DeepLinks/DeepLinkParser.swift
enum DeepLinkParser {
    // Universal Links:  https://app.example.com/orders/123
    // URL Scheme:       myapp://orders/123

    static func parse(_ url: URL) -> DeepLink {
        // Normalize: strip host differences, handle both scheme and universal links
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch pathComponents.first {
        case "orders"  where pathComponents.count == 2:
            return .orderDetail(id: pathComponents[1])
        case "products" where pathComponents.count == 2:
            return .productDetail(id: pathComponents[1])
        case "profile":
            return .profile
        case "settings":
            return .settings
        case "promotions" where pathComponents.count == 2:
            return .promotionDetail(id: pathComponents[1])
        default:
            return .unknown(url: url)
        }
    }
}
```

---

## DeepLinkHandler

```swift
// Core/DeepLinks/DeepLinkHandler.swift
@MainActor
final class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()

    @Published private(set) var pendingDeepLink: DeepLink?

    func handle(url: URL) {
        let deepLink = DeepLinkParser.parse(url)
        Logger.deepLinks.info("Handling deep link: \(url.absoluteString, privacy: .public)")

        if deepLink == .unknown(url: url) {
            Logger.deepLinks.error("Unknown deep link: \(url.absoluteString, privacy: .public)")
            return
        }
        pendingDeepLink = deepLink
    }

    func consume() -> DeepLink? {
        defer { pendingDeepLink = nil }
        return pendingDeepLink
    }
}
```

---

## NavigationRouter

```swift
// Core/Navigation/NavigationRouter.swift
@Observable @MainActor
final class NavigationRouter {
    var path = NavigationPath()
    var activeSheet: SheetDestination?

    enum SheetDestination: Identifiable {
        case promotionDetail(id: String)
        var id: String {
            switch self { case .promotionDetail(let id): return id }
        }
    }

    func navigate(to deepLink: DeepLink) {
        switch deepLink {
        case .home:
            path = NavigationPath()
        case .orderDetail(let id):
            path.append(OrderRoute.detail(id: id))
        case .productDetail(let id):
            path.append(ProductRoute.detail(id: id))
        case .promotionDetail(let id):
            activeSheet = .promotionDetail(id: id)
        case .profile, .settings:
            path.append(deepLink)
        case .unknown:
            break
        }
    }
}
```

---

## Wiring in RootView

```swift
// Features/Root/RootView.swift
struct RootView: View {
    @State private var router = NavigationRouter()
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: OrderRoute.self) { route in
                    switch route {
                    case .detail(let id): OrderDetailView(id: id)
                    }
                }
                .navigationDestination(for: DeepLink.self) { link in
                    switch link {
                    case .profile:   ProfileView()
                    case .settings:  SettingsView()
                    default:         EmptyView()
                    }
                }
        }
        .sheet(item: $router.activeSheet) { sheet in
            switch sheet {
            case .promotionDetail(let id): PromotionDetailView(id: id)
            }
        }
        .onOpenURL { url in
            deepLinkHandler.handle(url: url)
        }
        .onChange(of: deepLinkHandler.pendingDeepLink) { _, deepLink in
            guard let deepLink = deepLink else { return }
            router.navigate(to: deepLink)
            deepLinkHandler.consume()
        }
    }
}
```

---

## URL Scheme Setup (project.yml)

```yaml
targets:
  <AppName>:
    info:
      path: SupportingFiles/Info.plist
      properties:
        CFBundleURLTypes:
          - CFBundleURLName: com.company.appname
            CFBundleURLSchemes:
              - myapp
```

---

## Universal Links Setup (apple-app-site-association)

The `.well-known/apple-app-site-association` file must be served from your domain.
ios-pilot generates the app-side entitlements — the server-side file is a backend task.

```yaml
# project.yml entitlements
targets:
  <AppName>:
    entitlements:
      path: SupportingFiles/<AppName>.entitlements
      properties:
        com.apple.developer.associated-domains:
          - applinks:app.example.com
          - applinks:www.example.com
```

Expected server file at `https://app.example.com/.well-known/apple-app-site-association`:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.company.appname",
        "paths": ["/orders/*", "/products/*", "/profile", "/settings"]
      }
    ]
  }
}
```

---

## Logger extension

```swift
extension Logger {
    static let deepLinks = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "deeplinks")
}
```

---

## Spec Parser Integration

When brief mentions deep links, add to `01-spec.md`:

```markdown
## Deep Links
| URL | DeepLink case | Screen |
|---|---|---|
| `myapp://orders/:id` | `.orderDetail(id:)` | `OrderDetailView` |
| `myapp://products/:id` | `.productDetail(id:)` | `ProductDetailView` |
| `https://app.example.com/orders/:id` | `.orderDetail(id:)` | `OrderDetailView` |
```

---

## Self-check

- [ ] `DeepLink` enum covers all paths in spec
- [ ] `DeepLinkParser` handles both URL scheme and Universal Links
- [ ] `DeepLinkHandler` is a single shared instance, consumed once
- [ ] Navigation via `NavigationRouter`, not direct state mutation
- [ ] URL scheme registered in `project.yml` / `Info.plist`
- [ ] Universal Links: entitlement added to `project.yml`
- [ ] Backend team notified to serve `apple-app-site-association`
- [ ] Push notification payloads with deep links route through `DeepLinkHandler`
