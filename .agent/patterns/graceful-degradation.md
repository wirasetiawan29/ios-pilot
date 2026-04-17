# Pattern: Graceful Degradation

## Triggers
Load this pattern when:
- A parallel subagent produces no output or an error
- `pilot build` or `pilot test` returns `FAIL` mid-pipeline
- A task has a dependency that failed in a previous wave
- Keywords: `subagent failed`, `no output`, `blocked`, `AGENT-FLAG`, `retry`, `wave failed`
- Phases: Phase 3 Code Gen (wave failures), Phase 3.5 Build Validator, Phase 4.1 Test Run

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

## // AGENT-FLAG: Usage

When a subagent cannot fully complete a task but produces partial output, it MUST
annotate the problem inline rather than silently omitting it:

```swift
// AGENT-FLAG: AuthRepository — could not determine correct timeout value from spec.
// Defaulted to 30s. Verify against actual API SLA before shipping.
let timeout: TimeInterval = 30
```

**Rules for `// AGENT-FLAG:`:**
- One flag per distinct issue — do not stack multiple problems in one comment
- Include: what is unknown, what was assumed, what to verify
- Flags surface automatically in Phase 5 Review — reviewer must resolve or escalate each one
- A file with `// AGENT-FLAG:` is a **soft fail**, not a hard fail — pipeline continues

---

## `pilot build` / `pilot test` Failure During Pipeline

When `pilot build` returns `## PILOT_BUILD_RESULT: FAIL_COMPILE`:
1. Read the error from `.state/build-log.txt`
2. Identify which generated file caused the error
3. If fixable (type error, missing import, wrong API): fix inline, re-run `pilot build`
4. If not fixable (missing dependency, contract mismatch): mark the file as hard fail, write to `.state/<phase>-progress.md`, proceed to Phase 5 with blocker noted
5. Do NOT re-run the full Code Gen phase — only fix the specific file

When `pilot test` returns `## PILOT_TEST_RESULT: FAIL`:
1. Read failures from `.state/test-log.txt`
2. Check if failure is in the ViewModel or in a Mock
3. If ViewModel logic is wrong: fix ViewModel, re-run `pilot test`
4. If Mock is wrong: fix Mock, re-run `pilot test`
5. If test expectation is wrong (spec ambiguity): flag in `revision-requests.md`, proceed

---

## What Graceful Degradation Is NOT

- It does not retry indefinitely
- It does not invent missing output
- It does not skip failed tasks silently
- It does not downgrade a BLOCKER to a WARNING to keep the pipeline green
