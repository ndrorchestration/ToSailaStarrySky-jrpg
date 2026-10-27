# Perceptual sand optics — original Godot material study (2026-10-27)

**Authority:** IMPLEMENTED CANDIDATE / NONCANON / ART UNAPPROVED / DRAFT-ONLY. This is a bounded rendering experiment for the Godot 4.7.2 GDScript coast–forest–highland planar flight slice, *not* a physical sand simulation, full spherical-world material, playable dune surfing, a shader copy, a new biome, or an approved environment asset.

## Motivation / ethical art provenance

Design cues: micrograin surface-normal perception, oriented wind ripples, soft diffuse contrast, grazing-angle rim light, a broad nonmetallic silk-like highlight and rare view/light-dependent glints. The layered optical *concept* is informed by Alan Zucconi's public explanatory article [A Journey Into Journey's Sand Shader (2019)](https://www.alanzucconi.com/2019/10/08/journey-sand-shader-1/), discussing the original art direction of thatgamecompany/John Edwards. **All implementation formulas, constants, noise arrangement, control logic, shader code and screenshot art in this repo are newly authored for this prototype.** No proprietary textures, assets or source code are imported; no request to replicate the precise visual identity of Journey is implied.

## Exact parent and change isolation

Built on [draft PR #456](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/456) commit `6268400df43623b6673394abc9f368003798c981` for water shelf and established [#429](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/429) forest-understory/shore material.

- `godot/flight_slice/shaders/terrain.gdshader` gains `sand_optics_strength`, `sand_wind_axis`, `sun_direction`. The prior full shader still renders exactly when `sand_optics_strength=0.0`. The new computations run **only** for dry, gently sloped, visibly exposed sand; snow, cliffs, forest, ocean, geometry, collider, world/save/route and moon/story mechanics stay unchanged.
- Wind-oriented ripples are static in world-space with low-frequency curvature warp; pixel-frequency `fwidth` attenuates the normal ripple and micrograin vectors at distance to avoid a noisy shimmering horizon. No height displacement and no per-grain mesh nodes.
- Ripple/grain derivatives tilt the shading normal in view space, plus subtle diffuse-contrast response against the shared authored key light. A modest sand-only nonmetallic specular/rim response helps cinematic legibility. Grain-hash glints are rare and respond to the actual sun/view relation; they are not randomly animated.
- The established `low_quality` V mode **bypasses the new optical branch**. M reduced-motion/pause continue to freeze the existing externally supplied visual clock; sand's geometry and grain identity do not animate with wall time.
- Existing shader fog, sun, snow, damp shoreline and conservative coastal water color remain.

## QA contract

- Contract test checks explicit new shader parameter initialization, nonzero deterministic wind orientation, the same `SUN_DIRECTION` as the sky/water, and the ability to disable optics without changing terrain.
- Actual native Godot Compatibility OpenGL A/B frames `coast-sand-plain.png` and `coast-sand-optics.png` must use the **identical** 960×640 near-coast camera, clock, light, LOD and material, except optics toggle 0/1. Require 80–85,000 changed pixels on the existing deterministic subsample. This does **not** prove aesthetic superiority.
- `NATIVE_SAND_OPTICS_LOW_DELTA pixels=0` must prove identical visuals under V low-detail regardless of optics toggle.
- Additional `coast-sand-grazing.png` captures a low-angle different view with the optics enabled. It is not compared pixel-for-pixel with the previous camera because their projection differs.
- Existing native 64-chunk terrain 618 checks, LOD, atmosphere and cinematic, manual pilot/physics-confirmed touchdown/continuous contact, six legacy material regression capture markers, shoreline A/B, 96-frame high/low software-render sweeps and smoke gates remain mandatory.

## Visual failure modes to review

1. Sand texture must actually read at flight camera framing; if too weak, do not boost artificial bright emission without checking closer camera.
2. Prevent distant grain moiré, flicker, metallic/plastic shine, line-grid interference, unphysically lit cliff/snow, excessive bloom/glitter, or diffuse double-lighting.
3. Evaluate the wet waterline vs higher dry zones independently; no fake sand layer inside the ocean.
4. Inspect the scene with reduced motion and V low-detail, and benchmark a real target Windows GPU. Godot-hosted llvmpipe wall times are only a noisy renderer diagnostic.
5. The target cinematic feel must be distinct from other games and match the luminous solarpunk sky-fantasy art bible, rather than copying another game's palette or assets.

**No main merge, public deployment, canon approval or release.** Remaining planetary material portability and production asset decisions require independent review.

## First exact-head Godot receipt and image-informed revision

Initial version `9d08e3da8f61380d66bc6ba2540be4dd099ff990` was exercised by [Godot 4.7.2 run 40598923942](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40598923942) **PASS** and [repo smoke run 40598923959](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40598923959) **PASS**. Native source/scene import, all 618 terrain checks, presentation, 59 camera, 9 atmosphere, 21 manual flight, 45 native physics-touchdown, 30 contact lifecycle and GL capture/96-frame sweep checks passed. The real 960×640 [artifact 12776789781](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40598923942/artifacts/12776789781) was downloaded and visually inspected. Scripted native result: `NATIVE_SAND_OPTICS_PAIR_DELTA pixels=35162`; `NATIVE_SAND_OPTICS_LOW_DELTA pixels=0`.

**Image QA FOUND A FAILURE despite successful tests:** medium foreground sand displayed dark, relatively evenly spaced cross-shore stripe bands; the first version looks too much like an artificial washboard rather than luminous wind-textured ground. The added shading-normal gradient and ripple albedo multiplier were overpowered at the existing cinematic camera; no artist acceptance.

The corrective candidate at commit `502fd5b4` shortens / slightly warps ripple wavelength, reduces normal displacement to about a third, lowers albedo banding to a third, halves micrograin normal amplitude and restrains rim/specular. The original strength-0 and V-low quality code branches are unchanged. **Do not transfer initial exact-head native verification to this new revision.** Only the revised 960×640 native A/B and grazing screenshots can establish whether the artifact is improved. Final planet-wide portability, actual sparkles moving with camera, and real GPU cost remain separate unsolved gates.
