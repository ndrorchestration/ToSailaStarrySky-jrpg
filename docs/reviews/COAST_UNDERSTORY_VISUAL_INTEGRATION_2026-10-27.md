# Coast-and-understory visual integration — October 27, 2026

Status: **IMPLEMENTED CANDIDATE; noncanon planar Godot 4.7.2 art lab; draft-only**.

## Parent and evidence lineage

- Base: [#407 grounded understory](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/407), exact source head `a632b466517cd4c754a0302b81bfc3a2e67b6e5c`. Retain its fixed CPU tree/understory placement, reduced-motion clock, quality fallback and ground-cover material.
- Shared-datum shoreline treatment and wet/dry/quality capture protocol adapted from [#406](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/406), exact head `0abbb4c5eb1bb68bf7077a5b8908e40a8c292b2e`.
- The root `AGENTS.md` game-development authority remains in force. This is an **isolated visual prototype**, not world geometry, playable globe, final ocean/ship/forest art, canonical geography or a release.

## What is integrated

- The sand/rock/snow terrain shader includes narrow waterline-darkened sand, subtle fixed-frequency dry sand grains and a shared `TerrainStudy.SEA_LEVEL` binding, matching the water/shallow-bed datum. Dampness is gated by low slope; no separate coastline or tidal clock.
- `V` low-quality mode also disables expensive ground fine grains while preserving #407's undergrowth quality switch. Reduced-motion policy remains unchanged.
- The existing six native gameplay images, fixed forest/highland and 96-sample rendered-sweep profiling stay in the suite. Add separate 960×640 **native GL** fixed-camera, ship/HUD-free `coast-shore-dry.png`, `coast-shore-wet.png`, and `coast-shore-low.png` from one clock/camera position, plus nonzero pixel-delta admission and CI file-existence gates.
- Tests assert the identical land/ocean sea datum, shoreline default and low-quality parameter round trip.

## Explicitly not integrated

- #406's five-blade vegetation or standalone MultiMesh rocks: duplicate groundcover conflicts with #407. The high/low mesh-seating experiment for #406's stones is preserved in its own draft, not applied to a version that has no such stones.
- [#405](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/405) fern/shrub variant, [#414](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/414) lobe replacement, [#418](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/418) coastal/alpine stone proposal, and [#420](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/420) atmosphere blends remain independently selectable stacked drafts. No silent merge of these visual languages.

## Visual quality and performance gates

1. Inspect native coast wet/dry/low screenshot triplet at identical viewpoint and 960×640 resolution. The damp band must be visible but not read as a hard artificial ring or as cliff-wide wet stripes.
2. Confirm the matched forest frame still looks like #407's restrained understory, without additional overlapping planted geometry; preserve shot-to-shot ship and geographic readability.
3. Retain 64 chunk budget, physically verified landing contact, terrain LOD seam tests and pause/reduced-motion behavior.
4. Check real Windows GPU memory/frame-time and actual game/planet integration separately. Hosted software OpenGL timing is not target FPS. Native pixel differences are evidence of rendering changes, not creator acceptance.
5. Any later consolidation of crown, scree or weather alternatives must occur in new bounded review branches with verified source commit and new CI, not by silently merging sibling drafts.

**No merge, public release, private plot disclosure or canonical approval.**
