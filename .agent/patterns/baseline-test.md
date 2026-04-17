# Pattern: Baseline Test Capture

**Runs as Phase B0 in Pipeline C (Brownfield) and before D2 in Pipeline D (Bugfix).**

Captures the pre-change test state so that post-change results can be compared accurately.
Without a baseline, "regressions" are indistinguishable from pre-existing failures.

---

## When to Run

| Pipeline | When |
|---|---|
| **C — Brownfield** | After Codebase Reader (Phase 0), before Delta Spec (B1) |
| **D — Bugfix** | After RCA (D1), before Fix Gen (D2) |

Skip if `b00-baseline-tests.md` already exists and was captured on the current branch
(check `git log --oneline -1 b00-baseline-tests.md` — if it matches current HEAD, reuse it).

---

## Process

### Step 1 — Detect Build Tool

Run `.agent/patterns/git-safety.md` → Build Tool Detection section.

For iOS packages and Xcode projects, use `xcodebuild`. Never use `swift test` for iOS targets.

### Step 2 — Run the Full Test Suite (Pre-change)

```bash
# iOS SPM package
xcodebuild test \
  -scheme <SchemeName> \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tee /tmp/baseline-test-raw.txt | \
  grep -E "Test.*passed|Test.*failed|error:|Build succeeded|Build FAILED"

# Xcode project
xcodebuild test \
  -project <project-path>/<App>.xcodeproj \
  -scheme <SchemeName> \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tee /tmp/baseline-test-raw.txt | \
  grep -E "Test.*passed|Test.*failed|error:|Build succeeded|Build FAILED"
```

If the build itself fails → record it as `BUILD_FAILED` in the baseline report. Do NOT stop.
The baseline is a snapshot of the current state — even a broken build is useful information.

### Step 3 — Parse Results

Extract from the raw output:

```bash
# Count passes and failures
PASSED=$(grep -c "passed" /tmp/baseline-test-raw.txt || echo 0)
FAILED=$(grep -c "failed" /tmp/baseline-test-raw.txt || echo 0)
TOTAL=$((PASSED + FAILED))

# List failing tests by name
grep "failed" /tmp/baseline-test-raw.txt | \
  sed 's/.*-\[//' | sed 's/\].*//' > /tmp/baseline-failures.txt
```

### Step 4 — Write Baseline Report

Write to `output/<feature-slug>/.state/b00-baseline-tests.md`:

```markdown
# Baseline Test Report

Captured: <ISO datetime>
Branch: <branch-name>
Commit: <git rev-parse --short HEAD>

## Summary
- Total tests: <N>
- Passed: <N>
- Failed: <N>
- Build status: ✅ succeeded | 🚫 FAILED

## Pre-existing Failures (do NOT fix — document only)

These tests were already failing before any changes were made:

| Test | Failure reason (first line) |
|---|---|
| `AuthTests/testLoginInvalidPassword` | `XCTAssertEqual failed: "error" != "invalid_credentials"` |

## Implications for Regression Detection

After changes, any test that was PASSING in this baseline must remain PASSING.
Tests that were already FAILING are pre-existing and are excluded from the regression gate.
```

---

## How Regression Detection Works

After B5 (Brownfield) or D3 (Bugfix) runs tests:

1. Load `b00-baseline-tests.md` → extract the pre-existing failures list.
2. Compare against current test results.
3. **Regression** = a test that PASSED in baseline but FAILS now.
4. **Pre-existing failure** = a test that FAILED in baseline AND still FAILS now → not a regression.
5. **Improvement** = a test that FAILED in baseline but now PASSES → note but do not require.

The regression gate blocks the pipeline if any new failures appear that weren't in the baseline.

---

## Output

`output/<feature-slug>/.state/b00-baseline-tests.md`

This file is read by:
- `b05-regression-tests.md` (Brownfield) — to filter pre-existing failures
- `d03-fix-validator.md` (Bugfix) — to confirm no regressions introduced

---

## Rules

- Never modify source files during baseline capture — read-only phase.
- If build fails during baseline, log it and continue. The failing build is the baseline.
- If no test targets exist yet → write an empty baseline report with `Total tests: 0`.
- Baseline is captured on the **unmodified** branch (before any patch/fix is applied).
