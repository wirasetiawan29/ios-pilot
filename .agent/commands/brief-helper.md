# Command: brief-helper

Triggered when user says: "brief helper", "help me write a brief", "buat brief", "new brief", "start brief", "brief?"

Guides the user through 5–8 questions to produce a complete, pipeline-ready feature brief.
Interactive — waits for each answer before proceeding.

---

## When to Use

Use this command when:
- The user doesn't know how to write a feature brief
- The user's input is too vague to detect a pipeline (e.g., "I want to add a cart")
- The user explicitly asks for help structuring their feature

Do NOT use this command if the user already provided a detailed brief — detect the pipeline directly.

---

## Process

### Step 0 — Welcome

Print:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Brief Helper — Let's build your feature brief
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Answer a few questions and I'll write a
pipeline-ready brief for you.

Type your answer, then press Enter.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Step 1 — Change Type (Q1)

Ask:
```
Q1: What type of change is this?

  1. New feature on a new screen (Greenfield)
  2. Change to an existing iOS project (Brownfield)
  3. Fix a bug or crash (Bugfix)
  4. Migrate UIKit → SwiftUI (Migration)

Type 1, 2, 3, or 4:
```

Save: `type` ∈ {greenfield, brownfield, bugfix, migration}

---

### Step 2 — Feature Name (Q2)

Ask:
```
Q2: Give your feature a short name.
    (Used as the slug — e.g., "cart-checkout", "profile-edit")

Feature name:
```

Save: `slug` (lowercase, hyphenated)

---

### Step 3 — Feature Description (Q3)

**If type = greenfield:**
```
Q3: Describe what this feature does in 1–3 sentences.
    Who uses it? What does it let them do?

Description:
```

**If type = brownfield:**
```
Q3: What is the change request?
    Be specific: what should happen that doesn't happen now?

Change request:
```

**If type = bugfix:**
```
Q3: Describe the bug.
    When does it happen? What is the wrong behavior?
    (Paste a crash log if you have one.)

Bug description:
```

**If type = migration:**
```
Q3: What is the project path?
    (e.g., ~/Projects/MyApp)
    Which screens should be migrated first?

Project path + scope:
```

---

### Step 4 — Screens / Flows (Q4) [Greenfield only]

**Skip if type ≠ greenfield.**

```
Q4: List the screens or flows involved.
    (e.g., "ProductListView, ProductDetailView, CartView")

Screens:
```

---

### Step 5 — Acceptance Criteria (Q5)

**If type = bugfix:** skip this step — derive ACs from bug description.

```
Q5: What must be true when this feature is done?
    List 3–6 conditions. Start each with "User can..." or "App must..."

    Example:
      - User can tap Add to Cart from the product page
      - Cart badge updates immediately after adding
      - Empty state shows when cart is empty

Acceptance criteria (one per line):
```

---

### Step 6 — API / Backend (Q6) [Greenfield + Brownfield only]

**Skip if type = bugfix or migration.**

```
Q6: Does this feature need API calls?

  a. Yes — I'll describe the endpoints
  b. Yes — use mock data for now
  c. No — local/offline only

Type a, b, or c:
```

If user answers `a`, ask:
```
Q6b: Describe the endpoints needed.
     (Method + path is enough — e.g., GET /api/v1/products, POST /api/v1/cart/items)

Endpoints:
```

---

### Step 7 — Platform / OS Constraints (Q7)

```
Q7: Any special requirements?
    (Leave blank to skip)

    Examples:
      - iOS 17+ only
      - iPad support needed
      - Offline support required
      - Dark mode only
      - Specific font / color provided

Special requirements:
```

---

### Step 8 — Generate Brief

Synthesize all answers into a formatted brief.

**Output for Greenfield:**
```markdown
# Feature: <slug>

## Overview
<Q3 description — 2-3 sentences>

## Screens
<Q4 screens list>

## Acceptance Criteria
<Q5 list — numbered AC-1, AC-2, ...>

## API Contracts
<Q6 endpoints — or "Mock data" or "None">

## Platform Requirements
<Q7 — or "Standard iOS 17+">

## Out of Scope
- <anything user explicitly excluded>
- Push notifications (unless specified)
- Analytics events (unless specified)
```

**Output for Brownfield:**
```markdown
# Change Request: <slug>

## Project
<project path from Q3 or "counter-feature (sandbox)">

## Change Description
<Q3 change request>

## Acceptance Criteria
<Q5 list — numbered AC-1, AC-2, ...>

## API Changes
<Q6 endpoints — or "None">

## Constraints
<Q7 — or "None">
```

**Output for Bugfix:**
```markdown
# Bug Report: <slug>

## Description
<Q3 bug description>

## Expected Behavior
<derived from description>

## Actual Behavior
<derived from description>

## Reproduction Steps
<derived — or ask user if unclear>

## Crash Log / Stack Trace
<Q3 crash log if provided — or "None">
```

---

### Step 9 — Confirm or Revise

Print the generated brief, then ask:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Brief ready!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Does this look right?

  "yes" — start the pipeline with this brief
  "edit <field>" — change a specific part
  "restart" — start over

Your choice:
```

If user says `"yes"` → detect pipeline from the generated brief, run pre-flight, start Phase 0/1.
If user says `"edit <field>"` → re-ask the relevant question, regenerate.
If user says `"restart"` → go back to Step 0.

---

## Rules

- Never invent acceptance criteria — only use what the user provided
- Never skip Step 9 — always confirm before starting the pipeline
- If the user's Q5 answer is vague (e.g., "it should work well"), ask one clarifying follow-up
- Keep questions short — one question per message
- Do not ask for Figma links, design tokens, or asset names unless user mentions them
- This command is compatible with Pipeline E (Micro) — if TRIVIAL signals detected in Q3, note it at Step 9:
  `"This looks like a micro-change. I'll use Pipeline E (fast path, no tests)."`
