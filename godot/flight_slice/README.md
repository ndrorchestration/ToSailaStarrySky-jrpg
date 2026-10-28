# Native Godot flight-scale art study — non-canon

Self-contained **Godot 4.7.2** Compatibility project at `godot/flight_slice/`. It is a **separate flight-scale visual vertical slice**, not the private v0.8.0 project, not a port of hidden Moon Bridge gates, and not a change to Chapter I. Open `project.godot` with Godot 4.7.2 and run F6/F5. No third-party assets, costs, online services, or JavaScript runtime.

## Aureate Wake faceted-glass geodesic bridge — 2026-10-27

**Creator-proposed visual direction, not yet approved exact geometry or final canon:** Place the **navigation/helm bridge inside a panoramic geodesic glass dome**—a compact crystal observatory integrated with the dragonfly-inspired hull, *not* an oversized flying greenhouse. Preserve the separately exposed forward observation deck outside the dome.

Native image QA at the first successful head showed excessive lattice density and a visually oversized dome. A follow-up reduces the subdivision count, darkens/slims the frame and scales down the dome while keeping a genuine clipped icosphere, original glass panes, and the same story/collision boundaries.\n\nThe reversible `ship_geodesic_bridge.gd` study creates an actual **icosahedron subdivided once, clipped to an upper spherical cap**, with triangle-pane buffers, unique brass support edges batched into one native mesh, a brass base ring, and minimal warm/teal navigation instruments beneath the dome. The local shell is about 1.52 art-units wide and **does not establish metres**. The previous solid ivory cabin roof has been moved into a reduced aft fairing and three navigation vanes/repeating aft roof ribs are repositioned outside the main transparent viewpoint. New close-up captures are `evidence/ship-hero/geodesic-bridge-bow.png` and `geodesic-bridge-side.png`.

**Critical engineering boundaries:** The glazing is a **visual shading mesh only**, not glass with measured strength, structural safety, impact tolerance or a physical pressure envelope. All triangle edges, base anchoring, frame stress, open-deck boarding, windshield glare/night readability, interior seated eye lines and compatibility with the independently meter-mapped boarding study require creator review and later physical validation. In particular the dome's brass ring is a decorative complete band; the existing exterior hull and geodesic glass **do not yet have a walkable/closable hatch opening**. Do not use this visual study to imply early discovery of restricted ship functions or approve dangerous weather exposure.

## Experimental crew boarding threshold — October 27, 2026

**PROPOSAL / standalone physics study**, built on top of the public-safe deck in PR #452. Open `res://ship_boarding_interface.tscn` separately for the bow-to-cabin threshold proof; the main flight scene, landed-state logic, save files, and chapter story are unchanged.

- `ship_boarding_interface.gd` scales the existing foredeck art geometry by an explicit **2.5 study-metres per art-unit**, with its deck raised/lowered to a proposed `y=0` walk surface. This is **not a proven overall ship scale**; the separately authored 10.4 × 3.8 × 2.6 m interior envelope is intentionally NOT attached.
- Constructs a **short isolated forward cabin entry** with a physical `StaticBody3D` floor, side bulkhead pieces, visible lintel and a hinged physical door. The actual bow deck gets a collidable `ConcavePolygonShape3D` built from the *same* mesh triangle faces as the rendered platform; the cabin floor uses a measured `BoxShape3D`. Physics collision mask/layer 8 keeps the prototype separate from the 792-triangle landing test-field contract.
- A nominal **1.36 m × 1.96 m** crew doorway is proposed. Opening the hinged door clears the test passage; closing it should block a **1.74 m-high, 0.26 m-radius** actor capsule. `tests/test_ship_boarding.gd` verifies `PhysicsDirectSpaceState3D` down-rays across each side of the walking-floor join and shape-casts through the door in closed/open conditions. Passing tests demonstrate only **that isolated physical segment**, not whole-ship traversability or seal strength.
- Two actual **960×640 native Godot** images capture the open and closed panel under `evidence/ship-boarding/`. `tests/capture_ship_boarding.gd` is an offline review fixture with no HUD and no associated gameplay controls.

