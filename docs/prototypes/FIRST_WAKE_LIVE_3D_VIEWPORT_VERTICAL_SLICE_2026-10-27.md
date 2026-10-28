# First Wake — native 3D Aureate Wake inside an actual Chapter I flight scene

**2026-10-27 · noncanonical review-only Godot 4.7.2 · no art/canon/release approval.**

## Baseline and provenance

This branch is stacked on [#492](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/492) exact `2b9626220894a352925dfc267196f11211073aea`, whose native Ionia-first Phase→3D-shot **read-only descriptor** and actual local 2D water-contact / flotation tests passed. It copies the *exact original source bytes* of `godot/flight_slice/ship.gd` from [#486](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/486) exact `36a13d6063235ed2114bb25d2a2cc61d1d4c9f22`, Git blob `2cbd1f0c11bd79fb6313cf3131d5bac4a83a5f4e`, to `godot/scripts/prototypes/aureate_wake_source_ship_3d.gd`. This is a source-controlled **original procedural 3D mesh**, not a still/screenshot, stock material, or approved final art.

## What is actually running

- The isolated playable [#447](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/447) First Wake job/engineering preview opts into a new `first_wake_3d_inset.gd` **genuine native Godot SubViewport with its own World3D, Camera3D and Node3D**, displayed in a 400×225 portion of the existing in-game 960×640 UI during the opt-in local 2D flight/water review.
- It actually instantiates the original PR #486 procedural Aureate Wake, including its real lofted LongHull and four separate 3D wing rigs. The 3D camera changes in place on real 2D preview's `awaiting_launch`, `ascent`, `warning`, `descent`, `waterborne` states using the earlier source-locked handoff's bow/wing/stern shot identities. No fullscreen cinematic, video asset, new input action or re-authored narrative.
- Its **visual-only** ocean is a deliberately simple material `PlaneMesh`; light and sky are small local Godot `WorldEnvironment` and `DirectionalLight3D`, **not** the full verified #486 depth/foam/microtexture/weather shader scene. Do not imply terrain, storm magic, globe flight or oceangoing seaworthiness have been ported. The storm-night look remains experimental and OFF in player preview by default. Reduced motion and low detail are explicit preview controls, but the latter does not yet constitute full source-scene LOD.
- The unchanged **real `RigidBody2D` / `Area2D` water entry / buoyancy settle / story FSM** exclusively determine whether the ship is waterborne. The 3D mesh and plane have *no collision*, scene authority, reactor/fuel knowledge, active-party changes, save mutations or ability to force story gates. Early Lyra and Talen remain barred.

## Native testing

- `godot/tests/first_wake_3d_inset_scene_test.gd`: uses the **actual job preview path** (accept Ionia + 3 engineering inspections), verifies genuine live `SubViewport`, 3D mesh, four wings, active `Camera3D`, reference-bound shot selection at actual scene phases, fail-closed forged descriptor, 2D hull unchanged by grade/quality selection, native water contact and settled float, no premature party join, no production ocean claim.
- `godot/tests/capture_first_wake_3d_inset.gd`: real Compatibility/OpenGL **five native 960×640 screenshots** in the combined playable scene at preflight/bow, ascent/wing, warning/stern, descent/bow, waterborne/stern. Measures panel-only differences and requires successful actual physics contact before final render. CI logs screenshot SHA-256; historical native-capture workflow keeps original full PNGs as runner-local because artifact quotas/rights are separate. Do not claim screenshots downloadable solely because a workflow ran.
- Add exact-head tests to both the native First Wake pilot workflow and separate GL render review without removing existing Chapter I, art, Windows-security or smoke checks.

## Admission requirements still open

1. Both exact-head native CI and OpenGL screenshot-capture workflow must pass. For visual art approval, human must inspect genuine frames at source size; numeric screenshot deltas are insufficient.
2. Full-screen coherent 2.5D compositing, properly matching 2D hull to the 3D image, visual water behavior synchronized to native waterline, original #486 shader assets, dynamic weather and cinematic camera animation remain future tasks.
3. Native Chapter I player acceptance, target GPU/frame pacing/VRAM, original licensed source custody, creator-approved art (including geodesic bridge and living deck), localization and reduced-motion UX remain open. Real physical 3D ship collision and global/ocean physics are expressly NOT certified.
4. Windows exact QA preflight remains held if host Defender real-time protection is disabled. Never bypass to claim verification.
5. No merge, canon edits, secret moon route exposure or release.

**Vertical-slice definition:** an actual rendered 3D ship inset inside the Chapter I physics-driven flight scenario, not an already unified production flight/cinematic pipeline.
