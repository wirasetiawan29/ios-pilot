# Pattern: Git Integration (Phase 5.5)

**This step affects shared systems (remote repo, team visibility).**
**Always show confirmation before push or MR creation.**

## Model
Sonnet — orchestration, command construction

---

## When to Run

Run Phase 5.5 when ALL of these are true:
1. User explicitly requests it: "create MR", "open PR", "push and create MR"
2. Phase 5 is complete (`05-pr.md` exists)
3. Project Mode is active (Sandbox has no git remote)

Never run automatically without user request.

---

## Process

### Step 1 — Check Prerequisites

```bash
# Confirm git repo
git rev-parse --git-dir 2>/dev/null || echo "NOT A GIT REPO"

# Check working tree is clean
git status --porcelain

# Get current branch
git branch --show-current

# Check if remote exists
git remote get-url origin 2>/dev/null || echo "NO REMOTE"
```

If working tree is dirty → STOP. Ask user to commit or stash first.
If no remote → STOP. Surface as: "No git remote found. Add a remote first."

### Step 2 — Detect Remote Platform

```bash
REMOTE_URL=$(git remote get-url origin)
echo $REMOTE_URL
```

| URL pattern | Platform | CLI tool needed |
|---|---|---|
| `github.com` | GitHub | `gh` |
| `gitlab.com` or self-hosted GitLab | GitLab | `glab` |
| Other | Unknown | Manual instructions |

Check CLI availability:
```bash
which gh   2>/dev/null && echo "gh available"
which glab 2>/dev/null && echo "glab available"
```

If CLI not found → provide manual instructions (see Fallback section).

### Step 3 — Show Confirmation

Before ANY push or MR creation, display:

```
## Git Integration — Confirmation Required

Action:    Push branch + create MR/PR
Branch:    <current branch>
Remote:    <remote URL>
Target:    main (or develop — see Step 4)
Platform:  GitHub | GitLab

PR Title:  <first line of 05-pr.md>
PR Body:   <preview of 05-pr.md — first 10 lines>

Proceed? (yes / no / change-target-branch)
```

STOP and wait for user response. Do NOT push without explicit "yes".

### Step 4 — Detect Base Branch

```bash
# Check if main or master or develop exists on remote
git ls-remote --heads origin main master develop 2>/dev/null
```

Priority: `main` > `master` > `develop`. Use the first one found.
If none found → ask user: "Which branch should this PR target?"

### Step 5 — Push Branch

```bash
git push -u origin $(git branch --show-current)
```

If push fails due to upstream divergence → STOP.
Show error and ask user to resolve manually. Never force push without explicit instruction.

### Step 6 — Create MR/PR

Read `05-pr.md` for title and body.

**GitHub (gh CLI):**
```bash
gh pr create \
  --title "<first line of 05-pr.md>" \
  --body "$(cat output/<feature-slug>/05-pr.md)" \
  --base main
```

**GitLab (glab CLI):**
```bash
glab mr create \
  --title "<first line of 05-pr.md>" \
  --description "$(cat output/<feature-slug>/05-pr.md)" \
  --target-branch main \
  --remove-source-branch
```

### Step 7 — Report Result

```
## MR/PR Created ✅

URL:    https://github.com/org/repo/pull/123
Title:  <title>
Branch: <feature-branch> → main
```

If visual report exists (`03.6-visual-report.md`) and has warnings:
→ Add a comment to the MR/PR: "⚠️ Visual check advisory: see 03.6-visual-report.md"

---

## Fallback — No CLI Available

If `gh` or `glab` not installed, provide manual instructions:

```
## Manual MR/PR Instructions

gh not found. Create the PR manually:

1. Push branch:
   git push -u origin <branch-name>

2. Open in browser:
   https://github.com/org/repo/compare/<branch-name>

3. PR Title:
   <title from 05-pr.md>

4. PR Body:
   <copy from output/<feature-slug>/05-pr.md>

Install gh CLI: brew install gh
Install glab CLI: brew install glab
```

---

## Hard Rules

- NEVER push without explicit user confirmation
- NEVER force push (`--force`) unless user explicitly requests it
- NEVER push directly to `main` or `master`
- NEVER auto-merge — create the MR/PR only, merging is always human action
- If `05-pr.md` doesn't exist → run Phase 5 first, then return here
