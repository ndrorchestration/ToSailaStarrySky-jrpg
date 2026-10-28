# Native planetary two-tile surface material — P2 engineering review

**Branch:** [draft PR #514](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/514), stacked on [native material-context PR #511](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/511) → [native spherical globe PR #367](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/367).
**Scope:** isolated NONCANON test fixture. Not integrated into the game's world-map scene or Chapter I. No final biome art/planet size, traversal unlock, collision/landing or creator visual acceptance.

## Why this path

There are **two parallel source lines**, not one unified production system:
- Native GDScript `worldmap_cartography.gd`, `worldmap_cube_tile_mesh.gd` and the weather-aware read-only `worldmap_material_context.gd` (native #367/#511) already produce real 3D cubed-sphere geometry and explicit non-authoritative `snow`, `sand` or `wet_ground` intents.
- JavaScript #349/#489 independently builds the `planetary-surface-admission/v1` JSON and has a **verified native Godot parser test**, but that contract does **not** equal the native GDScript cartography's biome/elevation algorithm. It was intentionally **not copied** here or silently merged. Prior native JSON admission is P1 only, not P2 rendering.
- Separate shader look studies #448/#459/#472/#483/#485 and material promotion review #501 inform visual requirements; their full branches are **not merged** and art remains nonapproved.

## Actual P2 native experiment

`worldmap_surface_patch_review.gd` selects two adjacent **real** 12-division spherical tiles where the native cartography resolver independently classifies both as either snow in clear weather or rain-wet land in explicit rain. It builds real mesh payloads using the existing `worldmap_cube_tile_mesh.gd::build()` and assigns a new `ShaderMaterial` to each existing mesh; new geometry, world radius, tile IDs and biome classification are not introduced.

`worldmap_surface_material_preview.gd` checks the read-only material context and maps only named approved look categories to an isolated shader. All weather is supplied by the resolver: high natural moisture without rain cannot wet the surface, and fog remains external to this ground shader. The shader uses **global planet-space** coordinates across tile boundaries, no UV seam-specific procedural mapping, and `effect_strength=0` gives the same shader's baseline. The material never assigns displacement, physical height, nav, a collider or saves. The review scene has **no collider**, and thus does **not authorize a landing**.

Tests:
1. `godot/tests/worldmap_surface_pair_test.gd`: true source tile IDs, distinct neighbor, 864 triangle vertices / 144 cells, material intent, exact unchanged vertices after on/off, reversible strength, no collider descendants, invalid context rejection. Existing cube-face seam and runtime tests continue separately.
2. `godot/tests/capture_worldmap_surface_pair.gd`: actual GL Compatibility/Mesa **960×640** equal-camera paired frames for clear-snow off/on and explicit rain-wet terrain off/on. Same geometry, camera, light and environment frame; require changed material pixels while background stays identical; all four PNGs retained as short-lived CI artifacts.
3. `.github/workflows/godot-worldmap-material-p2.yml`: checksum-pinned Godot 4.7.2, native import, headless contract and real GL rendering. The existing Godot-native migration/worldmap/First Wake suites remain in CI.

## Explicit admission gates

| Gate | Required evidence | Status |
| --- | --- | --- |
| P1 — JSON cross-engine admission | #489 immutable receipt, 7 native checks/190 fixture tiles | **Previously verified** on independent draft #489; not imported into this native scene |
| P2a — true native material consumer | Resolve a native `Cart.sample` biome and weather → attach material to at least two adjacent spherical meshes; no collision/save/surface displacement | **Submitted; exact-head native CI and captures are required** |
| P2b — visual isolation | Real same-camera off/on native PNG pair for clear-snow and rain-wet, background unchanged, pixel delta > threshold | **Submitted; inspect frame artifacts, not merely a pixel delta** |
| P3 — gameplay geography/physics | Planet-local authoritative height + collider contact + ship clearance/landing, seam and mixed-LOD continuity | **OPEN** |
| P4 — route/save/world authority | Exact single-cartography authority, canonical latitude/longitude/radius, discovery and story gate placement | **OPEN, creator-owned** |
| P5 — art/hardware | Night/weather consistency, signed visual review, accessibility, 60FPS or configured device budgets, real Windows/Forward+ GPU/VRAM | **OPEN** |
| P6 — integration/release | Reviewed dependencies and provenance, merge and playable release approval | **OPEN** |

**Open technical issues:** Both selected tiles share a grid level, not mixed view-dependent LOD. The worldmap mode-5 renderer is **not** being changed to use this shader; the standalone native view is a controlled test. The reference sphere is scaled to 12 Godot units with arbitrary 6371 km radius. Spherical curvature and source mesh are authentic, but no quality claim transfers to final chapter shots or a landing system.

## Current docs and next action

Update the native worldmap development reference and Notion planetary visual ledger with the exact CI head and screenshot links once complete. Coordinate the material resolver with [PR #501](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/501) rather than merging disconnected weather/snow shaders. Production migration and Visual Bible need a **review addendum**, not a canon rewrite.

Next: if independent visual and native tests pass, selectively attach **one inert material instance** to an existing opt-in worldmap mode-5 tile through a reversible setting, retain the original material fallback, and test the actual flight camera, horizon tile budgets, performance and play-scene scene transitions. Only after that should any terrain collision or progression be proposed.
