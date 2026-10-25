# To Sail the Starry Sky — Godot native world map, development slice 1

**Status:** Review-only playable foundation. The planetary map and seeded procedural geography are **not canonical world geography**; this is not final JRPG or chapter-one world integration. Native worldmap scene is intentionally isolated from Chapter I and any unreleased postgame navigation contracts.

**Engine:** Godot 4.7.2 Standard / GDScript. No p5.js/Three.js, HTML, npm or browser runtime required for worldmap features.

## Run

Open `godot/project.godot` in Godot 4.7.2, then open `res://scenes/planetary_worldmap.tscn` and **F6** (Run Current Scene). Press F5 to run the preserved First Wake main scene. The worldmap is **not** yet attached to chapter/story state.

### Controls

| Input | Action |
|---|---|
| 1 / 2 / 3 / 4 | Globe, global chart, local horizon survey, **native 3D low-sky terrain** |
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
7. A separate **3D low-sky development terrain** built from actual curved tangent-sphere mesh vertices and per-vertex biome colors; ship-relative camera follows heading and current altitude. The mesh updates around the flight position with a bounded sampling grid and does not replace the physically bounded 2D horizon survey.
8. Native Godot tests for seam, poles, biome variety, local mask, persistence roundtrip/tamper, and **scene construction / UI mode toggles**.

## Known limitations / acceptance gates

- **NOT the full finished world map**: no creator-approved coastline/continent/geopolitics/biome atlas; all new geographic names are generic **Survey A–D** test markers.
- Globe geometry is a smooth sphere with a **terrain albedo atlas**, not displacement meshes, collision-bearing 3D coastlines, landings, floating structures or streamed near-field terrain. Existing cubed-sphere modules plan tile metadata only; they are not silently upgraded by this slice.
- The local horizon survey remains physically bounded **2D**. New mode 4 adds a **real Godot 3D curved terrain mesh and ship-relative viewpoint**, but its terrain is a limited visual patch, **not** continuous streamed planet mesh, an approved Dragonfly chase camera, physics/collision, landings or production terrain LOD.
- No creator-approved full-detail Dragonfly 3D model, wing animation, shipboard context, or collision physics. Gold point is a locator, not character/ship art.
- No canon locations, authored trade routes, fog/persistence migration to chapter save, full-party auroral access, or concealed postgame route mechanics. **Do not put private mystery mechanics into this public repository.**
- Actual visual quality / atmospheric shaders / gameplay/target hardware 60FPS are **not established by headless tests**. Require genuine renderer captures with checked version, Forward+ and Compatibility profile, frame-time/VRAM, and creator acceptance.
- A separate native scene does not confer permission to merge a stacked Godot PR, alter production main, release installers or change Defender security holds.

## Architecture

```text
godot/scenes/planetary_worldmap.tscn
  scripts/planetary/planetary_worldmap.gd      Godot scene, controls, 3D mesh, UI, flight
  scripts/planetary/worldmap_cartography.gd   Deterministic globe and local sampling
  scripts/planetary/worldmap_chart.gd         Native CanvasItem chart / horizon panel
  scripts/planetary/worldmap_local_terrain.gd Curved tangent-sphere local 3D patch
  scripts/planetary/worldmap_state.gd         Versioned and bounded standalone persistence
  scripts/planetary/planetary_geometry.gd     Existing spherical coordinates and horizon
  scripts/planetary/planetary_flight.gd       Existing geodesic motion
  scripts/planetary/planetary_tiles.gd        Existing cubed-sphere addressing (future)
  scripts/planetary/planetary_streaming.gd    Existing tile metadata planning (future)
```

### Next slices, in dependency order

1. Native engine CI import and headless tests; fix any compiler/scene failures.
2. Genuine Windows/Linux renderer capture, atlas orientation, coast/cloud/material visual inspection and performance comparison, including GL Compatibility.
3. Production **cubed-sphere** multi-resolution streamed patch meshes, actual camera continuity between globe/3D low sky, seamless chunk boundaries and full 3D horizon/occlusion. The present near-field patch is only a nonstreamed prototype.
4. Authored biome masks/coastal geometry, rivers/reefs/wetlands, weather and ground-collision/landing physics.
5. Creator-reviewed Dragonfly mesh, navigation cockpit/flight camera, trade-lane visuals, route-aware movement and ground-to-ship scene switching.
6. Discovery/save compatibility and authored map data, settlements, quest access and art acceptance, respecting creator-controlled spoiler boundary.

Source authority: [native PR #364](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/364), [world contract #348](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/348), [visual issue #350](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/350), [creator guidance on main](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/main/docs/WORLD_SHIP_VISUAL_DIRECTION.md). This file documents *implemented code paths* but does not replace source/runtime evidence.
