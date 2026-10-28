# Organic canopy silhouette and source-derived coastal swash study

**Status:** Candidate isolated Godot 4.7.2 Compatibility art study; **draft/unmerged**. Stacks on PR #467, itself dependent on the regional-texture and mood branches. Not a production globe or Chapter One environment implementation.

## Forest silhouette
- The two existing `MultiMeshInstance3D` vegetation batches retain their world placements, instance counts, textures, shaders and vertex budgets. The conifer's existing 4×11 tier faces get static per-tier radial branch grouping; each 3-lobe broadleaf crown gets deterministic angular perimeter shaping. No new tree positions, extra surfaces, extra particles, alpha sorting or opaque forest collision bodies.
- `Y` reassigns the two existing shared meshes between source shape and shaped variant. This is **review-only**, not a gameplay action. Same art material and grounding. Change is calculated only on a toggle, not once per frame; silhouette is not noise-driven or a tree wind simulation.
- Existing foliage/understory source PNGs continue to be used. `M` reduced motion still fixes the shared scene clock, and V low detail remains supported. The forest-floor texture remains subordinate to silhouette geometry.

## Coast surf
- The existing ocean shader now layers a bounded, slow swash band **only on the water side** of the signed coastal distance image derived in PR #467 from the authoritative terrain RF height sampler. It is also bounded by shared depth, coast proximity and rendered terrain-coverage. There is no new coastline, no water-plane geometry, tide simulation or collider.
- The existing original `water_ripple_detail.png` perturbs the foam edge. The dedicated `U` toggle enables/disables it, preserving base foam in both cases. `V` low quality zeroes the added surf and skips its shader branch. `M` freezes `study_time` and surf movement, without blinking/emissive effects.

## Mandatory evidence
- `tests/test_foliage_surf.gd`: native real vertex arrays differ between organic/basic canopy while exact vertex budgets, tree poses, shader bindings, clock, terrain, physics-ground collider and Y/U/V/M invariants remain unchanged.
- `tests/capture_foliage_surf.gd`: 4 genuine 960×640 GL images (coastal base vs surf, forest base vs organic) at identical camera/time within A/B. Pixel differences show **integration only**, not art approval.
- Existing Godot physics touchdowns, native cinematic camera, deterministic weather grading, atmospheric crossfades, terrain LOD, texture reproducibility and software-GL 96-sample render sweeps must pass at the exact PR head.
- Open: actual high-quality foliage cards/leaf branches, forest interior lighting and depth, realistic breaking wave hydrodynamics, shoreline foam from other viewpoints, acceptable transition across altitude/LOD, target-platform GPU performance and creator acceptance.

**Canon:** No Five Lights, Ionia/Ender opening, plot magic, Aureate Wake ship configuration, Moon Bridge, planetary climate, unlocks or hidden navigation modified.
