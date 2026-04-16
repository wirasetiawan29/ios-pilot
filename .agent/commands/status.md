# Command: status

Triggered when user says: "status", "where am i", "progress", "what's running", "resume"

Show the current pipeline state without executing anything. Read-only.

---

## Process

### Step 1 — Find active state

Scan `output/` for the most recently modified `.state/` directory:

```bash
find output -name "*-progress.md" | sort -t/ -k2 | tail -1
```

If no `.state/` found → show **No active pipeline** message (see below).

### Step 2 — Read state files

From the active `.state/` directory, read:

| File | What to extract |
|---|---|
| `complexity.md` | SIMPLE or COMPLEX |
| `project-context.md` | exists? (yes/no) + age in days |
| `*-progress.md` | last completed phase + last completed step |
| `01-spec.md` | feature name (from `# Spec:` heading) |
| `02-tasks.md` | total tasks, completed tasks (count `[x]` vs `[ ]`) |
| `revision-requests.md` | exists and non-empty? |
| `b02-impact.md` | total files in impact list (Brownfield only) |
| `d01-rca.md` | root cause confidence (Bugfix only) |

### Step 3 — Detect pipeline type

Read `*-progress.md` or infer from files present:
- Has `01-spec.md` + `02-tasks.md` → Pipeline A (Greenfield)
- Has `m01-discovery.md` → Pipeline B (Migration)
- Has `b01-delta-spec.md` → Pipeline C (Brownfield)
- Has `d01-rca.md` → Pipeline D (Bugfix)

### Step 4 — Determine current phase

Find the last phase that has a completed progress entry. Use this table:

**Pipeline A:**
| File exists + complete | Phase |
|---|---|
| `complexity.md` only | Pre-Phase 1 |
| `01-spec.md` | Phase 1 done |
| `02-tasks.md` | Phase 2 done |
| `03-code/` has .swift files | Phase 3 in progress or done |
| `06-build-report.md` | Phase 3.5 done |
| `03.6-visual-report.md` | Phase 3.6 done |
| `04-tests/` has .swift files | Phase 4 in progress or done |
| `05-pr.md` | Phase 5 done |

**Pipeline C (Brownfield):**
| File | Phase |
|---|---|
| `b01-delta-spec.md` | B1 done |
| `b02-impact.md` | B2 done |
| patch log exists | B3 in progress or done |
| `b04-build-report.md` | B4 done |
| regression tests exist | B5 done |

**Pipeline D (Bugfix):**
| File | Phase |
|---|---|
| `d01-rca.md` | D1 done |
| `d02-fix-summary.md` | D2 done |
| `d03-fix-report.md` | D3 done |

### Step 5 — Determine next action

| Current phase | Next action |
|---|---|
| Pre-Phase 1 | Run spec parser — say: `yes` or describe feature |
| Phase 1 done | Run task breakdown — say: `yes` |
| Phase 2 done | Start code gen — say: `yes` |
| Phase 3 done | Run build validator — say: `yes` |
| Phase 3.5 done (✅/⚠️) | Run unit tests — say: `yes` |
| Phase 3.5 done (🚫) | Fix build errors before continuing |
| Phase 4 done | Run review — say: `yes` |
| Phase 5 done | Done — optionally: `create MR` |
| B1 done | Confirm and run impact analysis — say: `yes` |
| B2 done | Confirm DELETE files, then: `yes` |
| B3 done | Run patch validator — say: `yes` |
| B4 done (✅/⚠️) | Run regression tests — say: `yes` |
| D1 done (HIGH/MEDIUM) | Run fix gen — say: `yes` |
| D1 done (LOW confidence) | Waiting for more info from user |
| D2 done | Run fix validator — say: `yes` |
| D3 done | Pipeline complete |

---

## Output Format

### Active pipeline found:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Pipeline Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Feature  : <feature-slug>
Pipeline : <A — Greenfield | B — Migration | C — Brownfield | D — Bugfix>
Mode     : <SIMPLE | COMPLEX>
Phase    : <current phase name> (<done | in_progress>)
Progress : <X/Y tasks> (<Z%>)   ← omit if tasks not yet broken down
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next     : <exact next step description>
Say      : <exact word/phrase user should type>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Example:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Pipeline Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Feature  : login-biometric
Pipeline : A — Greenfield
Mode     : COMPLEX
Phase    : Code Gen — Phase 3 (in_progress)
Progress : 4/9 tasks (44%)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Next     : Wave 2 pending — LoginViewModel waiting for Wave 1 to complete
Say      : yes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### No active pipeline:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Pipeline Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
No active pipeline found.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ready to start. Try:
  • Describe a feature to build (Greenfield)
  • "project: MyApp — <change request>" (Brownfield)
  • Paste a crash log (Bugfix)
  • "migrate: MyApp" (UIKit → SwiftUI)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Multiple features found — show list:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Multiple features found:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. login-biometric  — Phase 3 in_progress  (most recent)
  2. push-permission  — Phase 5 done
  3. order-history    — Phase 1 done
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Showing status for: login-biometric (most recent)
To switch: say "status push-permission"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
