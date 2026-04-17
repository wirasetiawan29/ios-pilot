# ios-pilot

**Agentic iOS development pipeline — from brief to PR-ready Swift code, entirely inside Claude Code.**

No Python. No separate API key. No extra tooling beyond Xcode, `xcodegen`, and the included `pilot` CLI.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
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
| Pipeline never learns from mistakes | Learning Collector extracts reusable patterns after every run |

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/wirasetiawan29/ios-pilot/main/install.sh | bash
```

The installer clones ios-pilot to `~/ios-pilot`, installs `xcodegen`, and adds an `ios-pilot` alias to your shell. After installation, run `source ~/.zshrc` (or restart your terminal).

---

## Quickstart

### Start from anywhere — just type `ios-pilot`

```bash
ios-pilot
```

That's it. Claude Code opens with ios-pilot loaded. No `cd` needed.

### Sandbox Mode — no existing project required

```bash
ios-pilot
# In Claude:
plan: build a login screen with email/password, error handling, and loading state
```

The agent shows a plan. Approve with `yes`. Output goes to `output/<feature-slug>/` — a complete, compilable Xcode project.

### Project Mode — write directly to your existing app

Run `ios-pilot` from **inside your project directory**:

```bash
cd ~/Projects/MyApp
ios-pilot
```

The installer auto-detects your project and prints:

```
✓ Project detected: MyApp
→ In Claude, say: project: MyApp
```

Then in Claude:

```
project: MyApp — add push notification permission flow
```

The agent reads your codebase (Phase 0 — Codebase Reader), creates an `agent/feature-timestamp` branch, and writes only to that branch.

### Other commands

```bash
ios-pilot update     # pull latest version from GitHub
ios-pilot doctor     # check all dependencies
ios-pilot version    # show installed version
```

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

### E — Micro
> Single UI element on an existing screen — no spec, no tests, done in seconds

```
TRIVIAL detected → Plan Confirm → Surgical Edit → Quick Check (5 rules)
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
| L | Learning Collector | `.state/learnings.md` — new patterns extracted, privacy-filtered, ready to submit |

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
| L | Learning Collector | `.state/learnings.md` — migration-specific patterns extracted for submission |

**Key gates:**
- M1→M2 requires every UIKit component in the change request to have a discovery entry and tech debt baseline saved
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
| L | Learning Collector | `.state/learnings.md` — brownfield patch patterns extracted |

Gates: B1 zero ambiguities. B2 DELETE files confirmed by user before B3 runs.

### Pipeline D — Bugfix

| Phase | Agent | What it produces |
|---|---|---|
| 0 | Codebase Reader | Mandatory |
| D1 | RCA | `d01-rca.md` — root cause to exact file + line (Opus) |
| D2 | Fix Gen | Surgical fix, every changed line tagged `// BUGFIX:` |
| D3 | Fix Validator | Build + regression test that fails before fix, passes after |
| L | Learning Collector | `.state/learnings.md` — fix patterns extracted for catalogue |

Gate D1: confidence stays LOW after 5+ files → pipeline stops and asks for more information. A guess is never written as a fix.

### Pipeline E — Micro

| Phase | Agent | What it produces |
|---|---|---|
| T0 | Plan Confirm | One-line plan: "Edit `<file>`: add `<element>`" — waits for user "yes" |
| T1 | Surgical Edit | Minimal change using component library + Theme tokens, Haiku model |
| T2 | Quick Check | 5 compliance checks (C-1 C-2 C-3 C-4 C-10) on changed file only |

**Activates automatically** when all 5 TRIVIAL signals are true:
- Single named UI element (button, label, color, icon, spacing…)
- Element is on an existing screen — not a new screen or flow
- No API, network, or data persistence involved
- No ViewModel method, Service, or Protocol change
- Request uses: add · change · remove · move · rename + one element

If the edit turns out to need more than 2 files or new logic → escalates immediately and suggests running the full pipeline instead.

---

## How the Pipeline Thinks

### Complexity Scoring
Before routing, the pipeline classifies your request into one of three tiers:

| Tier | Condition | Pipeline |
|---|---|---|
| **TRIVIAL** | Single UI element, existing screen, no logic change | E — Micro (3 steps) |
| **SIMPLE** | Score < 40 | A/B/C/D with shortcuts |
| **COMPLEX** | Score ≥ 40 | A/B/C/D full pipeline |

TRIVIAL is detected before scoring runs — no scorer needed. For SIMPLE/COMPLEX, scores can vary ±8 pts; any score in the **35–45 range defaults to COMPLEX**. Only treat a score as reliably SIMPLE if it is ≤ 30.

