# Pattern: Secrets Management

**Apply when:** Any spec involves API base URLs, API keys, environment-specific config,
or user credentials that need to persist across sessions.

This pattern defines where every type of secret lives — and enforces that none of them
end up hardcoded in Swift source files.

---

## The Golden Rule

```
Secret type            → Where it lives
─────────────────────────────────────────────────────────────
Build-time config      → .xcconfig  (gitignored for real values)
  (base URL, env flags)  injected → Info.plist → AppConfiguration

Runtime secrets        → Keychain
  (auth token, refresh   via KeychainHelper
   token, biometric key)

CI/CD secrets          → GitHub Actions Secrets
  (signing certs,        never in .xcconfig or .env files
   App Store keys)       referenced as ${{ secrets.NAME }}

Never                  → Swift source files, UserDefaults, plist committed to git
```

---

## 1. Build-Time Config via .xcconfig

### File structure

```
<ProjectRoot>/
├── Configurations/
│   ├── Debug.xcconfig          ← committed (safe values only)
│   ├── Release.xcconfig        ← committed (safe values only)
│   ├── Debug.local.xcconfig    ← gitignored (real dev secrets)
│   └── Release.local.xcconfig  ← gitignored (real prod secrets)
```

### Debug.xcconfig (committed — template only)

```
// Configurations/Debug.xcconfig
// Safe to commit — contains no real secrets.
// Real values go in Debug.local.xcconfig (gitignored).

#include? "Debug.local.xcconfig"

APP_ENV = debug
BASE_URL = https://api-dev.example.com
FEATURE_FLAGS_ENABLED = YES
```

### Debug.local.xcconfig (gitignored — real values)

```
// Configurations/Debug.local.xcconfig
// ⚠️  NEVER COMMIT THIS FILE
// Copy from Debug.xcconfig and fill in real values.

BASE_URL = https://api-dev.yourcompany.com
SOME_THIRD_PARTY_KEY = your_real_key_here
```

### Release.xcconfig (committed — prod template)

```
// Configurations/Release.xcconfig
#include? "Release.local.xcconfig"

APP_ENV = production
BASE_URL = https://api.example.com
FEATURE_FLAGS_ENABLED = NO
```

### project.yml — wire xcconfig to targets

```yaml
# Add to project.yml
configFiles:
  Debug: Configurations/Debug.xcconfig
  Release: Configurations/Release.xcconfig
```

### Info.plist — inject xcconfig values

Add to `SupportingFiles/Info.plist`:
```xml
<key>BASE_URL</key>
<string>$(BASE_URL)</string>
<key>APP_ENV</key>
<string>$(APP_ENV)</string>
```

---

## 2. AppConfiguration — Read Config at Runtime

```swift
// Core/Config/AppConfiguration.swift
// Reads values injected from .xcconfig via Info.plist at build time.
// Never reads from environment variables or hardcoded strings.

enum AppEnvironment: String {
    case debug      = "debug"
    case staging    = "staging"
    case production = "production"
}

struct AppConfiguration: Sendable {
    let baseURL: URL
    let environment: AppEnvironment

    static let current: AppConfiguration = {
        guard
            let dict = Bundle.main.infoDictionary,
            let urlString = dict["BASE_URL"] as? String,
            let baseURL = URL(string: urlString),
            let envString = dict["APP_ENV"] as? String,
            let env = AppEnvironment(rawValue: envString)
        else {
            // This must never happen in a correctly configured build.
            // If it does, the xcconfig is not wired up properly.
            fatalError("AppConfiguration: missing BASE_URL or APP_ENV in Info.plist")
        }
        return AppConfiguration(baseURL: baseURL, environment: env)
    }()
}
```

### Usage in NetworkClient

```swift
// Inject via init — never read AppConfiguration inside NetworkClient directly
let client = NetworkClient(baseURL: AppConfiguration.current.baseURL)
```

---

## 3. Runtime Secrets via Keychain

Use this for: auth tokens, refresh tokens, session IDs, biometric keys.
Never use UserDefaults for these.

