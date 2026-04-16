# Changelog

All notable changes to ios-pilot are documented here.
Format: [version] — date — description

---

## [0.10.0] — 2026-04-16

### Fixed — Gaps found during real compile test
- `04-unit-test.md` — Default framework changed to XCTest (Xcode 15+); Swift Testing (`import Testing`) documented as Xcode 16+ only; added `@MainActor` rule for test class when ViewModel is `@MainActor @Observable`; added "Phase Completion" section: run `xcodebuild test` after generation, diagnose failures, one fix round, write `04-test-report.md`
- `06-build-validator.md` — Added 2 patterns to Fix Catalogue: `@MainActor`-isolated property access in non-`@MainActor` View; `ShapeStyle has no member 'appX'` due to missing `extension ShapeStyle where Self == Color`
- `component-library.md` — Added "Theme Token Integration" section explaining why both `extension Color` and `extension ShapeStyle where Self == Color` are required for shorthand color syntax
- `CLAUDE.md` — Added Phase 4.1 (Test Run) to Pipeline A; split Phase 4→4.5 gate into 4→4.1 and 4.1→4.5 with test pass requirement; updated Target Stack to Swift 5.9+ / Xcode 15+

---

## [0.9.0] — 2026-04-16

### Added — DX Improvements & Complete Reference Example
- `component-library.md` — AppButton (4 styles), AppTextField/AppSecureField (show/hide toggle), AppCard, AppLoadingOverlay modifier, AppErrorBanner (with retry), AppEmptyState; TASK-CL wave rules for code gen
- `examples/login-feature/03-code/` — fully compilable Login feature: project.yml, Info.plist, App entry, RootView, Theme, AuthServiceProtocol, AuthRepository, LoginView, LoginViewModel, LoginModels, 15 unit tests (Swift Testing framework) covering all 5 ACs

