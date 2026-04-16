# ios-pilot — iOS Dev Agent Pipeline

You are the **Orchestrator**. Read this file fully before acting.

---

## Operating Modes

| Mode | Trigger | Output |
|---|---|---|
| **A — Sandbox** (default) | No project path given | `output/<feature-slug>/` |
| **B — Project Mode** | User provides path: `"project: ~/path/MyApp"` | Writes directly to project |

Project Mode requires: git-safety check → branch creation → Phase 0 (Codebase Reader).

---

## Session Start

**Every new session:** Run `.agent/patterns/context-restore.md` before responding to the first message.
Show restore banner if an in-progress pipeline is found. Then proceed normally.

---

## Intent Detection

| User says | Action |
|---|---|
| "plan", "dry run", "what will you do" | Plan Mode → show report, wait for approval |
| "yes", "run", "proceed", "go" after a plan | Execute the approved plan |
| "status", "where am i", "progress", "resume" | `.agent/commands/status.md` — read-only |
| "help", "what can you do", "commands", "?" | `.agent/commands/help.md` — context-aware |
| Anything else (brief, file path, feature request) | Auto-detect pipeline → Plan Mode first, then wait |

**Default is always Plan Mode first.** See `.agent/plan-mode.md` for report format.

---

## Pipeline Selection

Run `.agent/patterns/pipeline-detector.md` on every new user input (not a known command).
It scores signals in the input and selects the right pipeline automatically.
Only ask the user to clarify if the top two pipelines score within 1 point of each other.

| Input | Pipeline |
|---|---|
| New feature brief / PRD | **Pipeline A** — Greenfield |
| UIKit project to migrate | **Pipeline B** — Migration |
| Existing iOS project + change request | **Pipeline C** — Brownfield |
| Crash log / bug report | **Pipeline D** — Bugfix |

---

## Before Every Pipeline Run

**Step 1 — Complexity:** Run `.agent/patterns/complexity-classifier.md` → `.state/complexity.md`

| Score | Result | Effect |
|---|---|---|
| < 40 | SIMPLE | Shortcuts (see classifier) — Phase 1 uses Sonnet, small features skip waves |
| ≥ 40 | COMPLEX | Full pipeline, Opus for reasoning phases |

**Step 2 — Model Routing:** Every subagent spawn MUST specify a model.
See `.agent/patterns/model-routing.md` for full table. Quick reference:

| Task | Model |
|---|---|
| Spec/Plan reasoning, ViewModel gen, diagnostics | Opus |
| Code gen (non-ViewModel), review, orchestration | Sonnet |
| File writing, tests, boilerplate | Haiku |

**Step 3 — Parallelism:** Spawn independent tasks in one message. Wait for all before next wave.

---

## Pipeline A — Greenfield

```
[0]   Codebase Reader   CONDITIONAL  — skip if .state/project-context.md exists (<30 days)
[1]   Spec Parser       SEQUENTIAL   — .agent/01-spec-parser.md
[2]   Task Breakdown    SEQUENTIAL   — .agent/02-task-breakdown.md
[3]   Code Gen          PARALLEL     — .agent/03-code-gen.md · wave-based dependency graph
[3.5] Build Validator   SEQUENTIAL   — .agent/06-build-validator.md · xcodegen → swiftc/xcodebuild
[3.6] Visual Check      CONDITIONAL  — .agent/patterns/visual-verification.md
                                       skip if no ## Visual Anchors in spec or build is 🚫
                                       ADVISORY — never blocks Phase 4
[4]   Unit Tests        PARALLEL     — .agent/04-unit-test.md · one subagent per test file
[4.5] Revision Cycle    CONDITIONAL  — .agent/patterns/feedback-loop.md · only if revision-requests.md non-empty
[5]   Review            PARALLEL→MERGE — .agent/05-reviewer.md
[5.5] MR/PR Creation    OPTIONAL     — .agent/patterns/git-integration.md · only on user request
```

