# Pattern: Context Restore

**Runs automatically at the start of every new session** — before the user says anything.

If an in-progress pipeline is found, show a restore banner so the user knows exactly
where they left off without having to remember or re-explain.

---

## When to Run

Run this pattern once at the very start of a new conversation (first message received).
Do NOT run it on subsequent messages in the same session.

Detection: check if `output/` directory exists and contains any `.state/` subdirectory
with at least one progress file.

---

## Process

### Step 1 — Scan for active pipelines

```bash
find output -name "*-progress.md" -o -name "01-spec.md" -o -name "d01-rca.md" \
  | sort -t/ -k2 -r | head -5
```

Count unique feature slugs found.

### Step 2 — Read last progress

For the most recently modified feature slug, read:
- `*-progress.md` → last completed phase + last completed step
- `01-spec.md` or `b01-delta-spec.md` or `d01-rca.md` → feature name
- `02-tasks.md` → count `[x]` (done) and `[ ]` (pending) tasks
- `06-build-report.md` → build status if exists (✅/⚠️/🚫)

### Step 3 — Determine next action

Use the same logic as `status.md` Step 5.

---

## Output: Single in-progress pipeline

Show banner immediately before responding to any user message:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Context Restored — Where You Left Off
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Feature  : <feature-slug>
Pipeline : <A — Greenfield | B — Migration | C — Brownfield | D — Bugfix>
Phase    : <phase name> (<done | in_progress>)
Progress : <X/Y tasks (Z%)>   ← omit if not yet at task breakdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next     : <what needs to happen next, in plain English>
Say      : <exact phrase to continue>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then respond normally to whatever the user said.

**Example:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Context Restored — Where You Left Off
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Feature  : login-biometric
Pipeline : A — Greenfield
Phase    : Code Gen — Phase 3 (in_progress)
Progress : 4/9 tasks (44%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next     : Wave 2 ready — LoginViewModel waiting to be generated
Say      : yes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Output: Multiple in-progress pipelines

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Context Restored — Multiple Features Found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. login-biometric  — Phase 3 in_progress  ← most recent
  2. push-permission  — Phase 1 done
  3. order-history    — Phase 5 done (complete)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Resuming: login-biometric (most recent active)
Next     : Continue code gen Wave 2
Say      : yes — or say "status <other-feature>" to switch
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Output: No active pipeline

Do NOT show any banner. Proceed normally — the user is starting fresh.

---

## Output: All pipelines complete

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Previous Work Found (all complete)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  • login-biometric  — Phase 5 ✅ done
  • push-permission  — Phase 5 ✅ done
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
All done. Ready for a new feature or "create MR" to open a PR.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Rules

- Never re-run completed phases. The restore banner is informational only.
- If the user's first message continues the pipeline (e.g., "yes") — show banner then immediately execute.
- If the user's first message starts something new — show banner, then start the new pipeline (the existing state is preserved in `output/`).
- If the user says "ignore" or "start fresh" — skip the banner for this session only. Do not delete state.

---

## Session Tracking (MANDATORY)

After running this pattern — regardless of whether an active pipeline was found —
write the following file so the Pre-Flight Checklist can verify this step ran:

**`output/.state/session-started.md`**

```markdown
# Session Started

Date: <ISO datetime — e.g. 2026-04-16T11:30:00>
Context restored: yes | no
Active pipeline found: <feature-slug> | none
Banner shown: yes | no
```

This file is checked by Gate 1 in the CLAUDE.md Pre-Flight Checklist.
If this file is missing, the Orchestrator must run context-restore before any other action.
