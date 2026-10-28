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

## 2026-10-27 — Native execution and image QA receipts

At exact implementation commit `8a4341d2d62040314db6542d39a008dcb8d90ba8`:
- [Native P2 shader/mesh workflow #40624369306](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624369306) **SUCCESS**. Godot 4.7.2 headless `GODOT_PLANETARY_SURFACE_PAIR_PASS checks=44 actual_meshes=4 physics=UNAUTHORIZED` and Compatibility software GL `GODOT_PLANETARY_MATERIAL_AB_PASS cases=2 frames=4`.
- [Real four-frame screenshot artifact #12788941267](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624369306/artifacts/12788941267): snow control vs enhanced and explicit rain-wet ground control vs enhanced; 960×640 each, same real planet mesh, camera, light, world-space coordinates and LOD.
- Native screenshot sampled changed pixels (>2/255, 2 px stride within the test window): **16,470 snow** and **48,015 wet ground**. Independent whole-screen image analysis: snow **66,443 / 614,400 pixels (10.81%)** and wet **233,304 (37.97%)** differ by more than 2/255 in at least one RGB component. The upper-left background pixel is unchanged in both pairs. Delta confirms rendering, **not** visual quality.
- Original first native pass [#40624137832](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624137832) was technically green but rendered excessive diagonal wave striping. This was visually rejected as a look-direction candidate; the shader was revised to irregular 3D value noise and recaptured on a fresh exact head. Do not erase this review history.
- [Native migration regression #40624369312](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624369312), [native worldmap view #40624369319](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624369319), [First Wake pilot #40624369283](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624369283), and [repository smoke #40624369285](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624369285) completed **SUCCESS** on the same shader head.

**Art assessment:** Improved/no longer visibly striped, but extremely simple rectangular test tiles, source-cartography block boundaries, snowy-to-green transitions and plain ground materials remain very far from cinematic art acceptance. This is a *geometry/material binding proof*. It does not demonstrate final biomes, mixed-LOD normal seams, full globe weather/lighting, or an integrated playable camera view. Baseline and enhanced frames are a shader-strength A/B, **not** a comparison with the production globe's original StandardMaterial3D. Target Windows GPU/Forward+ profiling and real scene acceptance are open.

## Explicit admission gates

| Gate | Required evidence | Status |
| --- | --- | --- |
| P1 — JSON cross-engine admission | #489 immutable receipt, 7 native checks/190 fixture tiles | **Previously verified** on independent draft #489; not imported into this native scene |
| P2a — true native material consumer | Resolve a native `Cart.sample` biome and weather → attach material to at least two adjacent spherical meshes; no collision/save/surface displacement | **EXECUTED / ENGINEERING PASS** at shader-correction commit `8a4341d2d62040314db6542d39a008dcb8d90ba8`; art acceptance remains provisional and final branch head must be rebound after doc edits |
| P2b — visual isolation | Real same-camera off/on native PNG pair for clear-snow and rain-wet, background unchanged, pixel delta > threshold | **Submitted; inspect frame artifacts, not merely a pixel delta** |
| P3 — gameplay geography/physics | Planet-local authoritative height + collider contact + ship clearance/landing, seam and mixed-LOD continuity | **OPEN** |
| P4 — route/save/world authority | Exact single-cartography authority, canonical latitude/longitude/radius, discovery and story gate placement | **OPEN, creator-owned** |
| P5 — art/hardware | Night/weather consistency, signed visual review, accessibility, 60FPS or configured device budgets, real Windows/Forward+ GPU/VRAM | **OPEN** |
| P6 — integration/release | Reviewed dependencies and provenance, merge and playable release approval | **OPEN** |

**Open technical issues:** Both selected tiles share a grid level, not mixed view-dependent LOD. The worldmap mode-5 renderer is **not** being changed to use this shader; the standalone native view is a controlled test. The reference sphere is scaled to 12 Godot units with arbitrary 6371 km radius. Spherical curvature and source mesh are authentic, but no quality claim transfers to final chapter shots or a landing system.

## Current docs and next action

Update the native worldmap development reference and Notion planetary visual ledger with the exact CI head and screenshot links once complete. Coordinate the material resolver with [PR #501](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/501) rather than merging disconnected weather/snow shaders. Production migration and Visual Bible need a **review addendum**, not a canon rewrite.

Next: if independent visual and native tests pass, selectively attach **one inert material instance** to an existing opt-in worldmap mode-5 tile through a reversible setting, retain the original material fallback, and test the actual flight camera, horizon tile budgets, performance and play-scene scene transitions. Only after that should any terrain collision or progression be proposed.
