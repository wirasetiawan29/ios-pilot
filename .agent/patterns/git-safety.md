# Pattern: Git Safety

Never write to a project without this protocol in place.

---

## Repo Identity Validation (MANDATORY — run before anything else)

**Risk:** The agent's CWD may differ from the user's target project. Running `git` without
`-C <project-path>` operates on the wrong repo (e.g., ios-pilot instead of the SDK).
This check must run before every git operation in Project Mode.

```bash
# 1. Resolve the project's root
PROJECT_ROOT=$(git -C <project-path> rev-parse --show-toplevel 2>/dev/null)

# 2. Resolve the agent's CWD root
AGENT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

# 3. Confirm they differ (Project Mode means writing to a DIFFERENT repo)
echo "Agent repo : $AGENT_ROOT"
echo "Target repo: $PROJECT_ROOT"
```

If `PROJECT_ROOT` is empty → the path is not a git repo. **STOP. Tell user.**

If `PROJECT_ROOT == AGENT_ROOT` and the user gave a project path → **STOP. Warn that the
target path resolves to the same repo as the agent. Confirm with user before continuing.**

Always use `git -C "$PROJECT_ROOT" <command>` — never bare `git <command>` — for all
subsequent operations in this pattern.

---

## Build Tool Detection

Before any test or build command, detect the project type:

```bash
# Check 1: Is there a Package.swift?
if [ -f "<project-path>/Package.swift" ]; then
  # Check 2: Does it target iOS? (not macOS-only)
  if grep -q '\.iOS' "<project-path>/Package.swift"; then
    BUILD_TOOL="xcodebuild"
    echo "📦 iOS Swift Package detected → must use xcodebuild (NOT swift test)"
  else
    BUILD_TOOL="swift_build"
    echo "📦 macOS/cross-platform Swift Package detected → swift build/test OK"
  fi
elif [ -f "<project-path>/project.yml" ]; then
  BUILD_TOOL="xcodegen_then_xcodebuild"
  echo "📱 XcodeGen project → run xcodegen generate first, then xcodebuild"
elif ls "<project-path>"/*.xcodeproj 1>/dev/null 2>&1; then
  BUILD_TOOL="xcodebuild"
  echo "📱 Xcode project → xcodebuild"
fi
```

**iOS Swift Packages MUST use `xcodebuild`**, not `swift test`. Reason: iOS-only dependencies
(e.g., Kingfisher) declare `.iOS` platform requirements that `swift test` (which runs on macOS)
cannot satisfy — resulting in a platform mismatch error that has nothing to do with the code.

Correct command for iOS SPM testing:
```bash
xcodebuild test \
  -scheme <SchemeName> \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:<TestTarget>/<TestClass> \
  2>&1 | grep -E "error:|warning:|Test.*passed|Test.*failed|Build succeeded|Build FAILED"
```

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