**Blocking quality findings:** Existing bow rails scale to **0.725 m** height in this explicit mapping, short of a 0.9 m design review target; they are still purely decorative, not collidable. The actual oval `UpperCabin` exterior is **solid and has no hatch cut-out**. The larger prior interior study has different proportions and cannot be assumed to fit the exterior. There is no cabin shell/collision/navmesh, watertight door rating, modeled egress, water handling, emergency overrides, or environment safety implementation. These remain explicit future integration gates. Keep unrevealed ship/plot capabilities in creator-controlled private lore, not in public source.

## Ordinary bow lookout visual study — 2026-10-27

Creator direction establishes an **ordinarily accessible forward open-air deck** on the compact Aureate Wake and authentic surface seaworthiness. This public-safe Godot geometry study adds `ship_foredeck.gd` as a standalone scene child mounted on the flight ship. It has a native upper-facing tapered platform, guardrails, bow crossrail, open rear crew threshold, and a review-only weather cover. Default is **open**. A translucent hood can be toggled visually but is **not** a watertight or pressure-rated enclosure.

`tests/test_slice.gd` asserts Godot winding, deck meshes and guardrails, normal-open state, and reversible coverage. `tests/capture_ship_hero.gd` adds two actual native 960×640 angles for ordinary-open and ordinary-weather-cover rendering. The existing native hull mesh remains unscaled study geometry; there is no actual walkable access hatch, pressure hull, buoyancy physics, environmental protective system, human-scale clearance or new gameplay mode. Undisclosed vessel capabilities and their plot reveals are reserved for private author-controlled lore; do not expose them through public repo documentation, tests, identifiers or screenshots.

**Future engineering gate:** reconcile the external ship's scaled envelope to the independently modeled crew interior; validate surface stability, hatch/rail headroom, egress, wave impact, hull sealing, pressure/thermal safety and target hardware performance. The foredeck is not safe under all external conditions simply because it appears accessible visually.

## Aureate Wake ship-as-home cutaway: isolated layout proposal — 2026-10-27

**Status: PROPOSAL / executable visualization, not Chapter I or canon floorplan.** This vertical slice includes an optional, *standalone* `res://ship_interior_study.tscn` Godot 4.7.2 scene. It is not installed into `main.tscn`; current exterior dimensions, six-strut docking clearance, gameplay navigation, saves, party joins and story remain untouched.

- `ship_interior_layout.gd` defines a hypothetical **10.4 × 3.8 × 2.6 m gross rectangular envelope** (102.75 m³). **This is NOT actual usable hull volume:** tapered sides, rib thickness, human heights, stairs, service ducts, exits, structural bulkheads and window/wing support intrusions have not been modeled. The existing exterior native mesh is not metrically registered to it. Meeting a gross box-volume target is not proof of habitable capacity.
- Eight small furniture footprints occupy three open conceptual deck sections: navigation and Ionia's captain-work area, common-room table/galley plus two foldaway bunks, and engineering work/tool storage, with an unblocked **1.32 m** central aisle. Engine-side aether/phase observation is just a noninteractive diagrammatic fixture. Additional party sleeping capacity, private quarters, child-safe space and any late-recruitment modifications are **not resolved**.
- `ship_interior_study.gd` procedurally builds a warm rootwood/brass/ivory/amber/teal cutaway, with floor grain bands, partial structural ribs, lights, foldaway bunks, and reading-scale engineering props. These are original native placeholder meshes; they are not a production Blender asset or a physical walkable/navmesh-proven scene.
- `tests/test_ship_interior.gd` checks proposed rectangular volumes, clearance, nonoverlapping furniture, zones and real scene nodes. The real Compatibility renderer capture test `tests/capture_ship_interior.gd` produces two HUD-free 960×640 frames. Screenshots require exact-head run and visual review; they must not be mislabeled as gameplay.

