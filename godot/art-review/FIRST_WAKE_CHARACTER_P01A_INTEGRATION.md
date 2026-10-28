# P-01A — Native First Wake character-visual admission adapter (draft)

**Source baseline:** PR #487 exact `aa68f341e62b7c5f8de666ecd6410f244ab4a0b3`, Godot 4.7.2 / GDScript. **Status:** opt-in prototype fixture only; not an admitted Chapter I character. This study deliberately distinguishes a real dock-scene test from the broader P-01 multi-surface/cinematic/equipment acceptance plan in [main-targeted documentation draft #502](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/502).

## Executable scope

- `first_wake_character_visual_p01.gd` attaches one original-source *unrecruited Lyra test visual* to the actual `res://scenes/first_wake.tscn` `YSortedActors` node. F6 toggles it; initial state is completely absent. It removes the actor on exit. All actual gameplay actors and dialogue remain the existing Ender/Ionia pilot.
- The fixture consumes the existing unapproved Lyra four-direction/six-phase SVG atlas sources using the verified distance-driven `CharacterBody2D` walk actor. Closed south→west→north→east route is 400 logical pixels inside current flat dock-review coordinates. The original sprite sources and all character movement logic are unchanged.
- The bridge does not read or write Chapter I party, progression, equipment, class, save, magical ability or recruitment state. It is intended to validate visualization only. It does **not** introduce Lyra into the narrative prior to her planned later entrance after the Ionia-first flight and splashdown.

## Actual scene evidence requirement

`tests/first_wake_character_visual_p01_test.gd` instantiates `first_wake.tscn`, proves default OFF, exercises the real F6 event path, asserts original source identities, every direction × six moving phases, bounded actual native physics displacement and closed route, unchanged live Ender/Ionia references, positions and dialogue, complete removal on F6 OFF, and a second opt-in collision blocked by a temporary **real `StaticBody2D`** introduced only inside the test. That temporary obstacle proves CharacterBody2D contact behavior **within the First Wake scene**, but is **not native dock/deck topology**: the regular First Wake dock art is still painted geometry without a verified permanent dock collider.

`tests/capture_first_wake_character_visual_p01.gd` captures real Godot OpenGL 960×640 frame hashes for default off, south-moving, west-moving, and restored off. The original baseline/restored images must be pixel-identical; the test actor must visibly alter the image during opt-in. Full screenshots remain runner-local while GitHub Actions artifact quota is constrained; bounded JPEG inspection crops are logged, not art acceptance.

## Evidence & state gates

| Check | Intended P-01A result | Wider P-01 production result |
|---|---|---|
| Native original art source / facing / six walk phases | Test on this branch | No approved costume or final art |
| In-scene actual movement and y-sort parent | Test on this branch | Terrain/slopes/projected 2.5D surface contact **NOT_RUN** |
| In-scene collision with temporary test-only obstacle | Test on this branch | Real deck/dock/planet colliders **NOT_RUN** |
| Ender, Ionia, dialogue identity invariant | Test on this branch | Ionia-first narrative playable flow and persistence across save/load **NOT_RUN** |
| F6 default off and source-free removal | Test on this branch | Release build exclusion/controls/accessibility **NOT_RUN** |
| In-scene native GL screenshots | Test on this branch | 1440×960, environment/weather, target GPU and Windows installer **NOT_RUN** |
| Equipment/portrait adapters | **NOT_BOUND** | Read-only equipment field→battle and cinematic consistency **BLOCKED** |
| Artist-labeled stance and corrected Lyra gait | **NOT_APPROVED** | 24.33/24.74 px candidate contact drift **not corrected** |

Do not label P-01 as fully PASS until those remaining gates are actually exercised on a single authoritative current Chapter I integration branch. This #487 descendant is the *historical native dock pilot*, not necessarily the latest playable revised Chapter I/hull/planet branch. Before production integration, diff this branch against the current Ionia-first revised runtime and preserve its scene/story/save ownership.

**Authority:** existing character locks, Ionia-first Chapter I hiring/test flight, post-splashdown Lyra arrival, and distinct innate Spirit/Earth/Water/Air/Fire story energies remain unchanged. Innate resonance never guarantees combat spells. No art, release or merge signoff.

## Native executed P-01A proof — 2026-10-27 local / 2026-10-28 UTC

**Exact implementation head:** `b6abd3768a940a24fd07ca0cf8ea71b5ad8fef3b`. All three [native Godot workflow #40623886417](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40623886417), [real OpenGL 960×640 capture #40623886478](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40623886478), and [repository smoke #40623886520](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40623886520) **PASS**. Native actual First Wake test emitted:

```text
FIRST_WAKE_CHARACTER_P01_ROUTE: native First Wake scene; 400.0px; four directions; six phases; unchanged Ender and Ionia
FIRST_WAKE_CHARACTER_P01_OBSTACLE: contact_ticks>0 stopped_y=449.00
FIRST_WAKE_CHARACTER_P01_PASS: integrated visual fixture real First Wake 2D dock, F6 reversible, no actor/dialogue authority changes
FIRST_WAKE_CHARACTER_P01_TERRAIN_2_5D=NOT_TESTED
FIRST_WAKE_CHARACTER_P01_SAVE_PARTY_STATE=NO_SAVE_OR_PARTY_IMPLEMENTATION_IN_THIS_PILOT
```

Authentic native Godot default-OFF, moving-SOUTH, moving-WEST, restored-OFF 960×640 PNG SHA-256 values:

| Mode | SHA-256 |
| --- | --- |
| OFF | `45b133d1131ec275466795158099f8a3b722f0cb6f710b001a167a65f30ef566` |
| SOUTH moving | `f3374468cc586e18d91bef9904dfb6159cc31eecd7e933e714b0c4bcf7846589` |
| WEST moving | `84db877003827c1a49a31391dddaf77576796d59c931a747843f12c884487603` |
| RESTORED OFF | `45b133d1131ec275466795158099f8a3b722f0cb6f710b001a167a65f30ef566` |

The OFF and RESTORED frames are **pixel-identical**, and moving frames visibly show distinct original Lyra art. Native 350×295 cropped JPEG previews were inspected from the private workflow logs; full PNG frames were retained runner-side. This proves an **actual in-scene native render and reversible physical fixture**, not approved art, permanent deck collision, playable recruitment, equipment/battle/portrait continuity, saved party integrity (no such system exists in this pilot), installed Windows behavior or creator acceptance.

**Next independent gate:** move this opt-in renderer into the current Ionia-first revised Chapter I branch (after exact-head conflict resolution), test against actual production floor/deck topology and scene-state persistence, and capture at required logical/presentation resolutions; keep class, energy, inventory, party and story state read-only. **P-01A executed; broader P-01 remains NOT COMPLETE.**
