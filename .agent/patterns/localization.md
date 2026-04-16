# Pattern: Localization

**Apply when:** Any View file contains user-facing text, or the spec mentions multiple languages.
iOS 17+ uses String Catalogs (`.xcstrings`) — never generate `.strings` files for new projects.

---

## Standard: String Catalog (iOS 17+)

All user-facing strings live in `Sources/Resources/Localizable.xcstrings`.

**Never use:**
```swift
// ❌ Never hardcode strings in Views
Text("Sign In")
Text("Invalid email address")
Button("Retry")
```

**Always use:**
```swift
// ✅ String(localized:) — type-safe, works with String Catalog
Text(String(localized: "action.sign_in"))
Text(String(localized: "error.invalid_email"))
Button(String(localized: "action.retry")) { … }
```

---

## L10n Helper

Generate this file once per project. It provides compile-time key safety.

```swift
// Core/Localization/L10n.swift
//
// Generated — do not edit manually.
// Keys match Localizable.xcstrings entries.
//
enum L10n {
    // MARK: - Actions
    enum Action {
        static let signIn       = String(localized: "action.sign_in")
        static let signOut      = String(localized: "action.sign_out")
        static let retry        = String(localized: "action.retry")
        static let cancel       = String(localized: "action.cancel")
        static let save         = String(localized: "action.save")
        static let delete       = String(localized: "action.delete")
        static let confirm      = String(localized: "action.confirm")
    }

    // MARK: - Errors
    enum Error {
        static let unknown           = String(localized: "error.unknown")
        static let noConnection      = String(localized: "error.no_connection")
        static let serverUnavailable = String(localized: "error.server_unavailable")
        static func validation(_ message: String) -> String {
            String(localized: "error.validation \(message)")
        }
    }

    // MARK: - Accessibility
    enum A11y {
        static let loading          = String(localized: "a11y.loading")
        static let closeButton      = String(localized: "a11y.close_button")
        static let backButton       = String(localized: "a11y.back_button")
    }
}
```

**Usage:**
```swift
Button(L10n.Action.signIn) { … }
Text(L10n.Error.noConnection)
```

---

## Localizable.xcstrings Template

Create `Sources/Resources/Localizable.xcstrings` with this structure:

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "action.sign_in" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Sign In" } }
      }
    },
    "action.sign_out" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Sign Out" } }
      }
    },
    "action.retry" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Retry" } }
      }
    },
    "action.cancel" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Cancel" } }
      }
    },
    "error.unknown" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Something went wrong. Please try again." } }
      }
    },
    "error.no_connection" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No internet connection. Check your network and retry." } }
      }
    },
    "error.server_unavailable" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Service temporarily unavailable. Please try again later." } }
      }
    },
    "a11y.loading" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Loading" } }
      }
    },
    "a11y.close_button" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Close" } }
      }
    }
  },
  "version" : "1.0"
}
```

---

## Naming Conventions

Use dot-separated namespacing. Never use raw sentence strings as keys.

| Context | Key format | Example |
|---|---|---|
| Action buttons | `action.<verb>` | `action.sign_in` |
| Error messages | `error.<domain>_<type>` | `error.login_invalid_credentials` |
| Screen titles | `screen.<name>_title` | `screen.home_title` |
| Labels | `label.<name>` | `label.email_address` |
| Placeholders | `placeholder.<field>` | `placeholder.email` |
| Accessibility | `a11y.<element>` | `a11y.loading_indicator` |
| Plurals | `<key>_count` | `item_count` |

---

## Plural Strings

```json
"item_count" : {
  "localizations" : {
    "en" : {
      "variations" : {
        "plural" : {
          "one"   : { "stringUnit" : { "state" : "translated", "value" : "%lld item" } },
          "other" : { "stringUnit" : { "state" : "translated", "value" : "%lld items" } }
        }
      }
    }
  }
}
```

```swift
// Usage
Text(String(localized: "item_count \(count)"))
```

---

## project.yml Setup

```yaml
targets:
  <AppName>:
    resources:
      - path: Sources/Resources
        includes: ["*.xcstrings", "*.xcassets"]
```

---

## Spec Parser Integration

When Spec Parser (Phase 1) processes a brief:
- Scan for every user-facing string in the AC `Then` clauses
- Add a `## Localization` section to `01-spec.md`:

```markdown
## Localization
<!-- Keys to add to Localizable.xcstrings for this feature -->
| Key | English value |
|---|---|
| `action.sign_in` | Sign In |
| `error.login_invalid_credentials` | Incorrect email or password. |
| `screen.login_title` | Welcome Back |
```

---

## Code Gen Rules

1. Every View file task gets an additional dependency: `Core/Localization/L10n.swift`
2. No `Text("…")` with raw strings — always `Text(L10n.…)` or `Text(String(localized: "…"))`
3. New feature keys must be added to `Localizable.xcstrings` as part of the same task
4. Accessibility labels also use localized strings via `L10n.A11y`

---

## Self-check (per View file)

- [ ] No hardcoded English strings in `Text(…)`, `Button(…)`, `.accessibilityLabel(…)`
- [ ] All strings use `L10n.<Category>.<key>` or `String(localized: "…")`
- [ ] New keys are defined in `Localizable.xcstrings`
- [ ] Plural strings use `String(localized:)` with count interpolation
