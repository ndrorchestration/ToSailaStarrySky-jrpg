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