### Changed
- `06-build-validator.md` — auto-fix loop expanded to 14-pattern Fix Catalogue (typo, missing import, wrong method/init, unused expression, unnecessary await, wrong enum case, N-1/N-2 violations, missing #Preview, ObservableObject→@Observable, print→Logger, force unwrap→guard let); 2 rounds max with explicit stop conditions
- `CLAUDE.md` — `component-library.md` added to Patterns Reference

---

## [0.8.0] — 2026-04-16

### Added — Remaining Production Gaps
- `push-notifications.md` — APNS, permission flow, payload model, NotificationRouter
- `analytics.md` — AnalyticsService protocol, Firebase/Debug providers, screen tracking, PII rules
- `persistence.md` — SwiftData, ModelContainer, domain↔entity mapping, InMemoryRepository for tests
- `feature-flags.md` — FeatureFlag enum, local/remote/composite service, migration gates
- `deep-links.md` — DeepLinkParser, DeepLinkHandler, NavigationRouter, Universal Links + URL scheme
- `crash-reporting.md` — Crashlytics, DebugReporter, user ID lifecycle, SPM setup

### Changed
- `CLAUDE.md` — 6 new patterns added to Patterns Reference

---

## [0.7.0] — 2026-04-16

### Added
- `secrets-management.md` — `.xcconfig` per env, `AppConfiguration`, `KeychainHelper`, developer onboarding checklist

### Changed
- `03-code-gen.md` — hardcoded URL/key and UserDefaults token added to Hard Prohibitions
- `05-reviewer.md` — Secrets & Configuration checklist added to per-file review
- `CLAUDE.md` — `secrets-management` wired into Patterns Reference

---

## [0.6.0] — 2026-04-16

### Added — Production Readiness Patterns
- `network-layer.md` — NetworkClient, Endpoint, retry logic, MockNetworkClient
- `error-handling.md` — AppError hierarchy, domain error mapping, Logger, retry UI
- `localization.md` — String Catalog (iOS 17+), L10n helper, naming conventions
- `accessibility.md` — Rules A-1 to A-6: labels, identifiers, Dynamic Type, VoiceOver
- `cicd.md` — GitHub Actions CI + deploy workflows, Fastlane Fastfile + Matchfile

### Changed
- `01-spec-parser.md` — added Localization pass (Step 7) and Accessibility pass (Step 8)
- `03-code-gen.md` — new patterns wired in, expanded Hard Prohibitions, expanded self-check
- `05-reviewer.md` — added Localization and Accessibility checklists to per-file review
- `CLAUDE.md` — new patterns in reference table, CI/CD standalone command

---

## [0.5.0] — 2026-04-16

### Added
- `status` command — shows current pipeline phase, task progress, and exact next step
- `help` command — context-aware help that adapts to active pipeline and phase
- `pipeline-detector` pattern — auto-detects Greenfield/Brownfield/Bugfix/Migration from user input
- `context-restore` pattern — auto-restores in-progress pipeline state at session start

### Changed
- `CLAUDE.md` — wired session start (context restore), pipeline detector, and new commands

---

## [0.4.0] — 2026-04-16

### Added
- `examples/login-feature/` — golden examples: 01-spec.md, 02-tasks.md, LoginModels.swift, LoginViewModel.swift
- `plan-mode.md` — plan report format for Pipeline C (Brownfield) and Pipeline D (Bugfix)
- `05-reviewer.md` — Mode 3: optional security + tech debt scan integration after review

### Improved
- `01-spec-parser.md` — explicit Step 5 Navigation Contract pass (was implied, now mandatory with gate)
- `01-spec-parser.md` — Visual Anchors pass renumbered to Step 6

---

## [0.3.0] — 2026-04-16

First stable release. Four full pipelines, standalone commands, and production-ready patterns.

### Pipelines

**Pipeline A — Greenfield** (original)
- Phase 0: Codebase Reader (conditional, cached)
- Phase 1: Spec Parser with Navigation Contract enforcement
- Phase 2: Task Breakdown with dependency graph + parallel wave planning
- Phase 3: Code Gen with parallel wave execution
- Phase 3.5: Build Validator (xcodegen + swiftc/xcodebuild, one auto-fix retry)
- Phase 3.6: Visual Verification (advisory, XCUITest screenshots + AI analysis)
- Phase 4: Unit Tests (all parallel)
- Phase 4.5: Revision Cycle (max 1 cycle)
- Phase 5: Review (parallel per file → merged PR description)
- Phase 5.5: MR/PR Creation (optional, on user request)

**Pipeline B — Migration** (original, updated v1.0.0)
- M1–M5: UIKit → SwiftUI component-by-component migration
- Added: model routing per phase (Haiku/Sonnet/Opus)
- Added: tech debt baseline scan before conversion
- Added: navigation rules enforcement in M4 converter
- Added: Visual Anchors generation in M4 for converted screens

**Pipeline C — Brownfield** (new in v1.0.0)
- B1: Delta Spec (what changes, not full spec)
- B2: Impact Analysis (NEW/MODIFY/DELETE/RIPPLE classification per file)
- B3: Code Patch (surgical edits, wave-ordered, RIPPLE-tagged)
- B4: Patch Validator (full xcodebuild with baseline check)
- B5: Regression Tests (NEW + RIPPLE + UNCHANGED-TEST scopes)
- B6: Review

**Pipeline D — Bugfix** (new in v1.0.0)
- D1: RCA — root cause to exact file + line (Opus)
- D2: Fix Gen — surgical fix with `// BUGFIX:` tagging
- D3: Fix Validator — build + regression test that fails before fix, passes after

### Patterns (new in v1.0.0)

| Pattern | Purpose |
|---|---|
| `complexity-classifier.md` | SIMPLE/COMPLEX scoring before every pipeline run |
| `model-routing.md` | Opus/Sonnet/Haiku assignment per task type |
| `navigation-rules.md` | N-1 to N-6 SwiftUI navigation hard rules (extracted from CLAUDE.md) |
| `visual-verification.md` | Phase 3.6 — XCUITest screenshots + AI visual analysis |
| `git-integration.md` | Phase 5.5 — push branch + create MR/PR via gh/glab CLI |

### Standalone Commands (new in v1.0.0)

| Command | Agent |
|---|---|
| "security review" | `security-review.md` — 10 iOS security checks (Keychain, ATS, secrets, biometric…) |
| "tech debt" / "scan debt" | `tech-debt.md` — 9 Swift debt categories (force unwrap, @MainActor, ObservableObject…) |
| "create MR" / "open PR" | `git-integration.md` — GitHub/GitLab MR with confirmation gate |

### Infrastructure

- `CLAUDE.md` reduced from 557 → 227 lines (detail moved to agent files)
- `VERSION` file added
- `CHANGELOG.md` added
- `templates/visual-test.swift` — XCUITest template for Phase 3.6
- `01-spec-parser.md` updated — now generates `## Visual Anchors` section
- Pipeline B fully updated with Sprint 1–3 improvements

### Target Stack
Swift 6 · SwiftUI iOS 17+ · MVVM + Clean Architecture · `@Observable` · `async/await` · XCTest

---

## [0.2.0] — 2026-04-15

- Added Pipeline B (UIKit → SwiftUI Migration): M1 Discovery, M2 Strategy, M3 Component Mapping, M4 Converter, M5 Parity Checker
- Navigation Contract hard rules (N-1 to N-6) added to CLAUDE.md

## [0.1.0] — 2026-04-15

Initial release.

- Pipeline A (Greenfield): Phase 0–5 with parallel wave execution
- SwiftUI Navigation Contract enforcement
- Build Validator with xcodegen support
- Revision Cycle (Phase 4.5)
- Shared patterns: context-management, self-validation, graceful-degradation, input-guard, api-contract-verification, design-tokens, project-yml, git-safety, feedback-loop
