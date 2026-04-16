# Pattern: Component Library

**Apply when:** Any View task is generated. Components replace raw SwiftUI primitives
to ensure visual consistency and reduce repetition across screens.

Generated once as `TASK-CL` (Component Library), depended on by all View tasks.

---

## Theme Token Integration

Custom color tokens require **two extensions** in `Theme.swift` to work correctly in all contexts:

```swift
// 1. Direct usage: Color.appPrimary, Color.appError, etc.
extension Color {
    static let appPrimary = Color(hex: "#1A73E8")
    static let appError   = Color(hex: "#D93025")
    // … all tokens
}

// 2. Shorthand in foregroundStyle/background: .appPrimary, .appError, etc.
extension ShapeStyle where Self == Color {
    static var appPrimary: Color { .init(hex: "#1A73E8") }
    static var appError:   Color { .init(hex: "#D93025") }
    // … same tokens
}
```

**Why both are needed:** `foregroundStyle(.appPrimary)` uses a generic `S: ShapeStyle` parameter.
Swift cannot infer `S = Color` from an `extension Color` alone — it needs
`extension ShapeStyle where Self == Color` to make the static member visible in that context.
This is identical to how SwiftUI exposes `.red`, `.blue` etc. system colors.

**Rule:** Every token added to `extension Color` must also appear in
`extension ShapeStyle where Self == Color`. Missing one causes compile error:
`type 'ShapeStyle' has no member 'appX'`.

---

## Standard Components

### AppButton

```swift
// Sources/DesignSystem/Components/AppButton.swift
// AC coverage: — (infrastructure)
// Depends on: Theme.swift

import SwiftUI

enum AppButtonStyle {
    case primary    // filled, appPrimary bg
    case secondary  // outlined, appPrimary border
    case destructive // filled, appError bg
    case ghost      // text only, no border
}

struct AppButton: View {
    let title: String
    let style: AppButtonStyle
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        style: AppButtonStyle = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .scaleEffect(0.8)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(.appBody.weight(.semibold))
                    .foregroundStyle(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.button)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1.5 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isDisabled ? .isNotEnabled : [])
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:     return .appPrimary
        case .secondary:   return .clear
        case .destructive: return .appError
        case .ghost:       return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive: return .white
        case .secondary, .ghost:     return .appPrimary
        }
    }

    private var borderColor: Color {
        style == .secondary ? .appPrimary : .clear
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        AppButton("Sign In", action: {})
        AppButton("Sign In", isLoading: true, action: {})
        AppButton("Sign In", isDisabled: true, action: {})
        AppButton("Cancel", style: .secondary, action: {})
        AppButton("Delete", style: .destructive, action: {})
    }
    .padding()
}
```

---

### AppTextField

```swift
// Sources/DesignSystem/Components/AppTextField.swift
import SwiftUI

struct AppTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isDisabled: Bool = false
    var hasError: Bool = false
    var identifier: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            if !label.isEmpty {
                Text(label)
                    .font(.appCaption)
                    .foregroundStyle(.appSubtle)
            }
            TextField(placeholder, text: $text)
                .font(.appBody)
                .padding(AppSpacing.sm)
                .background(.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.field)
                        .stroke(hasError ? Color.appError : Color.appBorder, lineWidth: 1)
                )
                .disabled(isDisabled)
                .accessibilityLabel(label.isEmpty ? placeholder : label)
                .accessibilityIdentifier(identifier)
        }
    }
}

struct AppSecureField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isDisabled: Bool = false
    var hasError: Bool = false
    var identifier: String = ""

    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            if !label.isEmpty {
                Text(label)
                    .font(.appCaption)
                    .foregroundStyle(.appSubtle)
            }
            HStack {
                Group {
                    if isRevealed {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .font(.appBody)

                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .foregroundStyle(.appSubtle)
                }
                .accessibilityLabel(isRevealed ? L10n.A11y.hidePassword : L10n.A11y.showPassword)
            }
            .padding(AppSpacing.sm)
            .background(.appSurface)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.field)
                    .stroke(hasError ? Color.appError : Color.appBorder, lineWidth: 1)
            )
            .disabled(isDisabled)
            .accessibilityLabel(label.isEmpty ? placeholder : label)
            .accessibilityIdentifier(identifier)
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        AppTextField(label: "Email", placeholder: "Enter email",
                     text: .constant(""), identifier: "email_input")
        AppSecureField(label: "Password", placeholder: "Enter password",
                       text: .constant(""), identifier: "password_input")
        AppTextField(label: "Email", placeholder: "Enter email",
                     text: .constant("bad"), hasError: true, identifier: "email_error")
    }
    .padding()
}
```

