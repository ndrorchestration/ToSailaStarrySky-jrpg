# First Wake — layered coast local visual review (2026-10-28)

**Status:** locally implemented, unrendered, not art-approved, not merged or released.

## Source
- Parent: PR #564 exact head `701eac388cf8e7899ca753dd8a8e3ce502ce65bf`.
- Isolated local branch: `visual/first-wake-layered-coast-review-20261028`.
- Modified: `godot/scripts/first_wake_flight_water_review.gd` only.

## Change
Replace one uniform coastal polygon with three depth-separated land silhouettes, authored distant quay roofline, a few lit windows and shoreline glints. All geometry is decorative `Node2D._draw` work in the existing 960×640 First Wake scene. The existing tidal shader and ship renderer are retained.

## Strictly unchanged
The `SURFACE_Y`, 144×34 ship collider, `Area2D` water and berth sensors, buoyancy, launch/settle sequencing, dialogue, saves, party admission, transformations and release safeguards.

## QA boundary
- Git `diff --check`: clean.
- Godot 4.7.2 native import: **PASS**.
- Native visual rig test: **PASS**.
- Native splashdown/berth/family contract: **PASS** with test-only physics-frame waits.
- Native main entry to Chapter I water/reunion/story test: **PASS** with same test-only physics-frame waits.
- Native dialogue scene test: **PASS**.
- Authentic native OpenGL image capture of updated coastline: **PASS**, six genuine 960x640 Godot PNG frames produced by `capture_first_wake_recovery_review.gd` (afloat, approach, contact, secured, family, Lyra joined). Existing image-distinctness assertions passed; artistic inspection still pending.
- Capture waits for berth contact and secured-state now use `physics_frame` instead of render frames to avoid headless timing dependence.
- Runtime gameplay mechanics were not changed by timing corrections.
- Cinematic/art sign-off: **pending authentic Godot screenshot comparison**.
- Windows installer/Defender custody: **blocked independently**.
- No GitHub branch push or PR merge performed.

## Next review
Run the existing native Godot scene/visual capture workflow on this branch, compare waterborne and berth images at native 960×640, check readability around the ship and HUD, and review coast silhouettes for excessive repetition. Only after passing those checks consider integrating with PR #564 or a distinct draft PR.
