# Pattern: Complexity Classifier

Run ONCE per pipeline, after the brief is received, BEFORE Phase 1 (Spec Parser).
Result determines: pipeline depth, model routing, parallelism threshold.

---

## When to Run

- Triggered automatically by Orchestrator after brief is received
- Re-run after Phase 1 only if spec reveals significantly more scope than the brief suggested
- Skip if user explicitly states: "simple fix", "one file", "quick change"

---

## Scoring

Use the brief (and `.state/project-context.md` if it exists) to score these dimensions:

### Base Score

| Dimension | Score | Criteria |
|---|---|---|
| Files affected | 0–30 | <3 files = 10 · 3–5 files = 20 · >5 files = 30 |
| Lines of code | 0–30 | <150 LOC = 10 · 150–400 LOC = 20 · >400 LOC = 30 |
| New layers introduced | 0–25 | none = 0 · 1 new layer = 10 · 2+ new layers = 25 |
| Spec clarity | 0–15 | clear requirements = 0 · some gaps = 5 · vague/high-level = 15 |

### Adjustments (add to base)

| Condition | Points |
|---|---|
| New external dependency (new Package/Pod) | +10 |
| New network endpoint (not existing service) | +5 per endpoint |
| New navigation destination | +5 |
| Modifies existing public protocol or API contract | +10 |
| Requires new data persistence layer | +10 |
| Cross-feature impact (touches >1 existing feature) | +10 |

**Borderline (38–42): default to COMPLEX.** When in doubt, run the full pipeline.

---

## Result Thresholds

| Score | Classification | Description |
|---|---|---|
| < 40 | **SIMPLE** | Small, self-contained change — shortcuts allowed |
| ≥ 40 | **COMPLEX** | Multi-layer feature — full pipeline required |

---

## SIMPLE Pipeline Shortcuts

When SIMPLE, apply these shortcuts (all others run normally):

```
Phase 0  — skip if greenfield, run if project mode (always needed)
Phase 1  — Spec Parser uses Sonnet for both reasoning AND writing (no two-pass)
Phase 2  — Task Breakdown: skip dependency graph visualization, just list tasks
Phase 3  — run tasks sequentially if ≤3 tasks, parallel waves only if >3 tasks
Phase 5  — Review: single-pass consolidation (no per-file subagents if ≤3 files)
```

**Phases 3.5, 4, 4.5 are never skipped** — build validation and tests always run.

---

## COMPLEX Pipeline — Full Run

When COMPLEX, all phases run with no shortcuts:

- Phase 1: two-pass (Opus reasoning → Haiku writing)
- Phase 2: full dependency graph required before proceeding
- Phase 3: wave-based parallel execution (spawn per dependency wave)
- Phase 5: one review subagent per file, then sequential merge

---

## Output → `.state/complexity.md`

Write this file immediately after scoring:

```markdown
# Complexity Classification

Date: <ISO date>
Score: <total> / 100
Result: SIMPLE | COMPLEX

## Score Breakdown
| Dimension | Score | Notes |
|---|---|---|
| Files affected | XX | <brief reason> |
| Lines of code | XX | <estimate> |
| New layers | XX | <which layers> |
| Spec clarity | XX | <observation> |
| Adjustments | +XX | <list conditions that triggered> |

## Pipeline Behavior
<If SIMPLE: list which shortcuts apply>
<If COMPLEX: "Full pipeline — no shortcuts">

## Model Routing
Phase 1 reasoning: <Opus | Sonnet>
Phase 2 reasoning: <Opus | Sonnet>
```

---

## Integration with Orchestrator

After writing `.state/complexity.md`, the Orchestrator:

1. Reads `Result: SIMPLE | COMPLEX`
2. Applies shortcuts (if SIMPLE) or confirms full pipeline (if COMPLEX)
3. References complexity result in the plan report shown to user:

```markdown
## Plan Report
Feature: <name>
Complexity: SIMPLE (score: 28) — 3 files, no new layers
Pipeline: Phases 1–5 with shortcuts (no parallel waves, Sonnet for spec)
Estimated output: 3 Swift files + 1 test file
```

---

## Examples

### Example A — SIMPLE
Brief: "Add a loading spinner to the existing LoginView while the login API call is in progress"
- Files: 1 (LoginView.swift, already exists) → 10
- LOC: ~20 lines → 10
- New layers: none → 0
- Clarity: very clear → 0
- Adjustments: none
**Score: 20 → SIMPLE**

### Example B — COMPLEX
Brief: "Build a product listing screen with search, filter, pagination, and add-to-cart"
- Files: 6+ (Model, Protocol, Repository, Service, ViewModel, View) → 30
- LOC: 400+ → 30
- New layers: Repository + Service → 25
- Clarity: some gaps (filter criteria not specified) → 5
- Adjustments: 2 new endpoints (+10), new navigation destination (+5)
**Score: 105 → COMPLEX** (capped at 100 for display, still COMPLEX)
