# Environmental transition and motion continuity — noncanonical visual study

**Status:** IMPLEMENTED CANDIDATE / NATIVE VALIDATION PENDING / ART NOT APPROVED  
**Source:** isolated Godot 4.7.2 Compatibility flight lab, stacked strictly on draft PR #417 at `c161cae0b650281960a3c06d3c53b65c44ad5a94`.

## Intent
The initial B/N/G environment look gallery switched instantly between four authored light grades, four weather looks and a decorative sky ribbon. Abrupt jumps in skylight, fog, weather and rain prevent evaluating the actual in-flight visual language. This pass adds a **bounded, interruptible 1.8-second grade transition**. It is not a world time-of-day simulation, seasonal/weather gameplay, celestial alignment, spell cast, canonical auroral lane or cinematic cutscene editor.

## Design contract
- `environment_blend.gd` is a pure function taking original and target colors/scalars with clamped cubic smoothstep interpolation. It exactly preserves source at 0 and target at 1. No random number generation, resources, textures or changes to core physics.
- `visuals.gd` offers the existing **instant** `set_environment_look()` to native capture and tests plus a new `queue_environment_look()` and explicit `advance_environment_transition(delta, reduced_motion)`. Only the visible palette gets blended; discrete preset IDs remain the artist's chosen targets.
- **B/N/G** invoke the cinematic fade. Mid-fade inputs begin from the **current interpolated palette** rather than the previous original look. Lighting, fog, sky, ocean solar reflections, non-navigable magic ribbons and one fixed-budget rain batch move in sync.
- Rain geometry remains a single 112-instance MultiMesh; precipitation opacity changes continuously, and the layer is hidden below a low-opacity threshold. There is no emitter churn, additional lights or new shadows.
- **P pause** passes zero transition delta; **M reduced motion** completes the transition immediately and hides moving rain. **V low detail** continues disabling rain and decorative sky branches without affecting the underlying palette target.
- Zero/invalid requested duration selects the target immediately. Transitions are capped to 0.1–8 seconds to avoid surprising linger and have no effect on saves or gameplay time.
- Existing 37-second cinematic camera, automatic route, landing collision, terrain heights, ship and foundational Five Lights identities are unchanged.

## Acceptance evidence
- Native `tests/test_environment_blends.gd`: deterministic intermediate values, endpoint identity, bounded fog and rain, finite fractions, shader and native light synchronization, reentrancy, pause, reduced-motion and quality toggles, roundtrip to original golden default, no change to native terrain tile count.
- Native `tests/capture_environment_transition.gd`: software-OpenGL **matched** 960x640 frames for golden clear, halfway and storm-night magic, with the *same* camera, scene clock and actor pose; verifies two distinct intermediate rendered pixel deltas. This is evidence of visibly different images, **not** artistic quality or physically plausible weather.
- Full existing terrain/LOD/camera/atmosphere/landing/flight regression gates remain required for exact head. Inspect native pictures for acceptable intermediate exposure, rain popping at threshold, forest/ship silhouettes and non-flashing magic.
- Target hardware GPU frame-time, actual temporal video continuity across a full camera flight, color-blind readability, creator art approval and performance at production planet scale remain **OPEN**.

Provenance: original procedural source only; no external asset download, shader pack, fonts, or music licenses.