```swift
// Core/Security/KeychainHelper.swift
import Security

enum KeychainHelper {
    enum Key: String {
        case authToken    = "com.app.authToken"
        case refreshToken = "com.app.refreshToken"
        case userID       = "com.app.userID"
    }

    // MARK: - Save

    @discardableResult
    static func save(_ value: String, for key: Key) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrAccount:     key.rawValue,
            kSecValueData:       data,
            kSecAttrAccessible:  kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)  // delete existing before adding
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Load

    static func load(for key: Key) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key.rawValue,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else { return nil }
        return value
    }

    // MARK: - Delete

    @discardableResult
    static func delete(for key: Key) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    // MARK: - Clear all (logout)

    static func clearAll() {
        Key.allCases.forEach { delete(for: $0) }
    }
}

extension KeychainHelper.Key: CaseIterable {}
```

### Usage in AuthService

```swift
// After successful login:
KeychainHelper.save(response.authToken, for: .authToken)
KeychainHelper.save(response.refreshToken, for: .refreshToken)

// Reading token for API requests:
guard let token = KeychainHelper.load(for: .authToken) else {
    throw AppAuthError.notAuthenticated
}

// On logout:
KeychainHelper.clearAll()
```

---

## 4. What Goes in .gitignore

Add these entries when this pattern is applied:

```gitignore
# Secrets — never commit
Configurations/*.local.xcconfig
.env
.env.*
!.env.ci.example

# Fastlane / signing
fastlane/report.xml
*.ipa
*.mobileprovision
*.p12
*.cer
```

---

## 5. Developer Onboarding Checklist

When a new developer joins and clones the repo, they need to:

```markdown
## First-time setup (after git clone)

1. Copy xcconfig templates:
   cp Configurations/Debug.xcconfig Configurations/Debug.local.xcconfig
   cp Configurations/Release.xcconfig Configurations/Release.local.xcconfig

2. Fill in real values in Debug.local.xcconfig:
   - BASE_URL → get from team lead or 1Password
   - Any third-party keys → get from team lead or 1Password

3. Open in Xcode — the app should build without any "missing config" errors.

4. Never commit *.local.xcconfig files.
```

Add this checklist to the project `README.md` under a `## Setup` section when CI/CD is configured.

---

## Code Gen Rules

When any task involves API calls or session management:

1. Add to task file list:
   - `Configurations/Debug.xcconfig`
   - `Configurations/Release.xcconfig`
   - `Core/Config/AppConfiguration.swift`
   - `Core/Security/KeychainHelper.swift`
   - Update `SupportingFiles/Info.plist` with `BASE_URL` and `APP_ENV` keys
   - Update `project.yml` with `configFiles` section
   - Update `.gitignore` with `*.local.xcconfig`

2. `NetworkClient` always receives `baseURL` via `AppConfiguration.current.baseURL` — never hardcoded

3. Auth tokens always saved/read via `KeychainHelper` — never `UserDefaults`

---

## Spec Parser Integration

When Spec Parser detects API calls or authentication in the brief, add to `01-spec.md`:

```markdown
## Secrets & Configuration
| Key | Type | Where stored | Who provides |
|---|---|---|---|
| `BASE_URL` | Build-time | `.xcconfig` → `Info.plist` | Team lead / 1Password |
| `AUTH_TOKEN` | Runtime | Keychain (`.authToken`) | Returned by login API |
| `REFRESH_TOKEN` | Runtime | Keychain (`.refreshToken`) | Returned by login API |
```

---

## Self-check (per file)

- [ ] No API keys, tokens, or URLs hardcoded in any `.swift` file
- [ ] Base URL read via `AppConfiguration.current.baseURL` — not from a constant or `Bundle.main` directly
- [ ] Auth token saved to Keychain via `KeychainHelper`, not `UserDefaults`
- [ ] `Configurations/*.local.xcconfig` in `.gitignore`
- [ ] `Info.plist` has `BASE_URL` and `APP_ENV` keys injected from xcconfig
- [ ] `project.yml` has `configFiles` section pointing to xcconfigs
