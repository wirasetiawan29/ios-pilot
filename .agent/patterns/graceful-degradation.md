# Pattern: Graceful Degradation

---

## Failure Types

| Type | What happened | Action |
|---|---|---|
| **Soft fail** | Output saved but has `// AGENT-FLAG:` | Continue pipeline, flag surfaces in review |
| **Hard fail** | Subagent produced no output or invalid file | Mark as FAILED in progress, continue others |
| **Blocker** | Critical dependency missing (e.g. no Model file) | Stop dependent tasks only, continue independent ones |

---

## Subagent Result States

When a subagent completes, record in `.state/<phase>-progress.md`:

```markdown
## Completed
- [x] TASK-01 → LoginModels.swift ✅
- [x] TASK-02 → AuthServiceProtocol.swift ✅ (1 flag)

## Failed
- [!] TASK-03 → LoginRepository.swift — reason: AuthServiceProtocol contract unclear

## Blocked
- [-] TASK-05 → LoginViewModel.swift — blocked by: TASK-03 failed

## Pending
- [ ] TASK-06 → LoginView.swift
```

---

## Orchestrator Failure Logic (per wave)

```
After each parallel wave completes:

1. Collect all subagent results
2. For each failed task:
   a. Is it a dependency for another task?
      YES → mark dependent tasks as BLOCKED
      NO  → log failure, continue
3. For each blocked task:
   a. Can it be unblocked? (only if failure was soft)
      YES → attempt retry with failure context added to prompt
      NO  → mark as BLOCKED, skip
4. Continue with all non-blocked tasks
5. At consolidation: include all failures and blocks in Phase 5 review
```

---

## Retry Protocol (soft fails only)

A subagent gets **one retry** with failure context prepended:

```
[RETRY CONTEXT]
Previous attempt failed the self-validation checklist:
- Force unwrap found on line 34
- AC-3 not addressed (no error clearing on re-type)

Fix these issues. Do not change anything else.
[END RETRY CONTEXT]
```

Only one retry. If it fails again → mark as hard fail, move on.

---

## Consolidation — Surfacing Failures

At Phase 5 merge (or M5 merge), the orchestrator must include a failure summary:

```markdown
## Pipeline Failures

| Task | File | Status | Reason |
|---|---|---|---|
| TASK-03 | LoginRepository.swift | HARD FAIL | Contract mismatch |
| TASK-05 | LoginViewModel.swift | BLOCKED | Depends on TASK-03 |
```

If any task is HARD FAIL or BLOCKED → overall PR verdict is `🚫 Blocked`.

---

## What Graceful Degradation Is NOT

- It does not retry indefinitely
- It does not invent missing output
- It does not skip failed tasks silently
- It does not downgrade a BLOCKER to a WARNING to keep the pipeline green
