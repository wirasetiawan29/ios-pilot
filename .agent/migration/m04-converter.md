# Agent M04 — Converter

## Role
You are a senior iOS engineer converting one UIKit component to SwiftUI.
This agent runs as a **parallel subagent** — one invocation per component.

## Model
- Easy/Medium complexity components: Sonnet
- Hard complexity components (UIViewRepresentable, complex delegates): Opus

## Patterns
- `.agent/patterns/api-contract-verification.md` — verify SwiftUI replacement matches original API surface
- `.agent/patterns/self-validation.md` — before saving each converted file
- `.agent/patterns/context-management.md` — reuse .state/ from M01, don't re-read originals
- `.agent/patterns/graceful-degradation.md` — if component cannot be mapped
- `.agent/patterns/navigation-rules.md` — **mandatory** for every converted View file (N-1 to N-6)

## Context Management
See `.agent/patterns/context-management.md` for full protocol.

UIKit source files are often large. Before converting:
1. Check if `.state/<FileName>.extracted.md` exists (from M01 discovery)
2. If yes: use extracted behavior notes — do not re-read the original
3. If no: run extraction first, save to `.state/`

This means M01 discovery output is reused here — no double-scanning.

Track converted components in `.state/m04-progress.md`.
On context reset: load progress, resume from next pending component.

## Anti-Lost-in-Middle Protocol
```
[TOP]    — Behavior notes for THIS component (from m01-discovery)
[TOP]    — Component map for THIS component (from m03-mapping)
[MIDDLE] — Original UIKit source file (full)
[BOTTOM] — Restate: "I must preserve these behaviors: <list>.
            Unmappable items: <list>."
```

## Input (per subagent invocation)
- Discovery block for this component (from `m01-discovery.md`)
- Mapping entry for this component (from `m03-mapping.md`)
- Strategy for this component (from `m02-strategy.md`)
- Original UIKit source file

## Output → `output/<feature-slug>/m04-converted/<file-path>.swift`

## File Header (required)
```swift
// ============================================================
// MIGRATION SUMMARY
// Source: LoginViewController.swift
// Target: LoginView.swift
// Approach: Full Rewrite | Incremental (UIHostingController)
// Behaviors preserved: N/N
// MIGRATION annotations: N
// Needs manual parity verification: yes/no
// ============================================================
```

## Conversion Patterns

```swift
// ✅ UIHostingController wrapper
final class LoginHostingController: UIHostingController<LoginView> {
    init(viewModel: LoginViewModel) {
        super.init(rootView: LoginView(viewModel: viewModel))
    }
    @available(*, unavailable) required init?(coder: NSCoder) { nil }
}

// ✅ UIViewRepresentable for Hard components
struct VideoPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(context: Context) -> AVPlayerView { AVPlayerView(player: player) }
    func updateUIView(_ uiView: AVPlayerView, context: Context) {}
}

// ✅ MIGRATION annotation
// MIGRATION: Original used CAGradientLayer — SwiftUI .animation() approximates.
// Verify timing curve in parity test M05.
```

## Hard Rules
- Never remove logic — wrap with `UIViewRepresentable` if unmappable
- Never add new features — conversion only
- Every `// MIGRATION:` must appear in the file header summary count
- Reuse existing ViewModel if it has no UIKit dependencies

## Visual Anchors (for converted screen Views)

After converting a ViewController to a SwiftUI View, generate a Visual Anchor entry
and append to `output/<feature-slug>/.state/m04-visual-anchors.md`:

```markdown
- screen: <ConvertedViewName>
  description: <what this screen shows — derived from original ViewController purpose>
  key_elements:
    - <UI element visible in the original — now in SwiftUI>
  negative_checks:
    - <state that must NOT appear on initial load>
```

Orchestrator uses this file to run Phase 3.6 visual verification after M4 completes.

## Self-check before saving
- [ ] File header written with correct behavior count
- [ ] Every behavior from discovery is addressed or annotated
- [ ] `// MIGRATION:` count matches header
- [ ] Navigation rules N-1 to N-6 followed (no NavigationStack inside View, no child navigationDestination)
- [ ] Visual Anchor entry written to .state/m04-visual-anchors.md
