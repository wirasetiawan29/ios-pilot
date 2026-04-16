# Pattern: Context Management

Shared protocol used by all agents when handling large files.
**Goal**: never lose state when context fills up.

---

## Core Principle

Write to disk = persist state.
Reading from a compact state file << re-reading the original large file.

```
❌ Keep everything in context window
✅ Extract → Compress → Write to disk → Load compressed state
```

---

## File Size Tiers

Before loading any file, estimate size:

| Tier | Lines | Strategy |
|---|---|---|
| Small | < 200 | Load whole file — normal processing |
| Medium | 200–500 | Load whole file, extract key parts to state file before processing |
| Large | 500–1000 | Chunked extraction protocol |
| XL | > 1000 | Chunked extraction + section index first |

> Estimate by reading the first 5 lines and checking if the file has clear section markers.
> If unsure, treat as Large.

---

## Chunked Extraction Protocol (Large / XL files)

Use this when a file is too large to process in one pass.

### Step 1 — Build section index
Read the first 50 lines. Identify major sections (classes, methods, MARK comments).
Write index to state file:

```markdown
<!-- .state/LoginViewController.index.md -->
# Index: LoginViewController.swift (~800 lines)
- L1–30: imports, class declaration, properties
- L31–120: viewDidLoad, setupUI
- L121–200: IBActions (fieldsChanged, loginTapped, togglePassword)
- L201–400: UITableViewDelegate methods
- L401–600: private helpers
- L601–800: extensions
```

### Step 2 — Extract by section
Read one section at a time. For each section:
1. Read the chunk
2. Extract only what matters for your task (behaviors, public APIs, state mutations)
3. Append extracted info to state file
4. Do NOT carry the raw chunk forward

```markdown
<!-- .state/LoginViewController.extracted.md -->
# Extracted: LoginViewController.swift

## Properties (L1–30)
- emailField: UITextField
- passwordField: UITextField
- loginButton: UIButton — starts disabled
- isPasswordVisible: Bool = false

## User Actions (L121–200)
- fieldsChanged() — enables button when both fields non-empty; hides error label
- loginTapped() — calls authService.login(), shows/hides loading, handles error
- togglePasswordVisibility() — toggles isSecureTextEntry

## State Mutations
- loginButton.isEnabled driven by: email.isEmpty && password.isEmpty
- errorLabel.isHidden = true on fieldsChanged
- errorLabel.isHidden = false on login failure
```

### Step 3 — Work from state file only
After extraction is complete, **close the original file**.
All subsequent processing reads only `.state/<name>.extracted.md`.

---

## State File Conventions

```
output/<feature-slug>/
└── .state/
    ├── <FileName>.index.md       ← section index (step 1)
    ├── <FileName>.extracted.md   ← extracted content (step 2)
    └── <phase>-progress.md       ← which tasks are done (for resumption)
```

### Progress tracking file
Write after completing each task or file:

```markdown
<!-- .state/phase3-progress.md -->
# Phase 3 Progress

## Completed
- [x] TASK-01 → Features/Login/LoginModels.swift
- [x] TASK-02 → Features/Login/AuthServiceProtocol.swift

## In Progress
- [ ] TASK-03 → Features/Login/LoginRepository.swift

## Pending
- [ ] TASK-04, TASK-05, TASK-06
```

If context fills mid-phase: load `.state/<phase>-progress.md` to know exactly
where to resume. Do not re-process completed tasks.

---

## Resumption Protocol

If you detect context is near full (responses getting cut off, earlier instructions
becoming unreachable):

1. **Save current state immediately** — write progress to `.state/<phase>-progress.md`
2. **Write a resumption note** at the top of the state file:
   ```
   RESUMPTION POINT: Context was reset after completing TASK-03.
   Next task: TASK-04 → Features/Login/LoginService.swift
   Load: 01-spec.md (relevant ACs only), 02-tasks.md (TASK-04 only), .state/phase3-progress.md
   ```
3. On resume: load state file first, then only the context needed for the next task

---

## What to Extract vs Discard

| Keep | Discard |
|---|---|
| Public API signatures | Private implementation details |
| State-driving properties | UI layout code |
| Method names + behavior summary | Method internals |
| Error cases + edge case handling | Comments and documentation |
| Dependencies and their usage | Import statements |

---

## Large Feature Protocol (> 8 tasks)

When Phase 2 produces more than 8 tasks, activate Large Feature mode:

### Before Phase 3 starts:
1. Group tasks into waves (already done by Phase 2 dependency graph)
2. Write wave manifest to `.state/wave-manifest.md`:

```markdown
# Wave Manifest: <Feature>

## Wave 1 — Foundation (no deps)
- TASK-01: LoginModels.swift
- TASK-02: AuthServiceProtocol.swift

## Wave 2 — Core (depends on wave 1)
- TASK-03: LoginViewModel.swift
- TASK-04: AuthRepository.swift

## Wave 3 — UI (depends on wave 2)
- TASK-05: LoginView.swift
- TASK-06: RootView.swift

## Wave 4 — Tests (depends on wave 3)
- TASK-07: LoginViewModelTests.swift
- TASK-08: AuthRepositoryTests.swift
```

### During Phase 3:
- Load **only the current wave's tasks** into context at a time
- After each wave completes: write wave checkpoint to `.state/phase3-progress.md`
- Drop wave N context before loading wave N+1 — do not accumulate across waves

### Context health check — before each wave:
Before starting a new wave, verify you can still load the spec:
```
✓ I can read output/<feature-slug>/01-spec.md
✓ I can see the relevant ACs for this wave's tasks
✓ .state/wave-manifest.md is loaded
```
If spec is unreachable → save progress state immediately, request context reset.

---

## Token Budget Reference

Rough guidance for how many files fit comfortably in one context pass:

| File type | Avg lines | Files per pass |
|---|---|---|
| Models / Protocols | ~50 | 8–10 |
| ViewModels | ~100 | 4–6 |
| Views | ~150 | 3–4 |
| Repositories | ~120 | 4–5 |
| UIKit ViewControllers | ~400 | 1–2 |
| Test files | ~200 | 3–4 |

**Rule of thumb:** if the total lines of files in the current task exceed 800,
use chunked extraction. Do not try to load all files at once.

---

## Context Pressure Signals

You are approaching context limits when:
- Earlier messages in the conversation become unreachable via scroll
- You can no longer quote exact content from the spec you loaded earlier
- Tool results from more than 3 steps ago are no longer visible
- Your response starts truncating mid-sentence

**On first signal:** save current progress state immediately. Do not wait until
context is full — saving early costs nothing, losing state costs a full re-run.
