# Aureate Wake — neutral four-wing hinge preview and native evidence

**2026-10-27 / REVERSIBLE ART STUDY / NOT APPROVED GAMEPLAY OR FINAL ASSETS**

## Source and dependency
- Forked only from draft [#432](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/432) frozen head `b65c9ca1114c2df35193df9e0c598b8705b305d8`, with no edits to that review branch.
- Branch: `study/aureate-wake-neutral-wing-hinges-20261027`; PR base must be #432's head branch to keep the code diff auditable.
- The new changes are public-safe **articulation fundamentals only**: wing rig roots, a 0–15° optional preview, native assertions, matched GL evidence.
- The inherited Aureate Wake ship, terrain, weather/magic transitions, 1.8-second fades, pilot/landing/contact systems and scene controls retain their original authority.

## Implementation
- In `ship.gd`, retain four direct child `WingRig_PortFore`, `WingRig_PortAft`, `WingRig_StarboardFore`, `WingRig_StarboardAft` nodes and their original `Membrane_*`, `BrassRibBundle_*`, `DarkRibBundle_*`, `GlassRibBundle_*` children.
- Move each rig's local origin to the membrane's original first/root vertex and apply equal/opposite translations to its four child MeshInstance3D nodes. In the default pose, mesh transforms and rendered pixels are intended to remain unchanged.
- `set_wing_review_sweep(progress)`: opt-in, no automatic activation or new player control. Accepted finite fraction is clamped to [0,1] and produces a symmetrical 15° aftward yaw. Invalid numbers reject without mutating pose.
- Existing procedural wing flex remains an independent `rotation.z` controlled by `set_motion()` and suppressed with M reduced-motion. The preview yaw uses a separate axis and must not change the whole-ship transform, flight controller or collision tests.

## Test boundaries and acceptance
1. **Native contract** `tests/test_wing_hinge_review.gd`: checks pivot roots, original direct-child names, original neutral geometry, midpoint/full sweep, NaN rejection, reversible return to baseline, reduced-motion flex behavior, hull identity and 64 terrain tiles.
2. **GL A/B** `tests/capture_wing_hinge_review.gd`: two actual 960×640 Compatibility software-OpenGL frames at same ship/camera/time/weather: `neutral.png` versus `gentle-sweep.png`. Requires same camera and ship transforms, with nonzero image difference. Pixel difference is not an artistic acceptance measure.
3. **Full inherited native CI**: world terrain, atmospheric fades, six original ship captures, flight/touchdown/contact, weather captures, 96-frame rendered sweeps and smoke must all pass on the exact combined head.
4. **Human review**: no wing-to-wing / hull / forward-deck collision, transparent membrane sorting, camera occlusion, hinge continuity, mechanical believability or final proportion issues. A separate [foredeck study #452](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/452) must be reconciled and checked directly; this branch alone does **not** include #452's deck.
5. **Hardware**: production Windows Forward+/Compatibility GPU/VRAM, animation smoothness and in-game collision/occupancy remain unproven until their own tests. Software-renderer timings are only diagnostics.

## Explicit holds
- No automatic in-game wing reconfiguration, no player skills or route authorization, no save mutation, no story/canon promotion, no source migration or commercial/game build.
- No merging without exact-head native CI, screenshot inspection, subsequent deck-clearance review and creator approval.
- All nonpublic narrative mechanics remain in creator-controlled private records, not public code or evidence.