---

### AppCard

```swift
// Sources/DesignSystem/Components/AppCard.swift
import SwiftUI

struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.md)
            .background(.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    AppCard {
        VStack(alignment: .leading) {
            Text("Card Title").font(.appTitle)
            Text("Card body content goes here.").font(.appBody)
        }
    }
    .padding()
}
```

---

### AppLoadingOverlay

```swift
// Sources/DesignSystem/Components/AppLoadingOverlay.swift
import SwiftUI

struct AppLoadingOverlay: View {
    let isVisible: Bool

    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.appPrimary)
                    .accessibilityLabel(L10n.A11y.loading)
            }
            .transition(.opacity)
        }
    }
}

extension View {
    func loadingOverlay(_ isVisible: Bool) -> some View {
        overlay { AppLoadingOverlay(isVisible: isVisible) }
            .animation(.easeInOut(duration: 0.2), value: isVisible)
    }
}

#Preview {
    Text("Content behind overlay")
        .loadingOverlay(true)
}
```

---

### AppErrorBanner

```swift
// Sources/DesignSystem/Components/AppErrorBanner.swift
import SwiftUI

struct AppErrorBanner: View {
    let message: String
    var onRetry: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.appError)
                .accessibilityHidden(true)

            Text(message)
                .font(.appCaption)
                .foregroundStyle(.appError)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let onRetry {
                Button(L10n.Action.retry, action: onRetry)
                    .font(.appCaption.weight(.semibold))
                    .foregroundStyle(.appError)
            }
        }
        .padding(AppSpacing.sm)
        .background(Color.appError.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.field))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityIdentifier("error_banner")
    }
}

#Preview {
    VStack {
        AppErrorBanner(message: "Invalid email or password. Please try again.")
        AppErrorBanner(message: "No internet connection.", onRetry: {})
    }
    .padding()
}
```

---

### AppEmptyState

```swift
// Sources/DesignSystem/Components/AppEmptyState.swift
import SwiftUI

struct AppEmptyState: View {
    let icon: String          // SF Symbol name
    let title: String
    let message: String
    var action: (label: String, handler: () -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.appSubtle)
                .accessibilityHidden(true)

            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(.appTitle)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.appBody)
                    .foregroundStyle(.appSubtle)
                    .multilineTextAlignment(.center)
            }

            if let action {
                AppButton(action.label, style: .secondary, action: action.handler)
                    .frame(maxWidth: 200)
            }
        }
        .padding(AppSpacing.pagePadding)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AppEmptyState(
        icon: "tray",
        title: "No orders yet",
        message: "Your orders will appear here once you make a purchase.",
        action: ("Browse products", {})
    )
}
```

---

## Theme Extensions Required

Add to `Theme.swift`:

```swift
// AppRadius — used by components
enum AppRadius {
    static let button: CGFloat = 12
    static let field: CGFloat  = 10
    static let card: CGFloat   = 16
}

// AppBorder color
extension Color {
    static let appBorder = Color(uiColor: .separator)
}

// AppSpacing additions
extension AppSpacing {
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 16
    static let lg: CGFloat  = 24
    static let xl: CGFloat  = 32
}
```

---

## Code Gen Rules

1. Add `TASK-CL` to `02-tasks.md` for every feature with View files:
   ```
   TASK-CL — Component Library
   File: Sources/DesignSystem/Components/ (all component files)
   Depends on: TASK-DS
   Wave: 1 (alongside TASK-DS)
   ```

2. View tasks must import and use components:
   - Replace `Button { } label: { Text("…") }` → `AppButton("…", action: { })`
   - Replace `TextField(…)` → `AppTextField(label:placeholder:text:identifier:)`
   - Replace `SecureField(…)` → `AppSecureField(…)`
   - Replace raw `ProgressView()` overlay → `.loadingOverlay(viewModel.isLoading)`
   - Replace error `Text` → `AppErrorBanner(message:)`
   - Replace empty states → `AppEmptyState(icon:title:message:)`

3. Never generate raw `Button { Text("Label") }` in Views — always `AppButton`

---

## Self-check (per View file)

- [ ] All buttons use `AppButton` — no raw `Button { Text(…) }`
- [ ] All text inputs use `AppTextField` or `AppSecureField`
- [ ] Loading state uses `.loadingOverlay(…)` modifier
- [ ] Errors shown via `AppErrorBanner`
- [ ] Empty states use `AppEmptyState`
- [ ] All components have `.accessibilityIdentifier` set
