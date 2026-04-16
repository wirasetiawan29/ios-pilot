# ios-pilot

**Agentic iOS development pipeline — from brief to PR-ready Swift code, entirely inside Claude Code.**

No Python. No separate API key. No extra tooling beyond Xcode.

---

## What is this?

ios-pilot is a multi-agent pipeline that orchestrates Claude Code subagents to build, migrate, patch, and debug iOS apps. You describe what you want — the pipeline handles spec parsing, code generation, build validation, unit tests, and review automatically.

Each pipeline runs in **Plan Mode first**: the agent shows you exactly what it will do before touching a single file.

---

## Pipelines

### A — Greenfield
> New feature or app from a product brief

```
brief → spec → task graph → code (parallel waves) → build check → visual check → tests → review → PR
```

### B — Migration
> UIKit → SwiftUI, component by component

```
UIKit code → discovery → strategy → component map → converted SwiftUI → parity tests
```

### C — Brownfield
> Change request on an existing iOS project

```
delta spec → impact analysis (NEW/MODIFY/DELETE/RIPPLE) → surgical patch → build validation → regression tests → review
```

### D — Bugfix
> Crash log or bug report → root cause → fix → validated

```
crash/report → RCA (exact file + line) → surgical fix → build + regression test
```

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/wirasetiawan29/ios-pilot/main/install.sh | bash
```

The script will:
- Check for Claude Code, Xcode, and Homebrew
- Install `xcodegen` if missing
- Clone ios-pilot to `~/ios-pilot`
- Print next steps

Then open the folder in Claude Code:
```bash
claude ~/ios-pilot
```

---

## Quickstart

### Option A — Sandbox (no Xcode project needed)

Open this folder in Claude Code and describe what you want:

```
plan: build a login screen with email/password, Remember Me toggle, and biometric fallback
```

The agent shows a plan. Approve to run:

```
yes
```

Output goes to `output/<feature-slug>/`.

### Option B — Project Mode (writes to your Xcode project)

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

The agent reads your codebase first (Phase 0 — Codebase Reader), then picks the right pipeline automatically.

---

## How it works

Every pipeline run goes through three automatic steps before Phase 1:

| Step | What happens |
|---|---|
| Complexity check | Scores your request SIMPLE / COMPLEX to pick the right model and skip unnecessary phases |
| Model routing | Assigns Opus for reasoning, Sonnet for code gen, Haiku for boilerplate — automatically |
| Parallelism | Independent tasks spawn in parallel waves; the orchestrator waits for each wave before continuing |

Human gates stop the pipeline at key decision points — unresolved ambiguities, risky file deletions, feature flag decisions — so you stay in control.

If the context resets mid-run, the pipeline resumes from the last completed step by reading `.state/<phase>-progress.md`. No work is lost and no phase is re-run.

---

## Phase Overview

### Pipeline A — Greenfield

| Phase | Agent | Output |
|---|---|---|
| 0 | Codebase Reader | `.state/project-context.md` — conventions, existing infra (cached 30 days) |
| 1 | Spec Parser | `01-spec.md` — structured spec, ambiguity gate, Navigation Contract |
| 2 | Task Breakdown | `02-tasks.md` — dependency graph + wave plan |
| 3 | Code Gen | `03-code/**/*.swift` — parallel waves |
| 3.5 | Build Validator | `06-build-report.md` — real `xcodegen` + `xcodebuild` typecheck |
| 3.6 | Visual Check | Screenshots + AI analysis against spec — advisory, never blocks |
| 4 | Unit Tests | `04-tests/**/*.swift` — one subagent per file, parallel |
| 4.5 | Revision Cycle | Targeted re-gen for untestable ViewModels (conditional) |
| 5 | Review | `05-pr.md` — BLOCKER / WARNING / SUGGESTION |
| 5.5 | MR/PR | GitHub / GitLab — on request only |

### Pipeline B — Migration

| Phase | Agent | Output |
|---|---|---|
| M1 | Discovery | `m01-discovery.md` — behavior map of UIKit screens |
| M2 | Strategy | `m02-strategy.md` — approach per component, feature flag gate |
| M3 | Component Mapping | `m03-mapping.md` — UIKit → SwiftUI API map |
| M4 | Converter | `m04-converted/**/*.swift` — navigation rules enforced |
| M5 | Parity Checker | `m05-tests/` + `m05-parity-report.md` |

### Pipeline C — Brownfield

| Phase | Agent | Output |
|---|---|---|
| 0 | Codebase Reader | Mandatory — always refreshes if >30 days old |
| B1 | Delta Spec | `b01-delta-spec.md` — what changes only, not the whole feature |
| B2 | Impact Analysis | `b02-impact.md` — NEW / MODIFY / DELETE / RIPPLE per file |
| B3 | Code Patch | Surgical edits, wave-ordered, RIPPLE-tagged |
| B4 | Patch Validator | `b04-build-report.md` — full `xcodebuild` with baseline check |
| B5 | Regression Tests | NEW + RIPPLE + UNCHANGED-TEST scopes |
| B6 | Review | Parallel per file → merged PR description |

Gates: B1 requires zero unresolved ambiguities. B2 DELETE files must be confirmed by user before B3 runs.

### Pipeline D — Bugfix

| Phase | Agent | Output |
|---|---|---|
| 0 | Codebase Reader | Mandatory |
| D1 | RCA | `d01-rca.md` — root cause to exact file + line (Opus) |
| D2 | Fix Gen | Surgical fix, every changed line tagged `// BUGFIX:` |
| D3 | Fix Validator | Build + regression test that fails before fix, passes after |

