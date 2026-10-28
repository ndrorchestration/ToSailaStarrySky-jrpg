# Perceptual precipitation materials — snow and rainy mist (2026-10-27)

**Status:** ORIGINAL PROTOTYPE / NONCANON / DRAFT / ART APPROVAL OPEN.

## Source and relationship to parallel drafts

This original shader material experiment extends the verified standalone smooth optical terrain review [#472](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/472) at exact parent `c92d7516a7c5b3111b6199f432ab29dc93764e2c`. It adapts the perceptual rendering principles that informed original sand optics [#459](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/459): smooth geometry + normal perturbation + depth/angle-sensitive shading + sparse grain reflections instead of simulating particles.

**Existing source authority to preserve:**
- [#448](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/448): alternative wind-scoured snow material over *actual alpine slopes*, tested and visually subtle; **not silently merged**.
- [#417](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/417), [#420](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/420), [#432](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/432): existing scene weather, fog, rain streaks, grade transitions and Aureate Wake visuals; **not duplicated or merged here**.
- [#454](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/454): independent regional biome texture/macro-detail atlas. Future integration must reconcile ancestry and art authority before production changes.

## Original implementation

- `shaders/precipitation_ground.gdshader` is a standalone *original* Godot spatial shader offering two discrete surface modes. Both retain the exact former base at `weather_optics_strength=0.0` and bypass the optical branch at `low_quality=true`. Wind axis and sunlight are explicitly bound.
- **Snow mode**: frost-blue albedo variation; wind-curved sastrugi/wind-packed crust normal microdetail filtered with `fwidth`; low-energy cool crystalline sun glints; subdued wide rim light and matte diffuse behavior. No additional snowflake meshes, snowdrift deformation or snowfall physics.
- **Rain mode**: patched wet soil and exposed stone darkening, small anisotropic rivulets, steeper specular response and tighter roughness. A *separate environment fog* overlay expresses misty rain and reduces visual depth; it is not water accumulation, simulated droplets, volumetric fluid or gameplay visibility logic.
- `precipitation_study.gd` mounts these material modes on #472's **same analytic smooth dune mesh** for a controlled optical comparison. No collision, snow/rain map tags, starship/character movement, script progression, global shader override, story, save or planetary globe state changes.
- Scene fog in `capture_precipitation_optics.gd` is only a local review control. Its setup is compatible with—but **not integrated into**—the existing cinematic environment blend/storm systems. Reduced-motion explicitly freezes material clock, and V low-quality opts out of additional cost.

## Verification matrix (native Godot 4.7.2)

1. `tests/test_precipitation_optics.gd`: shader source identity, wind and light bindings, two modes, 0/1 A/B uniforms, V low-quality, reduced motion, reuse of exact bounded shared terrain mesh, no collider, unchanged geometry.
2. `tests/capture_precipitation_optics.gd`: actual native 960×640 Godot Compatibility GL scene. Six original review frames: matched `snow-plain/snow-crust`, `rain-dry-ground/rain-soaked-ground`, same wet material `rain-mist-ground`, and `rain-mist-grazing` from lower camera.
3. Pixel admission checks detect at least 200 changed sampled snow/ground material pixels, **0** top-sky pixel changes under static weather material A/B, **0** differences between 0/1 optical modes under V low quality, and at least 300 changed mist pixels.
4. Existing parent dune study native QA, 618 terrain/LOD checks, camera, atmosphere, physics-confirmed flight and touchdown, continuous contact, six original gameplay screenshots, shoreline optical A/B, software high/low 96-frame sweep, and repo smoke must still pass. Only exact-head CI plus direct image review can certify implementation.
5. Host llvmpipe frame times are **not** GPU frame-rate certification. Look for frost aliasing, repetitive stripes, excessive blue sparkle, rain-as-plastic shine, ungrounded wetness, mist flattening silhouettes, and camera/altitude appearance before any creator art approval.

## Production follow-up

A later **separately authorized** integration should reuse the common material input conventions (height/slope and world-space coordinates, wind/light, quality/motion) within the true planetary terrain biome classifier, while hooking snow to #448 and wetness/fog to #420 without duplicate control loops. Test mountain crest snow, ice fields, sheltered alpine passes, rain-soaked forest paths, coastal storms and reduced visibility from the actual ship flight camera. Keep plot energy affinities independent of weather effects.

**No merge, canon promotion, release or public deployment.**

## First native visual QA and bounded correction

**Initial implementation head:** `b3f37c7bce21df367547d7c123583031959aeb1f`. [Exact native Godot 4.7.2 run #40609217216](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40609217216) **PASS** and [repository smoke #40609217191](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40609217191) **PASS**. [Original real GL screenshot artifact #12781804376](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40609217216/artifacts/12781804376) was downloaded and visually inspected.

Headless material/geometry contract passed. Native 960×640 A/B: snow **95,014** changed sampled pixels, **0 sky drift**, **0 V low-quality drift**. Rain soil **97,354** changed sampled pixels, **0 sky drift**, **0 V low-quality drift**. Adding independent scene fog affected **127,200** samples (full subsampled image). Existing 618 terrain checks, camera/atmosphere/flight/landing/contact and high/low rendered sweeps passed.

**Art critique:** The first snow-crust silhouette read convincingly, but the sastrugi stripes were too evenly repeated at close range; the rain material was unacceptably mirror-like and looked like an uneven reflective metal sheet, not rain-soaked earth. Fog felt a little too flattening. All three limitations are visible in genuine native frames despite CI success. Subsequent shader revision `da972860` introduces slower, noisier, patch-interrupted snow ridges with smaller normal tilts, and increases wet-earth roughness while reducing specular/rivulet perturbation. Capture revision `77693051` reduces environmental fog density. **Neither initial technical pass nor image evidence certifies the revised head.** A new exact-head CI run and actual A/B are required.
