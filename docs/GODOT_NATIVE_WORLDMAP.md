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