**Fast Mode** — requests scoring ≤ 20 skip Plan Mode approval entirely and auto-start with a `⚡ Fast Mode — score X/100` notice. All build and test phases still run.

### Model Routing
Every subagent spawn picks a model based on the task:

| Task type | Model |
|---|---|
| Spec reasoning, RCA, architectural decisions | Opus |
| Code gen (non-ViewModel), review, orchestration, **complexity classification**, **migration discovery** | Sonnet |
| Test gen, file writing, boilerplate | Haiku |

Complexity classification runs on Sonnet — a wrong classification cascades to all downstream routing decisions. Migration Discovery (M1) also runs on Sonnet — UIKit behavior classification requires pattern recognition beyond Haiku's capability.

Phase 2 (Task Breakdown) uses **smart downgrade**: Sonnet for SIMPLE scores, Opus for COMPLEX. ViewModel generation, Pipeline C MODIFY, and D1 RCA always stay on Opus — downgrading those would materially hurt result quality.

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

C-2 (force unwrap) and C-10 (#Preview) use robust shell patterns that avoid false positives from boolean-NOT operators and protocol conformance declarations.

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

**35 shared patterns** run automatically at the right phase. Each pattern has an explicit `## Triggers` section — keywords, phases, and task types that activate it — so agents load only the context they need.

**Architecture & Code Quality**
`complexity-classifier` · `model-routing` · `navigation-rules` · `self-validation` · `compliance-checker` · `context-management` · `graceful-degradation` · `feedback-loop` · `api-contract-verification`

**Swift & Concurrency**
`swift-concurrency` · `observable-migration`

**UI & Design**
`component-library` · `design-tokens` · `accessibility` · `visual-verification`

**Networking & Data**
`network-layer` · `error-handling` · `persistence` · `secrets-management`

**Platform**
`push-notifications` · `deep-links` · `feature-flags` · `analytics` · `crash-reporting` · `localization`

**Infrastructure**
`cicd` · `git-integration` · `git-safety` · `project-yml` · `pipeline-detector` · `context-restore` · `input-guard` · `learning-collector`

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
| `brief helper` / `buat brief` | Guided 7-step Q&A → produces a pipeline-ready brief for Greenfield, Brownfield, or Bugfix |
| `security review` | 10-point iOS security scan: Keychain, ATS, hardcoded secrets, biometric flow |
| `tech debt` | 9-category Swift debt report: force unwrap, `@MainActor` misuse, `ObservableObject` leftovers |
| `apple docs check` | Live Apple documentation check — verifies all APIs in the current spec or code against your deployment target using real docs, not model knowledge |
| `create MR` / `open PR` | Push branch + create GitHub / GitLab MR with generated description |
| `setup ci` | GitHub Actions CI + deploy workflows + Fastlane Fastfile |
| `submit learnings` | Create a draft PR to ios-pilot with patterns learned from this pipeline run |

---

## Self-Improving Pipeline

After every pipeline run, ios-pilot runs a **Learning Collector** — a lightweight agent that reads the build report, compliance report, test results, revision requests, and PR review, then extracts patterns that could improve the pipeline itself.

```
Pipeline completes
  → Learning Collector writes output/<slug>/.state/learnings.md
  → Patterns scored: HIGH · MEDIUM · LOW
  → Privacy filter strips all project-specific identifiers

You review the file, then say: "submit learnings"
  → Agent shows confirmation screen with every proposed change
  → You approve → draft PR created on ios-pilot repo
  → Maintainer reviews before merge
```

**What gets learned:**

| Source | Example learning |
|---|---|
| Build report — unmatched error | New row added to Fix Catalogue |
| Compliance report — gap in C-1 to C-11 | New grep-based check proposed |
| Revision requests — recurring pattern | Code-gen rule added to prevent the issue |
| PR review — BLOCKER not caught by compliance | New compliance check candidate |

**Privacy is mandatory.** All class names, method names, file paths, and string literals are stripped before any pattern leaves your machine. The draft PR contains only generic, reusable rules — nothing project-specific.

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

## pilot CLI

ios-pilot ships with a `pilot` command-line tool at the repo root. Agents use it as the canonical interface for all build, test, and compliance operations — no more constructing raw `xcodebuild` flags from scratch each session.

```bash
pilot build        # xcodegen + xcodebuild. Logs to .state/build-log.txt
pilot test         # xcodebuild test. Auto-detects scheme and simulator.
pilot compliance   # All 11 C-* grep checks against Sources/ in one command
pilot status       # Current pipeline, phase, progress, and blockers
pilot clean        # Remove project-local DerivedData
pilot doctor       # Verify all dependencies are installed
pilot update       # Pull latest ios-pilot from origin main
```

Every command outputs a `## PILOT_*_RESULT:` line for reliable agent parsing alongside human-readable output.

```
## PILOT_TEST_RESULT: SUCCESS passed=9 failed=0
## PILOT_COMPLIANCE_RESULT: PASS violations=0
## PILOT_BUILD_RESULT: SUCCESS
```

Run `pilot doctor` after installation to verify your environment:

```bash
./pilot doctor
```

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
| **Tests** | XCTest (`XCTestCase` on Xcode 15) · Swift Testing (`@Suite` + `@Test` on Xcode 16+) |
| **Build** | xcodegen + xcodebuild |
| **CI/CD** | GitHub Actions + Fastlane |

---

## Known Limitations

ios-pilot is honest about what it does not yet support:

| Limitation | Detail |
|---|---|
| **Swift 5.9+ only** | Generated code targets Swift 5.9. Swift 6.0 strict concurrency (`Sendable`, actor isolation) is not enforced — planned for v1.1.0 |
| **No UITest generation** | Only XCTest unit tests are generated. UI automation tests are out of scope |
| **Claude Code CLI required** | Does not run in the Claude web interface or API directly — requires the `claude` CLI |
| **xcodegen required in Sandbox Mode** | Sandbox Mode needs `xcodegen` to produce an `.xcodeproj`. Project Mode uses your existing project |
| **Not validated at scale** | Tested on features up to ~10 files. Large projects (50+ files, complex dependency graphs) may surface edge cases |
| **Learning system in early use** | The Learning Collector is built and battle-tested — first draft PRs from real runs are pending community review |
| **Pipeline E does not generate tests** | Micro edits skip test generation by design. Run the full pipeline if test coverage is required |

---

## Internal Reference Files

| File | Purpose |
|---|---|
| `.agent/gates.md` | Complete phase gate conditions for all 4 pipelines + state file recovery protocol |
| `.agent/RULE-INDEX.md` | Cross-reference: each hard rule → all files that enforce or reference it |
| `CONTRIBUTING.md` | How to add patterns, pipelines, and rules without breaking existing behavior |

---

## Version History

See [CHANGELOG.md](CHANGELOG.md) for full history.

| Version | Highlights |
|---|---|
| **1.0.0** | **All 5 pipelines verified end-to-end. Fast Mode (≤20 score). `brief-helper` command. Project Mode git-safety + agent branch. Learning Collector battle-tested.** |
| 0.17.0 | Pipeline D (Bugfix) tested: D1 RCA → D2 BUGFIX-tagged fix → D3 validator. Project Mode tested: G2/G3 gates + Phase 0 Codebase Reader + agent branch auto-creation. Pipeline B (Migration) tested: M1→M5 full run, UIKit→SwiftUI parity verified |
| 0.16.0 | Pipeline C (Brownfield) tested end-to-end: B0→B5, 9→13 tests. Context restore verified. `brief-helper` guided Q&A command. Fast Mode for score ≤ 20 (skip Plan Mode). Learning Collector: 5 eligible learnings from real run |
| 0.15.2 | Battle-tested fixes from real Pipeline A run: `nonisolated init()` pattern, hardened `project.yml` template, `pilot test` auto-detects stale xcodeproj, C-3 false positive fixed, graceful degradation `// AGENT-FLAG:` rules |
| 0.15.1 | `pilot` CLI (7 commands, machine-readable output), 35 patterns with explicit Triggers, `swift-concurrency.md` + `observable-migration.md` gap fills, `apple docs check` via live Sosumi MCP |
| 0.15.0 | Smart model downgrade: Phase 2 Sonnet for SIMPLE, Opus for COMPLEX — ~40% cost reduction for Pro subscribers |
| 0.14.0 | Pipeline E — Micro: TRIVIAL pre-check, 3-step flow for single UI edits, Haiku-only, auto-escalation |
| 0.13.0 | Semi-autonomous learning system: Learning Collector + submit-learnings command, privacy filter, draft PR flow |
| 0.12.0 | Model routing fixes (Complexity Classifier + Migration Discovery → Sonnet), gates.md extracted, RULE-INDEX.md, CONTRIBUTING.md, M1→M2 gate, C-2/C-10 robustness, complexity soft window |
| 0.11.0 | Compliance checker (11 grep checks), Pipeline B gates + test run, Large Feature Protocol |
| 0.10.0 | Phase 4.1 test run, ShapeStyle/`@MainActor` in Fix Catalogue, Xcode 15+ target stack |
| 0.9.0 | Component library, 14-pattern auto-fix loop, complete compilable login example |
| 0.8.0 | Push notifications, analytics, persistence, feature flags, deep links, crash reporting |
| 0.3.0–0.7.0 | Four full pipelines, security review, tech debt scan, secrets management, network layer, CI/CD |
