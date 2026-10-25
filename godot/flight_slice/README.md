# Native Godot flight-scale art study — non-canon

Self-contained **Godot 4.7.2** Compatibility project at `godot/flight_slice/`. It is a **separate flight-scale visual vertical slice**, not the private v0.8.0 project, not a port of hidden Moon Bridge gates, and not a change to Chapter I. Open `project.godot` with Godot 4.7.2 and run F6/F5. No third-party assets, costs, online services, or JavaScript runtime.

## Delivered experiment

- One continuous, deterministic coastal shelf → eroded shoreline → treeline → highlands / alpine study, with the same height sampler at LOD boundaries, downward skirts, near/far LOD hysteresis and bounded 64-tile geometry. Camera-relative visibility is a **local-demo approximation**, not the planet's true geodesic horizon.
- Instanced five-sided evergreen silhouettes, a coastal beacon/dock and an inland hamlet for scale cues. All landmarks and geography are provisional and may not be used as canon.
- Independently modelled, multi-part airship **silhouette placeholder** (membrane wings, spars, keel, cabin, restrained deck light). It is not approved Dragonfly asset work.
- Teal/silver fogged sky and warm low-angle lighting, cinematic follow/framing option at **960×640**. C swaps framing, P pauses the timed flyover, R resets and M suppresses ship idle oscillation. This is an automatic flyover **art study**, not manual planetary navigation.
- No secrets: no lunar alignment math, clues, gate logic, inaccessible route geometries, save paths or production character assets.

## How to verify

1. In the project: run `godot --headless --editor --path godot/flight_slice --quit` to check import/GDScript parse on a machine with Godot.
2. Run `godot --headless --path godot/flight_slice --script res://tests/test_slice.gd` for deterministic native tests.
3. Capture native frames from the fixed 960×640 project on Windows/Compatibility and Windows/Forward+ **only if the project is migrated/renderer-configured separately**; this project defaults to Compatibility. Compare coast, beacon, treeline, highland, and ship readability at matching viewpoints.
4. Diagnostic on Windows: `godot --path godot/flight_slice -- --benchmark` records 120 warmups and 1,000 MAIN-LOOP interval samples to `user://flight_slice_intervals.json`. This does **not** measure GPU completion or VRAM. Independent GPU capture/driver tooling is required for 30-FPS acceptance. Record OS, GPU/driver, actual renderer, resolution, VSync, power mode, build/manifest and screenshots for each run.

## Integration boundaries / known weaknesses

- The terrain tiles are *local tangent-plane geometry*, not yet connected to #349's cubed-sphere address/visibility planner. Production must accept tile keys through an explicit native adapter, bind only viewer-authorized discoveries and stream real meshes without swapping historical `x,y` saves. Never infer canonical radius.
- Mesh skirts mask differing-LOD cracks, but **no native captured evidence for pop-in, skirt occlusion, normals, horizon or texture-filtering** has been obtained from this project. No collision, terrain contact safety, planet-to-local seam, biome climate model, manual piloting, cinematic sound pass, final animation or target performance claim.
- The bridge route implementation remains owner-private in v0.8.0. Merge requires separate source integration, artist approval, actual target Windows GPU benchmarks and gameplay/canon gate review. The 4.7.2 tests in this new project are **unverified until CI or a native engine run completes**.

## Review targets

At 960×640, verify five captures: over open water facing coast; ship beside beacon; sail over forest; highland ridge with ship silhouette; and mixed-LOD transition while traversing the coastline. Assess ship legibility, biome identity without HUD, horizon fill, silhouette consistency, frame pacing and pop-in. Creator determines whether this direction can be admitted; the prototype itself cannot grant that approval.

Reference: #349 geometry/addressing; #363 independent visual direction; #369 native v0.8.0 observational evidence. All three remain preserved.
