# Command: help

Triggered when user says: "help", "what can you do", "how do i", "commands", "?"

Context-aware help — shows different content depending on current pipeline state.
Read-only. Never executes anything.

---

## Process

### Step 1 — Detect context

Check for active pipeline state (same as `status.md` Step 1–4).

| Context | Show |
|---|---|
| No active pipeline | Quickstart guide |
| Pipeline active, phase in_progress | Current phase guide |
| Pipeline active, phase done, waiting | Next step prompt |
| Build failed (🚫 in build report) | Recovery guide |
| Low confidence RCA (Pipeline D) | Investigation guide |

---

## Output: No active pipeline

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛠  ios-pilot — Quick Start
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BUILD A NEW FEATURE (Greenfield)
  Just describe what you want:
  "build a login screen with email, password, and biometric fallback"

ADD TO EXISTING PROJECT (Brownfield)
  "project: MyApp — add push notification permission flow"

FIX A BUG (Bugfix)
  Paste a crash log or describe the bug:
  "crash: EXC_BAD_ACCESS in LoginViewModel line 47"

MIGRATE UIKIT → SWIFTUI
  "migrate: MyApp"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STANDALONE COMMANDS
  "status"          — where am I in the pipeline
  "security review" — 10-point iOS security scan
  "tech debt"       — Swift debt report
  "create MR"       — push + open GitHub/GitLab MR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Output: Active pipeline — Greenfield (Pipeline A)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛠  Help — <feature-slug> (Greenfield)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
You are at: <current phase>

WHAT HAPPENS NEXT
  <one paragraph explaining the current or next phase in plain terms>

YOUR OPTIONS RIGHT NOW
  "yes"              — continue to next phase
  "status"           — see full progress breakdown
  "security review"  — run security scan (can do anytime after Phase 3)
  "tech debt"        — run debt scan (can do anytime)
  "create MR"        — only available after Phase 5

PIPELINE OVERVIEW
  Phase 0  Codebase Reader    <✅ done | ⏭ skipped | ⏳ pending>
  Phase 1  Spec Parser        <✅ done | 🔄 active | ⏳ pending>
  Phase 2  Task Breakdown     <✅ done | 🔄 active | ⏳ pending>
  Phase 3  Code Gen           <✅ done | 🔄 active | ⏳ pending>
  Phase 3.5 Build Validator   <✅ done | 🔄 active | ⏳ pending>
  Phase 4  Unit Tests         <✅ done | 🔄 active | ⏳ pending>
  Phase 5  Review             <✅ done | 🔄 active | ⏳ pending>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Output: Active pipeline — Brownfield (Pipeline C)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛠  Help — <feature-slug> (Brownfield)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
You are at: <current phase>

WHAT HAPPENS NEXT
  <plain-english explanation of next phase>

  ⚠️  If B2 impact has DELETE files — you must confirm each before B3 runs.

YOUR OPTIONS RIGHT NOW
  "yes"    — continue
  "status" — full progress breakdown

PIPELINE OVERVIEW
  Phase 0  Codebase Reader    <✅ | ⏳>
  B1       Delta Spec         <✅ | 🔄 | ⏳>
  B2       Impact Analysis    <✅ | 🔄 | ⏳>
  B3       Code Patch         <✅ | 🔄 | ⏳>
  B4       Patch Validator    <✅ | 🔄 | ⏳>
  B5       Regression Tests   <✅ | 🔄 | ⏳>
  B6       Review             <✅ | 🔄 | ⏳>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Output: Active pipeline — Bugfix (Pipeline D)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛠  Help — <bug-slug> (Bugfix)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
You are at: <current phase>

WHAT HAPPENS NEXT
  <plain-english explanation>

  💡 Bugfix pipeline is surgical — only the files in d01-rca.md will be touched.
     All changes are tagged // BUGFIX: for easy review.

YOUR OPTIONS RIGHT NOW
  "yes"    — continue
  "status" — see RCA confidence + fix scope

PIPELINE OVERVIEW
  Phase 0  Codebase Reader    <✅ | ⏳>
  D1       Root Cause (RCA)   <✅ HIGH | ✅ MEDIUM | ⚠️ LOW | 🔄 | ⏳>
  D2       Fix Gen            <✅ | 🔄 | ⏳>
  D3       Fix Validator      <✅ | 🔄 | ⏳>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Output: Build failed (🚫)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛠  Help — Build Failure Recovery
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The build failed (🚫). Phase 4 is blocked until errors are fixed.

WHAT TO DO
  1. Read the errors in: output/<slug>/06-build-report.md
  2. Say: "fix build errors" — the agent will attempt a targeted patch
  3. Or paste the error here and describe what you think is wrong

THINGS THAT OFTEN CAUSE BUILD FAILURES
  • Missing type import (add to project.yml dependencies)
  • NavigationStack in a child view (violates Rule N-1)
  • @Observable missing on a model used with @Bindable
  • Module not found — project.yml target missing source file

The build validator runs one auto-fix retry automatically.
If it still fails after retry, manual guidance is needed.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
