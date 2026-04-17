# Command: submit-learnings

Triggered when user says: "submit learnings" / "send learnings" / "push learnings"

Reads `output/<slug>/.state/learnings.md`, re-verifies privacy, creates a branch
on the ios-pilot repo, patches `.agent/` files, and opens a draft PR.

---

## Model
Sonnet — git operations, file patching, confirmation management.

---

## Prerequisites

Verify all before any action:

1. `learnings.md` exists (see Step 1)
2. `gh` CLI available: `which gh`
3. Running from ios-pilot repo root (not inside a project directory)
4. Working tree is clean: `git status --porcelain`

If any prerequisite fails → stop and report clearly. Do not proceed.

---

## Process

### Step 1 — Find Learnings File

```bash
find output -name "learnings.md" -path "*/.state/*" | sort -t/ -k2 -r
```

- One result → use it
- Multiple results → list them, ask user which slug to submit
- None → report: "No learnings.md found. Run a pipeline first."

Read the file. Check `Eligible for PR:` line.
If 0 items → report: "No HIGH or MEDIUM confidence learnings to submit. LOW items are reference only."

### Step 2 — Re-verify Privacy Filter

Re-read every HIGH and MEDIUM learning entry. Flag if any line:
- Contains a capitalized multi-word identifier that looks like a Swift type name
- Contains a method signature with real argument labels
- Contains a file path with a non-generic directory name
- Contains text in double-quotes that looks like a user-facing string literal

If flagged → strip automatically and note the change.
If unsure → ask user: "This entry may contain a project-specific identifier: `<text>`. Remove it?"

Do NOT proceed to git operations until privacy check passes.

### Step 3 — Show Confirmation

Display before any git action and wait for explicit "yes":

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Learning Submission — Confirmation Required
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Source:  output/<slug>/.state/learnings.md
Pipeline: <A/B/C/D>   Date: <YYYY-MM-DD>
Branch:  learning/<slug>-<YYYY-MM-DD>

Changes to be applied:
  <one line per learning: target file + change type>

Privacy:  verified ✅
Items:    HIGH (X) · MEDIUM (Y)

Proceed? (yes / no)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

STOP. Wait for user "yes". Do NOT create branch without explicit confirmation.

### Step 4 — Create Branch

```bash
git checkout -b learning/<slug>-<YYYY-MM-DD>
```

If branch exists:
```bash
git checkout learning/<slug>-<YYYY-MM-DD>
```
Check if it has commits — if yes, ask user: "Branch already exists with commits. Overwrite or use a new name?"

### Step 5 — Apply Patches

For each HIGH/MEDIUM learning, edit its target file:

#### Fix Catalogue Addition → `.agent/06-build-validator.md`

Find the `#### Fix Catalogue` table. Add a new row:

```
| `<sanitized error pattern>` | <diagnosis> | <fix strategy> |
```

Before inserting: `grep -n "<error pattern>" .agent/06-build-validator.md`
If match found → skip (already catalogued). Do not duplicate.

#### Compliance Check Addition → `.agent/patterns/compliance-checker.md`

Find the last `### C-N` section. Append:

```markdown
### C-<N+1> — <rule description>
```bash
grep -rn "<pattern>" Sources/ --include="*.swift"
```
**Expected:** no output.
**Fix:** <fix strategy>
```

Then add the check to the summary/output template if present.

#### Feedback / Code-Gen Addition → target varies

- MEDIUM revision-pattern → `feedback-loop.md` table or `03-code-gen.md` Hard Prohibitions
- Add minimally — one row or one bullet. No structural changes.

### Step 6 — Commit

Stage only the patched `.agent/` files:

```bash
git add .agent/06-build-validator.md
git add .agent/patterns/compliance-checker.md
# ... any other patched files
git commit -m "learning(<slug>): <one-line summary of highest-confidence learning>"
```

Commit message format: `learning(<slug>): <summary>`

### Step 7 — Push

```bash
git push -u origin learning/<slug>-<YYYY-MM-DD>
```

If push fails → report error. Never force push.

### Step 8 — Create Draft PR

```bash
gh pr create \
  --draft \
  --title "learning: <slug> — <one-line summary>" \
  --body "$(cat <<'EOF'
## Learning Submission — <slug> — <YYYY-MM-DD>

Pipeline: <A — Greenfield | B — Migration | C — Brownfield | D — Bugfix>

## Changes

<one subsection per learning applied:>

### <target file> — <change type>
- Pattern: `<sanitized pattern>`
- Diagnosis: <generic explanation>
- Fix: <fix strategy>

## Source

- Pipeline run: `output/<slug>/`
- Reports analysed: <list of input files that had learnings>
- Privacy filter: applied — no class/method names, no project paths, no string literals

## Confidence

- HIGH: <X> items
- MEDIUM: <Y> items
- LOW: omitted — available in `output/<slug>/.state/learnings.md` for local reference

## Reviewer Checklist

- [ ] Error patterns are generic and reusable across projects
- [ ] Fix Catalogue entries follow existing table format exactly
- [ ] New compliance checks include a working grep command
- [ ] Changes do not duplicate existing catalogue entries
- [ ] Privacy filter confirmed: no project-specific identifiers

🤖 Generated by ios-pilot learning-collector. Maintainer review required before merge.
EOF
)" \
  --base main
```

### Step 9 — Report to User

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Learning PR Created ✅
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PR:     <URL from gh output>
Branch: learning/<slug>-<YYYY-MM-DD>
Status: Draft — maintainer review required before merge
Items:  HIGH (X) · MEDIUM (Y)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LOW confidence learnings were not included.
See output/<slug>/.state/learnings.md for local reference.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Hard Rules

- NEVER push without explicit user "yes" at Step 3
- NEVER push to `main` directly
- ALWAYS use `--draft` flag — never a ready-for-review PR
- NEVER include LOW confidence learnings in the PR
- NEVER skip the privacy re-verification (Step 2)
- NEVER create a PR if privacy check found unresolvable project-specific identifiers
- If `gh` not installed → report: "Install with: brew install gh" and stop
