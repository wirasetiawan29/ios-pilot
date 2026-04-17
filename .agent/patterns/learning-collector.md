# Pattern: Learning Collector

Haiku agent. Runs after every pipeline completes. Extracts reusable patterns
from build, compliance, test, and review reports. Non-blocking — pipeline is
already complete when this runs.

---

## Model
Haiku — summarization of structured reports into structured output.

---

## When to Run

After the final phase of any pipeline:
- Pipeline A: after Phase 5 (or 5.5 if MR was created)
- Pipeline B: after M5.1
- Pipeline C: after B6
- Pipeline D: after D3

Do NOT run if the pipeline ended with 🚫 (hard fail) in its final phase — there
is nothing useful to learn from an incomplete run.

---

## Input Files (read all that exist — skip missing without error)

```
output/<slug>/06-build-report.md            — Auto-Fix Log + Findings
output/<slug>/compliance-report.md          — violations and fixes applied
output/<slug>/04-test-report.md             — test pass/fail (Pipeline A)
output/<slug>/b04-build-report.md           — build findings (Pipeline C)
output/<slug>/d03-fix-report.md             — fix validation + regression (Pipeline D)
output/<slug>/.state/revision-requests.md  — structural issues found by Phase 4
output/<slug>/05-pr.md                      — review findings (BLOCKERs, WARNINGs)
```

---

## Privacy Filter (MANDATORY — apply before writing any learning)

Strip every extracted text segment through these rules before saving:

| What to strip | Replace with |
|---|---|
| Swift type names (class/struct/enum names) | `<TypeName>` |
| Method names | `<methodName>` |
| Variable and property names | `<varName>` |
| String literals (`"..."` or `"""..."""`) | `<string>` |
| Project-specific file paths | `<ProjectPath>/<FileName>.swift` |
| Feature-specific directory names | `<Feature>` |
| Bundle IDs | `<bundle-id>` |
| Any identifier that only exists in this project | `<identifier>` |

Keep:
- xcodebuild error pattern text (the template, not the project-specific values)
- Compliance rule IDs (C-1 to C-11, N-1 to N-6)
- Fix strategy descriptions (generic: "add import", "move to root view")
- Framework and language names (SwiftUI, Observation, XCTest, async/await)

Privacy verification: after writing each entry, re-read it and confirm no line
contains a recognizable project-specific identifier. If found — re-strip.

---

## Extraction Process

### Step 1 — Read Build Report

From `06-build-report.md` or `b04-build-report.md` → `## Auto-Fix Log`:

For each auto-fix entry:
- Extract: error pattern (sanitized), fix applied
- Check if pattern matches an existing row in `.agent/06-build-validator.md` Fix Catalogue
  - Matches → LOW confidence (already catalogued)
  - No match → HIGH confidence candidate (new pattern)

From `## Findings` → any 🚫 UNRESOLVED errors that required human intervention:
- HIGH confidence if they represent a new pattern not in Fix Catalogue

### Step 2 — Read Compliance Report

From `compliance-report.md` → `## Violations`:

For each violation:
- Extract: which check (C-1 to C-11), root cause
- Same check + same root cause as an existing check description → LOW
- Same check + new root cause → HIGH (extends the check)
- Pattern not covered by any existing check → HIGH (new check candidate)

### Step 3 — Read Revision Requests

From `.state/revision-requests.md`:

For each revision request:
- Extract: structural issue type (generic — not the specific type name)
- Pattern already in `feedback-loop.md` → LOW
- New structural pattern → MEDIUM (seen once in this pipeline)
- Same pattern corroborated by build report → HIGH

### Step 4 — Read PR Findings

From `05-pr.md` → `## Findings` → each `[BLOCKER]`:

- Extract: category + violated rule
- Cross-reference against `.agent/patterns/compliance-checker.md`
- Not covered by any C-check → MEDIUM (candidate for new check)

### Step 5 — Score and Filter

| Confidence | Condition |
|---|---|
| HIGH | New xcodebuild pattern + fix verified in auto-fix log · OR compliance root cause not in existing checks |
| MEDIUM | Seen in 2+ source files · OR triggered both compliance and revision cycle · OR [BLOCKER] not covered by any grep check |
| LOW | Already in Fix Catalogue or existing checks · OR single occurrence, no corroboration |

Only HIGH and MEDIUM are eligible for PR submission.
LOW is written to the file for local reference only.

---

## Output Format → `output/<slug>/.state/learnings.md`

```markdown
# Learnings — <slug> — <YYYY-MM-DD>

Pipeline: <A — Greenfield | B — Migration | C — Brownfield | D — Bugfix>
Privacy filter: applied
Eligible for PR: <N> items (HIGH: X · MEDIUM: Y)

---

## HIGH Confidence Learnings

### L-01 — Build Fix: <generic pattern name>
Source: 06-build-report.md Auto-Fix Log
Confidence: HIGH — new pattern, fix confirmed in auto-fix log
Error pattern: `<sanitized xcodebuild error text>`
Diagnosis: <generic explanation>
Fix: <generic fix strategy>
Target: `.agent/06-build-validator.md` Fix Catalogue — add new row

---

### L-02 — Compliance Gap: <rule description>
Source: compliance-report.md
Confidence: HIGH — root cause not covered by C-1 to C-11
Pattern: <when does this violation occur — generic>
Grep to detect: `grep -rn "<pattern>" Sources/ --include="*.swift"`
Fix: <what resolves it>
Target: `.agent/patterns/compliance-checker.md` — new C-12 check candidate

---

## MEDIUM Confidence Learnings

### L-03 — Revision Pattern: <generic name>
Source: .state/revision-requests.md
Confidence: MEDIUM — seen once, triggered revision cycle
Issue: <generic structural pattern that caused revision>
Suggested addition: <what rule or note would prevent this>
Target: `.agent/patterns/feedback-loop.md` or `.agent/03-code-gen.md`

---

## LOW Confidence (Reference Only — NOT included in PR)

### L-04
Source: 05-pr.md
Confidence: LOW — single occurrence, no corroboration
Note: <observation>

---

## Summary
- Total patterns observed: N
- Eligible for PR: HIGH (X) + MEDIUM (Y) = Z items
- Skipped (LOW or already catalogued): W items
- To submit: say "submit learnings"
```

---

## Non-Blocking Protocol

This pattern runs after the pipeline completes. It:
- NEVER writes to any pipeline output file
- NEVER modifies `.state/*-progress.md`
- NEVER triggers a gate check
- ONLY writes to `.state/learnings.md`

If the learning-collector itself fails (Haiku error, unreadable report):
- Log: `// AGENT-FLAG: learning-collector failed — <reason>`
- Write minimal `learnings.md`: `Status: SKIPPED — <reason>`
- Do not surface this failure unless user says "submit learnings"

---

## Self-check

- [ ] Privacy filter applied to every learning entry
- [ ] No class names, method names, or project paths in any learning
- [ ] Each learning identifies a specific target file in `.agent/`
- [ ] LOW confidence items are in a separate section marked "NOT included in PR"
- [ ] Summary line at bottom shows counts and "To submit: say submit learnings"
- [ ] Output file is valid markdown (no unclosed code fences)
