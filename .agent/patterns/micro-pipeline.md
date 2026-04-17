# Pipeline E — Micro

Single-file surgical edits. No spec, no task breakdown, no wave planning, no test generation.
Activates when a TRIVIAL request is detected before the complexity scorer runs.

---

## TRIVIAL Detection (Pre-Classification)

Run this check BEFORE the complexity scorer. If ALL five signals are true → TRIVIAL.
Skip to Pipeline E immediately. Do NOT run the complexity scorer.

| Signal | True when |
|---|---|
| Single UI element | Request names one element: button, label, text, color, icon, image, spacing, padding, font |
| Existing screen | Element belongs to an existing View — not a new screen or flow |
| No data layer | No mention of API, network, data persistence, Keychain, or UserDefaults |
| No logic change | No mention of ViewModel logic, Service, Repository, Protocol, or business rule |
| Action keyword | Request contains: add/tambah · change/ganti/ubah · remove/hapus · move/pindah · rename + one element |

If ANY signal is false → run complexity scorer normally (SIMPLE / COMPLEX path).

---

## Model
Haiku — all three steps. No reasoning phase needed.

---

## Flow

```
[T0] Plan Confirm   PLAN MODE   — one-line plan · wait for "yes"
[T1] Surgical Edit  SEQUENTIAL  — read file · make minimal change
[T2] Quick Check    SEQUENTIAL  — 5 compliance checks on changed file only
```

---

## T0 — Plan Confirm

Show this before any file edit:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Micro Edit — Plan
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Mode:   Pipeline E (TRIVIAL)
File:   <file path>
Change: <one sentence description of the edit>
        e.g. "Add AppButton("Submit") below the email field in LoginView"

⚠️  No tests generated. No full build run.
    Say "run pipeline" instead to get full test coverage.

Proceed? (yes / no)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

STOP. Wait for "yes". Never edit without confirmation.

---

## T1 — Surgical Edit

1. Read the target file fully
2. Locate the exact insertion point (the nearest relevant MARK section or element)
3. Make the minimal change:
   - Add elements using component library (`AppButton`, `AppTextField`, etc. — not raw SwiftUI primitives)
   - Use existing Theme tokens for colors, fonts, spacing — never hardcode
   - Match surrounding code style (indentation, naming, MARK structure)
4. Do NOT:
   - Add new imports (unless strictly required by the change)
   - Refactor existing code
   - Add or modify `#Preview` content beyond what the change requires
   - Touch any file other than the target

---

## T2 — Quick Check

Run only the 5 checks relevant to UI edits on the changed file:

```bash
grep -n "print(" <file>                                            # C-1
grep -n "[a-zA-Z0-9_)]!" <file> | grep -v "!=" | grep -v "^.*//"; # C-2
grep -n "Color(red:" <file>                                        # C-3
grep -n "\.system(size:" <file>                                    # C-4
grep -n "#Preview" <file>                                          # C-10 (must exist)
```

All must pass. If any fail → fix inline, no revision cycle needed.

---

## Completion Message

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Done ✅ (Pipeline E — Micro)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File:    <file path>
Change:  <what was done>
Checks:  C-1 C-2 C-3 C-4 C-10 ✅

No tests generated — this was a micro edit.
For full test coverage, run: "plan: <your feature>"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## What Pipeline E Does NOT Do

| Skipped | Why |
|---|---|
| Spec Parser | No ambiguities to resolve for a single element |
| Task Breakdown | One file, one change — no graph needed |
| Full compliance check | 6 out of 11 checks irrelevant for pure UI edit |
| Build Validator | No new Swift files compiled |
| Unit Tests | No logic change; existing tests still cover the ViewModel |
| PR Review | Change too small to warrant full review |
| Learning Collector | No new patterns to extract from a trivial edit |

User is explicitly informed of this at T0 and completion.

---

## Escalation

If during T1 the agent discovers the change requires any of:
- A new ViewModel property or method
- A new navigation destination
- A new API call
- Touching more than 2 files

→ STOP. Report:

```
This edit requires more than a micro change.
Suggested: "plan: <describe what you want>" for full pipeline.
```

Do NOT proceed silently with a larger change.

---

## Self-check

- [ ] TRIVIAL detection: all 5 signals confirmed true before entering Pipeline E
- [ ] T0 confirmation received before any file edit
- [ ] Only target file modified — no other files touched
- [ ] Component library used — no raw SwiftUI primitives
- [ ] Theme tokens used — no hardcoded colors, fonts, or spacing
- [ ] T2 quick check passes (5 checks)
- [ ] Completion message states "No tests generated"
