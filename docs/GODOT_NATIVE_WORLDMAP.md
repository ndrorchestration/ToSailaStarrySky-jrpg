# To Sail the Starry Sky — Godot native world map, development slices 1–3

**Status:** Review-only playable foundation. The planetary map and seeded procedural geography are **not canonical world geography**; this is not final JRPG or chapter-one world integration. Native worldmap scene is intentionally isolated from Chapter I and any unreleased postgame navigation contracts.

**Engine:** Godot 4.7.2 Standard / GDScript. No p5.js/Three.js, HTML, npm or browser runtime required for worldmap features.

## Run

Open `godot/project.godot` in Godot 4.7.2, then open `res://scenes/planetary_worldmap.tscn` and **F6** (Run Current Scene). Press F5 to run the preserved First Wake main scene. The worldmap is **not** yet attached to chapter/story state.

### Controls

| Input | Action |
|---|---|
| 1 / 2 / 3 / 4 / 5 | Globe, global chart, local horizon survey, tangent 3D low-sky, **global cubed-sphere 3D tile flight** |
| Mouse drag / wheel | Orbit 3D globe / zoom |
| A / D | Rotate the globe view |
| W / S | Throttle / brake |
| Q / E | Turn flight heading |
| R / F | Climb / descend |
| Shift | Accelerate simulation time in prototype (not final ship performance) |
| Click the global chart | Choose geodesic waypoint (no teleport or direct progression unlock) |
| P | Enable / disable waypoint flight assistance |
| K / O | Save / load **worldmap preview only**, rejecting corrupted data |
| J (mode 5 only) | Cycle **OFF / snow review / synthetic-rain wet-ground review / OFF**; visual-only, one eligible streamed tile, not persisted |
| Esc | Stop waypoint assistance |

## Implemented

1. Godot 3D spherical world mesh with **explicit lat/lon-to-UV mapping**, directional lighting, animated cloud shell, atmospheric rim and reproducible background starfield. This is an actual `MeshInstance3D` surface, not Canvas-only faux perspective.
2. Deterministic xyz-on-sphere terrain/biome sampling: ocean basins, shelves, beaches, woodland, rainforest, grassland, arid areas, alpine terrain, sea ice and snow. Longitudes wrap; polar geography is invariant across longitude.
3. World chart drawn in native CanvasItem with meridians, parallels, location marker, saved waypoint, simulated exploration/discovery fog and **four clearly non-canon survey beacons**. Fog of knowledge is **not** a physical visibility test or a basis to reveal secrets.
4. Local north-up survey generated from great-circle offsets. The disk is bounded by the observer's **physical geometric horizon**; the texture beyond that disk is masked. The globe overview, chart, and local survey are separate viewpoints.
5. Geodesic flight based on existing `planetary_flight.gd`, actual speed and altitude updates, marker attached to the spherical surface, optional chart-selected waypoint assistance; there is no instant teleport.
6. Explicit `starry_worldmap_preview_v1.json` under Godot's `user://` sandbox, separate from First Wake saves. Version, latitude/longitude, speed, altitude, heading, distance, view mode, waypoint and discovery IDs are validated; invalid/unrecognized data fails closed.
7. **3D low-sky terrain and ocean** on separate real Godot `MeshInstance3D` surfaces: colored curvature-aware land/bathymetry, a water surface with deterministic animated waves, shallow/deep color shifts and shoreline foam, plus a dedicated procedural sky gradient. This is a visual prototype with no physical buoyancy, collision or final weather simulation.
8. **Continuous local camera movement:** the ship-relative viewpoint now uses geodesic east/north offsets from the active patch anchor and terrain-relative height, rather than remaining fixed until the patch abruptly recenters. The patch rebuilds after bounded travel or a material horizon/altitude shift; this does not yet implement seamless streamed world chunks.
9. **Godot cubed-sphere tile preview (key 5):** genuine spherical tiles across six cube faces, sharing unit-sphere border positions, shaded procedural land and independent ocean surfaces. Tile selection reuses the existing physically computed horizon planner and global geodesic camera. At most **32 simultaneously visible meshes** (each tile can include land and water surfaces), **64 cached tile payloads**, **maximum requested level 7** with explicit automatic downgrade if the visibility budget is exceeded. Level is uniform within each plan, not a full continuous view-dependent LOD hierarchy.
10. Native Godot tests for seam, poles, biome variety, local mask, persistence roundtrip/tamper, camera continuity, adaptive patch extent, actual land/sea mesh/material contracts, cube-face boundary samples, bounded cache, **scene construction and all UI view modes**.

