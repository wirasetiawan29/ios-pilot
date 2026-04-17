# Phase Gate Validators

Complete gate conditions for all pipelines. Load this file when evaluating a phase transition.
A failed gate **blocks** the pipeline until resolved — never skip a gate.

---

## Pipeline A — Greenfield

| Gate | Condition |
|---|---|
| Pre-Phase 1 | `.state/complexity.md` exists |
| Phase 0→1 | `.state/project-context.md` exists |
| Phase 1→2 | Ambiguities empty · Spec Checksum matches · `## Navigation Contract` present |
| Phase 2→3 | Every task has unique path · all deps exist · View tasks quote Navigation Contract |
| Phase 3→3.5 | All .swift files saved · compliance-checker passes (no Hard Rule violations) · no NavigationStack outside #Preview · no child navigationDestination |
| Phase 3.5→3.6 | Build ✅ or ⚠️ · spec has `## Visual Anchors` (else skip) |
| Phase 3.5→4 | Build ✅ or ⚠️ (no 🚫) |
| Phase 4→4.1 | All test files saved · no PENDING-REVISION |
| Phase 4.1→4.5 | `04-test-report.md` exists · all tests ✅ · `revision-requests.md` exists AND is empty → skip 4.5 · file absent → treat as empty → skip 4.5 |
| Phase 5→PR | AC Coverage Table complete (no empty "Implemented in" or "Tested in" cells) |
| Phase 5→5.5 | User requested · `05-pr.md` exists · working tree clean |
| Phase 5.5 | No CRITICAL in `security-report.md` (if run) |

---

## Pipeline B — Migration

| Gate | Condition |
|---|---|
| M1→M2 | `m01-discovery.md` exists · Discovery Checksum complete · every UIKit component named in change request has a discovery entry · tech debt baseline saved to `.state/m01-debt-baseline.md` |
| M2→M3 | Coexistence plan written · feature flag approach confirmed by user |
| M4→M4.5 | All converted files saved · MIGRATION annotation count matches each file header |
| M4.5→M5 | Build ✅ or ⚠️ (no 🚫) |
| M5.1→merge | All parity tests ✅ · no BLOCKED verdict · all MIGRATION annotations resolved |

---

## Pipeline C — Brownfield

| Gate | Condition |
|---|---|
| B0→B1 | `b00-baseline-tests.md` exists · captured on unmodified branch |
| B1→B2 | Ambiguities empty · Delta Checksum matches |
| B2→B3 | DELETE files confirmed by user · wave order present |
| B3→B4 | Patch log exists for every file in `b02-impact.md` |
| B4→B5 | `b04-build-report.md` ✅ or ⚠️ |
| B5→B6 | All UNCHANGED-TEST files have regression test |

---

## Pipeline E — Micro

| Gate | Condition |
|---|---|
| Pre-T1 | User confirmed "yes" at T0 plan screen |
| T2 | C-1 C-2 C-3 C-4 C-10 pass on changed file |
| Escalation trigger | Change requires >2 files or new ViewModel/Service/Protocol → stop, suggest full pipeline |

No state files. No resumption needed (3 steps, completes in one context window).

---

## Pipeline D — Bugfix

| Gate | Condition |
|---|---|
| D1→D2 | Root cause: specific file + line · confidence HIGH or MEDIUM |
| D2→D3 | `d02-fix-summary.md` exists · `// BUGFIX:` in all changed lines |

---

## State File Recovery Protocol

When `.state/*-progress.md` is **missing** (not just empty):

```
1. Do NOT assume the phase completed — treat as "phase not started"
2. Check for output files from that phase (e.g., 01-spec.md for Phase 1)
   → If output exists: phase likely completed, advance to next phase
   → If output missing: phase did not complete, restart it
3. Log: "// AGENT-FLAG: progress file missing for <phase>, inferred state from output files"
4. Never re-run a phase whose output files already exist and are non-empty
```

When `.state/*-progress.md` appears **corrupted** (truncated, unreadable, or missing required fields):

```
1. Flag: "// AGENT-FLAG: progress file corrupted for <phase>"
2. Fall back to output-file inference (same as missing case above)
3. Surface in Phase 5 review under [WARNING]
```
