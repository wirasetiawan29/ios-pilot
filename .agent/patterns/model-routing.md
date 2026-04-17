# Pattern: Model Routing

Cost-optimized model selection per phase and task type.
Every subagent spawn MUST specify a model based on this table.

---

## Model Tiers

| Model | ID | Best For | Cost |
|---|---|---|---|
| Opus | `claude-opus-4-6` | Architecture, complex reasoning, spec gaps, diagnostic | High |
| Sonnet | `claude-sonnet-4-6` | Orchestration, code gen (logic-heavy), review, build errors | Medium |
| Haiku | `claude-haiku-4-5-20251001` | File writing, boilerplate, repetitive structured output | Low |

---

## Routing Table

| Phase | Task | Model | Reason |
|---|---|---|---|
| Complexity Classifier | scoring | Sonnet | Brief interpretation requires reasoning — wrong classification cascades to all downstream routing |
| Phase 0 | Codebase Reader | Sonnet | Read + summarize, moderate reasoning |
| Phase 1 | Spec reasoning (gap analysis, ambiguities) | Opus | Architectural judgment required |
| Phase 1 | Spec file writing (01-spec.md) | Haiku | Structured template output |
| Phase 2 | Task breakdown reasoning (dependency graph) | Opus | Dependency logic, risk assessment |
| Phase 2 | Task list file writing (02-tasks.md) | Haiku | Structured list output |
| Phase 3 | Code Gen — Model, Protocol | Sonnet | Pattern-following, low reasoning |
| Phase 3 | Code Gen — Repository, Service | Sonnet | API contract following |
| Phase 3 | Code Gen — ViewModel | Opus | Business logic, async patterns, @Observable |
| Phase 3 | Code Gen — View | Sonnet | UI patterns, consistent SwiftUI output |
| Phase 3 | Code Gen — Theme.swift | Haiku | Token-to-Swift translation, boilerplate |
| Phase 3.5 | Build Validator (error diagnosis) | Sonnet | Read error + generate targeted fix |
| Phase 4 | Unit Tests (all) | Haiku | Boilerplate-heavy, pattern-following |
| Phase 4.5 | Revision Cycle (diagnosis) | Sonnet | Single-file structural diagnosis — Sonnet capable |
| Phase 4.5 | Revision Cycle (code fix) | Sonnet | Targeted code patch |
| Phase 5 | Review (per file) | Sonnet | Code review, pattern matching |
| Phase 5 | PR description merge | Sonnet | Consolidation writing |
| Pipeline B | Migration Discovery (per file) | Sonnet | UIKit behavior classification requires pattern recognition beyond Haiku |
| Pipeline B | Migration Strategy | Opus | Architectural conversion decisions |
| Pipeline B | Converter (per component) | Sonnet | UIKit → SwiftUI translation |
| Pipeline C | Delta Spec reasoning | Opus | What changes, impact on existing code |
| Pipeline C | Delta Spec file writing | Haiku | Structured output |
| Pipeline C | Impact Analysis | Sonnet | File-level change classification |
| Pipeline C | Code Patch — NEW files | Sonnet | Same as greenfield code gen |
| Pipeline C | Code Patch — MODIFY files | Opus | Surgical edit of existing code (high risk) |
| Pipeline C | Patch Validator | Sonnet | Build error diagnosis |
| Pipeline C | Regression Tests | Haiku | Test boilerplate |

---

## Two-Pass Strategy

For Phase 1 and Phase 2 (and Pipeline C Delta Spec), use two-pass:

```
Pass 1 — Reasoning (Opus):
  Analyze brief/context, identify gaps, draft structure in memory.
  Output: structured notes (not saved to file).

Pass 2 — Writing (Haiku):
  Take structured notes from Pass 1, write the final file.
  Output: saved .md file.
```

This captures Opus reasoning quality while Haiku handles verbose file output.
Net saving: ~60% cost vs using Opus for full output.

---

## How to Specify Model When Spawning Subagents

```
Agent({
  subagent_type: "general-purpose",
  model: "haiku",    // file writing tasks
  model: "opus",     // reasoning/diagnostic tasks
  model: "sonnet",   // orchestration/code gen
  prompt: "..."
})
```

---

## Override Rules

| Situation | Override |
|---|---|
| Subagent produces `[BLOCKER]` → diagnosis needed | Escalate to Opus |
| Retry after soft fail | Keep same model as original (no downgrade) |
| Build Validator auto-fix | Always Sonnet (reads error + generates fix) |
| MODIFY file in Brownfield (high risk) | Always Opus |
| >5 AGENT-FLAG comments in output | Escalate review to Opus |

---

## Anti-Pattern: Do NOT

- Do NOT use Haiku for ViewModel generation — business logic requires reasoning
- Do NOT use Opus for test boilerplate — expensive and unnecessary
- Do NOT use Haiku for build error diagnosis — it will produce incorrect fixes
- Do NOT downgrade model on retry — the problem needs at least the same capability
