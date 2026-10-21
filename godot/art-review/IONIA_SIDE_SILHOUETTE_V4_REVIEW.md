# Ionia V4 side silhouette and material-language review — 2026-10-21

**Status: DRAFT, NOT VISUAL ACCEPTANCE.** Stacked on PR #321 at exact parent `3288cf1e501dc53a32c2b7b53c07519f694718b3`. No production/approved art was overwritten.

## Observed native deficiency
PR #321 corrected the first failed frame-bound geometry and established a genuine sideways profile instead of a back-facing torso. Its authentic native 960×640 screenshots (privately retained under `docs/reviews/native-evidence/2026-10-21-pr321/`) also show Ionia's east/west field silhouette remains **extremely narrow** against Ender's visible equipment and her own more detailed forward-facing reference. Fine hair/costume features almost disappear at 0.13×. A green Godot CI result did not solve this.

## Art revision

Two new editable `3072×768` / six-cell SVGs:
- `ionia-east-sidebody-v4-candidate.svg`
- `ionia-west-sidebody-v4-candidate.svg`

Both derive directly from the retained v3 source, preserving its separately authored full side-body pose geometry and adding **two editable layers in each of six phases**:

1. **Rear silhouette**: a dynamic large curled blonde hair mass and a leather-and-ivory coat tail, with movement-dependent shape offsets; placed *behind* v3 limbs/body.
2. **Foremost detail**: separated curled locks, a swinging sleeve/hand with the opposing phase, brighter visible brass captain insignia/epaulets, utility pouch, and fabric/hem material highlights. These are new vector paths, not a filter, sprite mirroring, or enlargement of a previously approved raster.

East and west are separate SVG sources with independently positioned directional geometry, not a flipped full-sheet texture. The old v3 and v2 baseline sources, Ionia original green-eye/cream blouse SVG, and Ender's approved-source hash evidence stay intact. Native Godot switches only the existing two *opt-in* Ionia side-review atlas preloads. All Y/T/V/C, R and G controls, scene anchors, walkable bounds, physics, plot and canon remain unchanged.

## Verification and admission

The native `ionia_four_direction_test.gd` must still pass actual import, six pairwise-unique source frames, four real bounded movement legs, default off and fallback states. New checks require two six-phase art overlay families and a **measurable head/hair and coat-hem silhouette difference** against native-imported v3 pixels on specific source rows. This is a narrow **technical silhouette** signal, never proof of better anatomy, art quality, stylistic parity, continuity or player readiness.

The existing fixed-anchor renderer captures unmodified source v3 and candidate v4 under identical scene geometry, logged full-size source hashes and private lossless crop channels. Inspect the actual 960×640 scene at game scale, then compare Ionia east/west against her front/back and the source-approved Ender. A 960×640 photographically authentic PNG is not equivalent to independent visual approval.

**Stop/hold:** screenshot delivery to the creator, 1× artistic assessment, animation physics/weight, canon likeness and five-actor field-pack admission all remain PENDING. Do not merge into protected main or release; Defender #293 hold, production runtime/migration and Chapter 1 gameplay parity unchanged. `VISUAL_ACCEPTANCE=PENDING`; `FIELD_PACK_READINESS=NOT_READY`; `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`; `RELEASE=NOT_AUTHORIZED`.
