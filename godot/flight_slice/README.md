# Native Godot flight-scale art study — non-canon

Self-contained **Godot 4.7.2** Compatibility project at `godot/flight_slice/`. It is a **separate flight-scale visual vertical slice**, not the private v0.8.0 project, not a port of hidden Moon Bridge gates, and not a change to Chapter I. Open `project.godot` with Godot 4.7.2 and run F6/F5. No third-party assets, costs, online services, or JavaScript runtime.

## Godot physics-confirmed test-field touchdown (experimental) — 2026-10-26

**Scope:** This isolated, noncanonical GDScript flight study now uses an actual `StaticBody3D` with a `ConcavePolygonShape3D` triangle shape over the same small provisional landing rectangle, constructed from the scene's authoritative `TerrainStudy.sample_height`. The collider has **792 triangles** on collision layer 2 and is queried through `PhysicsDirectSpaceState3D.intersect_ray` from `_physics_process`; pressing **T** only queues a request. The first descent cannot start until a real native collider hit, correct collider identity, upward normal, low slope, allowed dry field, and a sufficiently close collider/sampler height **all agree**. An absent or disabled collider fails closed rather than falling back to an analytic height guess.

**Not production physics:** Collision is a **static terrain query**, not a dynamically simulated Dragonfly, body-to-body collision response, landing-gear suspension, collision with trees/buildings, arbitrary-planet landings, geodesic flight or a shipped save/mission system. The visual landing feet and bounded interpolation remain approximations. No other terrain tiles gain collision from this isolated fixture.

The native headless test checks the real shape, correct collision mask, ray-confirmed admission, and rejects an unregistered/disabled collision layer. The graphical CI also verifies that the sixth native 960×640 touchdown capture was generated after the real physics hit. Source must pass **exact-head** Godot 4.7.2 CI before this section can be cited as verified.

### Continuous support and return to hover — 2026-10-26

**IMPLEMENTED, experimental:** Descent and landed support now share the native physics tick. Each tick must reconfirm the intended terrain body's ray hit, upward normal, and unchanged contact height before landing motion advances. Losing the layer, shape or body, or moving the support height by more than 0.02 scene units, cancels touchdown and enters `RECOVERING`. This bounded visual recovery holds horizontal position and climbs to terrain clearance; it never moves downward to a stale contact point. Pause holds the position; resuming checks contact before descent continues. A fresh **T** request is needed after recovery returns to `FLYING`.

The 0.02 continuity tolerance is deliberately tighter than the 0.12 initial collider/sampler tolerance: a hit can agree approximately with the sampler yet no longer support the height accepted earlier. This remains one center ray over the provisional field, not a hull/landing-foot footprint sweep, force simulation or moving-platform support.

