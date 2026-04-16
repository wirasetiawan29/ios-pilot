# ios-pilot

**Agentic iOS development pipeline — from brief to PR-ready Swift code, entirely inside Claude Code.**

No Python. No separate API key. No extra tooling beyond Xcode and `xcodegen`.

![Version](https://img.shields.io/badge/version-0.11.0-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![iOS](https://img.shields.io/badge/iOS-17%2B-lightgrey)
![Xcode](https://img.shields.io/badge/Xcode-15%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## What is ios-pilot?

ios-pilot is a **CLAUDE.md-driven multi-agent pipeline** that lives entirely inside Claude Code. You describe what you want — the pipeline handles everything else: spec parsing, task breakdown, parallel code generation, build validation, compliance checking, unit tests, and PR review.

```
You:   "plan: add a push notification opt-in screen with permission flow and fallback"
Agent: [shows plan with phases, files to be created, and risks]
You:   "yes"
Agent: [runs all phases, produces PR-ready Swift code]
```

Every pipeline run starts in **Plan Mode** — the agent shows exactly what it will do before touching a single file. You approve, then it runs.

### Why ios-pilot?

| Without ios-pilot | With ios-pilot |
|---|---|
| Write spec in Notion, copy-paste to Claude manually | Brief → structured spec automatically |
| Manually manage file dependencies | Wave-based dependency graph, automatic |
| Forget to write tests | Tests generated and **run** as part of the pipeline |
| Build fails after code gen | Build validator catches errors before tests start |
| Review done by eye | Automated review with BLOCKER / WARNING / SUGGESTION |
| Context resets lose work | State files persist every phase — auto-resume |

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/wirasetiawan29/ios-pilot/main/install.sh | bash
```

The installer checks for Claude Code, Xcode, and Homebrew, installs `xcodegen`, and clones ios-pilot to `~/ios-pilot`. Then open it in Claude Code:

```bash
claude ~/ios-pilot
```

---

## Quickstart

### Sandbox Mode — no Xcode project needed

Open the folder in Claude Code and describe what you want:

```
plan: build a login screen with email/password, error handling, and loading state
```

The agent shows a plan. Approve with:

```
yes
```

Output goes to `output/<feature-slug>/`. Includes a `project.yml` so you can open it in Xcode immediately.

### Project Mode — writes directly to your app

Place your Xcode project inside this folder:

```
ios-pilot/
├── .agent/
├── CLAUDE.md
└── MyApp/              ← your project here
    ├── MyApp.xcodeproj
    └── MyApp/
```

Then point the agent at it:

```
project: MyApp — add push notification permission flow
```

The agent reads your codebase first (Phase 0 — Codebase Reader), detects the right pipeline, and proceeds.

---

## Pipelines

ios-pilot auto-detects which pipeline fits your request. You can also name it explicitly.

### A — Greenfield
> New feature or screen from a product brief

```
Brief → Spec → Task Graph → Code Gen (parallel waves)
     → Compliance Check → Build → Visual Check → Tests → Test Run → Review → PR
```

### B — Migration
> UIKit → SwiftUI, component by component

```
UIKit Code → Discovery → Strategy → Component Map
          → Converter (parallel) → Build → Parity Tests → Test Run → Merge
```

### C — Brownfield
> Change request on an existing iOS project

```
Delta Spec → Impact Analysis (NEW/MODIFY/DELETE/RIPPLE)
          → Surgical Patch → Build → Regression Tests → Review
```

### D — Bugfix
> Crash log or bug report → root cause → fix → validated

```
Crash / Report → RCA (exact file + line) → Surgical Fix → Build + Regression Test
```

---

## Phase Details

### Pipeline A — Greenfield

| Phase | Agent | What it produces |
|---|---|---|
| 0 | Codebase Reader | `.state/project-context.md` — conventions, existing infra (cached 30 days) |
| 1 | Spec Parser | `01-spec.md` — structured spec, Navigation Contract, Visual Anchors, a11y IDs |
| 2 | Task Breakdown | `02-tasks.md` — dependency graph, wave plan, TASK-CL for component library |
| 3 | Code Gen | `03-code/**/*.swift` — parallel waves, navigation rules enforced |
| 3.0 | Compliance Checker | `compliance-report.md` — 11 grep-based Hard Rule checks before build |
| 3.5 | Build Validator | `06-build-report.md` — `xcodegen` + `xcodebuild`, 2-round auto-fix loop |
| 3.6 | Visual Check | Screenshots + AI vs spec — advisory, never blocks |
| 4 | Unit Tests | `04-tests/**/*.swift` — one subagent per ViewModel, parallel |
| 4.1 | Test Run | `xcodebuild test` — all tests must pass before proceeding |
| 4.5 | Revision Cycle | Targeted re-gen for untestable ViewModels (conditional) |
| 5 | Review | `05-pr.md` — BLOCKER / WARNING / SUGGESTION per file |
| 5.5 | PR / MR | GitHub / GitLab — on request only |

**Key gates:**
- Phase 1→2 requires Navigation Contract present and zero unresolved ambiguities
- Phase 3→3.5 requires compliance checker to pass (no Hard Rule violations)
- Phase 3.5→4 requires build ✅ or ⚠️ (no compile errors)
- Phase 4.1→4.5 requires all tests pass

### Pipeline B — Migration

| Phase | Agent | What it produces |
|---|---|---|
| M1 | Discovery | `m01-discovery.md` — behavior map, UIKit API inventory, risk flags |
| M2 | Strategy | `m02-strategy.md` — Full Rewrite / Incremental / Strangler Fig per component |
| M3 | Component Map | `m03-mapping.md` — UIKit → SwiftUI API translation table |
| M4 | Converter | `m04-converted/**/*.swift` — `// MIGRATION:` annotations, navigation rules |
| M4.5 | Build Validator | Converted code must compile before parity tests start |
| M5 | Parity Checker | `m05-tests/` + `m05-parity-report.md` — behavior-level regression tests |
| M5.1 | Test Run | All parity tests must pass — BLOCKED verdict if any fail |

**Key gates:**
- M2→M3 requires feature flag strategy confirmed by user
- M4→M4.5 requires all `// MIGRATION:` annotation counts to match file headers
- M4.5→M5 requires build ✅ or ⚠️
- M5.1→merge requires all parity tests pass and all `// MIGRATION:` annotations resolved

### Pipeline C — Brownfield

| Phase | Agent | What it produces |
|---|---|---|
| 0 | Codebase Reader | Mandatory — refreshes if >30 days old |
| B1 | Delta Spec | `b01-delta-spec.md` — what changes only, not a full spec rewrite |
| B2 | Impact Analysis | `b02-impact.md` — NEW / MODIFY / DELETE / RIPPLE per file |
| B3 | Code Patch | Surgical edits, wave-ordered, RIPPLE-tagged |
| B4 | Patch Validator | `b04-build-report.md` — full `xcodebuild` with baseline check |
| B5 | Regression Tests | NEW + RIPPLE + UNCHANGED-TEST scopes |
| B6 | Review | Parallel per file → merged PR description |

Gates: B1 zero ambiguities. B2 DELETE files confirmed by user before B3 runs.

### Pipeline D — Bugfix

| Phase | Agent | What it produces |
|---|---|---|
| 0 | Codebase Reader | Mandatory |
| D1 | RCA | `d01-rca.md` — root cause to exact file + line (Opus) |
| D2 | Fix Gen | Surgical fix, every changed line tagged `// BUGFIX:` |
| D3 | Fix Validator | Build + regression test that fails before fix, passes after |

Gate D1: confidence stays LOW after 5+ files → pipeline stops and asks for more information. A guess is never written as a fix.

---

## How the Pipeline Thinks

### Complexity Scoring
Before Phase 1, the pipeline scores your request as **SIMPLE** (< 40 points) or **COMPLEX** (≥ 40). Simple features skip heavyweight phases and use faster models.

### Model Routing
Every subagent spawn picks a model based on the task:

| Task type | Model |
|---|---|
| Spec reasoning, RCA, architectural decisions | Opus |
| Code gen (non-ViewModel), review, orchestration | Sonnet |
| Test gen, file writing, boilerplate | Haiku |

### Parallel Waves
Phase 3 Code Gen uses a dependency graph to group tasks into waves. Independent tasks in the same wave run as parallel subagents. The orchestrator waits for each wave to complete before starting the next.

### State Resumption
If the context resets mid-run, the pipeline reads `.state/<phase>-progress.md` and resumes from the last completed step. No phase is re-run.

---

## Compliance Checker

After code generation and before the build, the compliance checker runs 11 grep-based checks against every generated Swift file. These checks do not rely on LLM judgment — each one is a shell command with a deterministic pass/fail result.

| Check | Rule enforced |
|---|---|
| C-1 | No `print()` calls — use `Logger` from `os.log` |
| C-2 | No force unwraps `!` — use `guard let` / `if let` |
| C-3 | No hardcoded `Color(red:)` — use Theme tokens |
| C-4 | No hardcoded font sizes — use `.appTitle`, `.appBody` etc. |
| C-5 | `NavigationStack` only in root view (N-1) |
| C-6 | No `ObservableObject` / `@Published` — use `@Observable` |
| C-7 | `URLSession` only in Repository/Service files, never in ViewModel |
| C-8 | No auth token in `UserDefaults` — use `KeychainHelper` |
| C-9 | No unresolved `// TODO:` in generated code |
| C-10 | Every View file has a `#Preview` block |
| C-11 | No `error.localizedDescription` assigned directly to UI |

Any violation = `[BLOCKER]`. The build step does not start until all violations are resolved.

---

## Navigation Rules

Every generated View is checked against 6 hard navigation rules enforced by both the compliance checker and the build validator.

| Rule | Requirement |
|---|---|
| N-1 | `NavigationStack` appears exactly once — inside `RootView` only |
| N-2 | All `navigationDestination(for:)` declared at root, never in child views |
| N-3 | No-back-button flows (Login, Onboarding) use `.fullScreenCover` not push |
| N-4 | Modal views receive `@Binding` for dismissal — not internal `@State` |
| N-5 | `01-spec.md` must contain a `## Navigation Contract` before Code Gen |
| N-6 | Every View agent prompt must quote the Navigation Contract |

---

## Production Patterns

30 shared patterns run automatically at the right phase. Patterns cover every production concern:

**Architecture & Code Quality**
`complexity-classifier` · `model-routing` · `navigation-rules` · `self-validation` · `compliance-checker` · `context-management` · `graceful-degradation` · `feedback-loop` · `api-contract-verification`

**UI & Design**
`component-library` · `design-tokens` · `accessibility` · `visual-verification`

**Networking & Data**
`network-layer` · `error-handling` · `persistence` · `secrets-management`

**Platform**
`push-notifications` · `deep-links` · `feature-flags` · `analytics` · `crash-reporting` · `localization`

**Infrastructure**
`cicd` · `git-integration` · `git-safety` · `project-yml` · `pipeline-detector` · `context-restore` · `input-guard`

---

## Component Library

Every generated View uses standard components from `AppButton`, `AppTextField`, `AppSecureField`, `AppCard`, `AppLoadingOverlay`, `AppErrorBanner`, and `AppEmptyState` — ensuring visual consistency without hardcoded SwiftUI primitives.

---

## Standalone Commands

Run individual agents without a full pipeline:

| Say this | What runs |
|---|---|
| `status` / `where am i` | Shows current pipeline, phase, progress, and exact next step |
| `help` | Context-aware help — adapts output to active pipeline and phase |
| `security review` | 10-point iOS security scan: Keychain, ATS, hardcoded secrets, biometric flow |
| `tech debt` | 9-category Swift debt report: force unwrap, `@MainActor` misuse, `ObservableObject` leftovers |
| `create MR` / `open PR` | Push branch + create GitHub / GitLab MR with generated description |
| `setup ci` | GitHub Actions CI + deploy workflows + Fastlane Fastfile |

---

## Examples

`examples/login-feature/` contains a complete golden example — fully compilable and tested:

```
examples/login-feature/
├── 01-spec.md                          ← structured spec with Navigation Contract
├── 02-tasks.md                         ← dependency graph and wave plan
└── 03-code/                            ← compilable Xcode project
    ├── project.yml
    ├── Sources/
    │   ├── App/
    │   │   ├── LoginExampleApp.swift
    │   │   └── RootView.swift          ← NavigationStack owner (N-1)
    │   ├── DesignSystem/
    │   │   └── Theme.swift             ← Color, Font, Spacing tokens
    │   └── Features/Login/
    │       ├── LoginModels.swift        ← LoginCredentials, AuthSession, AuthError
    │       ├── LoginViewModel.swift     ← @Observable @MainActor
    │       ├── LoginView.swift          ← fullScreenCover (N-3), a11y IDs
    │       ├── AuthServiceProtocol.swift
    │       └── AuthRepository.swift    ← URLSession, Keychain, 30s timeout
    └── Tests/Features/Login/
        └── LoginViewModelTests.swift   ← 15 tests, all AC coverage, XCTest
```

**Build and test verified:** `xcodebuild build` ✅ · `xcodebuild test` ✅ 15/15 passed on iPhone 15 Pro simulator.

---

## Requirements

| Tool | Purpose | Install |
|---|---|---|
| Claude Code | Runs the pipeline | [claude.ai/code](https://claude.ai/code) |
| Xcode 15+ | Build + validate | Mac App Store |
| `xcodegen` | Generate `.xcodeproj` from `project.yml` | `brew install xcodegen` |
| `gh` / `glab` | PR / MR creation (optional) | `brew install gh` |

`xcodegen` is only required in Sandbox Mode. If missing, the pipeline flags it under Risks in the plan report.

---

## Target Stack

| | |
|---|---|
| **Language** | Swift 5.9+ |
| **UI** | SwiftUI iOS 17+ |
| **Architecture** | MVVM + Clean Architecture |
| **State** | `@Observable` (not `ObservableObject`) |
| **Concurrency** | `async/await` |
| **Tests** | XCTest (Xcode 15+) · Swift Testing (Xcode 16+) |
| **Build** | xcodegen + xcodebuild |
| **CI/CD** | GitHub Actions + Fastlane |

---

## Version History

See [CHANGELOG.md](CHANGELOG.md) for full history.

| Version | Highlights |
|---|---|
| 0.11.0 | Compliance checker (11 grep checks), Pipeline B gates + test run, Large Feature Protocol |
| 0.10.0 | Phase 4.1 test run, ShapeStyle/`@MainActor` in Fix Catalogue, Xcode 15+ target stack |
| 0.9.0 | Component library, 14-pattern auto-fix loop, complete compilable login example |
| 0.8.0 | Push notifications, analytics, persistence, feature flags, deep links, crash reporting |
| 0.7.0 | Secrets management: xcconfig, AppConfiguration, KeychainHelper |
| 0.6.0 | Network layer, error handling, localization, accessibility, CI/CD |
| 0.5.0 | Status/help commands, pipeline detector, context restore |
| 0.3.0 | Four full pipelines, security review, tech debt scan |
