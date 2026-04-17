# Command: apple docs check

## Triggers
- User says: "apple docs check", "check apple docs", "docs check", "api version check"
- Auto-trigger: before Phase 3 Code Gen if spec references platform APIs flagged as version-sensitive
- Standalone: can be run at any point in the pipeline

## Purpose
Verify that APIs referenced in the current task are available and not deprecated
for the project's deployment target. Uses live Apple documentation via Sosumi MCP —
not model knowledge — so results reflect current API status.

---

## Execution Steps

### Step 1 — Detect deployment target

Read from (in order of priority):
1. `project.yml` → `options.deploymentTarget.iOS`
2. Active spec file (`.state/01-spec.md` or `output/<slug>/.state/01-spec.md`)
3. `.xcodeproj` build settings → `IPHONEOS_DEPLOYMENT_TARGET`

If not found → ask the user before proceeding.

### Step 2 — Collect APIs to check

Scan these sources for Apple framework API references:
- Active spec file (`01-spec.md`) — especially `## Data Models` and `## Acceptance Criteria`
- Generated code in `output/<slug>/03-code/Sources/` (if Phase 3 is complete)
- Current task description

Identify:
- SwiftUI view types and modifiers (e.g., `NavigationStack`, `@Observable`, `.navigationDestination`)
- Foundation/Swift standard library types
- Platform frameworks: `HealthKit`, `CoreLocation`, `MapKit`, `StoreKit`, `AuthenticationServices`, `UserNotifications`, `App Intents`, `SwiftData`
- Swift language features with version requirements: `async/await`, `actor`, `@Observable`, `@Bindable`, `Swift 6 concurrency`

### Step 3 — Fetch live documentation

For each flagged API, use Sosumi MCP to fetch the current Apple documentation:

```
mcp__claude_ai_Sosumi_AI__searchAppleDocumentation(query: "<API name>")
mcp__claude_ai_Sosumi_AI__fetchAppleDocumentation(url: "<doc URL from search result>")
```

Check each result for:
- `Availability` — when was it introduced? (e.g., `iOS 17.0+`)
- `Deprecated` notice — is it deprecated, and when?
- `Beta` or `visionOS only` flags
- Migration notes (e.g., "Use X instead of Y")

### Step 4 — Assess version risk

For each API, compare `Availability` against the project's deployment target:

| Situation | Risk level |
|---|---|
| API introduced after deployment target | HIGH — will crash on older devices |
| API deprecated in recent iOS version | MEDIUM — still works, but plan migration |
| API behavior changed in a version ≥ deployment target | MEDIUM — test carefully |
| API available since before deployment target, no deprecation | NONE |
| Cannot determine from docs | Flag as `[VERIFY MANUALLY]` |

### Step 5 — Write output file

Write `.state/APPLE_DOCS_CHECK.md` (relative to active feature slug directory):

```markdown
# Apple Docs Check
Generated: [ISO 8601 timestamp]
Project deployment target: iOS [N]
Scanned: [list of files/sources checked]

## Flagged APIs

### [API Name]
Introduced: iOS [N]
Status: [Available | Deprecated in iOS N | Changed in iOS N]
Risk: [description of the risk or behavior change]
Docs: [URL from Sosumi result]
Recommendation: [what to do — use availability check, find alternative, or verify manually]

## Clean APIs
[N] APIs scanned with no version concerns detected.
```

---

## Behavior Rules

- **Advisory only** — this command never blocks pipeline execution
- **Never modifies generated code** — reports only
- If Sosumi MCP returns no results for an API → write `[VERIFY MANUALLY]`
- If deployment target cannot be determined → ask user, do not guess
- Results in `.state/APPLE_DOCS_CHECK.md` persist across the session
- Review phase (Phase 5) should reference this file if it contains HIGH risk items

---

## Auto-trigger Condition

Before Phase 3 Code Gen, the Orchestrator checks if the spec contains any of:
- `SwiftData`, `App Intents`, `@Observable`, `NavigationStack`, `async/await`, `actor`
- Any framework imported that was introduced in iOS 16 or later

If yes → run `apple docs check` before spawning Phase 3 subagents.
Results are advisory — Phase 3 proceeds regardless.

---

## Example Output

```markdown
# Apple Docs Check
Generated: 2026-04-17T10:30:00Z
Project deployment target: iOS 16
Scanned: output/login-feature/.state/01-spec.md, output/login-feature/03-code/Sources/

## Flagged APIs

### @Observable
Introduced: iOS 17.0
Status: Available
Risk: Project targets iOS 16 — @Observable requires iOS 17+. Devices on iOS 16 will crash.
Docs: https://developer.apple.com/documentation/observation/observable()
Recommendation: Either raise deployment target to iOS 17+, or use ObservableObject for iOS 16 support.

### NavigationStack
Introduced: iOS 16.0
Status: Available
Risk: None — matches deployment target exactly.
Docs: https://developer.apple.com/documentation/swiftui/navigationstack
Recommendation: No action needed.

## Clean APIs
4 APIs scanned with no version concerns detected.
```
