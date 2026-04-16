# Changelog

All notable changes to ios-pilot are documented here.
Format: [version] — date — description

---

## [1.1.0] — 2026-04-16

### Added
- `examples/login-feature/` — golden examples: 01-spec.md, 02-tasks.md, LoginModels.swift, LoginViewModel.swift
- `plan-mode.md` — plan report format for Pipeline C (Brownfield) and Pipeline D (Bugfix)
- `05-reviewer.md` — Mode 3: optional security + tech debt scan integration after review

### Improved
- `01-spec-parser.md` — explicit Step 5 Navigation Contract pass (was implied, now mandatory with gate)
- `01-spec-parser.md` — Visual Anchors pass renumbered to Step 6

---

## [1.0.0] — 2026-04-16

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