Run `godot --headless --path godot/flight_slice --script res://tests/test_contact_lifecycle.gd` for native support-loss/recovery checks. The touchdown tests now wait until physics callbacks finish before inspecting the result; merely awaiting `SceneTree.physics_frame` does not establish that a queued request was consumed. See [Godot's signal ordering](https://docs.godotengine.org/en/stable/classes/class_scenetree.html#class-scenetree-signal-physics-frame) and [physics-query timing](https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html).

**OPEN:** body/gear collision response, footprint and obstacle clearance, global terrain integration, target Windows hardware verification, creator visual/player acceptance. The original flyover, 64 visual tiles and 792 collision triangles remain the comparison baseline.

## Bounded visual touchdown and takeoff — 2026-10-26

In the noncanon **Godot 4.7.2 / GDScript flight-scale study only**, switch to F pilot mode and fly over an open temporary grass test field roughly at local planar `x=6…15, z=-18…-7`; press **T** to request a visually staged touchdown. Unsafe requests are denied if outside that field, over water, on ground steeper than the sampled local slope limit, while paused, or during a previous transition. Movement and steering are locked during the descent, landed and takeoff states. Press **T** again after the landing finishes to ascend to flight clearance and resume piloting. Provisional landing feet become visible while descending/landed/taking off and retract once safely airborne. F or R clears the transient state and restores the original automatic 37-second flyover.

**Important:** This is a *native-raycast-confirmed visual contact fixture*, **not actual 3D collision response, rigidbody physics, safe landing-zone gameplay, landing near trees/buildings, player/save progression, canonical geography or an approved Dragonfly animation**. The field, slope and single-height contact parameters are demonstration constants, not world-lore facts. No airship dynamics or planet→Moon gameplay has been certified.

Verification: `godot --headless --path godot/flight_slice --script res://tests/test_touchdown.gd` checks unsafe water/field/slope rejection, timed descent and takeoff, floor height, input lock/pause, native control-key integration, visual landing-feet toggles and 64-tile preservation. The real Compatibility framebuffer capture now includes `touchdown.png` as **sixth** reference cut; only actual native captured imagery counts as screenshot evidence. Creator art and Windows GPU/physical-controller acceptance remain separate.

## Opt-in manual Dragonfly flight study — 2026-10-26

**Still an independent NONCANON local planar art prototype, not Dragonfly production flight physics or a global planetary flight system.** The default scripted 37-second coast-to-highland cinematic flyover remains unchanged for comparison and original screenshots.

Controls while running the local Godot scene:

- **F** toggles between automatic flyover and manual pilot, preserving existing cinematic capture behavior.
- **W / S** move forward/backward; **A / D** turn; **E / Q** ascend/descend.
- **C** selects cinematic versus follow-camera framing in automatic mode; manual pilot uses a directional chase camera.
- **P** pauses both scene clock and manual movement; **M** suppresses animation bob while preserving the vessel's chosen heading.
- **R** resets to the automatic route at the beginning, **V** changes presentation detail and **H** hides/shows the accessibility-oriented control/clearance HUD.

The new `flight_controller.gd` computes deterministic local planar travel and steers within a limited prototype area. It clamps excessive frame delta to avoid large position jumps, maintains at least 5 local meters above the same terrain sampler as the native meshes (or sea), and limits world altitude and flight domain. It deliberately **does not** claim physics/collision response, obstacle avoidance, live terrain-streaming, geodesic globe coordinates, altitude bands, landing/takeoff, save persistence, multiplayer, user input-remapping, real Dragonfly canon, hidden celestial routes, or first-chapter story acceptance.

Native verification in `res://tests/test_manual_flight.gd` covers pure movement/climb/turn/bounds/clearance math, actual opt-in key toggle, native ship movement, pause/reduced-motion/heading continuity, 64-chunk budget, and automatic-mode return. The art-capture test also saves a **fifth** real Compatibility frame `manual-pilot.png` at a known controlled flight pose; this is a visual QA reference, not a synthetic mockup or GPU FPS result.

**Authority correction:** Current published public main `AGENTS.md` specifies Godot 4.7.2 and **GDScript for forward gameplay**. The draft C# cubed-sphere work (#368/#375) is an isolated verified numeric-engine experiment, not an approved entire-game language migration. Older lines in this document referring to a product C# mandate are retained as historical project-study context but are not present-day authority.

## Delivered experiment

- One continuous, deterministic coastal shelf → eroded shoreline → treeline → highlands / alpine study, with the same height sampler at LOD boundaries, downward skirts, near/far LOD hysteresis and bounded 64-tile geometry. Camera-relative visibility is a **local-demo approximation**, not the planet's true geodesic horizon.
- Instanced five-sided evergreen silhouettes, a coastal beacon/dock and an inland hamlet for scale cues. All landmarks and geography are provisional and may not be used as canon.
- Independently modelled, multi-part airship **silhouette placeholder** (membrane wings, spars, keel, cabin, restrained deck light). It is not approved Dragonfly asset work.
- Teal/silver fogged sky and warm low-angle lighting, cinematic follow/framing option at **960×640**. C swaps framing, P pauses the timed flyover, R resets and M suppresses ship idle oscillation. V changes material detail and H hides the study overlay. This is an automatic flyover **art study**, not manual planetary navigation.
- No secrets: no lunar alignment math, clues, gate logic, inaccessible route geometries, save paths or production character assets.

## How to verify

1. In the project: run `godot --headless --editor --path godot/flight_slice --quit` to check import/GDScript parse on a machine with Godot.
2. Run `godot --headless --path godot/flight_slice --script res://tests/test_slice.gd` for deterministic native tests.
3. Capture native frames from the fixed 960×640 project on Windows/Compatibility and Windows/Forward+ **only if the project is migrated/renderer-configured separately**; this project defaults to Compatibility. Compare coast, beacon, treeline, highland, and ship readability at matching viewpoints.
4. Diagnostic on Windows: `godot --path godot/flight_slice -- --benchmark` records 120 warmups and 1,000 MAIN-LOOP interval samples to `user://flight_slice_intervals.json`. This does **not** measure GPU completion or VRAM. Independent GPU capture/driver tooling is required for 30-FPS acceptance. Record OS, GPU/driver, actual renderer, resolution, VSync, power mode, build/manifest and screenshots for each run.

## Integration boundaries / known weaknesses

- The terrain tiles are *local tangent-plane geometry*, not yet connected to #349's cubed-sphere address/visibility planner. Production must accept tile keys through an explicit native adapter, bind only viewer-authorized discoveries and stream real meshes without swapping historical `x,y` saves. Never infer canonical radius.
- Mesh skirts mask differing-LOD cracks, but the captures do **not** prove seamless transitions or conceal every LOD/skirt artifact. No collision, terrain contact safety, planet-to-local seam, biome climate model, manual piloting, cinematic sound pass, final animation or target performance claim.
- The bridge route implementation remains owner-private in v0.8.0. Merge requires separate source integration, artist approval, actual target Windows GPU benchmarks and gameplay/canon gate review. The original 94-check suite and added presentation contracts passed locally with official Godot 4.7.2; hosted exact-head checks are separate.

## Review targets

At 960×640, verify five captures: over open water facing coast; ship beside beacon; sail over forest; highland ridge with ship silhouette; and mixed-LOD transition while traversing the coastline. Assess ship legibility, biome identity without HUD, horizon fill, silhouette consistency, frame pacing and pop-in. Creator determines whether this direction can be admitted; the prototype itself cannot grant that approval.

Reference: #349 geometry/addressing; #363 independent visual direction; #369 native v0.8.0 observational evidence. All three remain preserved.


## Atmosphere/material continuation — 2026-10-25

The separate `visuals.gd` adapter adds a directional warm sky, procedural cloud strata, depth-colored water with foam, slope/height-based rock and snow, and layered conifer crowns. It preserves the existing height sampler, 64-tile budget, flight route and ship geometry. The water's bounded 256×256 floating-point depth field is baked from that same sampler. An 8×8 mask follows actual tile visibility and fades surf at the finite terrain boundary. These are stylized materials and layered sky clouds, **not volumetric atmosphere, physical ocean simulation or pixel-authored final assets**.

All effect animation uses the scene's explicit clock. P holds the route and effect clocks; the inherited follow camera may finish settling briefly. M freezes effect/ship oscillation at a reference state while the flyover continues. V toggles low/high material detail; it does not change terrain LOD or content. H hides the technical overlay. Launch with `-- --baseline` to compare the original PR #370 presentation at the same route/poses; this is a temporary review fixture.

Native verification commands (replace `godot` with the official 4.7.2 executable):

```sh
godot --headless --path godot/flight_slice --script res://tests/test_slice.gd
godot --headless --path godot/flight_slice --script res://tests/test_visuals.gd
godot --path godot/flight_slice --script res://tests/capture_study.gd
godot --path godot/flight_slice --script res://tests/capture_study.gd -- --baseline
godot --path godot/flight_slice --write-movie flight.avi --fixed-fps 30 --script res://tests/capture_movie.gd
godot --path godot/flight_slice --script res://tests/profile_visuals.gd
```

Capture checks compile the actual shaders, save matched coast/forest/highland frames and a low-detail coast frame, then compare shader motion, frozen state and reduced motion. Profiling accepts `-- --baseline` or `-- --low`; its 120 samples per view measure wall intervals between frame callbacks, **not GPU timestamps or accepted target FPS**. The 24-second movie uses fixed-step capture; smooth encoded playback is not real-time performance proof.

C# remains the recorded product language in issue #366. This branch extends the isolated GDScript **art study only**. Neither the original studies nor this material adapter are silently promoted into the product. Creator visual approval, C# integration, authored assets, planetary continuity, target-hardware profiling and gameplay remain open.
