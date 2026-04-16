# Pattern: Design Token Extraction

Apply this pattern when a brief, spec, or design reference contains any of:
- Color names, hex values, or "primary/secondary/accent" labels
- Typography scale (font sizes, weights, families)
- Spacing values
- A design image, Figma link, or UI screenshot

---

## When to Apply

| Signal in brief | Action |
|---|---|
| Hex color (`#6B47F5`, `purple`, `brand color`) | Extract to `AppColor` |
| Font spec (`SF Pro, 34pt bold`, `heading`, `body`) | Extract to `AppFont` |
| Spacing values (`16pt padding`, `8pt gap`) | Extract to `AppSpacing` |
| Design image provided | Scan for all visible colors + typography |
| No visual spec at all | Skip this pattern — use SwiftUI semantic colors |

---

## Process

### Step 1 — Identify tokens from the brief/image
List every token you find:
```
Colors:
  - primary   → #6B47F5 (purple, buttons + splash background)
  - onPrimary → #FFFFFF (text/icons on primary)
  - surface   → #FFFFFF (card/form backgrounds)
  - onSurface → #333333 (primary text)
  - subtle    → #8C8C8C (secondary text, placeholders)
  - separator → #D9D9D9 (divider lines)

Typography:
  - displayLarge → 44pt, bold   (splash title)
  - title        → 34pt, bold   (screen title)
  - body         → 16pt, regular
  - label        → 13pt, regular (field labels)
  - footnote     → 12pt, regular (helper text)

Spacing:
  - pagePadding  → 28
  - sectionGap   → 40
  - itemGap      → 24
```

### Step 2 — Write `Sources/DesignSystem/Theme.swift`

```swift
// File: Theme.swift
// Central design token registry. Do NOT hardcode colors or font sizes in Views.

import SwiftUI

// MARK: - Color Tokens

extension Color {
    static let appPrimary   = Color(red: 0.416, green: 0.271, blue: 0.961)
    static let appOnPrimary = Color.white
    static let appSurface   = Color.white
    static let appOnSurface = Color(white: 0.20)
    static let appSubtle    = Color(white: 0.55)
    static let appSeparator = Color(white: 0.85)
}

// MARK: - Typography Tokens

extension Font {
    static let appDisplayLarge = Font.system(size: 44, weight: .bold)
    static let appTitle        = Font.system(size: 34, weight: .bold)
    static let appBody         = Font.system(size: 16, weight: .regular)
    static let appLabel        = Font.system(size: 13, weight: .regular)
    static let appFootnote     = Font.system(size: 12, weight: .regular)
}

// MARK: - Spacing Tokens

enum AppSpacing {
    static let pagePadding: CGFloat  = 28
    static let sectionGap: CGFloat   = 40
    static let itemGap: CGFloat      = 24
}
```

### Step 3 — Register in task breakdown
Add as the first Swift file task (after Scaffold TASK-01/02, before Models):

```markdown
## TASK-DS — DesignSystem: Theme
- **File**: `Sources/DesignSystem/Theme.swift`
- **Depends on**: none
- **AC coverage**: — (infrastructure)
- **Contract**: `Color` extension with `appPrimary`, `appSubtle`, `appSeparator`;
  `Font` extension with `appTitle`, `appBody`, `appLabel`;
  `AppSpacing` enum with `pagePadding`, `sectionGap`, `itemGap`
```

---

## Rules for Downstream Code Gen

- **Never** hardcode `Color(red:green:blue:)` or numeric font sizes in View files
- **Always** use `Color.appPrimary`, `Font.appTitle`, `AppSpacing.pagePadding`, etc.
- If a token is missing from Theme.swift → add it there first, then use it
- `Color("AssetCatalogName")` is allowed for image-backed colors from xcassets — use
  this when the project has a proper asset catalog with named colors

---

## Asset Catalog Color Entries (optional, Xcode only)

When building for Xcode (not swift build) and a color needs dark mode support:
1. Create entry in `Assets.xcassets` → New Color Set → name it `AppPrimary`
2. Reference with `Color("AppPrimary")` in Theme.swift instead of raw RGB
3. Document in task as: `**Asset**: requires Color Set "AppPrimary" in xcassets`

---

## Self-check

- [ ] Every color in a View traces back to `Color.app*` or `Color("...")`
- [ ] Every font in a View traces back to `Font.app*`
- [ ] Every spacing value in a View traces back to `AppSpacing.*`
- [ ] `Theme.swift` has no view code, no logic — tokens only
