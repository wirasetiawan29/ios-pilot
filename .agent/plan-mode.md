# Plan Mode

When the user says **"plan"**, **"dry run"**, or **"what will you do"** before running
a pipeline — enter Plan Mode.

Plan Mode reads the input and produces a report **without executing anything**.
No files are written. No Swift code is generated. Minimal token usage.

After showing the plan, **wait for explicit user approval** before proceeding.

---

## Plan Report Format

```markdown
# Plan: <Feature Name>

## Pipeline
<Greenfield | Migration> — reason in one sentence

## Understanding
<2–3 sentence summary of what will be built, from the agent's reading of the brief>

⚠️ Potential misreading: <if brief is ambiguous, flag it here before spending tokens>

## Files to Generate
| # | File | Layer | AC coverage |
|---|---|---|---|
| 1 | `project.yml` | Scaffold | — |
| 2 | `SupportingFiles/Info.plist` | Scaffold | — |
| 3 | `Features/Login/LoginModels.swift` | Model | AC-1, AC-4 |
| 4 | `Features/Login/AuthServiceProtocol.swift` | Protocol | AC-3, AC-4, AC-5 |
| 5 | `Features/Login/UserSession.swift` | Service | AC-4 |
| 6 | `Features/Login/LoginViewModel.swift` | ViewModel | AC-1–5 |
| 7 | `Features/Login/LoginView.swift` | View | AC-1–3 |
| 8 | `Tests/Login/LoginViewModelTests.swift` | Unit Test | AC-1–5 |
Total: 2 scaffold files + 5 Swift files + 1 test file

## Phases
| Phase | Action | Parallel? | Conditional? |
|---|---|---|---|
| 0 | Codebase Reader | — | Skip (no existing project path given) |
| 1 | Spec Parser | — | — |
| 2 | Task Breakdown | — | — |
| 3 | Code Gen | ✅ 2 waves | — |
| 3.5 | Build Validator | — | — |
| 4 | Unit Tests | ✅ all parallel | — |
| 4.5 | Revision Cycle | — | ✅ only if testability issue found |
| 5 | Review | ✅ per file | — |

## Execution Waves (Phase 3)
Wave 1 (parallel): project.yml, Info.plist, LoginModels, AuthServiceProtocol, UserSession
Wave 2 (parallel): LoginViewModel (needs wave 1)
Wave 3 (parallel): LoginView, LoginViewModelTests (both need wave 2)

## Risks & Questions
- ⚠️ `UserSession` marked as "existing singleton" but no interface specified in brief.
  Will generate a new one — confirm this is correct.
- ✅ No ambiguities found in AC coverage.

## Rough Token Estimate
| Phase | Estimated tokens |
|---|---|
| Spec Parser | ~1,500 |
| Task Breakdown | ~800 |
| Code Gen (6 files) | ~6,000 |
| Build Validator | ~200 |
| Unit Tests (1 file) | ~2,000 |
| Review | ~1,500 |
| **Total** | **~12,000** |

---
Proceed? Reply **yes** to run, or give feedback to adjust the plan first.
```

---

---

## Pipeline C Plan Report Format (Brownfield)

```markdown
# Plan: <Change Request Title> [BROWNFIELD]

## Pipeline
Brownfield (Pipeline C) — modifying existing feature in project at <path>

## Understanding
<2–3 sentences: what changes, which screens/layers are affected>

## Baseline
- Last build: ✅ confirmed (or ⚠️ unknown — will check in B4)
- Project context: cached / will read now

## Impact (preliminary — confirmed in B2)
| File | Status | Risk |
|---|---|---|
| `Features/Login/LoginViewModel.swift` | MODIFY | LOW |
| `Features/Orders/OrderListView.swift` | NEW | LOW |
| `Core/Services/AuthServiceProtocol.swift` | MODIFY | HIGH (structural) |

## Phases
| Phase | Action | Note |
|---|---|---|
| 0 | Codebase Reader | Refresh if >30 days |
| B1 | Delta Spec | Two-pass: Opus reasoning → Haiku writing |
| B2 | Impact Analysis | Classify every affected file |
| B3 | Code Patch | Wave-ordered per B2 |
| B4 | Patch Validator | Full xcodebuild |
| B5 | Regression Tests | NEW + RIPPLE + UNCHANGED-TEST |
| B6 | Review | Changed files only |

## Risks & Questions
- ⚠️ AuthServiceProtocol structural change will ripple to all implementors — confirm scope.

## Rough Token Estimate
~8,000–14,000 depending on number of affected files

---
Proceed? Reply **yes** to run, or give feedback to adjust the plan first.
```

---

## Pipeline D Plan Report Format (Bugfix)

```markdown
# Plan: <Bug Title> [BUGFIX]

## Pipeline
Bugfix (Pipeline D) — targeted fix in project at <path>

## Bug Signal
<crash type / symptom / stack trace excerpt>

## Suspected Location (preliminary — confirmed in D1 RCA)
<file and function if identifiable from crash log, else "unknown — RCA will trace">

## Phases
| Phase | Action | Note |
|---|---|---|
| 0 | Codebase Reader | Confirm project context |
| D1 | RCA | Opus — trace to exact file + line |
| D2 | Fix Gen | Surgical — minimum lines changed |
| D3 | Fix Validator | Build + regression test |

## Risks & Questions
- ⚠️ If root cause turns out to be a protocol-level issue, scope may expand.
- Fix will include one regression test.

## Rough Token Estimate
~4,000–8,000 (much smaller than greenfield)

---
Proceed? Reply **yes** to run, or give feedback to adjust the plan first.
```

---

## Plan Mode Rules

- **Read the brief, do not execute it.** No files written, no spec saved.
- List every file that will be generated — user must be able to spot wrong assumptions.
- Flag every ambiguity or potential misreading upfront.
- Token estimate is rough — better to overestimate.
- If the brief is too vague to even plan → list the questions instead of guessing.
- After user approves: run the full pipeline normally.
- After user gives feedback: update the plan and show it again before running.

## Token Estimate Guide

| Item | Rough tokens |
|---|---|
| Spec Parser (per brief page) | ~1,000–2,000 |
| Task Breakdown | ~500–1,000 |
| Code Gen (per Swift file) | ~800–1,500 |
| Build Validator | ~200–500 |
| Unit Test (per test file) | ~1,500–2,500 |
| Reviewer (per file reviewed) | ~500–800 |
| PR consolidation | ~500 |
| Migration Discovery (per UIKit file) | ~1,000–2,000 |
| Migration Converter (per component) | ~2,000–4,000 |
