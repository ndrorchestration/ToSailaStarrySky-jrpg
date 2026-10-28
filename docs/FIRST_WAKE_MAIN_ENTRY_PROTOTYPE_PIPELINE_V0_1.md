# Main-scene prototype pipeline — First Wake review-route v0.1

**Status:** opt-in native Godot 4.7.2 candidate for **player-accessible integration testing**. This is neither a canonical scene handoff nor the release/production quest.

## What is linked into the actual configured game entry

The current `godot/project.godot` **retains its existing** `run/main_scene="res://scenes/first_wake_chapter1_player_preview.tscn"`. That scene has the older Lyra-first Crossing party and existing v1 durable save system. Replacing it prematurely would silently rewrite current game/save authority. We instead expose an explicit **F8: Revised Opening / Ionia First (opt-in prototype)** label and a remappable new InputMap action on the current startup scene.

When the user activates F8 **outside an active dialogue or encounter**:

1. `first_wake_prototype_route.gd` requires the actual current native entry scene and a semantically valid existing `first_wake_chapter1_save_codec.gd` v1 snapshot, captures its original story/resolver/position in **volatile SceneTree memory**, and changes scene to the existing `res://scenes/first_wake_job_preview.tscn`.
2. The already playable review scene starts Ender alone, exposes Captain Ionia's job flyer, hiring dialogue, physical gangway, three engine inspections, a safe-preflight handoff, new K/L revised-v2 checkpoint, and the still-locked Ender/Lyra Resonance status. It is **not** claimed to be a continuation of the old Crossing plot and cannot show the real post-splashdown Lyra reunion.
3. Within the revised review, **F8** returns to the original default scene. The router validates the volatile v1 snapshot again and restores the **exact original legacy chapter state, position, resolver stats and party** after the scene is rebuilt. It clears its in-memory handoff keys after success. None of this writes or converts either permanent save schema or grants combat/spell/Art authority.

This is a deliberately reversible **review menu path through the real application entrypoint**. It is not a hidden start-of-story gate, a saved unlock, a new relationship flag, nor an approved production on-ramp.

## Inheritance and integrity

- Source base: [draft #480](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/480), which includes revised v2 K/L checkpoint with durable integrity/backup recovery, prior [Ionia-first chronology #450](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/450), and [nonexecuting Resonance composite #465](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/465).
- Creator-directed opening chronology remains **Ender alone → Ionia before test flight → safe water splashdown → Lyra/Talen family introduction later**. Plot Spirit/Water/Earth/Fire/Air identities never create combat authority; Talen is never a combat recruit.
- `first_wake_prototype_route.gd` only accepts the exact existing main native scene and the exact isolated revised-opening review scene. It declines source forgery, nested handoffs, bad snapshots, inactive return targets, and combat/dialogue interruption.
- The two save slots remain independent: `user://first_wake_chapter1_save.json` for historical v1 and `user://first_wake_revised_opening_review_v2.json` for revised prototype v2.
- Input `tstss_first_wake_prototype_route` maps to F8 **only when not already configured**, preserving player remaps. Existing F5/F9, dialogue, party and battle controls remain.
- The main game scene, its quest FSM, legacy episode resolution, restore path and defaults remain in place. The saved v1 source remains backward-readable.
- **No output build** or installer is distributed. No main branch merge/release.

## Testable pipeline boundary

`godot/tests/first_wake_prototype_entry_route_test.gd` exercises **actual Godot SceneTree changes** starting from the configured main scene, dispatching the mapped F8 key in both directions. It verifies a legible prototype hint, Ender-only preview roster, Lyra/Resonance lock, player-visible return hint, preservation of the source's exact legacy v1 snapshot including stats/position, absence of on-disk writes to either slot, no leftover transient route keys and a second successful open/return cycle. It also checks combat-active entry refusal.

The pinned Godot 4.7.2 native workflow runs this alongside all prior gameplay, chapter saves, revised checkpoints, party chronologies, Resonance lab and scene regressions. **Exact-head native execution is required**; earlier sibling PR passes do not certify this new route.

## Practical next full playable integration gates

1. Add a genuine flight/engine-load state and authoritative ocean-contact physics evidence after the preflight handoff.
2. Implement safe postflight family reunion with Lyra and Talen before any Ender–Lyra combined Art, including visual and dialogue sign-off.
3. Only after those scenes exist, reconcile full Chapter I legacy v1 save locations with revised v2 playable stages and author a documented opt-in migration policy; preserve old saves.
4. Independently approve a canonical Art unlock event, build runtime action scheduling and balance, integrate accepted character/magic VFX, run gamepad/accessibility tests, uncoached player QA and Windows Defender release prerequisites.

No feature in this prototype implies any of those later tests or permissions have passed.
