# First Wake Dock — Dragonfly and Actor Scale Characterization (2026-10-18)

**Status:** SOURCE-LEVEL CHARACTERIZATION ONLY. No new artistic acceptance, canon dimension or field-pack admission.

## Bound implementation

- Candidate: draft PR #289, head `2cdff5ab38c20bdfdd6a8360d6fa1a831d95ad46`, stacked on draft PR #288. No renderer or scaling change in this characterization.
- Source: `modules/dragonfly-visual.js` defines `bodyLengthAdultHeights=3.0`, `runtimeBodyLengthPx=126`; dock-walk call in `modules/first-wake-visual-stage.js` selects `scale=1.62` after opening cinematic. Nominal scaled body length: **204.12 logical pixels**.
- Admitted `drawFieldCharacter` selects Ender `scale=.70`, `FIELD_CELL_H=96` -> 67.2-pixel logical bounding cell. Ship/cell ratio **3.038:1**. This is a prospective comparison; `drawFieldCharacter` is conditional on an admitted ready field pack.
- Provisional `drawProvisionalFieldCharacter` selects Ender `scale=2.20`, multiplied by internal `0.5`, `FIELD_CELL_H=96` -> 105.6-pixel bounding cell. Ship/cell ratio **1.933:1**. Ionia uses 2.10 * 0.5 * 96 = 100.8 pixels -> **2.025:1**.
- The provisional sprite has 2x-nearest-neighbor art **inside** the 64x96 cell; transparent margins and actual opaque silhouette may make apparent height shorter. Therefore these ratios are drawable bounding-cell values, **not physical-height measurements** or a proven failure of the 3:1 canon.
- The runtime `runtimeBodyLengthPx=126` also requires rendered-object measurements to establish alignment with visible hull pixels. Distinguish body from full wing span and platform/rig.

## Direct provisional-alpha measurement (follow-up)

Read actual first idle frames from `assets/characters/v1/ender/provisional-idle.png` and `assets/characters/v1/ionia/provisional-idle.png` (each 512x96 strip with 64x96 frame cells). Alpha-channel nonzero bounds in the first 64x96 frame:

| Character | Opaque bounds (left, top, right, bottom) | Nonzero-alpha height | Applied dock scale | Estimated opaque height | Nominal ship body / opaque height |
|---|---|---:|---:|---:|---:|
| Ender | (19, 21, 53, 89) | 68 px | 2.20 * .5 = 1.10 | 74.8 logical px | 2.729:1 |
| Ionia | (15, 25, 49, 92) | 67 px | 2.10 * .5 = 1.05 | 70.35 logical px | 2.901:1 |

Across all current provisional idle/walk frames, the alpha-bounds height is stable: Ender idle 8/8 and walk 6/6 frames each span 68 pixels; Ionia idle 8/8 and walk 6/6 each span 67 pixels. This supports scale stability across those actions, not eventual art quality or gameplay acceptance.

The opaque-art calculation is materially more representative than whole-cell bounds. It **narrows the previously hypothesized discrepancy**: provisional art may be reasonably close to the 3:1 adult-height target rather than mismatched by the earlier cell-ratio figures. It remains a source/image-alpha estimate and not an exact rendered pixel assessment. Alpha outlines may include isolated decorations; actual ship body bounds, backdrop occlusion, projection, and movement states still require joint scene-level measurement. Do **not** resize characters or craft based on 1.933:1 cell comparison.

## Before any scale correction

1. Record actual opaque bounds (excluding shadow and wing membranes) for Ender, Ionia, and the Dragonfly hull in matched captured frames at the 960x640 logical canvas.
2. Inspect first-wake dock-walk, Ionia arrival, docked Dragonfly, and gameplay field contexts. Confirm art-path identities actually loaded at capture time.
3. Check plausible door heights and deck connections using the visual-strike contract (door 1.35 adult heights; crate 0.38), without converting artist intent into unsupported exact physical measurements.
4. Compare prospective 3:1 body-to-person framing with the current fallback. Test a **separate preview-only** rendering configuration if needed; do not silently resize provisional assets or alter approved likeness.
5. Preserve `AETHERWAKE_FIELD_PACK_READINESS=NOT_READY`, `VISUAL_ACCEPTANCE=PENDING`, `HUMAN_PLAYER_ACCEPTANCE=PENDING`. PRs #288/#289 remain draft; no release or canon change.

**Conclusion:** The differing renderer paths are an important scene-scale risk. The numbers above describe candidate sprite/canvas bounding boxes, not a demonstrated 3:1 failure on screen.