Gate D1: if confidence stays LOW after reading 5+ files → pipeline stops and asks for more information. A guess is never written as a fix.

---

## Visual Verification (Phase 3.6)

After a successful build, the pipeline can optionally boot a simulator, run XCUITest screenshots, and use AI to compare each screen against the spec requirements.

This phase is **advisory** — results are warnings, never blockers. Pipeline always continues to Phase 4 regardless of outcome.

Runs automatically when `01-spec.md` contains a `## Visual Anchors` section. If the section is missing, Phase 3.6 is skipped silently. Results flow into the Phase 5 review as `## Visual Check` in the PR description.

---

## Navigation Rules (N-1 to N-6)

Every generated View file is checked against six hard navigation rules. Violations are treated as build errors and must be fixed before Phase 4.

| Rule | Requirement |
|---|---|
| N-1 | `NavigationStack` appears exactly once, inside `RootView` only |
| N-2 | All `navigationDestination(for:)` modifiers declared at the root, never in child views |
| N-3 | No-back-button flows (Onboarding, Login) use `.fullScreenCover`, never a push |
| N-4 | Modally presented views receive `@Binding` for dismissal, not internal `@State` |
| N-5 | `01-spec.md` must contain a `## Navigation Contract` before Code Gen starts |
| N-6 | Every View agent prompt must include the Navigation Contract |

---

## Patterns

14 shared patterns run automatically at the right phase. Key ones:

| Pattern | When it runs |
|---|---|
| `complexity-classifier` | Before every pipeline — determines SIMPLE vs COMPLEX |
| `model-routing` | Every subagent spawn — assigns Opus / Sonnet / Haiku |
| `navigation-rules` | Every View file (N-1 to N-6 enforcement) |
| `self-validation` | Before saving any generated file |
| `visual-verification` | Phase 3.6 — when Visual Anchors are present |
| `graceful-degradation` | When any parallel subagent fails — pipeline continues where it can |
| `context-management` | Any file over 200 lines — prevents context overflow |
| `api-contract-verification` | Before calling any existing service |
| `design-tokens` | Phase 1 — when brief describes colors, fonts, or images |
| `feedback-loop` | Phase 4.5 — targeted revision if tests expose untestable ViewModels |
| `git-integration` | Phase 5.5 — push + create MR/PR on request |

---

## Standalone Commands

Run individual agents on demand without a full pipeline:

| Say this | What runs |
|---|---|
| `security review` | 10-point iOS security scan: Keychain, ATS, hardcoded secrets, biometric flow |
| `tech debt` | 9-category Swift debt report: force unwrap, `@MainActor` misuse, `ObservableObject` leftovers |
| `create MR` / `open PR` | Push branch and create a GitHub / GitLab MR with a generated description |

---

## Hard Rules

These rules are enforced across every pipeline. Generated code that violates them will not be saved.

- No force unwrap (`!`)
- No `print()` statements
- No unresolved `TODO` comments
- Every generated View must include a `#Preview` block
- No hardcoded `Color(red:green:blue:)` or numeric font sizes — use Theme tokens
- Image/Color assets that are not SF Symbols get a `// ASSET-REQUIRED:` comment
- `// MIGRATION:` annotations flow through to the parity report
- Navigation rules N-1 to N-6 are enforced on every View file

---

## Examples

`examples/login-feature/` contains a complete golden example:
- `01-spec.md` — parsed spec with Navigation Contract and Visual Anchors
- `02-tasks.md` — dependency graph and wave plan
- `03-code/Features/Login/LoginModels.swift` — generated models
- `03-code/Features/Login/LoginViewModel.swift` — generated ViewModel

Use these as a reference for what each phase produces.

---

## Requirements

| Tool | Purpose | Install |
|---|---|---|
| Claude Code | Runs the pipeline | [claude.ai/code](https://claude.ai/code) |
| Xcode | Build + validate | Mac App Store |
| `xcodegen` | Generate `.xcodeproj` from `project.yml` | `brew install xcodegen` |
| `gh` / `glab` | PR / MR creation | `brew install gh` or `brew install glab` |

`xcodegen` is only required if your project uses `project.yml`. If it's missing, the pipeline flags it under Risks in the plan report.

---

## Stack

Swift 6 · SwiftUI · iOS 17+ · MVVM + Clean Architecture · `@Observable` · `async/await` · XCTest

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
