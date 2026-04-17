# Pattern: Feedback Loop (Phase 4 → Phase 3)

Maximum one revision cycle. If the revised code still has testability issues,
surface as `[WARNING]` in Phase 5 review — do not loop indefinitely.

---

## When Phase 4 Triggers a Revision

Phase 4 should request a revision when it finds the ViewModel is **structurally untestable**:

| Issue | Example | Why it blocks testing |
|---|---|---|
| Dependency not injectable | `let service = AuthService()` hardcoded in init | Cannot mock |
| Side effects in init | `init() { Task { await self.load() } }` | Test triggers real async work immediately |
| Singleton access inside method | `UserSession.shared.save(user)` directly | Cannot verify in isolation |
| Static method calls | `Analytics.track("login")` | Cannot intercept |

Do NOT request revision for:
- Logic bugs (test them anyway, mark as failing)
- Missing edge case handling (report in Phase 5)
- Style issues (report as WARNING in Phase 5)

---

## Revision Request Protocol

### Step 1 — Phase 4 writes revision request

When a testability issue is found, before generating the test file,
write to `.state/revision-requests.md`:

```markdown
# Revision Requests

## REV-01
- **File**: `Features/Login/LoginViewModel.swift`
- **Issue**: `UserSession.shared` accessed directly — cannot mock in tests
- **Required change**: inject `UserSession` via init as `UserSessionProtocol`
- **AC affected**: AC-4
- **Requested by**: Phase 4 (Unit Test Agent)
```

Continue generating test files for all other ViewModels that don't have issues.
Mark the problematic ViewModel's test task as PENDING-REVISION.

### Step 2 — Orchestrator checks after Phase 4

After all Phase 4 subagents complete:
1. Check if `.state/revision-requests.md` exists and has unresolved items
2. If yes → enter revision cycle (one time only)
3. If no → proceed to Phase 5 normally

### Step 3 — Targeted Phase 3 revision

For each revision request:
1. Load the specific file from `03-code/`
2. Load the revision request (what to change and why)
3. Load the relevant AC from spec
4. Make only the requested structural change — nothing else
5. Re-run self-validation on the changed file
6. Re-run Build Validator (Phase 3.5) on changed files only:
   ```bash
   swiftc -typecheck [changed files] [existing unchanged files]
   ```
7. Mark revision as RESOLVED in `.state/revision-requests.md`

### Step 4 — Phase 4 retry for revised files only

Re-run Phase 4 only for the ViewModels that were revised.
All other test files are already written — do not re-generate them.

### Step 5 — Mark revision cycle complete

Update `.state/revision-requests.md`:
```markdown
## Revision Cycle
Status: COMPLETE (1/1 max cycles used)
Resolved: REV-01
```

---

## Revision Cycle Limits

**Maximum: 1 cycle.**

If after revision the ViewModel is still untestable:
- Write the test file with a clear failure comment:
  ```swift
  // REVISION-FAILED: UserSession still not injectable after revision cycle.
  // Manual intervention required before this test can be written.
  @Test("placeholder — requires manual fix")
  func test_placeholder() {
      // See .state/revision-requests.md REV-01
      Issue.record("ViewModel not testable — see revision request REV-01")
  }
  ```
- Surface in Phase 5 as `[BLOCKER]`

---

## What Revision Does NOT Do

- Does not re-run Phase 1 or Phase 2
- Does not change the spec or task list
- Does not regenerate files that were not revision targets
- Does not add new features (structural change only)
- Does not run more than once
