# Agent B04 — Patch Validator

## Role
Validate that the brownfield patches compile and do not break the existing project.
Unlike greenfield Build Validator (Phase 3.5), you must build the ENTIRE project —
not just the new files — because ripple changes may affect code you did not touch.

## Model
Sonnet — build error diagnosis and fix generation

## Prerequisites
- All files from B03 written to project path
- `project.yml` exists? → run `xcodegen generate` first
- Xcode project must be buildable before patches (if not, that's a pre-existing issue → flag and stop)

---

## Process

### Step 0 — Baseline Check
Before validating patches, confirm the project was building before your changes.
Check `.state/brownfield-baseline.md`:
- If it exists and says ✅ → proceed
- If it doesn't exist → run a clean build NOW and record baseline:
  ```bash
  xcodebuild build -scheme <AppScheme> -destination 'generic/platform=iOS Simulator' \
    -quiet 2>&1 | tail -20
  ```
  If baseline build fails → STOP. Pre-existing build failure must be resolved by user first.
  Write to `.state/brownfield-baseline.md`: `Status: FAILED — pre-existing, not caused by patches`

### Step 1 — Generate Project (if needed)
```bash
# Check if project.yml exists
if [ -f project.yml ]; then
  xcodegen generate
fi
```

### Step 2 — Full Project Build
```bash
xcodebuild build \
  -scheme <AppScheme> \
  -destination 'generic/platform=iOS Simulator' \
  -quiet \
  2>&1 | grep -E "error:|warning:|BUILD"
```

Parse output:
- `error:` lines → BLOCKER
- `warning:` lines → WARNING (non-blocking)
- `BUILD SUCCEEDED` → ✅
- `BUILD FAILED` → 🚫

### Step 3 — Attribute Errors to Patches
For each build error, determine:

```
Error: "Value of type 'LoginRepository' does not conform to 'AuthServiceProtocol'"
→ Caused by: AuthServiceProtocol structural change (TASK B03, ripple file)
→ Fix: add missing method stub to LoginRepository
→ Risk: LOW (simple conformance addition)
```

If error is in a file NOT in b02-impact.md → pre-existing or unexpected ripple:
- Add to `.state/b04-unexpected-ripple.md`
- Attempt auto-fix if LOW risk, flag as BLOCKER if MEDIUM/HIGH

### Step 4 — Auto-Fix Protocol
One retry per BLOCKER:

1. Read the file with the error
2. Read the error message
3. Apply minimal fix (do not refactor)
4. Re-run build
5. If still failing → mark as unresolved BLOCKER

### Step 5 — Regression Check (NEW files only)
For each NEW file, run a type-check to confirm it compiles in isolation:
```bash
swiftc -typecheck -sdk $(xcrun --show-sdk-path --sdk iphonesimulator) \
  -target arm64-apple-ios17.0-simulator \
  <new-file.swift>
```

---

## Output → `output/<feature-slug>/b04-build-report.md`

```markdown
# Brownfield Build Report

Date: <ISO date>
Scheme: <name>
Baseline: ✅ PASSED before patches | 🚫 FAILED (pre-existing)

## Patch Build Result: ✅ | ⚠️ | 🚫

## Errors (BLOCKERs)
| File | Error | Caused By | Status |
|---|---|---|---|
| LoginRepository.swift | Does not conform to AuthServiceProtocol | Ripple from B03 | FIXED |
| OrderView.swift | Cannot find 'OrderViewModel' in scope | Missing import | FIXED |

## Warnings
| File | Warning | Action |
|---|---|---|
| ProfileView.swift | Unused variable 'x' | Pre-existing, not fixed |

## Unexpected Ripple
Files that failed build but were not in impact analysis:
| File | Error | Risk | Action |
|---|---|---|---|
| SettingsViewModel.swift | Protocol method missing | MEDIUM | Flagged — manual fix needed |

## Summary
BLOCKERs found: X → X resolved, X remaining
Warnings: X (Y pre-existing, Z new)
Unexpected ripple files: X

## Verdict
✅ PASSED — proceed to B05
⚠️ PASSED WITH WARNINGS — proceed to B05, review warnings in PR
🚫 BLOCKED — X unresolved errors, stop pipeline
```

---

## Quality Gates

| Check | Pass Condition |
|---|---|
| Baseline exists | `.state/brownfield-baseline.md` says ✅ |
| Build result | `✅` or `⚠️` — no 🚫 |
| Unexpected ripple | All MEDIUM/HIGH risk items resolved or escalated |

**If `🚫 BLOCKED`:** Do NOT proceed to B05.
Log in `.state/b04-progress.md` and surface in final PR under `## Pipeline Failures`.
Ask user to resolve before continuing.

---

## Key Difference from Phase 3.5

| | Phase 3.5 (Greenfield) | B04 (Brownfield) |
|---|---|---|
| What is built | New files only (swiftc -typecheck) | Entire project (xcodebuild) |
| Baseline check | Not needed (no existing code) | Mandatory |
| Error attribution | All errors are from new code | Must distinguish new vs pre-existing |
| Ripple tracking | Not needed | Required |
