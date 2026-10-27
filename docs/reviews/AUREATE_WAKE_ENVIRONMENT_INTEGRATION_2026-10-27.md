# Aureate Wake + environmental cinematography — exact-head integration review

**Date:** 2026-10-27
**Type:** noncanonical Godot 4.7.2 / GDScript **native-review visual slice**, NOT shipped game, approved art, canonical weather, playable planetary globe, Frigate-class Dragonfly, or moon route.

## Intent and lineage

This is the first reversible assembly of two previously independently native-tested art studies in **one shared Godot scene**, rather than proposing unrelated screenshots:
- Parent base [#417](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/417) at `c161cae0b650281960a3c06d3c53b65c44ad5a94`: environmental light/weather grading, rain/sky ribbon, camera/terrain/flight/contact contracts.
- Cherry-picked **specific source files and native assertions**, not history/entire PR, from [#408](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/408) at `f047569a20a9c73192803a62d7cdc5df93f12d9f`: original lofted ship hull, four wing membranes, spars/veins, hearth windows, and three-view ship capture.
- All terrain, coastline, LOD, flight, physics contact, visual settings, environmental mood sampler, and existing weather tests remain at base semantics. Combine just the needed overlapping workflow/readme/test additions.
- Rename in-scene ship review node from historic `DragonflySilhouetteStudy` to `AureateWakeSilhouetteStudy`. **CREATOR CANON:** Aureate Wake is the small, inhabited protagonist home; the **Dragonfly** is a *different*, larger Frigate. New modeled hull/wing shape is provisional and requires separate artistic acceptance.

## Post-capture review and geometry promotion (2026-10-27)

**First combined exact head** `f7bbed156e3826f4ddc5ee9bf6675924278a810b`: [native Godot run 40576780091](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40576780091) **SUCCESS**, [smoke 40576780090](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40576780090) **SUCCESS**. Logs: terrain/native `checks=644`, environment/native `checks=89`, `NATIVE_ENVIRONMENT_CAPTURE_PASS comparisons=4`, five true ship 960×640 GL frames, two same-view grade deltas 407.6745 and 1063.9216, `NATIVE_SHIP_WEATHER_INTEGRATION_PASS`. [Exact native artifact #12768191113](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40576780091/artifacts/12768191113) ZIP CRC/integrity verified, actual images visually reviewed. **Art finding:** vessel's initial wings look too planar/high-contrast and body remains deliberately faceted. The environment remains provisional with low-detail trees/architecture and strong shoreline glare. A technically successful screenshot is NOT premium-art acceptance.

**Soft-performance warning:** on the software-GL hosted run the first combination's high-detail 96-frame sweep was median **117.271 ms**, p95 **134.682 ms**; low-quality sweep median **111.628 ms**, p95 **132.375 ms**. Earlier [#417](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/417) reported lower software-GL intervals in an independent run. These are **not controlled same-host A/B GPU comparisons** and cannot be attributed causally to the ship; they justify a performance gate, not a slowdown conclusion.

**Latest visual iteration:** following separate native review of [#419](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/419) head `5e51458d64e72ed01e939dc62578db6fd2c784e6` (native and smoke CI SUCCESS), the integration branch was updated to its improved **cambered 3D membranes, batched three-material rib meshes, stern turbine, and cabin roof panels**. The original verified integration snapshot remains accessible; latest PR #422 head requires fresh combined native tests. Hero-frame offsets were deliberately matched to #419's improved three-angle review, including BOTH same-camera weather variants. Source comparison was visually promising, **not controlled camera-equal pixel proof**.

## Scene/visual verification

1. Exact Godot 4.7.2 import, main scene parse and regression via `.github/workflows/godot-flight-slice.yml`.
2. Original bounded terrain classification/LOD/seam, island/coast, flight/manual pilot/touchdown/contact and reduced-motion suites must pass **on this integrated head**, not by transferring parent receipts.
3. Native `test_slice.gd` must verify shaped lofted hull (ArrayMesh, 500+ station vertices), distinct four wing rigs with membrane and radial veins, windows, navigation vanes, two retained visual feet, and precise stillness when reduced motion is enabled.
4. Native `test_environment_mood.gd` must demonstrate four-wing ship coexists with all deterministic weather/time grades, optional sky ribbon, rain/quality toggles, reduced motion and zero unauthorized flight-position change. Do not couple ship physics authority to weather.
5. `tests/capture_environment_mood.gd` continues collecting original five environmental captures. `tests/capture_ship_hero.gd` now renders **five authentic native Godot 960×640 HUD-free images**: golden bow/stern/top, same-view blue-hour rain, and same-view storm+magic. Both alternate golden-bow comparisons require a nonzero bounded pixel delta in real GL. A pixel delta establishes rendering difference, **not** better art.
6. Preserve all original evidence captures, logs and generator sources. New test logs must show `NATIVE_SHIP_WEATHER_INTEGRATION_PASS views=5 matched_mood_comparisons=2`. No exact-head success until the workflow actually completes.

## Next art-quality gates (not claimed)

- Compare identical bow framing at golden, rain and storm to ensure four-wing transparency sorting, window/cabin readability, rain layering, highlights, and silhouette stay legible. Determine whether magical ribbons compete with the hero vessel.
- Compare original #408 closeups to integrated images for geometry regressions, and original #417 weather frames for fog/day-grade regressions.
- Real **Forward+** high-fidelity matching captures and actual Windows target GPU frame-time, shader compilation, VRAM, 96-frame movement profile, and quality-mode behavior; software-GL timings are not desktop GPU proof.
- Creator-reviewed materials, modeling/rigging, and scale against independently approved ship/character assets; no final ship dimensions, cabins, strut counts or other unapproved canon inferred.
- Integrate into one **playable** surface↔ship journey with navigation, save/load, physical obstacle/hull safety, equipment, people and chapter parity only after separately governed tests.

## Private/public boundary

Public branch includes only original test geometry, noncanonical atmospheric palette and public-safe QA; no moon trigger, lunar secret, endgame lore, private native v0.8.x archive, or unlicensed artwork. No auto-merge, deployment, installer, canon promotion or release approval.
