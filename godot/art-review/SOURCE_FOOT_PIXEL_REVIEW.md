# Source-pixel boot baseline and contact review — 2026-10-27

**Status:** Native source-art measurement / reversible review only. Stacked on physics-walk draft PR #458. NOT a field-art, gameplay or narrative change.

## Why this exists

The existing native Godot motion proof established actual world movement (400 logical pixels per actor, 268 moving ticks), collision blocking, four independent directional art sources, and six distinct frames per source. However **12 logical pixels of world travel can occur while one source frame is held**, and the original SVG frame changes do not declare authoritative toe/heel, swing and plant markers. Thus physics success is NOT proof of planted feet.

## New source measurements and correction

`scripts/character_foot_pixel_probe.gd` inspects actual Godot-imported 480×128 atlases (6 frames of 80×128) at alpha >= 0.55 within y=104..127. Each source frame returns the lowest nontransparent boot-band pixel, separate left/right half-frame support candidates, and a per-phase vertical alignment offset. Results are transparent about uncertainty: **alpha boot-support candidates are not automatically identified anatomical feet**.

The isolated `character_field_walk_review_actor.gd` can opt into `baseline_correction_y = 64 - source_bottom_y`; this places the lowest imported boot pixel at the actor's review-stage ground origin. Source assets are immutable, and world/physics/collision coordinates are untouched. The correction can be toggled off to restore the original -60 source sprite anchor. This **does not** lock a planted toe in world space, eliminate held-frame horizontal sliding, or certify gait.

`character_foot_pixel_overlay.gd` draws optional source-derived left/right diagnostic support dots (press **P** in `three_character_physics_walk_review.tscn`). Display defaults OFF. When ON, no actor physics, collision or Chapter I state may change. Space runs the actual character routes; Esc stops the isolated review.

## Fail-closed evidence

- `tests/character_source_foot_pixel_test.gd`: rejects wrong atlas sizes, transparent/empty boot bands and invalid phase values; inspects all **72** imported directional frames across Lyra/Aepex/Reson. Requires bounded boot alpha rows and at least one support sample; proves per-frame visual boot baseline y becomes local 0 when enabled; verifies source-anchor undo and diagnostic toggle invariants; samples live physics movement at 55 consecutive ticks.
- `tests/capture_character_source_foot_pixels.gd`: starts actual physical movement, freezes actors only for the A/B screenshot, and captures two native Godot OpenGL 960×640 frames with guides off/on at the exact same source frame and world position. Source pixels and full PNG SHA-256 receipts remain runner-local, bounded 680×298 crops appear only in CI job logs. A/B difference only demonstrates the guides rendered.
- Keep full frame source/render provenance separate from apparent artist-approved foot contact. Persistent GitHub Actions artifact storage quota prevents full image publication from this workflow.

## Remaining hard gates

1. **Anatomical stance/contact authoring**: per-character × facing × phase toe/heel and leading-foot labels, verified against original layered art. Current two-half alpha detector cannot distinguish boots from costume/props or know which foot is planted.
2. Quantify **foot world-slip during stance**, including phase transitions: world position + art-foot pixel in each consecutive rendered frame; compare with animation beat and actual gait velocity. Held-frame displacement alone is a diagnostic upper bound, not a stance test.
3. Review true-scale material/lighting, proportions, hair and tattoo continuity, idle and stop transitions, collision/terrain grounding, reduced-motion alternative, creator approval.
4. Do NOT move these actors into Ionia-first Chapter One gameplay or infer combat magic from innate Water, Air and Fire resonance; keep all draft PRs unmerged until explicit authorization.
