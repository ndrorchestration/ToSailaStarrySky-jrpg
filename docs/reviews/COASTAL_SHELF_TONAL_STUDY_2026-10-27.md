# Coastal shelf tonal transition — 2026-10-27

Status: **NONCANON / IMPLEMENTED CANDIDATE / NOT CREATOR-ACCEPTED**. Visual-only Godot 4.7.2/GDScript planar flight study; no full planet, Chapter I, tide, world geography, ocean dynamics, saving, or collision authority.

## Source and relationship

- Exact parent: [#437](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/437) at `864597868d2eb8e4c1e9147e53d27ba0646a8272`, its refined foam already native-verified with actual 960×640 GL A/B images.
- [#429](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/429) supplies the preserved ground-truth terrain sampler/sea datum, restrained forest-floor shader/geometry, and matched wet/dry shoreline capture.
- [#433](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/433), [#440](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/440), and #418 work on different terrain/material/ridgeline lineages; this does not silently merge or supersede them.

## Visual goal and implementation

The remaining dominant visual defect in #437 is a **broad, coherent turquoise coastal shelf** behind the improved broken foam.

A new `shelf_transition_strength` water shader uniform supports exact visual A/B:
- `0.0` returns the exact previous #437 color path, at unchanged foam and land wetness settings.
- `1.0` narrows the water-depth gradient from a broad 0.2–2.4 elevation span to a shorter 0.07–1.32 shallow interval, with low-amplitude spatial noise and a muted shallow teal mineral tone. Existing reflective sky, surface normals, current foam mode and authoritative depth/coverage mask remain.
- A corresponding reduction in additive shallow turquoise light suppresses a continuous bright ring. The material uses already-baked shared terrain-derived bathymetry, not a new physics shoreline or second land geometry source.
- In `low_quality` mode this additional branch is skipped and both A/B settings must render pixel-identically, retaining the previous economical default. Pause/reduced-motion still share the scene's time uniform.

## Required QA and evidence

- Existing physical touchdown, 64 terrain chunks, LOD, flight, atmospheric depth, cinematic camera, forest-floor V and M controls, legacy six art captures, and high/low rendered-flight sweep must pass **at exact branch head**.
- `res://tests/test_visuals.gd` checks the new shader parameter is explicitly initialized and reversible.
- Existing `tests/capture_study.gd` at one HUD- and ship-free fixed coast camera at world clock=9 captures `coast-shelf-old.png` and `coast-shelf-toned.png`, with `foam_breakup_strength=1` for both, while land wetness, lighting, fog, angle, water height and terrain LOD stay fixed.
- Native scan `NATIVE_SHELF_COLOR_PAIR_DELTA` must report 100–65,000 differing sampled pixels, to avoid invisible changes or uncontrolled full-screen drift. `NATIVE_SHELF_COLOR_LOW_DELTA` must equal **0**, verifying exact low-detail fallback. Distinct `NATIVE_SHORELINE_CAPTURE` receipts protect the six gameplay image count.
- Compare actual images for a quieter shelf without a new hard band, sediment checkerboard pattern, artificial dark rim, ghosting at tile edges, or reduced readability of the Aureate Wake. Pixel differences alone do not establish artistic merit.

**Open:** actual Godot native results, image review, target Windows GPU performance, planetary integration and creator artistic approval. Hosted software OpenGL timings are diagnostics, not comparable GPU FPS. This study is draft-only; no merge/release.
