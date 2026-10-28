# Native Godot flight-scale art study — non-canon

Self-contained **Godot 4.7.2** Compatibility project at `godot/flight_slice/`. It is a **separate flight-scale visual vertical slice**, not the private v0.8.0 project, not a port of hidden Moon Bridge gates, and not a change to Chapter I. Open `project.godot` with Godot 4.7.2 and run F6/F5. No third-party assets, costs, online services, or JavaScript runtime.

## Fine-terrain highland geometry study — 2026-10-27

**Draft-only, noncanonical visual study.** Increase the isolated native terrain slice's detailed grid from 18 to 24 quads per 24 m tile, retaining 6 coarse divisions, 64 terrain tiles, the same native terrain sampler, exact shoreline and touchdown heights, visual-only planet-independent coordinate system and unchanged collider. Divisibility by six retains shared coarse edge breakpoints, while the existing deterministic stitcher remains the single LOD seam owner. The increased mesh resolution samples upper-mountain arêtes, saddles and drainage cuts rather than replacing them with background cards; the effect may be more pronounced near the highland skyline than at sea level.

**Tradeoff:** one high-detail tile contains 3,456 top triangle vertices plus 576 skirt vertices (4,032 total), versus 1,944 top and 432 skirt vertices (2,376 previously), a 69.7% increase per selected high tile. Mesh startup generation, CPU terrain sampler cost, GPU vertex processing, LOD promotion and top-surface normal interpolation require native benchmarks and real frame captures. The existing low-detail tier, soft-snow material, forest and geology accents, physics fixture, and game/story state remain unchanged. Do not assert performance improvement or visual acceptance without matched captures and comparable target-hardware measurements.

## Alpine arêtes and drainage relief — 2026-10-27

**Isolated, noncanonical landform candidate, not a production planetary terrain change.** This pass sculpts the existing **authoritative terrain heightfield** instead of overlaying disconnected mountain cards. `alpine_arrete_relief(x,z)` adds up to 1.85 local units of signed upper-mountain crest and gully variation through smoothly faded, deterministic oblique wave envelopes. It is zero for all `x <= 57` (including coast, forest, hamlet and native landing physics field), and fades out by `x = 100`. The pre-existing `_sample_height_before_arretes` sampler preserves the prior highland fixtures, and the only rendering height authority remains `sample_height`: both tile LOD meshes, normals, biome assignment, instanced boulders, flight altitude, and the isolated landing fixture read the same updated terrain heights. No scripted backdrop panels, shaders, textures, additional draw calls, global biome rules, procedural seed changes, third-party assets or game progression.

**Risks and validation:** Changing highland elevations is more consequential than a material tweak. Native regression coverage compares inherited historical height fixtures before applying the new relief, exact unchanged lower-world samples, finite and bounded positive/negative offsets, upper-slope continuity, shared high/low LOD edge agreement, landform-derived placement and the existing touchdown collision invariants. Exact-head native captured highland views must then establish whether genuine 3D terrain surfaces look more convincing, without unnatural ripples or smearing. This trial is **not** a streamed spherical terrain engine or creator-approved canon geography; target-hardware GPU frame times and broad playable traversal are still open.

## Highland snow wind-scour material study — 2026-10-27

**Noncanonical shader-only candidate.** The existing terrain shader retains exactly the same sampled height, cliff slope, biome thresholds, shoreline, snowline and global clock. In high detail, a single additional anisotropic noise lookup subtly exposes existing rock tint through snow on windward slopes, with restrained frost color variation. This is surface coloration, **not** real erosion, volumetric weather, new collision or a new terrain generator. The **V** low-detail switch removes this additional shader branch while preserving all geometry and flight behavior. The baseline path still uses its separate existing material for controlled comparison.

Validation requires exact-head Godot 4.7.2 shader import, native presentation tests and matched highland native rendered screenshots. Quality claims must be based on visual inspection: reject dirty-looking snow, muddy patches or obvious tiled noise. Frame-time/perceptual results on target hardware are not established by software GL rendering.

## Coastal stones and alpine talus geometry study — 2026-10-27

**Isolated draft visual layer, not canonical geology.** Two low-detail, instanced geology groups (`ShorelineStones` and `AlpineTalus`) use a **single shared custom nine-sided faceted mesh** and separate subdued non-emissive minerals. Coastal stones are confined to exposed sand/grass close to the existing procedural shoreline and avoid the dock; talus is confined to existing alpine/summit biomes and avoids steep sampling gradients. Small deterministic low-frequency placement envelopes leave natural gaps in the shoreline and group flatter, less conspicuous talus along upper slopes, as revised after native capture review. Placement uses existing deterministic hash/height/biome functions with no physics bodies, level gates, save state, navigation or elevation edits. No third-party textures/assets, transparent materials, particles or additional lights.

The standard art-study presentation enables the accents; baseline and reduced-detail mode leave them hidden. No motion is applied to rocks. The native `tests/test_visuals.gd` checks separate instance budgets, shared mesh, material wetness, original terrain grounding, biome restriction and safe-field exclusions. Intended for small-scale coastal/weathered-rock reading; **not** full cliff sculpting, a planet-wide erosion pipeline, collision-safe flythroughs or a production biome atlas. Native render capture/creator approval and target GPU costs remain independent criteria.

## Asymmetric broadleaf silhouette experiment — 2026-10-27

