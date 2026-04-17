# Pattern: Compliance Checker

**Run after Phase 3 (Code Gen), before Phase 3.5 (Build Validator).**

Grep-based verification of Hard Rules. Does **not** rely on LLM judgment — every
check is a shell command with a deterministic pass/fail result.

Violations are treated as `[BLOCKER]` — same severity as compile errors.
Phase 3→3.5 gate will not pass until all violations are resolved.

---

## When to Run

```
Phase 3 complete → Run Compliance Checker → write compliance-report.md
                                           ↓
                             ✅ No violations → proceed to Phase 3.5
                             🚫 Violations found → fix → re-run checker
```

---

## Checks

Run from `output/<feature-slug>/03-code/` directory.

### C-1 — No `print()` calls in Sources
```bash
grep -rn "print(" Sources/ --include="*.swift" | grep -v "// "
```
**Expected:** no output. Any match = violation.
**Fix:** replace with `Logger.<category>.debug(…)` from `os.log`.

---

### C-2 — No force unwraps in non-test Sources
```bash
grep -rn "[a-zA-Z0-9_)]!" Sources/ --include="*.swift" \
  | grep -v "!=" \
  | grep -v '^\s*//' \
  | grep -v "fatalError\|#Preview"
```
**Expected:** no output.
**Fix:** replace with `guard let`, `if let`, or `?? defaultValue`.
**Note:** matches `optional!` or `result!.` patterns. Boolean NOT (`!flag`) is excluded because `!` is not preceded by `[a-zA-Z0-9_)]` in that position.

---

### C-3 — No hardcoded Color values (must use Theme tokens)
```bash
grep -rn "Color(red:\|Color(hue:\|UIColor(red:" Sources/ --include="*.swift"
```
**Expected:** no output.
**Fix:** replace with `Color.appPrimary` / `Color.appError` etc. from `Theme.swift`.
If the color is new, add it to `Theme.swift` with both `extension Color` and
`extension ShapeStyle where Self == Color`.

---

### C-4 — No hardcoded numeric font sizes
```bash
grep -rn "\.font(.system(size:" Sources/ --include="*.swift" | grep -v "Theme.swift\|// "
```
**Expected:** only matches inside `Theme.swift` itself.
**Fix:** replace with `.font(.appTitle)`, `.font(.appBody)`, etc.

---

### C-5 — `NavigationStack` only in root view
```bash
grep -rn "NavigationStack" Sources/ --include="*.swift" | grep -v "App\.swift\|RootView\.swift\|#Preview\|// "
```
**Expected:** no output.
**Fix:** remove `NavigationStack` from child view. Navigation ownership lives only
in `*App.swift` or `RootView.swift` (Rule N-1).

---

### C-6 — No `ObservableObject` / `@Published` (use `@Observable`)
```bash
grep -rn "ObservableObject\|@Published" Sources/ --include="*.swift"
```
**Expected:** no output.
**Fix:** replace `class X: ObservableObject` with `@Observable class X`,
remove all `@Published` prefixes.

---

### C-7 — No `URLSession` in ViewModel files
```bash
grep -rn "URLSession" Sources/Features/ --include="*.swift" | grep -v "Repository\|Service\|// "
```
**Expected:** only in `*Repository.swift` or `*Service.swift` files.
**Fix:** move network call to a Repository that conforms to a protocol.
ViewModel should only call the protocol method.

---

### C-8 — No auth token in UserDefaults
```bash
grep -rni "userdefaults.*token\|token.*userdefaults\|userdefaults.*key\|userdefaults.*secret" Sources/ --include="*.swift"
```
**Expected:** no output.
**Fix:** use `KeychainHelper.save(_:for:)` — see `.agent/patterns/secrets-management.md`.

---

### C-9 — No unresolved TODO in generated code
```bash
grep -rn "// TODO:" Sources/ --include="*.swift"
```
**Expected:** no output. Hard rule: no unresolved TODO in generated Swift.
**Fix:** implement the TODO or replace with `// ASSET-REQUIRED:` / `// MIGRATION:`
if it genuinely needs human follow-up.

---

### C-10 — Every View file has a `#Preview` block
```bash
grep -rln "struct [A-Za-z]*: View\|class [A-Za-z]*: View" Sources/ --include="*.swift" \
  | while IFS= read -r f; do
    if ! grep -q "#Preview" "$f"; then
      echo "MISSING #Preview: $f"
    fi
  done
```
**Expected:** no output.
**Fix:** append a minimal `#Preview { <ViewName>() }` block at end of file.
**Note:** uses `IFS= read -r` to handle filenames with spaces; matches `struct Name: View` / `class Name: View` to avoid false-positives from protocol definitions.

---

### C-11 — No `error.localizedDescription` assigned directly to UI
```bash
grep -rn "errorMessage = error.localizedDescription\|= error.localizedDescription" Sources/ --include="*.swift"
```
**Expected:** no output.
**Fix:** map to a typed domain error first:
`errorMessage = (error as? AppError)?.userMessage ?? AuthError.unknown(error.localizedDescription).errorDescription`

---

## Output → `output/<feature-slug>/compliance-report.md`

```markdown
# Compliance Report: <Feature Name>

## Result
✅ All checks passed | 🚫 N violations found

## Violations

### [BLOCKER] C-5 — NavigationStack in child view
File: Sources/Features/Feed/FeedView.swift:12
```
NavigationStack {
```
Fix: remove NavigationStack, use plain VStack. Navigation owned by RootView.

### [BLOCKER] C-6 — ObservableObject used
File: Sources/Features/Feed/FeedViewModel.swift:5
```
class FeedViewModel: ObservableObject {
```
Fix: replace with `@Observable class FeedViewModel {`, remove @Published.

## Checks Passed
- C-1 No print() ✅
- C-2 No force unwrap ✅
- C-3 No hardcoded Color ✅
- C-4 No hardcoded font size ✅
- C-5 NavigationStack only in root 🚫
- C-6 No ObservableObject 🚫
- C-7 URLSession only in Repository ✅
- C-8 No token in UserDefaults ✅
- C-9 No unresolved TODO ✅
- C-10 All Views have #Preview ✅
- C-11 No raw error.localizedDescription ✅

## Next Step
🚫 Fix violations above, then re-run compliance checker before Phase 3.5.
✅ Proceed to Phase 3.5 (Build Validator).
```

---

## Fix Round

Apply fixes → re-run failing checks only (not full suite).
If any violation remains after 1 fix round → write to `revision-requests.md`,
flag for human review. Do not block indefinitely.
