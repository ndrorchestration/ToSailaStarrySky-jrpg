# Aureate Wake + live atmospheric transitions — integration acceptance record

**2026-10-27 / STAGED NATIVE REVIEW / NOT CREATOR-APPROVED ART**

## Frozen parents

- Exact [#422](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/422) ship + environmental baseline: `0ba35e6bd4e6acd4c5b7e880be1758d17feebab6`, previously Godot native CI PASS and 5-view rendered evidence.
- Exact [#420](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/420) deterministic environment transition source: `2f72a0816650794a1b4c9698d0eb43a58fcdc374`, independently native Godot CI PASS.
- First stage: transfer only the #420 environment interpolation sampler, pure blend implementation, continuous rain opacity, controls, dedicated tests/capture and workflow gates on top of #422. Retain #422's refined, noncanonical cambered ship, four wing rigs, stern/cabin features and full native regression. No reverse merge or rewriting source branch. `main.gd` keeps `AureateWakeSilhouetteStudy`: Dragonfly Frigate is a separate larger craft.

## Exact combined validation

1. Native Godot **4.7.2** import, 12-frame parse and 600+ terrain/native regression assertions, plus physics-backed dry landing and continuous contact recovery.
2. All light, weather, pause/reduced-motion/quality-mode contracts including new `test_environment_blends.gd`; four unique ship membranes and original loft mesh remain present during the fade and no ship position mutation occurs.
3. Original five `capture_environment_mood.gd` weather frames. Additionally original `capture_environment_transition.gd` creates **three** fixed-camera, fixed-time endpoint/halfway GL images.
4. `capture_ship_hero.gd` captures **six** real 960×640 GL frames: original bow/stern/top; bow in rain/blue-hour, storm/magical nighttime, and half of a deterministic 2-second golden-to-storm fade. The four same-camera/time image pairs (golden→rain; golden→storm; golden→half; half→storm) each must exceed bounded sampled RGB delta. This proves rendered visual differences, not physically plausible or beautiful atmospheric lighting.
5. Native flight sweeps run in both detailed and low-detail modes. Record exact intervals rather than assert performance certification. Review screenshots visually for rim highlights, canopy occlusion, transparent membrane ordering, intermediate exposure, rain alpha threshold popping, abrupt storm shifts, readability and motion/accessibility.
6. New CI status is **NOT VERIFIED UNTIL ITS OWN RUN COMPLETES**. Independent parent green checks cannot be transferred.

## What is still blocked

- No creator approval of mesh design, world aesthetic, lighting, final ship dimensions, collision footprint, rigging, original soundtrack, or canonical weather.
- No verified continuous video smoothness; screenshot endpoints alone cannot test temporal stability.
- No target Windows hardware, OpenGL/Forward+ matching, deterministic performance comparison, or Windows export security bypass.
- No globe with authored planetary latitude/aurora/moon progression, actual Chapter I landing/splashdown cinematic, approved character sprites, gameplay interactions, or release package.
- No Moon Bridge hidden clue, private sources or unapproved public reveals. Draft only; preserve separated PR lineages.

[Development control #387](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/387) and [Notion visual development ledger](https://app.notion.com/p/406f5bad238b81649ecaea05f451c2d6).
