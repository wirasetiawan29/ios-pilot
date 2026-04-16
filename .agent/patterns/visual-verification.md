# Pattern: Visual Verification (Phase 3.6)

Runs AFTER Phase 3.5 (build succeeded) and BEFORE Phase 4 (unit tests).
Generates an XCUITest visual check, boots simulator, captures screenshots,
and uses AI to compare against spec requirements.

**This phase is ADVISORY — results are warnings, never pipeline blockers.**

---

## When to Run

Run Phase 3.6 only when ALL of these are true:
1. `01-spec.md` contains a non-empty `## Visual Anchors` section
2. Phase 3.5 build result is ✅ (not ⚠️ or 🚫)
3. A booted iOS simulator is available OR user can boot one

If `## Visual Anchors` is missing from spec → skip silently, log in `.state/phase-progress.md`:
`Phase 3.6: SKIPPED — no Visual Anchors in spec`

---

## How to Add Visual Anchors to a Spec

In `01-spec.md`, add this section (Spec Parser should generate it when the brief describes screens):

```markdown
## Visual Anchors

- screen: LoginScreen
  description: Login form with email, password, and submit button
  key_elements:
    - email text field
    - password secure field
    - "Sign In" button (primary style)
    - app logo at top
  negative_checks:
    - no loading spinner visible on initial load
    - no error message visible on initial load

- screen: HomeScreen
  description: Logged-in home with greeting and product list
  key_elements:
    - user greeting text ("Welcome, {name}")
    - product list with at least one item
    - bottom tab bar
  negative_checks:
    - no login form visible
```

---

## Process

### Step 1 — Parse Visual Anchors

Read `01-spec.md ## Visual Anchors`. For each screen:
- Extract: `screen`, `description`, `key_elements`, `negative_checks`
- Infer accessibility identifiers:
  - `"email text field"` → `textFields["email_input"]`
  - `"Sign In button"` → `buttons["sign_in"]` or `buttons["Sign In"]`
  - Unresolvable → add `// TODO: .accessibilityIdentifier("<id>") needed`

### Step 2 — Detect iOS Test Infrastructure

```bash
# Find scheme
xcodebuild -list 2>/dev/null | grep -A 20 "Schemes:" | head -10

# Find simulator
xcrun simctl list devices available | grep -E "iPhone" | head -5

# Check for UITests target
xcodebuild -list 2>/dev/null | grep -i "uitest"
```

If no simulator available:
→ Ask user: "No booted simulator found. Boot one and press Enter, or type 'skip' to skip visual check."
→ If skip → log and proceed to Phase 4

### Step 3 — Generate Visual Test File

Load `templates/visual-test.swift`. Substitute:
- `{feature_slug}` → feature folder name
- `{FeatureSlug}` → PascalCase
- `{AppScheme}` → from xcodebuild -list

Per visual anchor → generate `func test_visual_{ScreenName}()` with:
- Navigate to screen
- Assert key_elements exist
- Assert negative_checks are absent
- `captureScreenshot(name: "{ScreenName}")`

Output: `output/<feature-slug>/03.6-visual-tests/<Feature>VisualTests.swift`

In Project Mode: save to `{ProjectPath}/{AppName}UITests/`

### Step 4 — Run Visual Tests

```bash
SIMULATOR_ID=$(xcrun simctl list devices booted | grep "iPhone" | head -1 | grep -oE '[A-F0-9-]{36}')

xcodebuild test \
  -scheme {AppScheme} \
  -destination "id=$SIMULATOR_ID" \
  -only-testing:{AppName}UITests/{FeatureSlug}VisualTests \
  -quiet \
  2>&1 | grep -E "Test (passed|failed|error)"
```

Pull screenshots — Priority 1: app container Documents/
```bash
CONTAINER=$(xcrun simctl get_app_container $SIMULATOR_ID {bundle_id} data 2>/dev/null)
if [ -n "$CONTAINER" ] && [ -d "$CONTAINER/Documents/wira_screenshots" ]; then
  cp -r "$CONTAINER/Documents/wira_screenshots/." \
    output/<feature-slug>/.state/screenshots/
fi
```

Priority 2: xcresult bundle (CI fallback)
```bash
RESULT=$(find . -name "*.xcresult" -newer output/ 2>/dev/null | head -1)
if [ -n "$RESULT" ]; then
  xcrun xcresulttool export --type directory --path "$RESULT" \
    --output-path output/<feature-slug>/.state/xcresult/
  find output/<feature-slug>/.state/xcresult/ -name "*.png" \
    -exec cp {} output/<feature-slug>/.state/screenshots/ \;
fi
```

### Step 5 — AI Visual Analysis

For each captured screenshot:
1. Read the image using the Read tool
2. Compare visually against the `description` and `key_elements` from the Visual Anchor
3. Assign result: `PASS` | `SIMILAR` | `FAIL`

```
PASS    — all key_elements visible, all negative_checks absent
SIMILAR — most elements visible, minor visual differences (spacing, font size)
FAIL    — key element missing OR negative_check present
```

iOS note: safe area, notch, Dynamic Island, home indicator are system chrome — do NOT flag these.
Only flag if they OBSCURE content.

### Step 6 — Write Report

---

## Output → `output/<feature-slug>/03.6-visual-report.md`

```markdown
# Visual Verification Report

Date: <ISO date>
Phase: 3.6 (Advisory — not a pipeline gate)

## Results

| Screen | Result | Notes |
|---|---|---|
| LoginScreen | ✅ PASS | All 4 key elements visible, spinner absent |
| HomeScreen | ⚠️ SIMILAR | Product list visible but greeting text truncated |
| ProfileScreen | ❌ FAIL | "Sign Out" button not found — may need .accessibilityIdentifier |

## Screenshots
<!-- Paths to captured screenshots -->
- `.state/screenshots/LoginScreen.png`
- `.state/screenshots/HomeScreen.png`

## Issues to Address

| Severity | Screen | Element | Issue | Suggested Fix |
|---|---|---|---|---|
| ⚠️ Minor | HomeScreen | greeting text | Truncated on small screen | Check .lineLimit or .minimumScaleFactor |
| ❌ Missing | ProfileScreen | Sign Out button | Not found by XCUITest | Add .accessibilityIdentifier("sign_out") |

## Verdict
⚠️ PASS WITH WARNINGS — 1 PASS, 1 SIMILAR, 1 FAIL
All issues are advisory. Proceed to Phase 4.

<!-- Include in PR description under ## Visual Check -->
```

---

## Failure Mode Handling

| Situation | Action |
|---|---|
| No `## Visual Anchors` in spec | Skip silently |
| No simulator available | Ask user to boot one, or skip |
| Build result was ⚠️ | Still run — warnings don't prevent a runnable build |
| Test compile error | Show error, ask: retry / skip |
| 0 screenshots captured | Log warning, skip AI analysis |
| All screens FAIL | Surface in PR as advisory, NOT a blocker |

---

## Integration with Pipeline A

Phase 3.6 results flow into Phase 5 (Review):
- Phase 5 review agent reads `03.6-visual-report.md`
- Includes `## Visual Check` section in `05-pr.md`
- Issues are listed as `⚠️ Visual Advisory` — reviewer discretion

**Phase 3.6 NEVER blocks Phase 4.** Even if all screens FAIL, tests still run.
