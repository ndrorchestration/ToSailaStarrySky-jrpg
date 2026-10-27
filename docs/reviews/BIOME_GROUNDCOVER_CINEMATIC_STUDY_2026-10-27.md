# Biome ground-cover cinematic study — 2026-10-27

Status: **IMPLEMENTED CANDIDATE / NON-CANON / DRAFT REVIEW**. The scene is a bounded Godot 4.7.2 Compatibility-mode planar art study, not the full planet or a Chapter I release.

## Purpose

The existing sky, water, mixed forest and exposed alpine slope reads as wide biome-colored terrain from near the flight camera. This pass gives **middle/foreground parallax and scale** through opaque, low-complexity geometry:

- Five-blade crossed meadow and forest-understory tussocks. Color varies deterministically by grassland versus forest and by local instance.
- Small, low-poly, variably oriented stones along exposed coastal and alpine terrain.
- Two instanced MultiMesh draw groups; no per-tuft nodes or texture dependencies, up to 950 tufts and 420 stones on a deterministic bounded lattice.
- Placements sample the **existing** `terrain.gd` height and biome classifier. The registered physics landing field and the five provisional hamlet footprints are deliberately clear.
- The existing **V** low-quality toggle hides fine grass while leaving larger stone silhouettes visible. The cover is static; it introduces no new movement, shader clock, collision, route, save, canon, or gameplay state.

## Visual gate

Compare exact-matched 960×640 native screenshots of coast, forest and highland against the #404 head, with the same camera and clock. Assess whether foreground vegetation adds depth without looking like repetitive spikes, whether stones read as scale cues rather than geometric noise, and whether the landing approach remains clear. Review the low-quality capture separately.

Reject or revise if placement appears as a regular grid, tufts protrude through buildings or the ship, coastal stones float, distant aggregate looks noisy, or rendered flight performance regresses unacceptably on representative hardware. Prefer hand-authored focal points and authored foliage materials for the final world.

## Verification

`res://tests/test_visuals.gd` adds checks for bounded nonempty MultiMesh instance counts, repeatable CPU placement, sampled-ground elevation, biome filtering, fixture clearance, 15-vertex/5-blade meshes and quality-mode fallback. Existing tests must continue to prove 64 terrain tiles, stitched LOD continuity, native touchdown, effect accessibility and cinematic capture.

**Evidence boundary:** Source code and tests were prepared on the above review branch. Until its exact-head Godot 4.7.2 CI and real GL captures complete, runtime correctness and visual improvement are **unverified**. Even passing CI cannot establish final artist acceptance, full-globe integration, GPU frame-time or memory budgets. No merge, release or canon approval is implied.

Upstream drafts: #402 combined camera/cloud/terrain, #403 snow headroom, #404 mixed forest canopy. This candidate stacks on #404 and must not be silently merged or rebased into a different authority chain.
