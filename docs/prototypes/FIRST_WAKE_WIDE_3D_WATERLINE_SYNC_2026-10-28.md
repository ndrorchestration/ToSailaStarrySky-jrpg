# First Wake: wide 3D composition driven by real physical 2D waterline

**Date: 2026-10-28. Classification: prototype visual integration test, NOT approved art, world physics, completed Chapter I, or release.**

## Exact foundations

This draft builds on [#525](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/525) exact `32eb4cc221c0573d4e05cf8662f46435f63a7e7d`, itself stacked on [#492](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/492) and the native [#447](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/447) real local flight/sea-contact preview. #525 passes actual First Wake Godot scene/GL tests with the unmodified original procedural Aureate Wake hull+four wings from [#486](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/486). Source 3D art is an experimental authored ship **not** creator-accepted geometry or collision.

## Bounded improvement

- The isolated playable **job flyer's legitimate preflight path** now uses an opt-in wide `960×442` Godot `SubViewport` composition positioned directly between the 960×103 upper HUD and 960×95 bottom prompt band. No new input or canon; preflight is still blocked until Ionia joins and the three original inspection items complete.
- **Only actual native `RigidBody2D` height** drives the visual 3D hull vertical offset. At sea-surface reference `SURFACE_Y=410` and a study hull center reference 14 pixels above the water sensor, `visual_altitude_y = (410 - 14 - physical_body_y) × 0.035` local 3D units. The visual water `PlaneMesh` stays at `y=-0.89`. The existing bow/wing/stern camera orbits relative to the *rendered* ship's world position, so the ship stays framed while ocean perspective changes with actual descent. This is a **local image-space scaling study** and does not claim actual physical draft/metric airship dimensions or hydrostatics.
- When the wide stage is active, hide **only the duplicated 2D hull and 2D wing Polygon2D sprites** beneath the live 3D ship. The real `RigidBody2D`, its `CollisionShape2D`, the `Area2D` water sensor and the actual buoyancy FSM remain untouched and keep running invisibly. Contact and stable flotation—not a camera frame—are the **sole** waterborne authority.
- The existing **355×200 source-ship review inset + original 2D polygons** can be instantly restored with `set_cinematic_wide_mode(false)` or by setting `use_wide_cinematic_review=false` on the optional job-preview scene. No scene-save mutations. Nonfinite spoofed body coordinates are rejected. The shot/preset handoff is still read-only; first-flight storm is not asserted by default.
- The entire 3D stage is still the **source-original ship plus simple source-made water, light and sky**. It has no actual bathymetry, shoreline, 3D ship collider, wave buoyancy, approved geodesic helm, terrain geometry or original weather microtexture shaders. A 2D physical ocean surface and 3D preview plane are *not interchangeable*.

## Native evidence requirements

- `godot/tests/first_wake_wide_composition_test.gd`: real Chapter I preflight → native 3D World3D + 4-wing hull; checks 960×442 view/hud and collision shape retained; validates physical pixel-to-3D altitude, nonfinite rejection, accessible fallback, physics body and story unchanged by toggles; advances real 2D lift, engine warning, commanded descent, true Area2D contact and sustained flotation; never recruits Lyra/Talen early.
- `godot/tests/capture_first_wake_wide_composition.gd`: **six native Godot OpenGL frames** (preflight bow, ascent wing, engine warning stern, controlled descent bow, physically afloat stern, actual 2D fallback). Upper/lower HUD remain legible and no fake waterborne is accepted. 960×640 source PNGs and checksums are runner-local per existing visual review workflow; 480×320 preview JPEGs are bounded to three safe, review-only scenes in logs.
- Existing native #525 contract and five-frame 3D scene captures plus the full Chapter I save, combat/party, Ionia sprite, and Defender host security CI remain mandatory.
- Exact combined-head native runs, scene captures, and actual human visual inspection are required; separate #525 successes **do not** prove this new wide composition.

## Production admission still open

No claim of final cinematic polish, whole-frame depth continuity, 3D ocean physics or a coherent 2.5D shoreline transition. Need approved visual source/camera/screen staging; test the actual sea-horizon and ship-scale visuals at 960×640; accessible reduced-motion & lighting controls with genuine before/after; full shoreline, foam, ship geodesic helm and signature song/audio source; target GPU/performance; exact Windows security preflight and uncoached Chapter I player acceptance. Do not merge or release without explicit authorization. Preserve Five Lights, character joining order and restricted lunar material outside public spoiler surfaces.
