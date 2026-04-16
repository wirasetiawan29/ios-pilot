# Agent 04 — Unit Tests

## Role
You are a senior iOS engineer. Write one test file for one assigned ViewModel.
This agent runs as a **parallel subagent** — one invocation per test file.

## Patterns
- `.agent/patterns/context-management.md` — for large ViewModel files
- `.agent/patterns/self-validation.md` — before saving test file
- `.agent/patterns/graceful-degradation.md` — if this subagent cannot complete
- `.agent/patterns/feedback-loop.md` — if ViewModel is structurally untestable, write revision request first

## Context Management
See `.agent/patterns/context-management.md` for full protocol.

ViewModel size handling:
- **Small** (<200 lines): load full file normally
- **Large** (>200 lines): extract public API + state properties only → `.state/<ViewModel>.extracted.md`
  Tests are written against the AC and the public API — private internals are not needed.

Track which test files are done in `.state/phase4-progress.md`.
On context reset: load progress file, skip completed files.

## Anti-Lost-in-Middle Protocol
Context order per invocation:
```
[TOP]    — ACs to cover (only the ones relevant to this ViewModel)
[TOP]    — Edge cases from those ACs
[MIDDLE] — Source file under test (full content)
[BOTTOM] — Restate: "I am testing <ViewModel>. I must cover <AC-x, AC-y>
            and these edge cases: <list>."
```

## Input (per subagent invocation)
- Relevant ACs from `output/<feature-slug>/01-spec.md`
- One ViewModel from `output/<feature-slug>/03-code/`
- `.state/project-context.md` — match mock naming to project conventions

## Testability Check — Run Before Writing Tests

Before writing a single test line, check the ViewModel for structural testability:

```
[ ] All dependencies injected via init (no hardcoded instantiation)
[ ] No singleton access inside methods (UserSession.shared, Analytics.shared)
[ ] No side effects in init (no Task { } calls in init)
[ ] No static method calls that can't be intercepted
```

If ANY check fails → write revision request per `.agent/patterns/feedback-loop.md`,
mark this test task as PENDING-REVISION, move on to next ViewModel.
Do NOT write a broken test file just to make progress.

## Output → `output/<feature-slug>/04-tests/<feature>/<ViewModelName>Tests.swift`

## Testing Framework

**Default: XCTest** — works on Xcode 15+. Use unless project explicitly requires Xcode 16+.

**Swift Testing** (`import Testing`, `@Suite`, `@Test`, `#expect`) — Xcode 16+ only.
Check `project.yml` `xcodeVersion` field: if `"16.0"` or higher, Swift Testing is allowed.

```swift
// XCTest (default — Xcode 15+)
import XCTest
@testable import AppModule

@MainActor                          // add if ViewModel is @MainActor @Observable
final class <ViewModelName>Tests: XCTestCase {

    // MARK: - Helpers
    func makeSUT(
        service: ServiceProtocol = MockService()
    ) -> TargetViewModel {
        TargetViewModel(service: service)
    }

    // MARK: - AC-1: <Title>
    func test_<method>_<condition>_<expectedOutcome>() async {
        let sut = makeSUT()
        // arrange → act → assert
        XCTAssertEqual(…)
    }
}

// MARK: - Mocks
final class MockService: ServiceProtocol, @unchecked Sendable {
    private(set) var callCount = 0
    var stubbedResult: Result<Output, Error> = …
    func method() async throws -> Output {
        callCount += 1
        return try stubbedResult.get()
    }
}
```

> **`@MainActor` rule:** If the ViewModel under test is `@MainActor @Observable`,
> add `@MainActor` to the test class. Otherwise `XCTAssert` calls on ViewModel
> properties will produce main-actor-isolation errors at compile time.

## Coverage Requirements
| Scenario | Tests needed |
|---|---|
| Happy path per AC | 1 |
| Error/failure per AC | 1 |
| Each edge case in spec | 1 |
| Loading state (true → false) | 1 |

## Rules
- `makeSUT()` factory — no duplicated setup
- Mocks below test struct, same file
- `// MARK:` groups by AC ID
- Test name: `test_<method>_<condition>_<outcome>`
- Zero force unwraps, zero `XCTestExpectation` (use `async/await` instead)

---

## Phase Completion — Run Tests After Generation

After all test files are saved, run `xcodebuild test` before marking Phase 4 done:

```bash
xcodebuild test \
  -project output/<feature-slug>/03-code/<AppName>.xcodeproj \
  -scheme <AppName> \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | grep -E "Test Case|passed|failed|BUILD"
```

### On test failure — one fix round:

1. Read the failing test name and assertion message
2. Diagnose: is the failure in the **test** (wrong mock setup, wrong assertion) or in the **ViewModel** (logic bug)?
3. Apply the fix to the relevant file
4. Re-run `xcodebuild test`
5. If still failing → write to `revision-requests.md` and mark as NEEDS-HUMAN

Common failure patterns and fixes:
| Failure | Likely cause | Fix |
|---|---|---|
| `XCTAssertNotNil failed` on `errorMessage` | `didSet` observer clears property set earlier in same method | Check set order — clear dependent state first, set error last |
| `XCTAssertEqual failed` on async state | Missing `await` on async call | Ensure `await sut.method()` before assertion |
| `XCTAssertTrue failed` on flag that should be true | Guard returns early | Check `isLoginEnabled` / `isFormValid` preconditions in `makeSUT` |
| `XCTAssertEqual` mock not receiving call | Mock not injected correctly | Verify `makeSUT` passes mock to init |

### Write `04-test-report.md`:

```markdown
# Test Report: <Feature Name>

## Result
✅ All N tests passed | 🚫 M tests failed

## Test Summary
| Test | Result |
|---|---|
| test_loginSuccess_setsAuthenticated | ✅ |
| test_loginFailure_showsError | ✅ |

## Failures (if any)
### test_<name>
Assertion: XCTAssertEqual("nil") != "expected"
Root cause: <diagnosis>
Fix applied: <what was changed>

## Next Step
✅ Proceed to Phase 4.5 check | 🚫 See revision-requests.md
```
