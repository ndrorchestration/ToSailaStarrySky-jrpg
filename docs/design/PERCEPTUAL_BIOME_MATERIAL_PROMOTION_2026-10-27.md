# Perceptual terrain materials — prototype-to-production admission (2026-10-27)

**Decision class:** PROPOSED INTEGRATION / DOCUMENTATION ONLY. **Code status:** no production material adapter, playable planetary biome, weather-surface gameplay, new canon geography, or runtime migration implemented by this review. The main branch remains the historical JS baseline, while Godot 4.7.2/GDScript is the selected forward engine. All cited studies are **draft and unmerged**. Creator art acceptance, Windows target-GPU performance, production streaming and release are **OPEN**.

## 1. What is actually transferable now

| Capability | Verified source evidence | Transferable contract | Not demonstrated |
| --- | --- | --- | --- |
| Perceptual sandy soil / dunes | [#459](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/459) exact `819d004af54fe31bb89d7c4407f348fb74a39cf9`, [Godot native 40599578795](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40599578795); [#472](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/472) exact `c92d7516a7c5b3111b6199f432ab29dc93764e2c`, [native 40607862729](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40607862729) | Normal perturbation from wind ripples and procedural grain, light/view responsive sheen, LOD derivative filtering, deterministic material parameters; distinct material for `arid` / `shore` | Accepted dune geography, sand interaction/surfing, footsteps, dynamic grains, spherical renderer port |
| Snowpack / wind crust | [#483](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/483) exact `5c818efe4a12c6a16e5e54cfecf6282e45dcd68a`, [native 40609760775](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40609760775); parallel alpine [#448](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/448) exact `094f0740e63ad1a9a46b42b1f03f18b53eb3bc49` | Cool/scattered snow tint, slope/wind-sensitive crust normal, bounded crystalline specular; **compare** #448's real alpine slope masking instead of stacking both snow algorithms | Snow accumulation, snowfall wind transport, cold physics, terrain silhouette approval |
| Rain-wet earth / stone | #483 exact head above, [real OpenGL images 12782094949](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40609760775/artifacts/12782094949) | Surface wetness darkening, non-metallic roughness shift, narrow directional rivulet normal; opt-in condition from actual weather state | Weather-dependent gameplay friction, flooding, puddle depth, real-time water simulation |
| Mist / visibility layering | #483 fog-off/on review plus independent weather grades [#417](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/417) and transitions [#420](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/420) | Assign mist to the **existing WorldEnvironment weather/grade controller**, not a competing mesh material; fog density/visibility is a visual parameter | Validated volumetrics, ship sensors or gameplay visibility changes |
| Shared visual evidence process | #472/#483 true 960×640 Compatibility software-GL A/B, quality delta=0, physics/camera/terrain regression | One authored camera/time/lighting fixture, pixel coverage and unaffected-region gates, normal/high and low/reduced-motion contracts | Approved art, Forward+ parity, representative GPU budgets or full playable acceptance |

**Exact #483 receipt:** terrain 618 tests; camera 59; atmosphere 9; manual flight 21; physics touchdown 45; continuous contact 30; precipitation contract PASS; snow A/B 92,503 and rain A/B 97,353 sampled pixels altered; sky drift=0 in surface A/B; low-quality A/B=0. Mist on/off changes 127,200 sampled pixels because its environmental grade can change the entire frame. These numbers **only prove that something rendered differently**, not quality, cost, art acceptance or implementation within the game world. Note the source history includes an overly striped/glossy first technically passing iteration. All implementation evidence belongs to these exact draft heads, not to `main`.

## 2. Architecture: one authoritative signal, three distinct layers

Target production-native entry point for the first test: [#367 native Godot spherical worldmap](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/367), branch `feature/godot-native-worldmap-20261025`. Its `godot/scripts/planetary/worldmap_cartography.gd::sample(lat_deg,lon_deg,seed)` already returns **`biome`, `temperature`, `moisture`, `elevation`, `land`**; classifications include `snow`, `sea_ice`, `shore`, `arid`, `woodland`, `rainforest`, `grassland`, `alpine`, ocean. Its **native** low-sky and cube-sphere tile scenes still have unapproved geography, non-production streaming, and no collision-backed global landings. Keep the global chart/texture and visual ground independently scoped.

Proposed **read-only** MaterialContext, constructed from existing data (names illustrate a prospective interface, not shipped API):

```gdscript
{
    "biome": "snow",              # Cart.sample(...).biome; noncanon fixture
    "land": true,                 # from authoritative cartography
    "surface_normal": Vector3.UP, # actual mesh/collision-authoritative orientation
    "temperature": 0.12,          # climate visual cue, not precipitation
    "moisture": 0.57,             # ground-climate cue, NOT current rainfall
    "weather": "clear",           # separate weather look source: clear/mist/rain/storm
    "wetness": 0.0,               # controlled by chosen weather look
    "wind_world": Vector3.RIGHT,  # normalized in local tangent frame
    "sun_world": Vector3.UP,      # from one established scene sun
    "quality": "high",            # V low quality opts out; frozen external clock
    "study_time": 0.0
}
```

1. **Biomes are classification, not precipitation**. `temperature/moisture` are climatology inputs; do not invent rain whenever `moisture` is high. Explicit weather grade supplies instantaneous wetness/mist and may be clear in a rainforest. `snow` selects snow optics, `arid` and `shore` choose sand optics, nonfrozen `woodland/rainforest/grassland` can receive damp earth **only under chosen rain/storm**. `sea_ice` and any submerged/coastal-shelf/ocean class require **separate water/ice** rendering; do not blanket them with exposed snow or rainy soil.
2. **Shading is not geometry**. Material selection and local-space projected UV must be continuous across cube-face tile seams, ±180° longitude and the poles, with tangent-space wind and light correctly transported onto the sphere. Perceptual ripple normals, glints, fog and wet tints **must never** set height, physics collider, navigation, bathymetry, tile ID or save coordinates.
3. **One weather owner**. Use the existing #417/#420 environment/blend owner for fog, storm grading, rain visibility and reduced-motion/pause timing. Do not instantiate #483's standalone WorldEnvironment as a second global environmental controller.
4. **One material family with quality tiers**. Share input semantics among sand, snow and damp soil; no copy-paste of unrelated #448/#483 snow passes. Keep independent tunables for roughness, rim, specular, ripple frequency, sparkle density and derivative LOD. Runtime `low_quality` bypass must match the prior baseline. `V`, `M`, and pause remain respected. Material changes should be controllable A/B for QA, not an always-on irreversible scene edit.
5. **Biome art remains provisional**. Creator's established solarpunk palette and pixel-compositional hierarchy from [VISUAL_BIBLE](../VISUAL_BIBLE.md) and [WORLD_SHIP_VISUAL_DIRECTION](../WORLD_SHIP_VISUAL_DIRECTION.md) supersede any source study color; do not promote placeholder world geography or copy third-party textures/shader source. Surface wetness is unrelated to the five protagonists' plot energies and optional class/job magic.

## 3. Minimum reversible integration test — MATERIAL-P0

**Location:** create an isolated review branch **stacked on the exact #367 Godot worldmap head**, not main, and introduce the minimum material context bridge. Keep #459/#472/#483 sources as isolated implementation references rather than merging their entire unrelated #429→#472 ancestry into the planetary tree.

**Fixture:** select three **noncanonical** worldmap points using existing `Cart.sample`: an exposed `arid` or `shore` tile, one `snow` tile and one `woodland/grassland` tile. Construct identical nearby patch meshes in the existing native **mode 4 low-sky local patch** (or mode 5 if already verified), using unchanged tile heights and optional original wet/snow shader material instances. Compare clear to snow-optics or rain-wet only where the source biome and weather permit. Never write worldmap_state/Chapter I saves. Do not assume that a global atlas pixel already has walkable ground geometry.

**Executed acceptance required before saying "integrated":**

- **S0 / Source** — exact head, base PR, file/hash dependency manifest, avoid dual scene controllers, and no restricted lore/canon contamination.
- **S1 / Pure context contract** — deterministic `Cart.sample` same point and same mode; selection of `snow`, `arid/shore`, land-wet and excluded `sea_ice/open_ocean`; wind orientation projected into tile tangent frame; no rain inferred from biome moisture; frozen/reduced clock; no cross-seam/polar discontinuity; invalid states fail closed to original material.
- **S2 / Native geometry & physics** — world height, mesh indices/normals, seam alignment, collider/touchdown raycasts, tile budgets and world position unchanged with material A/B; unchanged save JSON and no navigation/route change. The desktop standalone dune fixture's passed geometry test does **not** substitute for this worldmap check.
- **S3 / Real frame evidence** — exact-head Godot 4.7.2 Compatibility 960×640 matched screenshots for at least snow off/on and clear/wet/mist, at **one actual spherical low-sky location**, at same camera/light/clock (except explicit condition). Add night/blue-hour comparison and frame sequence for camera-moving sparkle/moire. Measure foreground-only changes, sky/ship UI contamination, terrain continuity, and pass low-quality parity; reject a visually plastic or excessively bright texture even if pixels differ.
- **S4 / Quality/accessibility** — input and reduced-motion controls, fog/contrast/legibility for Ender/ship/interactive surfaces, no double weather grading; no surprise high-frequency flicker. Record image and manifest hashes, comparison rationale and human art outcome separately.
- **S5 / Device/promotion** — Forward+ desktop and Compatibility graphics differences, GPU frame time/VRAM and compile stalls on **representative Windows hardware**, cold-start/playable mode transitions, tests for longer sessions; eventual seamless 3D biome transitions and creator visual approval before accepting any actual production map asset. Hosted Mesa/llvmpipe times do **not** establish target hardware FPS.

**Pass criterion for MATERIAL-P0:** one native globe-local *rendered* material context switch, all S0–S4 verified at an exact review head, with unchanged terrain/collider/save data and preserved world/Chapter I test outcomes. That closes an engineering **integration prototype** only. S5 and human approval remain separate and required for production promotion.

## 4. Documentation changes required and source-of-truth discipline

| Target | Required change | Authority/when |
| --- | --- | --- |
| **This document** `docs/design/PERCEPTUAL_BIOME_MATERIAL_PROMOTION_2026-10-27.md` | Current PR lineage, seam/quality/render test, pass/fail gates, restricted scope | Documentation-only proposed bridge; update exact refs after every implementation head change |
| [GODOT_MIGRATION_COORDINATION](../GODOT_MIGRATION_COORDINATION.md) and [AGENT_HANDOFF_INDEX](../AGENT_HANDOFF_INDEX.md) | Link this admission gate so future agents don't merge disconnected render/weather stacks into the JS baseline | This draft PR adds cross-references; does **not** change runtime authority |
| [WORLD_SHIP_VISUAL_DIRECTION](../WORLD_SHIP_VISUAL_DIRECTION.md) and [VISUAL_BIBLE](../VISUAL_BIBLE.md) | Art review addendum: snow scattering/wind crust; wet roughness vs plastic; mist hierarchy, source/provenance, screenshots at playable framing | Proposal to art owners; **do not** rewrite canonical palettes or claim approved materials |
| [#367 worldmap docs](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/feature/godot-native-worldmap-20261025/docs/GODOT_NATIVE_WORLDMAP.md) and Godot worldmap tests | Local patch sample/material mapping, complete capture manifest, seam/polar and low sky glint QA, tier-performance budgets | Update **only on the actual future integration branch** once tested; no speculative completion claims |
| [#448/#459/#472/#483 review docs](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/483) and [#417/#420 weather docs](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/420) | Mark supersession choices once visual conflict resolved; retain original native run and rejection history | Keep source studies intact and labelled independent until selection |
| [Notion Visual Bible](https://app.notion.com/p/3e3f5bad238b81579019c70c72778e1f), [Cinematic Planetary Fidelity](https://app.notion.com/p/402f5bad238b81d3b96ef7b8641dd372), [Development & Cinematic Ledger](https://app.notion.com/p/406f5bad238b81649ecaea05f451c2d6) | Link evidence, classify verified *source* vs proposed integration, record art QA and prioritized MATERIAL-P0 acceptance gate | Working evidence logs; **do not** promote into canon or claim merged implementation |
| CI/release/QA checklist | Record real image comparison, source SHA, OpenGL renderer, off/on same camera, GPU/VRAM later; no screenshots alone as playability proof | Create tests **with the future real adapter**; no assertion of existing engine/world integration |

**Recommended next implementation:** **MATERIAL-P0 pure `MaterialContext` resolver + first worldmap local snow/wet tile A/B** on a #367-derived branch, after checking its latest head and reusing #420's weather look contract. Do not add gameplay weather physics, accumulation, secret celestial travel, or public PR descriptions containing protected lore. Review/merge/release decisions remain creator-controlled.

## 5. Executed S1 read-only context admission — 2026-10-27 update

The first executable subset of MATERIAL-P0 has now been implemented **on the native worldmap ancestry**, not on `main`: [DRAFT PR #511 — Worldmap Material Context](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/511) at exact head `c192c8d5030dae7f7caf9eb681bb5cf547c16479`, stacked on #367 fixed head `52354925c4d54c05f82471ecf0059e85bb6b7aa3`. It adds `godot/scripts/planetary/worldmap_material_context.gd` and `godot/tests/worldmap_material_context_test.gd`, wired to the native migration suite.

**EXACT-HEAD S1 VERIFIED:** [Godot-native migration run 40616020970](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40616020970) **SUCCESS**, including `GODOT_WORLDMAP_MATERIAL_CONTEXT_PASS checks=44 source=cartography read_only=true scene_material_applied=false`. No data or material is written. The pure resolver uses the actual `Cart.sample()` output and explicit `clear/mist/rain/storm` input to choose a non-authoritative `sand | snow | wet_ground | base` hint, excludes sea ice/ocean from land shading, respects V quality and M reduced motion flags, projects a world-space wind vector into seam-/pole-consistent local tangent axes, and fails closed on invalid input. All underlying planetary import, scene, save, stream and geometric tests also passed in this native migration run.

**Not yet executed:** S2 true material instance attached to a cubed-sphere/tangent local ground tile; S3 real in-scene snow/wet/mist screenshots from the actual planetary camera; S4 player readability/accessibility against ship/terrain; S5 Forward+/target Windows GPU/creator art. #511's passing 44 checks do **not** establish those later gates, nor resolve parallel #448/#420 material/weather ancestry. Other CI lanes are tracked independently; passing migration alone is not a release permission.
