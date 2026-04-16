# Pattern: Git Safety

Applied whenever the agent writes directly to a real project (not the output/ staging area).
Never write to a project without this protocol in place.

---

## Pre-write Checklist

Before touching any project file:

```bash
# 1. Confirm git repo exists
git -C <project-path> rev-parse --is-inside-work-tree

# 2. Check for uncommitted changes
git -C <project-path> status --short

# 3. Record current branch
git -C <project-path> branch --show-current
```

If uncommitted changes exist → **STOP. Tell user to commit or stash first.**
Never write over uncommitted work.

---

## Branch Creation

Create a feature branch before any write:

```bash
git -C <project-path> checkout -b agent/<feature-slug>-<timestamp>
# e.g. agent/user-login-20260415
```

All generated files are written to this branch.
User reviews and merges manually — agent never merges to main/develop.

---

## File Conflict Resolution

When a file already exists at the target path:

| Situation | Action |
|---|---|
| File exists, content is empty or stub | Overwrite |
| File exists, has real content, NOT in spec scope | Skip — log as `[INFO] Skipped existing: path/to/File.swift` |
| File exists, spec explicitly says "update this file" | Show diff in plan, confirm before overwrite |
| File exists, same name but different folder | Flag as conflict in plan — do not write |

---

## Post-write Verification

After all files are written:

```bash
# Stage all new/modified files
git -C <project-path> add Features/ Tests/

# Show what changed
git -C <project-path> diff --staged --stat
```

Include this diff summary in the final `05-pr.md`.

---

## Rollback

If Build Validator (Phase 3.5) finds unresolvable blockers:

```bash
# Revert all changes on the agent branch
git -C <project-path> checkout .
git -C <project-path> clean -fd Features/ Tests/
```

Main/develop branch is never touched — rollback is safe.