**Draft visual option, not final species or canon:** The three large, rounded, repeating leaf masses introduced in #404 are replaced in this stacked study by seven smaller, overlapping irregular masses. They remain **one indexed source mesh copied into one shared combined crown mesh**, instanced at the same broadleaf positions and tree heights. The study tests crown vertex and shape budget and preserves the existing shared shader/reduced-motion animation. Native image inspection is required to determine whether the additional detail actually makes trees read as more organic rather than as a cluster of small spheres. No physics, asset imports, gameplay or authoritative world biome logic changes.

## Deterministic forest-floor detail study — 2026-10-27

**Proposed visual iteration, not accepted final art.** The optional `GroundUnderstory` layer adds terrain-grounded, small fern/grass silhouettes in the forest and limited grassland. Positions are reproducible from the same static scene sampler, biome predicate, and local steep-slope limit; the temporary hamlet and native touchdown field are excluded. Seven two-triangle fronds form one *opaque*, double-sided mesh instanced through a single `MultiMeshInstance3D`. The effect uses no external textures, noise downloads, particles, transparent overdraw, per-clump nodes, new point lights, or gameplay collision.

The material uses the existing scene clock. **M** suppresses wind displacement, and **V** toggles lower presentation detail by hiding this decorative layer entirely. The unchanged baseline path keeps it hidden. This is bounded local decoration only: no new planet-wide species distribution, canonical vegetation, exploration gate, global terrain, occlusion policy, or saved state. Visual density, color and readability need exact-head native captures and creator review. Performance on the target GPU is not yet measured; instancing does not prove a frame-time win.

Regression coverage in `tests/test_visuals.gd` checks CPU placement authority, vertex attributes, budget, biome and height grounding, landing-field exclusion, wind control, and the detail fallback. It does **not** by itself verify native frame pixels, lighting quality, or target-hardware performance.

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


## Authored in-engine cinematic shot director — 2026-10-27

**IMPLEMENTED CANDIDATE / noncanonical camera-only art pass.** In automatic cinematic framing (default, toggled with **C**), the 37-second local flyover now follows `cinematic_shot_rig.gd`: wide coastal departure (0–10.5 s), eased forest approach (10.5–13.5 s), intimate forest passage (13.5–24.5 s), eased transition to a broad highland reveal (24.5–27.5 s), then highland vista (27.5–37 s). Deliberate composition and 50–57-degree lenses are intended to reveal horizon, craft and vertical scale without frantic pans, zoom pulses or camera shake. The existing global 37 s loop discontinuity still exists and is **not** a seamless authored film edit.

This is not new geometry or footage: it reuses the real scene, existing materials, temporary noncanonical craft and existing terrain. A pure deterministic camera pose is derived from the current ship position and the established clock; no new movement authority, physics, save, quest or secret-world routes. **M** removes optional gentle camera drift alongside the established reduced-effect behavior; **C** restores the earlier stable 62-degree follow camera, and manual piloting retains its 62-degree navigation-first lens.

Native contract test: `godot --headless --path godot/flight_slice --script res://tests/test_cinematic_camera.gd`. Existing graphical CI captures three HUD-free real Godot frames at 9/23/34 seconds and preserves the six regression captures. Source correctness, actual screen composition, renderer performance, color grading and creator art approval are **separate gates**. Do not mislabel the native test field as a true globe, production Aureate Wake ship or complete story cinematic.


## Layered atmospheric depth — native cinematic study (2026-10-27)

**IMPLEMENTED CANDIDATE / NOT ART ACCEPTED.** In the existing `sky.gdshader` golden-hour render, high-quality mode now adds a second, broader low-horizon cloud bank with slow opposing drift, sun-facing edge tint and a thin, noise-broken cool haze layer. It remains an **angular sky impostor**, not true volumetric clouds, planetary curvature, orbital atmosphere or physically simulated weather. It uses the same shared `sun_direction` and externally provided `study_time` as the existing sky and ocean; no new time-of-day or world mechanics.

- Normal mode: `cloud_depth_strength = 1.0`, exposed as an art-review shader uniform. Existing upper cloud masses and wisps remain.
- Matched reference mode: shader uniform `cloud_depth_strength = 0.0` disables only the added distant bank/haze; all scene geometry, timestamps and camera poses remain identical.
- Low-quality mode: the additional bank/haze branch is skipped entirely to bound noise sampling. **M** still freezes the effect clock as before.
- Added native contract: `godot --headless --path godot/flight_slice --script res://tests/test_atmosphere_contract.gd`.
- Added actual OpenGL matched A/B reference: `godot --path godot/flight_slice --rendering-driver opengl3 --audio-driver Dummy --script res://tests/capture_atmosphere_pair.gd` (requires display or Xvfb). It captures `coast-dusk` and `highland-horizon`, each with reference/layered variants at exactly the same pose and clock. Subsampled pixel difference must exceed a bounded minimum in at least one composition. This verifies an **observable material delta only**, not aesthetic superiority.
- Existing nine native frame captures and six-image regression markers remain unchanged; all are still noncanonical test assets.

**Unresolved:** creator visual acceptance, atmospheric plausibility, temporal stability across a full-flight video, clouds obscuring focal objects, real GPU timing and VRAM. Later integration with terrain revisions #393–#399 requires deliberate ancestry reconciliation; none are silently cherry-picked into this camera/sky track. No Moon Bridge, celestial alignment or restricted lore is published.