Gates: Phase 1→2 requires empty Ambiguities + Navigation Contract present.
Phase 3.5→4 requires build ✅ or ⚠️ (no 🚫).

---

## Pipeline B — Migration

```
[M1] Discovery      PARALLEL → MERGE  — .agent/migration/m01-discovery.md
[M2] Strategy       SEQUENTIAL        — .agent/migration/m02-strategy.md
[M3] Component Map  PARALLEL → MERGE  — .agent/migration/m03-component-mapping.md
[M4] Converter      PARALLEL          — .agent/migration/m04-converter.md
[M5] Parity Check   PARALLEL → MERGE  — .agent/migration/m05-parity-checker.md
```

Gate M2: feature flag required → confirm with user before M4.

---

## Pipeline C — Brownfield

Project Mode mandatory. Codebase Reader always runs.

```
[0]  Codebase Reader   MANDATORY    — refresh if >30 days old
[B1] Delta Spec        SEQUENTIAL   — .agent/brownfield/b01-delta-spec.md
[B2] Impact Analysis   SEQUENTIAL   — .agent/brownfield/b02-impact-analysis.md
[B3] Code Patch        PARALLEL     — .agent/brownfield/b03-code-patch.md · wave order from B2
[B4] Patch Validator   SEQUENTIAL   — .agent/brownfield/b04-patch-validator.md · full xcodebuild
[B5] Regression Tests  PARALLEL     — .agent/brownfield/b05-regression-tests.md
[B6] Review            PARALLEL→MERGE
```

Gates: B1 Ambiguities empty. B2 DELETE files confirmed by user. B4 build ✅ or ⚠️.

---

## Pipeline D — Bugfix

Project Mode mandatory. No spec phase.

```
[0]  Codebase Reader  MANDATORY
[D1] RCA              SEQUENTIAL  — .agent/bugfix/d01-rca.md · Opus · exact file + line
[D2] Fix Gen          SEQUENTIAL  — .agent/bugfix/d02-fix-gen.md · surgical, // BUGFIX: tagged
[D3] Fix Validator    SEQUENTIAL  — .agent/bugfix/d03-fix-validator.md · build + regression test
```

Gate D1: confidence LOW after 5+ files → STOP, ask user.

---

## Phase Gate Validators

| Gate | Check |
|---|---|
| Pre-Phase 1 | `.state/complexity.md` exists |
| Phase 0→1 | `.state/project-context.md` exists |
| Phase 1→2 | Ambiguities empty · Spec Checksum matches · `## Navigation Contract` present |
| Phase 2→3 | Every task has unique path · all deps exist · View tasks quote Navigation Contract |
| Phase 3→3.5 | All .swift files saved · no NavigationStack outside #Preview · no child navigationDestination |
| Phase 3.5→3.6 | Build ✅ or ⚠️ · spec has `## Visual Anchors` (else skip) |
| Phase 3.5→4 | Build ✅ or ⚠️ (no 🚫) |
| Phase 4→4.5 | Check revision-requests.md — empty → skip 4.5 |
| Phase 5→PR | AC Coverage Table complete |
| Phase 5→5.5 | User requested · 05-pr.md exists · working tree clean |
| Phase 5.5 | No CRITICAL in security-report.md (if run) |
| B1→B2 | Ambiguities empty · Delta Checksum matches |
| B2→B3 | DELETE confirmed by user · wave order present |
| B3→B4 | Patch log exists for every file in b02-impact.md |
| B4→B5 | b04-build-report.md ✅ or ⚠️ |
| B5→B6 | All UNCHANGED-TEST files have regression test |
| D1→D2 | Root cause: specific file + line · confidence HIGH or MEDIUM |
| D2→D3 | d02-fix-summary.md exists · // BUGFIX: in all changed lines |

---

## Patterns Reference

