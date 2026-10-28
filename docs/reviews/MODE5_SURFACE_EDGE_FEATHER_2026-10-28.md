# Mode-5 material boundary feather — native production admission (2026-10-28)

**Status: DRAFT / NONCANON / ART UNAPPROVED / no merge.** This is a constrained seam-artifact mitigation on top of verified [mode-5 PR #530](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/530), fixed parent `602753a2103cdfb756b5ad24cb0c73d88250d5d3`, itself stacked on spherical P2 [#514](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/514), MaterialContext [#511](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/511), worldmap [#367](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/367).

## Why this branch and not another mode-5 toggle

PR #530 already passed its actual scene native [41 checks and real GL flight-camera render](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40630204943). It demonstrated *one* review shader bound to an actual streamed cube-sphere tile with 32/64 cache budget, scene/weather/save isolation and an exact default-material restore. The images exposed a **hard wet-material tile seam** and simplified flat geometry. Independent parallel draft [#532](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/532) was closed unmerged as **duplicative**; its L5/L7 test fixture mismatch is documented, and its toggle implementation is not pulled in. Low-sky local-curved #518 is also a sibling shader, **not** the mode-5 source.

## Reversible original seam mitigation

- `planetary_surface_study.gdshader` adds **opt-in, default-off** `tile_edge_blend_width` and genuine cube-face basis/bounds uniforms. It reconstructs u/v from **world XYZ** and tapers only the added optical tint/roughness toward the exact existing source material over a maximum 22% of the tile's normalized edge distance. The original P2 shader in standalone #514 fixtures is **unchanged** when the new uniform defaults to 0.
- `worldmap_surface_material_preview.gd` can bind existing validated `planetary_tiles.gd` face frame and tile coordinate extents into the shader; CPU `tile_edge_fraction` uses the same projection to support precise six-face geometry tests.
- `worldmap_cube_stream.gd` configures the fade only for **the one already selected live mode-5 tile**; all other tile land materials, all oceans, all worldmap geometry/cache/mesh source and global world-weather/horizon/camera algorithms remain unchanged.
- The feather merely reduces the abrupt **material difference** at a one-tile experiment's borders. It **does not** blend multiple biome classes, produce actual topological/mixed-LOD stitching, fix missing horizon geometry, or make a globally approved weather material.

## Exact-head QA requirements

- Real Godot 4.7.2 scene script contract: all six cube-face directions; 12 cell face sample corners/borders map to zero normalized edge distance while interior center retains strength; selected material receives correct native u/v bounds; a single active wet tile, 32 active/64 cache budget, no extra mesh generated on toggle, unchanged state/save and mesh identity, exact rollback.
- Real Godot software OpenGL 960×640 capture **from the actual mode-5 flight camera**: matched source original, prior hard-tile look (edge width=0) and edge-feather look (width=0.22). No camera, current flight state, or tile geometry changes during comparisons. Require positive material-border A/B change, static sky untouched, and original material restoration. Additional native smoke and worldmap migration remain required.
- Visual comparison must judge whether an apparent dark seam actually becomes less noticeable, and whether a new unwanted halo forms. Source vs hard vs feather pixel delta only proves optical change, not art acceptance. GDScript engine pass without readable images cannot certify visual result.

**Open:** convincing globe-wide biome gradient, actual per-vertex biome masks, vegetation continuity, flight camera motion and dynamic sun, auto/low/reduced-motion UX, target GPU/Forward+ / VRAM / compile time, real collision-backed landing, canonical world geography and human Visual Bible acceptance. Windows security/Defender custody remains unchanged and must never be bypassed.

**No merge/release/canon changes authorized.**