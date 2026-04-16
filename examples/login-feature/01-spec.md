# Spec: User Login

## One-liner
Registered user needs to sign in with email and password so they can access their account.

## Goals
- G1: Login API call completes in under 2 seconds on 4G network
- G2: Failed login shows specific error message within 500ms of response
- G3: Session persists across app restarts

## Out of Scope
- Social login (Google, Apple Sign In)
- Biometric authentication (Face ID / Touch ID)
- Account registration / forgot password flow

---

## Acceptance Criteria

### AC-1: Successful login
**Given** a registered user with valid email and password  
**When** they tap "Sign In"  
**Then** the app navigates to HomeScreen  
**And** the session token is persisted in Keychain  
**And** the login form is no longer visible  

Edge cases:
- Leading/trailing whitespace in email field is trimmed before API call
- If already logged in (valid session in Keychain), skip login screen and go directly to HomeScreen

---

### AC-2: Invalid credentials
**Given** the user enters an incorrect email or password  
**When** they tap "Sign In"  
**Then** error message "Invalid email or password. Please try again." is shown below the form  
**And** the password field is cleared  
**And** the email field retains its value  

Edge cases:
- Error message disappears when user starts typing in either field

---

### AC-3: Loading state
**Given** the user taps "Sign In" with valid-format fields  
**When** the network request is in progress  
**Then** a `ProgressView` spinner is shown centered on the screen  
**And** the Sign In button shows "Signing in…" and is disabled  
**And** both text fields are disabled  

Edge cases:
- If request exceeds 30 seconds, show timeout error and re-enable form

---

### AC-4: Empty field validation
**Given** the user is on the login screen  
**When** either the email or password field is empty  
**Then** the Sign In button is disabled  
**And** no error message is shown (validation is silent until submission)

---

### AC-5: Network error
**Given** the device has no internet connectivity  
**When** the user taps "Sign In"  
**Then** error message "No internet connection. Please try again." is shown  
**And** the form is re-enabled immediately (no spinner shown)

---

## Data Models

```swift
struct LoginCredentials: Sendable, Equatable {
    let email: String
    let password: String
}

struct AuthSession: Sendable, Equatable {
    let userId: String
    let token: String
    let expiresAt: Date
}
```

## Dependencies
- `AuthServiceProtocol` — new — `func login(credentials: LoginCredentials) async throws -> AuthSession`
- `KeychainServiceProtocol` — existing — `func save(_ session: AuthSession) throws`

## Constraints
- Performance: API call timeout 30 seconds
- Security: Token stored in Keychain (`kSecAttrAccessibleWhenUnlocked`), never in UserDefaults
- Accessibility: All interactive elements have `.accessibilityIdentifier` for XCUITest

## Design Tokens
| Token | Value | Usage |
|---|---|---|
| `appPrimary` | `#1A73E8` | Sign In button background |
| `appSurface` | `#FFFFFF` | Screen background |
| `appError` | `#D93025` | Error message text |
| `appSubtle` | `#5F6368` | Placeholder text |

Typography: title 28pt semibold, body 16pt regular, caption 13pt regular  
Spacing: pagePadding 24, fieldGap 16, sectionGap 32

---

## Navigation Contract

```
Root: RootView
├── .fullScreenCover(isPresented: $showLogin) → LoginView(@Binding showLogin)
│   └── on successful login: showLogin = false → RootView shows HomeView
└── NavigationStack
    └── HomeView (NavigationStack root)
        └── .navigationDestination(for: Route.self) → [future screens]

Rules for this app:
- LoginView is a fullScreenCover — user cannot back-navigate out of it
- LoginView dismissed by setting showLogin = false (binding pattern, Rule N-4)
- No NavigationStack inside LoginView (Rule N-1)
- HomeView owns all navigationDestinations (Rule N-2)
```

---

## Visual Anchors

- screen: LoginScreen
  description: Login form with email, password fields and sign-in button on a clean white background
  key_elements:
    - app logo or title at top
    - email text field with placeholder "Email"
    - password secure field with placeholder "Password"
    - "Sign In" button (primary blue, disabled when fields empty)
  negative_checks:
    - no loading spinner on initial load
    - no error message on initial load
    - Sign In button is disabled when fields are empty

- screen: LoginScreen_Loading
  description: Login form during API call — spinner visible, controls disabled
  key_elements:
    - ProgressView spinner centered
    - Sign In button shows "Signing in…" and is disabled
  negative_checks:
    - text fields are not interactive during loading

- screen: LoginScreen_Error
  description: Login form after failed attempt — error message visible
  key_elements:
    - error message text in red below the form
    - email field retains value
    - password field is cleared
  negative_checks:
    - no spinner visible
    - Sign In button is re-enabled

---

## Ambiguities
<!-- empty — all requirements are clear -->

## ⚑ Spec Checksum
Requirements found in brief: 5  
Requirements captured in ACs: 5  
Unresolved ambiguities: 0
