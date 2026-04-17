# Contributing to ios-pilot

This document covers how to evolve the ios-pilot pipeline without breaking existing behavior.

---

## Adding a New Pattern

### 1. Create the pattern file

Place it in `.agent/patterns/<name>.md`. Use this structure:

```markdown
# Pattern: <Name>

<One-line description of what this pattern enforces or generates.>

---

## Architecture (if applicable)

<ASCII diagram showing data flow or component relationships.>

---

## [Main Content Sections]

<Code examples, rules, implementation details.>

---

## Code Gen Rules

When generating any file that uses this pattern:

1. <what to add to task list>
2. <specific constraints>

---

## Self-check (per file)

- [ ] <verifiable condition>
- [ ] <verifiable condition>
```

**Required sections:** at minimum `## Self-check`. Code examples are strongly recommended.
**Optional:** `## Architecture`, `## Spec Parser Integration`, `## Code Gen Rules`.

### 2. Register in CLAUDE.md

Add one row to the `## Patterns Reference` table:

```
| `.agent/patterns/<name>.md` | <When to apply — one line> |
```

Keep the "When" column to ≤ 10 words. Agents read this table to decide which patterns to load.

### 3. Update RULE-INDEX.md

If the pattern introduces a new **hard rule** (a check that must hold in every generated file), add it to `.agent/RULE-INDEX.md` so future editors know which files to update if the rule changes.

---

## Modifying an Existing Rule

When you change a hard rule, find it in `.agent/RULE-INDEX.md` and update **every file listed** for that rule. Never update just one file.

---

## Adding a New Pipeline Phase

1. Create the agent file: `.agent/<pipeline>/<phase-id>-<name>.md`
2. Add the phase to the pipeline flow in `CLAUDE.md`
3. Add the gate condition to `.agent/gates.md`
4. Update `CLAUDE.md` pipeline Gates summary line for that pipeline
5. Update `RULE-INDEX.md` if the phase enforces new rules

---

## Adding a New Pipeline

1. Create a directory: `.agent/<pipeline-name>/`
2. Add agents following the same structure as existing pipelines
3. Add the pipeline to `CLAUDE.md` Pipeline Selection table and Intent Detection table
4. Add all gates to `.agent/gates.md`
5. Update `.agent/patterns/pipeline-detector.md` with signals for the new pipeline

---

## Versioning

Update `VERSION` and `CHANGELOG.md` for every change. Format:

```
## vX.Y.Z — YYYY-MM-DD
### Added / Changed / Fixed
- <one-line description>
```

---

## Format Rules for Pattern Files

- **No "Apply when" preamble** — that information belongs in CLAUDE.md Patterns Reference table
- **No multi-paragraph docstrings** — one short comment line max
- **Self-check must be a checkbox list** — each item must be independently verifiable
- **Code examples must be complete** — no `// ... rest of implementation`
- **Hard rules must be grep-verifiable** — if you add a rule, add its grep command to `.agent/patterns/compliance-checker.md`

---

## Learning Submissions

The `learning-collector` pattern runs automatically after every pipeline and extracts reusable
patterns from build errors, compliance violations, and revision cycles. Users can submit
these as a draft PR to improve ios-pilot itself.

### As a pipeline user

1. After a pipeline completes, read `output/<slug>/.state/learnings.md`
2. Review HIGH and MEDIUM entries — confirm they describe generic patterns, not your project
3. Say "submit learnings" to create a draft PR
4. Share the PR URL with the ios-pilot maintainer

### Privacy requirements (mandatory)

Every learning must pass the privacy filter before submission:
- No Swift class or method names from your project
- No project-specific file paths or directory names
- No string literals from your codebase
- No bundle IDs or feature-specific identifiers

The `submit-learnings` command re-verifies this before pushing. If it flags an entry,
either strip it manually or exclude that learning from the PR.

### As a maintainer reviewing a learning PR

Learning PRs are always draft. Before approving:

1. Confirm every Fix Catalogue addition has a real xcodebuild error pattern (copy-pasteable)
2. Confirm every compliance check addition has a working grep command
3. Confirm no project-specific identifiers slipped through the privacy filter
4. Run any new grep command against `examples/login-feature/` — must not false-positive
5. Check that new Fix Catalogue rows follow the exact column format of existing rows

Merge only after all checklist items pass. Use "Squash and merge" to keep history clean.

### What NOT to submit

- LOW confidence learnings (single-occurrence) — keep them in `.state/learnings.md` locally
- Build failures caused by your project's own non-standard setup
- Learnings that cannot be expressed as a generic, grep-verifiable rule
