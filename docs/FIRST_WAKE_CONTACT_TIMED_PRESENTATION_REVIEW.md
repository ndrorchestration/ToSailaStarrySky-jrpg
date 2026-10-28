# First Wake: contact-timed damage presentation pilot

**Status:** Opt-in, reversible Godot 4.7.2 presentation study. Stacked on draft #521. This is not combat-authority migration, finished character art or an approved replacement for the Chapter I scene.

## Why
The first real signal-driven prototype proves an already-resolved `staffStrike` plays Ender's geometric combat animation, but the authoritative HP/staff-charge change appears immediately in the HUD, well before the visible contact beat. The improvement in this branch delays **only the depicted values**, never damage resolution.

## Implementation
- `first_wake_staff_presentation_queue.gd`: consumes a verified resolved staff-action receipt and deep copies of the actual encounter **before/after** snapshots. Until normalized progress 0.695 it projects the pre-action HP/staff and anticipatory status; at contact it reveals the already-committed post-action values, actual formula damage and a single readable number. The transition is monotonic within an event; a later accepted action replaces/flushes an old projection. Event serials cannot replay or rewind authority.
- `first_wake_staff_presentation_hud.gd`: a mouse-ignoring `Control` in an opt-in `CanvasLayer`, masking only the three specific text rows for Ender's resources, target HP, and combat status in the *existing Chapter I migration scene* at its native 960×640 viewport. These are an explicit **visual projection of resolved state**, not writes to the formula controller's `target`, `player`, logs or save codec. When inactive, the overlay disappears, exposing the real HUD.
- `first_wake_staff_signal_visual_presenter.gd`: links the transient projection to its already-verified opt-in staff signal and original 1.10 s attack timeline. It clears on interruption, disable, scene removal/inactive encounter and playback completion. Nonstaff actions never display staff cues. Reduced motion reveals the true result immediately, freezes pose movement and disables contact flashes.
- `first_wake_staff_signal_pilot_review.gd` installs the HUD **only in the separate draft review scene**, not the default game entry point or production saves. There is no new action request route or hitbox.

## Verification and QA
- Native Godot test `first_wake_staff_presentation_timing_test.gd`: true formula action resolves immediately and spends one staff charge/turn; pre-contact projection matches the snapshot **before** the actual action, despite already-mutated formula; at contact projection matches the authoritative post-action state; reveals no more than once; interrupted or nonstaff action clears stale projection; reduced motion reveals immediately; no additional turn, progression change or save schema mutation; toggling off fully restores the real HUD.
- `capture_first_wake_staff_presentation_timing.gd`: genuine **960×640** Godot screenshot series from the same single accepted staff turn: before action, anticipation projection, contact reveal, reduced-motion reveal. Lossless images stay runner-local with hashes; log-only downsampled 2×2 contact sheet permits independent visual QA.
- Previous Chapter I, party authority, formula encounter, scene action-signal, weapon poses, and target alignment regressions run on pinned official Godot 4.7.2.

## Explicit constraints
This is deliberately **not** delaying or queuing combat action execution, calculation, HP writes, staff charges or enemy retaliations. The pre-impact overlay depicts temporarily historical numbers as a cinematic convention and could be confusing in fast successive actions; fail-closed interruption immediately returns the authoritative HUD. Real production needs full HUD component architecture, animation event provenance, accessibility text announcements, controller review, variable-resolution layouts, target identity and enemy reaction design, accepted character art and independent Windows security acceptance before release.

The creator-approved Ender portrait, Five Lights, class/weapon permissions and latest opening plot remain unchanged. The current native Chapter I migration scene still uses the older Ender+Lyra-first ordering, which must be reconciled with the revised Ionia-first story before a player-facing vertical slice is accepted. No merge or release is authorized.
