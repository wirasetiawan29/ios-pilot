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

## Swift Testing Standards

```swift
import Testing
@testable import AppModule

@Suite("<ViewModelName>")
struct <ViewModelName>Tests {

    // MARK: - Setup
    func makeSUT(
        service: ServiceProtocol = MockService()
    ) -> TargetViewModel {
        TargetViewModel(service: service)
    }

    // MARK: - AC-1: <Title>
    @Test("<plain English behavior description>")
    func test_<method>_<condition>_<expectedOutcome>() async {
        let sut = makeSUT()
        // arrange → act → assert
        #expect(…)
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
- Zero force unwraps, zero `XCTestExpectation`
