# MATERIAL-P0 S4 — live planetary flight-view surface optic toggle (2026-10-28)

**Authority:** experimental Godot 4.7.2 GDScript, DRAFT, NONCANON. No merge, release, weather simulation, new biome geography, height, flight physics, save schema, celestial-story reveal or production art approval.

## Source and decision
Based on the native real cube-sphere [#514](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/514) exact head `1cb56205ad7721dbda4020554b87c06f9e735e2d`, rather than combining its shader with the **different** complementary mode-4 curved terrain study [#518](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/518). Both descend from validated globe biome/material context [#511](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/511). #514's spherical shader is globally XYZ-coherent; material selection remains original `Cart.sample` climate plus *explicit* visual weather. The native tile planner still owns 32 active tiles/64 cache entries. No shader branches are merged.

## Actual worldmap scene integration — not a detached fixture

- `worldmap_cube_stream.gd` adds volatile, opt-in `set_material_review(enabled,weather,rain_strength,low_quality)`, `review_stats()` and a single active-tile rebind after existing cache/stream refresh. Restores **all** original `StandardMaterial3D` land tile overrides before a selection; does not touch separate ocean nodes, mesh memory, tile allocation/identity, nav, ocean or collision. The existing P2 shader is used for just the closest eligible active snowy/sandy/wet tile. No other active tiles are changed. Explicit `clear/rain` only; invalid rain fails closed. A missing matching tile fails quietly to original rendering. Low quality avoids attaching optional optics.
- `planetary_worldmap.gd` adds opt-in **B surface optics** and **J explicit rain-study** keys *only when mode 5 cube tiles is active*. Both flags are memory-only and deliberately omitted from `worldmap_state.gd` v1 / save JSON. Mode 1–4 behavior remains unchanged. UI footer shows actual toggle state in mode 5. Rain is a deterministic **review look**, not weather, precipitation physics or plot state.
- No ongoing autonomous movement of clouds, weather or ship is authorized by this change. Existing modes 1–5, ship position, geodesic travel, saved discoveries and camera remain owned by the original scene.

## Evidence required

1. Native headless `worldmap_material_mode5_test.gd` loads the **real `planetary_worldmap.tscn`**. It tests B in mode 5 and J rain, one (not all) actual active tile overridden with the original P2 shader, original other tiles/oceans restored, 32/64 budgets, no unnecessary mesh generation, cache-aware travel and repeat, no extra state/save fields, fail-closed invalid intensity, and low-quality original-material parity.
2. Native `worldmap_material_mode5_capture.gd` renders the **real mode-5 flight camera and HUD** at a snow and explicitly rain-wet land tile. Produces *four* true 960×640 matched PNG frames, each before/after B. Compare central terrain ROI, excluding HUD text changes. Require nontrivial visual delta, pixel-identical V fallback, no camera/save change and no tile-budget increase.
3. `.github/workflows/godot-mode5-material-review.yml` executes both checks with official Godot 4.7.2 and software GL, preserving logs/captures/checksums; parent worldmap, migration, First Wake, Ionia and repository smoke must remain passing.
4. Independent actual screenshots are an engineering proof, **not** art approval. Review bright snow, weather-like wetness without weather owner double grade, distant UV/noise patterns and view-motion shimmer. Windows/Forward+ GPU, user motion controls, true tile seam mixing, ocean/cliffs/sea ice, multiple levels and target frame rate remain OPEN.

## Boundaries and next gate

This is **one selected tile at a time**, not production per-pixel biome blending, all tile shader replacement, or final planetary streaming. Scene mode-5 retains missing-tile gaps and noncanon geography. If the tile has mixed material classes, the **tile center** chooses the review material; this is a documented limitation. The next art/production gate must resolve #514 vs #518 material authoring, coverage transitions at tile boundaries, FOV/altitude and sun variation, reduced-motion and accessibility, and genuine target GPU benchmark. Do not relax Windows Defender preflight or claim a release.

**Exact-head CI evidence status:** PENDING until the actual new commit/run is verified; earlier #514 P2 and #518 S2–S3 successes only certify their own respective revisions.