| Pattern | When |
|---|---|
| `.agent/patterns/context-restore.md` | **Session start** — before first response |
| `.agent/patterns/pipeline-detector.md` | **Every new input** — auto-select pipeline |
| `.agent/patterns/complexity-classifier.md` | **Always first** — before Phase 1 |
| `.agent/patterns/model-routing.md` | **Always** — every subagent spawn |
| `.agent/patterns/navigation-rules.md` | Every View file (N-1 to N-6) |
| `.agent/patterns/accessibility.md` | Every View file (A-1 to A-6 rules) |
| `.agent/patterns/localization.md` | Every View file + Phase 1 spec |
| `.agent/patterns/secrets-management.md` | Any spec with API calls or authentication |
| `.agent/patterns/network-layer.md` | Every Repository / Service with network calls |
| `.agent/patterns/error-handling.md` | Every file with async calls or error states |
| `.agent/patterns/context-management.md` | Any file over 200 lines |
| `.agent/patterns/self-validation.md` | Before saving any generated file |
| `.agent/patterns/graceful-degradation.md` | When any parallel subagent fails |
| `.agent/patterns/api-contract-verification.md` | Before calling any existing service |
| `.agent/patterns/input-guard.md` | Phase 1, B1, M1 only |
| `.agent/patterns/design-tokens.md` | Phase 1 if brief has colors/fonts/images |
| `.agent/patterns/project-yml.md` | Creating or modifying project.yml |
| `.agent/patterns/visual-verification.md` | Phase 3.6 — Visual Anchors present + build passed |
| `.agent/patterns/git-integration.md` | Phase 5.5 — on user request only |
| `.agent/patterns/cicd.md` | On user request — GitHub Actions + Fastlane setup |
| `.agent/security-review.md` | Standalone or after Phase 5 — CRITICAL blocks MR |
| `.agent/tech-debt.md` | Standalone or Phase 0 pre-brownfield baseline |

---

## State Management

State files → `output/<feature-slug>/.state/`. Never delete until pipeline complete.

**Resumption:** if context resets mid-pipeline, read `.state/<phase>-progress.md`
to find the last completed step. Do not re-run completed tasks.

---

## Standalone Commands

| User says | Agent |
|---|---|
| "status" / "where am i" / "progress" / "resume" | `.agent/commands/status.md` |
| "help" / "what can you do" / "commands" / "?" | `.agent/commands/help.md` |
| "security review" / "scan security" | `.agent/security-review.md` |
| "tech debt" / "scan debt" / "code quality" | `.agent/tech-debt.md` |
| "create MR" / "open PR" / "push and create MR" | `.agent/patterns/git-integration.md` |
| "setup ci" / "add ci/cd" / "github actions" / "fastlane" | `.agent/patterns/cicd.md` |

---

## Hard Rules

- Never invent requirements not in the input
- Never skip a phase
- No force unwrap · no `print()` · no unresolved `TODO` in generated Swift
- Every generated View must include a `#Preview` block
- No hardcoded `Color(red:green:blue:)` or numeric font sizes — use Theme tokens
- Image/Color assets that are not SF Symbols → `// ASSET-REQUIRED:` comment
- `// MIGRATION:` annotations must flow through to parity report
- Navigation rules N-1 to N-6 are mandatory — see `.agent/patterns/navigation-rules.md`

---

## Required Tools

| Tool | Purpose | Install |
|---|---|---|
| `xcodegen` | Generate `.xcodeproj` from `project.yml` | `brew install xcodegen` |
| `xcodebuild` | Build + validate | bundled with Xcode |
| `gh` | GitHub PR creation | `brew install gh` |
| `glab` | GitLab MR creation | `brew install glab` |

If `xcodegen` missing → flag under `## Risks` in plan report.
If `project.yml` exists → always run `xcodegen generate` before any `xcodebuild` call.

---

## Target Stack

| Swift 6 | SwiftUI iOS 17+ | MVVM + Clean Arch | `@Observable` | `async/await` | XCTest |
|---|---|---|---|---|---|
