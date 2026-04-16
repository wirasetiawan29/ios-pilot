# Pattern: API Contract Verification

Before generating code that calls an existing service or uses an existing model,
verify the API signature matches what's actually available.

---

## When to Apply

Any time the spec or task references an **existing** dependency:
- `AuthService — existing`
- `UserSession — existing singleton`
- Any file marked `Depends on: TASK-xx` where TASK-xx is already generated

---

## Verification Protocol

### For existing codebase services (from architect brief)

The architect's brief is the source of truth for existing services.
Before using a service, extract and confirm its exact signature:

```
From spec Dependencies section:
  AuthServiceProtocol — func login(email: String, password: String) async throws -> User

Before calling in ViewModel:
  ✅ Check: parameter names match (email, password — not username, pass)
  ✅ Check: return type matches (User — not AuthUser, LoginResult)
  ✅ Check: error handling matches (throws — not Result<>)
```

If the brief is unclear or contradictory → add to Ambiguities in spec, **stop**.

### For files generated earlier in the same pipeline

Before a dependent task generates its file, read the Contract field
of its dependency from `02-tasks.md` — not the full generated file.

```markdown
TASK-02 — Protocol: AuthServiceProtocol
- Contract: `protocol AuthServiceProtocol` with
  `func login(email: String, password: String) async throws -> User`
```

Use this contract as the expected interface. If the actual generated file
differs from the contract → log a `// AGENT-FLAG: contract mismatch` in both files.

---

## Parallel Consistency Check

After each wave of parallel tasks completes, before the next wave starts,
run a quick consistency scan on shared types:

1. Find all types that appear in more than one generated file
2. Check that they're referenced with the same name, same field names, same types

```
Example:
  TASK-01 wrote: struct User { let id: String }
  TASK-04 wrote: viewModel.userId = user.id  ← OK, String
  TASK-05 wrote: label.text = "\(user.id)"   ← OK, String

  But if TASK-02 wrote: protocol AuthServiceProtocol {
    func login(...) async throws -> UserProfile  ← MISMATCH: UserProfile ≠ User
  }
  → Flag: AGENT-FLAG: type mismatch between TASK-01 and TASK-02
```

Log all mismatches in `.state/consistency-flags.md`.
Orchestrator includes them in Phase 5 review as `[WARNING]` or `[BLOCKER]`.

---

## Mismatch Severity

| Mismatch | Severity |
|---|---|
| Return type differs | BLOCKER — code won't compile |
| Parameter name differs | BLOCKER — API call is wrong |
| Optional vs non-optional | BLOCKER — nil safety broken |
| Method name differs | BLOCKER |
| Extra method on protocol | WARNING — unused but not breaking |
| Naming convention differs (camelCase vs PascalCase) | WARNING |
