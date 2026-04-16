# Pattern: Pipeline Detector

**Runs automatically** when the Orchestrator receives any new user input that is not
a known command ("status", "help", "security review", "tech debt", "create MR", "yes", "no").

Determines which pipeline to run — or asks one clarifying question if ambiguous.

---

## Signal Table

Score each signal present in the user's message. Pick the pipeline with the highest score.
If top two pipelines are within 1 point of each other → ambiguous, ask one question (see below).

### Greenfield signals (+1 each)
- "build", "create", "new", "add", "implement", "generate"
- "feature", "screen", "flow", "page", "view"
- No existing project path mentioned
- No crash log or stack trace present
- No mention of "existing", "current", "broken", "migrate"

### Migration signals (+2 each — strong signal)
- "migrate", "migration", "convert", "UIKit", "Storyboard", "XIB"
- "UIViewController", "UITableView", "UICollectionView"
- Words like "old code", "rewrite", "modernize" + iOS context

### Brownfield signals (+1 each)
- `project: <path>` present in input
- "existing project", "our app", "current implementation"
- "change", "update", "modify", "refactor", "extend", "add to"
- "the feature already", "we have", "currently works"
- Project file path or module name mentioned

### Bugfix signals (+2 each — strong signal)
- Crash log present (EXC_, SIGABRT, fatal error, Thread 1, etc.)
- Stack trace lines (file.swift:123)
- "crash", "bug", "fix", "broken", "error", "exception", "nil", "freeze"
- "regression", "stopped working", "used to work"
- ClickUp/Jira ticket number with bug/crash keywords

---

## Decision

```
Greenfield ≥ 2 AND highest score  →  Pipeline A
Migration  ≥ 2 AND highest score  →  Pipeline B
Brownfield ≥ 2 AND highest score  →  Pipeline C
Bugfix     ≥ 2 AND highest score  →  Pipeline D
All scores 0–1                    →  Ambiguous → ask
Top 2 pipelines within 1 point   →  Ambiguous → ask
```

---

## Ambiguous — Ask One Question

When ambiguous, show ONE targeted question. Do not ask multiple questions at once.
Do not explain the scoring. Keep it brief.

**Template:**

```
I want to make sure I use the right approach.

Is this:
  A — A brand new feature (no existing code for this yet)
  B — A change to an existing feature in your project
  C — A bug or crash to fix

Reply A, B, or C.
```

**Or if the ambiguity is specifically about project path:**

```
Are you working on an existing Xcode project?
If yes, share the path: "project: ~/path/MyApp"
If no, I'll generate output to output/<feature-slug>/ instead.
```

---

## After Detection

Once pipeline is determined, log the detection in `.state/pipeline-detected.md`:

```markdown
# Pipeline Detection

Input excerpt: <first 100 chars of user input>
Signals matched: <list>
Pipeline selected: <A | B | C | D>
Confidence: <HIGH | MEDIUM | AMBIGUOUS>
Detection method: <auto | user-confirmed>
```

Then immediately proceed to:
1. Complexity classifier
2. Show plan (Plan Mode — always first)
3. Wait for user approval

---

## Examples

| Input | Signals | Pipeline |
|---|---|---|
| "build a login screen with biometrics" | create, screen, new, no project path | A — Greenfield |
| "project: MyApp — add push notification" | project: path, add, existing | C — Brownfield |
| "EXC_BAD_ACCESS LoginViewModel.swift:47" | crash log, stack trace | D — Bugfix |
| "migrate our LoginViewController to SwiftUI" | migrate, UIViewController | B — Migration |
| "fix the login crash" | fix, crash | D — Bugfix |
| "update the login flow" | update, existing | C — Brownfield (ask for project path) |
| "add a settings screen" | add, screen | A — Greenfield (no project path → Sandbox) |