**Native screenshot critique:** The first successfully rendered cutaway (CI head `4f63461e`) showed an undersized on-screen deck, high-contrast ivory board stripes, and no overhead hull structure. The follow-up keeps all floor footprints, materials API, camera invariants and absence of collision while narrowing the native review lens, using subdued reclaimed-wood plank breakup and exposing four pairs of tapered structural cabin arches. The geometry is still provisional and does not make the deck physically integrated with the separate exterior ship study.

**Required next author decision** before adoption: precise external/internal proportional bridge, berthing capacity for current and eventual party, habitable headroom after tapering, hatch and emergency egress, Talen-safe accessible area when relevant, kitchen/sanitation and dynamic engineering clearance. Nothing here settles exact cabin ownership or early appearance timing for Lyra/Talen. Standard controls, flight/touchdown, Chapter I and hidden progression gates are unaffected.

## Aureate Wake second-pass geometry study — 2026-10-27

**SOURCE IMPLEMENTED / VERIFY AGAINST NEW NATIVE CAPTURES:** The previous real Godot bow, stern and overhead captures exposed overly flat bright trapezoidal wing membranes, an over-large spherical stern and a very smooth white cabin. This follow-up on top of the first ship art study makes each wing a six-panel fan of genuine three-dimensional cambered triangles with an asymmetrical scalloped outline, lower-intensity teal-silver vertex colors, narrower perimeter trim and fine two-segment radial veins. The stern turbine placeholder is a smaller layered cylindrical nozzle with an inner luminous throat. Four shallow roof ribs per side give the cabin visual segmentation without specifying a final interior. The review camera moves closer to make art-level features testable in 960×640 native screenshots.

No collision, physics sampler, touchdown admission, ship dimensions as canon, wing deployment rules or save/state change. A first hosted software-renderer sweep of the second pass showed **113.139 ms median high-quality wall interval** versus **61.146 ms in its parent #408** (independent GitHub-hosted llvmpipe runs, not target GPU FPS or a controlled paired performance study). Because per-wing rib geometry had multiplied independent mesh instances, a follow-up now batches the decorative edge/vein rods by material into **three mesh instances per wing** while retaining the cambered membrane as a fourth. New exact-head native captures and rendered sweep must demonstrate actual outcome; source-level draw-submission reduction is not enough. Visual acceptance, transparency sorting, pixel readability and target GPU timings remain OPEN. Shape is wholly original provisional art; hand-built/Blender-ready source asset, interior architecture and final author approval remain future gates.

## Aureate Wake close-range ship art study — 2026-10-27

**IMPLEMENTED SOURCE / NATIVE VISUAL PENDING:** The local planar flight-scene proxy now uses an original ring-lofted tapered compact body instead of a sphere-only hull, four separately modeled translucent dragonfly-derived membrane wings, slim structural edge spars and radial vein geometry, warm amber cabin windows against cool teal instrument glass, brass rootwood detailing, and three modest navigational vanes. Animation includes a subtle wing flex and suppresses it exactly under reduced-motion mode. A separate test checks silhouette objects, repeated lived-in details, animation reset and the original two visual touchdown feet; the physical landing state machine, single-ray ground contact, and terrain are not changed.

These details are **working interpretation / noncanon**: exact ship dimensions, deployed wing mechanism, final cabin plan, masts, materials, and final art are still subject to creator review. The decorative cabin windows do not assert specific berth locations. Two touchdown feet remain **visual-only** and do not establish full six-strut footprint or physics. No new movement powers, routes, moon/celestial mechanics, progression gates, or save format are introduced.

Native visual review: `res://tests/capture_ship_hero.gd` produces three **real Godot 4.7.2 Compatibility** 960×640 HUD-free frames at `evidence/ship-hero/` (bow quarter, stern quarter, overhead wing planform). Existing flight/touchdown captures remain distinct regression evidence. Examine clipping, wing depth sorting, frame readability, performance, and golden-hour contrast before any asset acceptance. Until exact-head hosted tests and the images are inspected, neither rendering correctness nor art quality is certified.

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
