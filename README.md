# ios-pilot

Multi-agent iOS dev pipeline. Runs entirely inside Claude Code — no Python, no separate API key.

## Setup

### Option A — Sandbox (safe, no project needed)
Just open this folder in Claude Code. Output goes to `output/`.

### Option B — Project Mode (writes directly to your iOS project)
Put your iOS project inside this folder:
```
ios-pilot/
├── .agent/
├── CLAUDE.md
└── MyApp/              ← your Xcode project here
    ├── MyApp.xcodeproj
    └── MyApp/
```
Then tell the agent: `project: MyApp`

## Pipelines

### A — Greenfield (new feature)
Takes a product brief, outputs PR-ready Swift code.

```
# Agent shows plan first, waits for approval
plan sample_input/feature_request.md

# Approve to run
yes

# Or adjust before running
change folder structure to match our project
```

### B — Migration (UIKit → SwiftUI)
Takes existing UIKit code + architect brief, outputs migrated SwiftUI code with parity tests.

```
run the migration pipeline for sample_input/migration/login_migration_brief.md
```

## Phase Overview

**Greenfield**
| Phase | Agent | Output |
|---|---|---|
| 0 | Codebase Reader | `.state/project-context.md` — conventions, existing infra |
| 1 | Spec Parser | `01-spec.md` — structured spec, ambiguity gate |
| 2 | Task Breakdown | `02-tasks.md` — dependency graph + tasks |
| 3 | Code Gen | `03-code/**/*.swift` — parallel waves |
| 3.5 | Build Validator | `06-build-report.md` — real `swiftc` typecheck |
| 4 | Unit Tests | `04-tests/**/*.swift` — parallel, testability check |
| 4.5 | Revision Cycle | targeted re-gen for untestable ViewModels (conditional) |
| 5 | Review | `05-pr.md` — BLOCKER / WARNING / SUGGESTION |

**Migration**
| Phase | Agent | Output |
|---|---|---|
| M1 | Discovery | `m01-discovery.md` — behavior map of UIKit code |
| M2 | Strategy | `m02-strategy.md` — approach per component |
| M3 | Component Mapping | `m03-mapping.md` — UIKit → SwiftUI API map |
| M4 | Converter | `m04-converted/**/*.swift` |
| M5 | Parity Checker | `m05-tests/` + `m05-parity-report.md` |

## Human Gates
- **Greenfield Phase 1**: stops if brief has unresolved ambiguities
- **Migration M2**: stops if any component requires a feature flag (confirm with user)

## Stack
Swift 6 · SwiftUI · iOS 17+ · MVVM + Clean Architecture · Swift Testing
