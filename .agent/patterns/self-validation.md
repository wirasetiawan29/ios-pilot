# Pattern: Self-Validation

Every agent that produces a file must run this checklist **before saving**.
Do not move on if any check fails — fix the output first.

---

## Universal Checklist (all generated Swift files)

```
[ ] File header present with AC coverage and depends-on
[ ] No force unwrap (!)
[ ] No print() in non-test files
[ ] No TODO / FIXME left unresolved
[ ] No ObservableObject / @Published
[ ] MARK sections present
[ ] Every AC listed in file header is actually addressed in the code
```

If any item fails → fix inline, do not save the broken version.

---

## Per-Layer Checks

**Model**
```
[ ] Conforms to Sendable, Equatable
[ ] No methods (pure data)
[ ] Field types match spec data model exactly
```

**Protocol**
```
[ ] All methods are async throws where the spec says they can fail
[ ] No default implementations (keep it minimal)
```

**ViewModel**
```
[ ] Annotated with @Observable and @MainActor
[ ] No direct URLSession / network calls
[ ] isLoading + defer pattern for every async operation
[ ] All dependencies injected via init (no singletons accessed directly)
```

**View**
```
[ ] No business logic (no if/else beyond simple UI switches)
[ ] ViewModel held as @State, not @StateObject
[ ] Loading and error states handled visually
[ ] #Preview block present at end of file
[ ] No hardcoded Color(red:green:blue:) or numeric font sizes — use Theme tokens
```

**Unit Test**
```
[ ] Framework matches project Xcode version:
    Xcode 15 → XCTestCase class + func test_<method>_<condition>_<outcome>()
    Xcode 16+ → @Suite struct + @Test + #expect  (check project.yml xcodeVersion)
[ ] makeSUT() factory present
[ ] Every AC in the paired ViewModel's file header has at least one test
[ ] Mock conforms to the correct protocol
[ ] No force unwrap
```

---

## Self-Correction Protocol

If a check fails:
1. Identify the specific line/section that fails
2. Fix it in place
3. Re-run the checklist from the top
4. Save only after a clean pass

If you cannot fix it (e.g. missing information you don't have):
→ Save the file with a `// AGENT-FLAG: <reason>` comment at the top
→ Log it in `.state/<phase>-flags.md`
→ Orchestrator will surface it in Phase 5 review
