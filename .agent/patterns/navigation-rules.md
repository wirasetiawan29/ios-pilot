# Pattern: SwiftUI Navigation Rules

## Triggers
Load this pattern when the task or spec contains any of:
- Keywords: `NavigationStack`, `NavigationLink`, `navigationDestination`, `fullScreenCover`, `sheet`, `push`, `routing`, `back button`, `modal`, `dismiss`
- Phases: Phase 1 Spec Parser (Navigation Contract), Phase 3 Code Gen (any View file)
- Task types: any task that writes a View file or defines screen-to-screen navigation

**Mandatory for every Code Gen agent that writes a View file.**
Violating any rule = treated as build error. Fix before Phase 4.

---

## Rule N-1 — Single NavigationStack

`NavigationStack` appears **exactly once** in the entire app, inside `RootView`
(or the `@main` App struct). No child view may create its own `NavigationStack`
except inside a `#Preview` block.

```swift
// ✅ CORRECT — only in RootView / App
struct RootView: View {
    var body: some View {
        NavigationStack { HomeView() }
    }
}

// ❌ WRONG — inside a child view
struct SomeView: View {
    var body: some View {
        NavigationStack { ... }   // never do this
    }
}
```

---

## Rule N-2 — navigationDestination Registered at Root Only

All `navigationDestination(for:)` modifiers are declared **once**, on the root
view of the NavigationStack. Never declare them on a pushed child view.

```swift
// ✅ CORRECT
NavigationStack {
    HomeView()
        .navigationDestination(for: Product.self) { DetailView(product: $0) }
        .navigationDestination(for: OrderRoute.self) { OrderView(route: $0) }
}

// ❌ WRONG — registered inside a pushed view (unreliable)
struct HomeView: View {
    var body: some View {
        List { ... }
            .navigationDestination(for: Product.self) { ... }
    }
}
```

---

## Rule N-3 — No-Back-Button Flows Use fullScreenCover

Screens the user must NOT back-navigate out of (Onboarding, Login, Splash)
MUST use `.fullScreenCover` or `.sheet`, never a push via `NavigationLink`.

```swift
// ✅ CORRECT — cannot be back-navigated
RootView()
    .fullScreenCover(isPresented: $showOnboarding) {
        OnboardingView(showOnboarding: $showOnboarding)
    }

// ❌ WRONG — user can press back to return
NavigationStack {
    OnboardingView()
}
```

---

## Rule N-4 — Views Dismissed via @Binding

Views presented as `.fullScreenCover` or `.sheet` receive a `@Binding` to control
their own dismissal. They do NOT own an internal `@State` to navigate away.

```swift
// ✅ CORRECT
struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    // Button action: showOnboarding = false
}

// ❌ WRONG
struct OnboardingView: View {
    @State private var navigateToHome = false
    // .navigationDestination(isPresented: $navigateToHome) { HomeView() }
}
```

---

## Rule N-5 — Navigation Contract in Every Spec

`01-spec.md` MUST contain a `## Navigation Contract` section before Code Gen starts.

**Required format:**
```markdown
## Navigation Contract

Root: RootView
├── NavigationStack
│   ├── <RootScreen> (NavigationStack root)
│   │   └── .navigationDestination(for: TypeA) → ScreenB
│   │       └── NavigationLink (closure) → ScreenC
│   └── (ALL navigationDestination registered here, never in child views)
└── .fullScreenCover → <ModalScreen>(@Binding dismiss)

Rules for this app:
- <ModalScreen> dismissed by setting binding to false, no back button
- <ScreenB/C> use standard push with system back button
- No View creates its own NavigationStack
```

**Gate (Phase 1→2):** Section must show at least: root view, one navigation
destination, and any modal flows. If missing → STOP, write contract first.

---

## Rule N-6 — Agent Prompts Must Include Navigation Contract

Every Code Gen agent prompt for a View file MUST quote the relevant portion
of the Navigation Contract. Without it, agents produce incompatible navigation code.

**Required boilerplate in every View agent prompt:**
```
## Navigation Contract (read before writing any navigation code)
<paste ## Navigation Contract from 01-spec.md here>

This view's role: <push destination | NavigationStack root | fullScreenCover>
Navigates to: <next screen or "nothing (leaf view)">
Navigated from: <previous screen>
Back button: <visible (system default) | hidden | N/A (modal)>
```

---

## Gate Checklist (Phase 3→3.5)

Before advancing from Code Gen to Build Validator, verify:
```
[ ] No View file contains NavigationStack outside of #Preview  (Rule N-1)
[ ] No child view declares navigationDestination(for:)          (Rule N-2)
[ ] Modal screens use fullScreenCover / sheet                   (Rule N-3)
[ ] Modal screens receive @Binding for dismissal                (Rule N-4)
[ ] 01-spec.md has ## Navigation Contract                       (Rule N-5)
[ ] Every View agent prompt included Navigation Contract        (Rule N-6)
```
