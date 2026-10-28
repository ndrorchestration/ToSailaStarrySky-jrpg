# Smooth dune optical-material review — 2026-10-27

**Authority:** NONCANON / EXPERIMENTAL / DRAFT / ART UNAPPROVED.

## Exact source and design goal

- Base [#459](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/459), fixed reviewed head `819d004af54fe31bb89d7c4407f348fb74a39cf9`. It implemented an original perceptual sand shader with wind ripples, grain normals, subtle rim/sheen and rare directional glitter; native-screenshot review still found repeated bands and limited ability to evaluate dunes from coastal geometry alone.
- This study adds a separate, true three-dimensional smooth dune test surface to assess the existing optical material at multiple view angles. It does **not** turn the coastal world into a desert, change production geographies, ocean boundaries, scene cameras, existing terrain/collision, spherical planet or Chapter I.

## Architecture

- `dune_study.gd`: deterministic analytic gently asymmetric dune-height sampler, terrain normals computed by finite differences, 97 × 97 vertex mesh (96 × 96 quads / 18,432 triangles) in one `ArrayMesh`/one `MeshInstance3D`. No collision body, runtime per-grain meshes, navigation, physics or game save.
- The existing `res://shaders/terrain.gdshader` is reused **as the same shader resource** with explicit opt-in `dune_study_override=true` for dry sand. Default `false` preserves the established live terrain material. Dune override enables the sand surface at dune elevations and suppresses wet shoreline tint only for the separate material instance. Wind axis/light direction are explicitly shared.
- Original optical uniforms `sand_optics_strength=0/1` and `low_quality` remain intact; all micro-grain/ripple/rim/sheens are shader only, never geometry deformation.
- No authored proprietary shader, textures, or assets from another game copied. This is an original science-fantasy rendering technique informed by publicly discussed optical principles and made for *To Sail the Starry Sky*.

## Native evidence contract

- `tests/test_dune_study.gd` asserts bounded vertex/index budget, same source shader, disabled wetness, opt-in override, correct analytic vertex height and normals, non-flat ridgeline, exact mesh preservation across optical/quality toggles, and no collider.
- `tests/capture_dune_study.gd` uses a detached actual Godot 4.7.2 OpenGL camera, authored golden-hour key/fill lighting and fixed geometry. It creates `evidence/dune-review/dune-plain.png`, `dune-optics.png` and a separate `dune-grazing.png`, each real 960 × 640 frames. A/B shader modes are compared from exactly the same camera/clock; low quality must produce pixel-identical before/after images.
- The independent review runs **in addition** to existing full terrain 618 tests, native cinematic, flight, touchdown/physics, contact, coast-sand, shoreline/water/gl A/B, fixed highland/LOD, and 96-sample rendered-flight sweeps. Existing `NATIVE_ART_CAPTURE` markers/count stay unchanged.
- Hosted software GPU is for source/render-correctness diagnostics, not target Windows frame-time or gameplay performance acceptance.

## Acceptance and open risks

Evaluate actual dune images for smooth traversable silhouettes and lighting response, ripple density at camera distance, subtlety of grain glitter, plausible wind orientation, absence of striped checkerboard aliasing, sky/foreground readability and comparison with the original coastal shader. Even with all assertions green, creator art approval and representative native GPU motion-performance remain open.

**No merge, release, public plot reveal, physical sand simulation, dune-surfer gameplay or canonical desert authoring.**
