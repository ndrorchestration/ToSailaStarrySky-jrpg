# Shoreline foam-breakup visual candidate — 2026-10-27

**Authority:** NONCANON / IMPLEMENTED CANDIDATE / DRAFT, not creator-accepted art, planetary coastline, simulated tides or physical water interaction. Isolated Godot 4.7.2 Compatibility-mode 960×640 local flight study.

## Base and why this exists

Source parent [#429](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/429) head `e28a6c140618e0b36a6b99773c6dbcc2348643df`. Its actual coastline capture still showed a visually even, luminous cyan surf edge despite the improved damp/dry sand. This branch explores a bounded fix to that *material-only* artifact before adding further vegetation or geology meshes.

## Changes (not new coastline authority)

- `shaders/water.gdshader` retains **exact original** narrow contour-parallel foam formula as `old_foam`.
- Review uniform `foam_breakup_strength`: `0` is exact old foam/white tint; `1` is a depth-bounded combination of slowly moving broad contour displacement, broken shore crest, a patch mask and a restrained desaturated foam tint. The explicit depth and existing rendered-terrain coverage mask still bound where foam can appear; the physical and visual shoreline coordinates are unchanged.
- Existing `low_quality` path bypasses the added noise and remains the original contour foam regardless of A/B setting; reduced motion and pause keep using the same shared external scene clock.
- No collision, landing, flight, sky, canopy, procedural stone, scene camera, route, save, canon or Chapter I changes.

## CI admission gates

- Native contract asserts `foam_breakup_strength` initialized to 1.0 and that the shader uniform can revert to exact 0.0 without touching the water depth or sea-level authority.
- Existing fixed camera, ship/HUD-free 960×640 Godot OpenGL study capture records `coast-foam-contour.png` (0.0) and `coast-foam-broken.png` (1.0), fixed wetness/clock/quality/scene. `NATIVE_SHORE_FOAM_PAIR_DELTA` pixel scan must change 100–65,000 of the 127,200 sampled pixel positions, avoiding invisible and whole-screen accidental changes.
- A second pair at low-quality must be **pixel-identical**, with the host report `NATIVE_SHORE_FOAM_LOW_DELTA pixels=0`. The new screenshots use their own `NATIVE_SHORELINE_CAPTURE` marker so the existing six native artifact receipt counts remain stable.
- Existing shoreline damp/dry pair, forest, highland, atmosphere, 618 terrain checks, 64 terrain tiles, movement/landing, contact lifecycle, 96-frame high/low render sweeps and repository smoke must still pass.

## Visual review / open risks

Compare genuine exact-head screenshots at the same pose for (1) broken up turquoise band, (2) foam fragments remaining near real shore only, (3) no checkerboard repetition or excessive glitter, (4) accessible still frame and low-quality parity. Two noisy material layers can interfere visually, so failure or ambiguous improvement should reject this candidate and preserve #429. The second noise branch adds fragment work; hosted llvmpipe times cannot prove target Windows GPU cost. No creator acceptance, merge, release or full-planet rendering claim.

## Native first-pass result and corrective iteration

Exact first head `4889e4294377909db5b4557c032dae221771281b` **PASSED** [Godot native run 40592922943](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40592922943) and [smoke 40592923110](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40592923110). [GL screenshots/artifact 12775491157](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40592922943/artifacts/12775491157) were downloaded and **visually inspected**, not just checked for pixel differences. Foam A/B changed 2,634 sampled positions and preserved pixel-identical low-quality A/B (`0` changed).

That first artistic candidate reduced the thin, double white surf line but left a **broad, saturated cyan band** along the coast. This is a legitimate QA defect relative to the restrained visual goal, despite all code/GL gates passing. Second shader iteration `e414e708` reduces shallow-shelf blue-green light, tightens the broken crest and patch thresholds and moves foam color toward softer neutral sea glass. Exact 0.0 and low-quality appearance remain the prior reference. **Do not transfer first-head native certification or visual judgment to second head; rerun and inspect its screenshots.**
