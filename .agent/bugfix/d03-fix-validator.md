# Agent D03 — Fix Validator + Regression Test

## Role
You are a senior iOS engineer validating that the fix works and will not regress.
Two jobs: (1) confirm the project builds, (2) write a regression test.

## Model
- Build validation: Sonnet
- Regression test writing: Haiku

---

## Part 1 — Build Validation

### Step 1 — Generate Project (if needed)
```bash
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

Parse:
- `BUILD SUCCEEDED` → ✅ proceed to Part 2
- `BUILD FAILED` + errors in fixed files → fix introduced new issues → diagnose and fix (one retry)
- `BUILD FAILED` + errors in unrelated files → pre-existing issue → flag and note in report

---

## Part 2 — Regression Test

### Goal
Write one test that:
1. **Would have FAILED before the fix** (demonstrates the bug)
2. **PASSES after the fix** (confirms the fix works)
3. **Is as simple as possible** — tests the exact scenario, no over-engineering

### Test Structure

```swift
// Regression test for: <bug title from d01-rca.md>
// Root cause: <one-line summary from d01-rca.md>
// Fixed in: <file + line>

@Test("login with nil-returning auth service does not crash")
func loginWithNilAuthServiceHandlesGracefully() async throws {
    // Arrange — simulate the condition that caused the crash
    let mockAuth = MockAuthService()
    mockAuth.stubbedResult = nil   // simulate network timeout → nil return
    let sut = LoginViewModel(authService: mockAuth)

    // Act — perform the action that caused the crash
    await sut.login(email: "test@example.com", password: "pass")

    // Assert — fix should handle nil gracefully, not crash
    #expect(sut.errorMessage != nil)     // error shown to user
    #expect(sut.isLoading == false)       // loading stopped
    // No crash = test passes
}
```

### Rules for Regression Tests

```
[ ] Test name describes the BUG scenario, not the fix (e.g., "login with nil auth does not crash")
[ ] Uses @Test and #expect (Swift Testing, not XCTestCase)
[ ] Mock simulates the EXACT condition from d01-rca.md root cause
[ ] Test is in the existing test file for this ViewModel/Service
[ ] If no test file exists → create one at the standard path
[ ] Comment above test links back to d01-rca.md classification
[ ] No force unwrap in test
```

### File Location

If a test file for the affected ViewModel already exists:
→ Add the regression test to that file

If no test file exists:
→ Create `Tests/<Feature>/<FileName>Tests.swift`
→ Follow same format as Phase 4 unit tests

---

## Output → `output/<feature-slug>/d03-fix-report.md`

```markdown
# Fix Validation Report

## Build Result
Date: <ISO date>
Result: ✅ BUILD SUCCEEDED | 🚫 BUILD FAILED

## Errors (if any)
| File | Error | Cause | Status |
|---|---|---|---|
| LoginViewModel.swift | ... | Introduced by fix | FIXED |

## Regression Test
File: `Tests/Login/LoginViewModelTests.swift`
Test: `loginWithNilAuthServiceHandlesGracefully()`
Status: ✅ ADDED | ⚠️ SKIPPED (reason: <why>)

## Verdict
✅ Fix validated — build passes, regression test written
⚠️ Fix validated — build passes, regression test skipped (<reason>)
🚫 Fix BLOCKED — build fails, see errors above

## PR Notes
<!-- For inclusion in the final PR description -->
**Bug fixed:** <title>
**Root cause:** <one-liner>
**Fix:** <one-liner describing the change>
**Regression test:** `<test name>` in `<file>`
**Workaround:** YES ⚠️ | NO
```

---

## Final Output Layout

```
output/<feature-slug>/
├── d01-rca.md
├── d02-fix/             (Sandbox) or project path (Project Mode)
│   └── <fixed files>
├── d03-fix-report.md
└── d03-regression/
    └── <test file>      (or note: "added to existing Tests/...")

.state/
├── d02-fix-summary.md
├── d02-ripple.md        (if any ripple)
└── brownfield-flags.md  (if workaround)
```

---

## Quality Gates

| Check | Pass Condition |
|---|---|
| Build | ✅ BUILD SUCCEEDED |
| Regression test | Written and traceable to root cause |
| Fix comment | `// BUGFIX:` present in all changed lines |
| Workaround flag | Flagged and noted if applicable |

**If `🚫 BUILD FAILED`:** Fix introduced new issues.
Attempt one auto-fix. If still failing → escalate to user before writing regression test.