## 2026-10-27 — spherical local material P2 validation (isolated, draft)

The [two-tile material study #514](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/514), stacked on [worldmap MaterialContext #511](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/511), uses the *actual native cubed-sphere mesh builder* from this project. Two adjacent tile instances receive an opt-in shader selected from the existing noncanonical `Cart.sample()` snow or explicitly rain-wet ground classification. Render material controls do not move mesh vertices, invent collision, write saves, activate navigation or alter the chapter scene. A high-quality baseline (`effect_strength=0`) and candidate (`=1`) are captured at matched 960×640 camera/light/clock. No changes to this world's current scene material owner or runtime modes were made.

**Native ENGINEERING PASS** for implementation exact head `8a4341d2d62040314db6542d39a008dcb8d90ba8`: [dedicated native P2 run #40624369306](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624369306) passed 44 checks, 4 real tile meshes, 4 actual GL frames; [native image artifact](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624369306/artifacts/12788941267). The prior technically green first shader produced unacceptable regular diagonal stripes; the current revision uses irregular 3D noise. **Art acceptance and target-GPU profiling remain OPEN**. [Full review and prototype-production gates](reviews/PLANETARY_NATIVE_SURFACE_P2_2026-10-27.md).

**Distinct prototype line:** [#489](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/489) has a separate engine-neutral JavaScript planner and a Godot JSON-admission proof. That independently authored fictional biome sampler is **not identical** to `worldmap_cartography.gd`. No cross-branch merge, runtime handoff adapter, save-schema change, creator geography approval or production shader integration is asserted here. The next review step is applying the candidate to a *single opt-in in-world tile* and checking native flight-camera interaction, mixed LOD, weather ownership and real collision authority.

## 2026-10-27/28 — True mode-5 in-scene material admission (review-only)

[Draft PR #530](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/530), stacked on detached [native P2 material #514](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/514) and S1 material context #511, adds **one optional material to an actual tile in this scene's mode-5 streamer**. The base `StandardMaterial3D`, native cubed-sphere geometry, geodesic flight camera, 32 visible / 64 cached tile limits, sea shader, mode-4 local patch, state validation and saves remain unchanged by default.

Press `J` in mode 5 to cycle **OFF → SNOW LOOK → SYNTHETIC RAIN-WET LOOK → OFF**. Only one visible currently active compatible tile may use the optional world-space shader, with the HUD identifying **NO ELIGIBLE TILE** when none qualifies. This is **not** a weather mechanic or evidence of rain. Opt-out and low-quality mode restore the original materials. The setting is ephemeral and excluded from saves; loading validated state resets it. No colliders, physical landing, discovery or progression are derived from art materials.

**Verified at implementation head `ab828011e4258664a15c0ea362c946e918069ecb`:** [native mode-5 admission #40630204943](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40630204943) **PASS**, including **41 in-scene assertions** and four real **960×640** same-camera original/review snow and wet-ground images, [artifact #12790619615](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40630204943/artifacts/12790619615). Snow changed **11,403 sampled** pixels; wet changed **16,388 sampled** pixels, reversible with unchanged sky. Native migration, existing native six-view globe GL, First Wake/Ionia pilot and repository smoke also PASS. The Windows exact-custody workflow **fails before package authorization** because the hosted runner reports Microsoft Defender real-time protection disabled; Windows functional prereqs independently pass. No security boundary was weakened.

**Visual QA HOLD:** actual screenshots show crude broad color fields and material discontinuities at a tile border. In-scene integration is a **technical proof, not cinematic art**, creator acceptance or target-GPU budget. [Detailed in-scene admission ledger](reviews/WORLDMAP_MODE5_MATERIAL_PRODUCTION_GATE_2026-10-28.md) records source tests, visuals, known debt and next criteria.

## Known limitations / acceptance gates

- **NOT the full finished world map**: no creator-approved coastline/continent/geopolitics/biome atlas; all new geographic names are generic **Survey A–D** test markers.
- The orbital globe (mode 1) still uses a **smooth sphere with a terrain albedo atlas**. Mode 5 actually constructs **spherical cubed-sphere tile meshes** from the pre-existing addressing/planner and **temporarily hides the smooth globe** to avoid physical surface overlap. It is an opt-in, synchronous bounded preview, NOT a production continuous LOD terrain-streamer, authoritative coastline, complete horizon, collision-bearing landing surface, flora or ship route.
- The local horizon survey remains physically bounded **2D**. Mode 4 adds **real curved 3D local terrain, shader water and atmosphere**, with geodesic local camera motion. Mode 5 adds spherical tiles on a shared global coordinate frame, but mode 4 and 5 still have **distinct cameras and geometry**. Missing: seamless cinematic interpolation between modes, asynchronous/background mesh generation, progressive tile morphing/skirt reconciliation between different LOD levels, collision and landing.
- No creator-approved full-detail Dragonfly 3D model, wing animation, shipboard context, or collision physics. Gold point is a locator, not character/ship art.
- No canon locations, authored trade routes, fog/persistence migration to chapter save, full-party auroral access, or concealed postgame route mechanics. **Do not put private mystery mechanics into this public repository.**
- An authentic Godot **Compatibility/Mesa** workflow checks five distinct runner-local 960×640 rendered frames (including a sea-facing ocean-shader test) and scene-pixel contributions. Low-sky color-sampling variation increased from **4 to 238** and sea-facing measured **242** in one controlled Linux runner. **These are palette-diversity checks, not cinematic fidelity, perceptual scoring or creator visual acceptance.** Screenshots are not distributable artifacts in this workflow. Forward+ render, Windows GPU quality, performance/FPS/VRAM, field-of-view art and creator acceptance remain open.
- A separate native scene does not confer permission to merge a stacked Godot PR, alter production main, release installers or change Defender security holds.

## Spherical tile implementation checkpoint

At development scale only, the preview constructs actual tile geometry in the **same global sphere coordinate frame as the orbital globe**, rather than instantiating a flat map. Tile face UVs are converted through the existing six-face basis and the world-wide biome sampler, and each triangle is oriented outwards regardless of face. 32-tile active render budget / 64-tile bounded LRU are checked in native tests. The level can be downgraded by the horizon planner for budget reasons. Current tiles all share one level per visibility plan and change synchronously; **there is no promised no-pop cross-LOD transition or sustained 60 FPS**. Shorelines, radius and all city marker coordinates remain illustrative. The 0.18 km land/0.28 km water mesh clearances are only visual development offsets, **not geographic elevations**. Real GL QA exposed intermittent occlusion against the old globe; mode 5 therefore **hides the smooth orbital-globe albedo geometry** so selected real tiles can be inspected independently. Areas outside the planned tile coverage are intentionally not filled by a fake full-world surface in this review mode. This is NOT yet a seamless complete flight-world render or final horizon compositing contract.

[Native six-face/scene regression](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40166712656) verified the real tiled mesh, planet-global camera and bounded tile budget. [Current two-process GL/Mesa verification](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40167057189) ran **two fresh Godot 4.7.2 processes**, both passing all six true 960×640 views, including positive streamed-tile pixel contributions at **26 visible tiles**. Earlier failures persisted intermittently after an initial two-pass success and after a documentation-only commit. Instrumentation showed 8 spherical mesh vertices in front of the camera (4 projected onscreen) but no rendered difference on a failing process. A later [documentation-only run 40167134634](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40167134634) still exposed the intermittent invisible-tile problem despite **18 render frames of GL readiness** and a downward-facing camera. The **review-only tile materials now render double-sided** (both land and water shaders), leaving mode 4 materials unchanged. [Fresh two-process GL run 40167221258](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40167221258) PASS in both captures with positive tile-pixel deltas, but this establishes only a native GL/Mesa regression improvement—not a proof of the root cause, universally stable GPU pipelines or artistic completion. The screenshot gate still fails when tile pixels do not appear; earlier failures remain visible. These are engine checks, **not accessible art frames, target-device FPS or creator visual approval**.

## Evidence — native verified review snapshots

- [Native worldmap migration suite, exact head `9dd8654ead57e9e41e4e2ea0d22015e2745b2050`](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40165265713) — official Godot 4.7.2 headless import, scene, save, camera movement and adaptive terrain tests **PASS**.
- [Five-view native Compatibility/Mesa renderer, same head](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40165265697) — true 960×640 globe/chart/survey/low-sky/sea-facing frames, both ground/ocean pixel contribution checks **PASS**. Images remain runner-local; human artistic review **NOT ESTABLISHED**.
- **Renderer reliability ledger:** [earlier 40167057189](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40167057189) PASS twice, [documentation-only 40167134634](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40167134634) FAIL despite warmed-up renderer, then [two-sided material 40167221258](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40167221258) PASS twice at SHA `ba23e98b2f366638d6d7ed2dff7ee757e4260e33`. Previous [40166851819](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40166851819) and [40166967835](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40166967835) FAIL. All actual outcomes preserved; no Forward+ or target-hardware performance contract.
- The exact-Windows QA lane is subject to a **host Defender-real-time security preflight hold**, distinct from separate successful native functional Windows export/install/launch tests. No release permission.
- This checkpoint does not assert approved authored geography, Dragonfly art, atmospheric volumetrics, biome simulation, actual performance optimization or full-world completion.

## Architecture

```text
godot/scenes/planetary_worldmap.tscn
  scripts/planetary/planetary_worldmap.gd      Godot scene, controls, 3D mesh, UI, flight
  scripts/planetary/worldmap_cartography.gd   Deterministic globe and local sampling
  scripts/planetary/worldmap_chart.gd         Native CanvasItem chart / horizon panel
  scripts/planetary/worldmap_local_terrain.gd Curved tangent-sphere local 3D patch
  scripts/planetary/worldmap_cube_tile_mesh.gd Native cube-face real mesh payload builder
  scripts/planetary/worldmap_cube_stream.gd    Horizon-limited live tile renderer with 64-entry LRU
  tests/worldmap_cube_stream_test.gd           Cross-face seams, poles, live tile budget, camera
  scripts/planetary/worldmap_state.gd         Versioned and bounded standalone persistence
  scripts/planetary/planetary_geometry.gd     Existing spherical coordinates and horizon
  scripts/planetary/planetary_flight.gd       Existing geodesic motion
  scripts/planetary/planetary_tiles.gd        Existing cubed-sphere addressing (future)
  scripts/planetary/planetary_streaming.gd    Existing tile metadata planning (future)
```

### Next slices, in dependency order

1. **Completed for the current branch code:** native Godot 4.7.2 import, geodesic/canon-constrained worldmap scene contract checks, and real Linux GL Compatibility/Mesa five-view capture. Recheck exact HEAD after every code change; this does **not** cover visual acceptance.
2. **Next acceptance:** Forward+ and native Windows GPU captures, image-based atlas orientation/UV and material review, representative frame-time/VRAM/performance profile, creator art critique.
3. Production **cubed-sphere** multi-resolution streamed patch hierarchy, incremental frame-time-budgeted mesh construction, asynchronous workers where appropriate, graceful LOD transitions, true ground collider/landing and camera blending between orbit, near-ground and ship. A bounded native cube tile proof is now present; it is not a completed streaming engine.
4. Authored biome masks/coastal geometry, rivers/reefs/wetlands, weather and ground-collision/landing physics.
5. Creator-reviewed Dragonfly mesh, navigation cockpit/flight camera, trade-lane visuals, route-aware movement and ground-to-ship scene switching.
6. Discovery/save compatibility and authored map data, settlements, quest access and art acceptance, respecting creator-controlled spoiler boundary.

Source authority: [native PR #364](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/364), [world contract #348](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/348), [visual issue #350](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/350), [creator guidance on main](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/main/docs/WORLD_SHIP_VISUAL_DIRECTION.md). This file documents *implemented code paths* but does not replace source/runtime evidence.

## Material-context prototype admission S1 — read-only, not renderer integration (2026-10-27)

A new **isolated draft branch stacked on this native worldmap source** adds `godot/scripts/planetary/worldmap_material_context.gd` and `godot/tests/worldmap_material_context_test.gd`. It samples `worldmap_cartography.gd::sample(lat,lon)` without changing its noncanonical geography and returns **a read-only proposed material hint**, not a shader or scene binding.

Provisional rules: `snow` -> snow optics; `arid/shore` -> sand optics; land `woodland/rainforest/grassland/alpine` -> wet soil/stone **only if explicit rain/storm intensity is positive**; `sea_ice` and all ocean surfaces remain existing material. Moisture and temperature are climatology, never weather enactment. Explicit global wind is projected onto a local east/north tangent coordinate frame with stable ±180° and exact-pole convention. Low-quality mode zeroes optional optical strength; reduced motion forwards a flag without owning the real weather clock. Invalid inputs return an empty no-op result.

The GDScript resolver/test are the **S1 contract only** for [MATERIAL-P0 admission plan](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/docs/perceptual-biome-promotion-gates-20261027/docs/design/PERCEPTUAL_BIOME_MATERIAL_PROMOTION_2026-10-27.md) in docs-only [draft #501](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/501). They do **not** import the sand/snow/rain shader from [#483](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/483), instantiate planet-world terrain materials, alter worldmap modes or physics, unify #420 weather controller, output a new rendered screenshot, or modify any save/quest. Exact-head Godot-native S1 CI still required; independent S2–S5 must follow. The underlying #367 planetary art is also an unmerged noncanonical preview. No creator acceptance, main merge or release.
