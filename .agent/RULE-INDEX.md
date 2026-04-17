# Rule Index

Cross-reference: each rule → all files that enforce or reference it.

**Usage:** when a rule changes, update EVERY file listed for that rule.
New rules must be added here when introduced.

---

## Navigation Rules (N-1 to N-6)

| Rule | Files to update |
|---|---|
| N-1: NavigationStack only in RootView | `navigation-rules.md` · `compliance-checker.md` (C-5) · `03-code-gen.md` Hard Prohibitions · `05-reviewer.md` Architecture checklist · `CLAUDE.md` Hard Rules · `06-build-validator.md` Fix Catalogue |
| N-2: navigationDestination only at root | `navigation-rules.md` · `06-build-validator.md` Fix Catalogue |
| N-3: No-back flows use .fullScreenCover | `navigation-rules.md` · `01-spec-parser.md` Navigation Contract pass |
| N-4: Modals receive @Binding for dismissal | `navigation-rules.md` |
| N-5: Navigation Contract required in spec | `navigation-rules.md` · `01-spec-parser.md` · `CLAUDE.md` Phase 1→2 gate · `gates.md` |
| N-6: Every View agent quotes Navigation Contract | `navigation-rules.md` · `02-task-breakdown.md` · `CLAUDE.md` Phase 2→3 gate |

---

## Code Quality Rules

| Rule | Files to update |
|---|---|
| No `print()` — use Logger | `compliance-checker.md` (C-1) · `03-code-gen.md` Hard Prohibitions · `05-reviewer.md` Code Quality checklist · `CLAUDE.md` Hard Rules · `06-build-validator.md` Fix Catalogue |
| No force unwrap `!` | `compliance-checker.md` (C-2) · `03-code-gen.md` Hard Prohibitions · `05-reviewer.md` Code Quality checklist · `CLAUDE.md` Hard Rules · `self-validation.md` |
| No unresolved TODO/FIXME | `compliance-checker.md` (C-9) · `03-code-gen.md` Hard Prohibitions · `CLAUDE.md` Hard Rules |
| No ObservableObject/@Published — use @Observable | `compliance-checker.md` (C-6) · `03-code-gen.md` Hard Prohibitions · `05-reviewer.md` Architecture checklist · `06-build-validator.md` Fix Catalogue · `self-validation.md` |
| Every View must have #Preview | `compliance-checker.md` (C-10) · `03-code-gen.md` Hard Prohibitions · `CLAUDE.md` Hard Rules · `06-build-validator.md` Fix Catalogue · `self-validation.md` |

---

## Design Token Rules

| Rule | Files to update |
|---|---|
| No hardcoded Color(red:green:blue:) | `compliance-checker.md` (C-3) · `03-code-gen.md` Hard Prohibitions + Design Token Rules · `CLAUDE.md` Hard Rules |
| No hardcoded numeric font sizes | `compliance-checker.md` (C-4) · `03-code-gen.md` Hard Prohibitions + Design Token Rules · `CLAUDE.md` Hard Rules |

---

## Architecture Rules

| Rule | Files to update |
|---|---|
| No URLSession in ViewModel | `compliance-checker.md` (C-7) · `03-code-gen.md` Hard Prohibitions · `05-reviewer.md` Architecture checklist · `network-layer.md` Code Gen Rules |
| No auth token in UserDefaults — use Keychain | `compliance-checker.md` (C-8) · `03-code-gen.md` Hard Prohibitions · `05-reviewer.md` Secrets checklist · `secrets-management.md` |
| No raw error.localizedDescription to UI | `compliance-checker.md` (C-11) · `03-code-gen.md` Hard Prohibitions · `05-reviewer.md` Code Quality checklist · `error-handling.md` |
| No hardcoded API keys/base URLs in Swift | `03-code-gen.md` Hard Prohibitions · `05-reviewer.md` Secrets checklist · `secrets-management.md` |

---

## Testing Framework Rule

| Rule | Files to update |
|---|---|
| Xcode 15: XCTestCase / Xcode 16+: @Suite+@Test | `04-unit-test.md` · `self-validation.md` · `CLAUDE.md` Target Stack |

---

## Migration Rules

| Rule | Files to update |
|---|---|
| MIGRATION annotations must flow to parity report | `CLAUDE.md` Hard Rules · `migration/m04-converter.md` · `migration/m05-parity-checker.md` · `gates.md` M4→M4.5 gate |
