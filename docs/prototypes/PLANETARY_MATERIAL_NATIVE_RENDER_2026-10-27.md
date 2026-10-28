# MATERIAL-P0 S2–S3 — real native curved worldmap material rendering, 2026-10-27

**Status:** DRAFT / NONCANON / BOUNDED REAL-RENDER PIPELINE CANDIDATE. Exact-head CI/native visual and creator art approval pending. This does NOT install biome shaders in the playable worldmap scene or Chapter I.

## Source and scope
- Base: [read-only S1 native cartography/material context draft #511](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/511) fixed `c192c8d5030dae7f7caf9eb681bb5cf547c16479`. Its 44 native tests passed in [40616020970](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40616020970).
- Art references: detached Godot sand [#459](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/459), smooth dunes [#472](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/472), snow/wet-soil/mist [#483](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/483), real alpines [#448](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/448), blend weather [#420](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/420). **None of those branches is merged, their code is not silently imported and art remains unapproved.**
- [Native spherical globe/map #367](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/367) already has `worldmap_local_terrain.gd` generating curved 3D terrain and coherent ocean from the same `Cart.sample()`. This stage uses **that exact scene-class/mesh**, not a replacement dune/painted flat test plane, and leaves its original logic unchanged.

## Proposed adapter and rendering test
- `godot/shaders/worldmap_material_optics.gdshader`: newly authored restrained spatial shader; keeps the actual biome-derived `COLOR.rgb` as base, optional `sand` ripples, `snow` wind crust, `wet_ground` soil shading. Wind and sunlight are transformed into the local tangent frame. Uses `fwidth` to attenuate detail at high pixel footprint. No mesh deformation, particle simulation, world-weather event, physics, magic or time advance.
- `godot/scripts/planetary/worldmap_material_render_adapter.gd`: opt-in `ShaderMaterial` per *existing* `CurvedTerrainMesh`; refuses existing material override, never writes cartography, height, ocean, topology, worldmap state/save, and provides exact baseline restoration. Global sun is mapped to local frame; 0/1 strength and `low_quality` are reversible. No new live material controller, no override of #420 fog owner.
- `godot/tests/worldmap_material_render_contract_test.gd`: instantiate actual `worldmap_local_terrain.gd`, choose distinct known native globe snow/sand/rain-capable coordinates from `Cart.sample()`, retain mesh vertices/water, assert material selection from S1, no collider, reversible binding, world-sun seam/pole continuity.
- `godot/tests/worldmap_material_visual_capture.gd`: **real Godot Compatibility GL** review scene at fixed 960×640 on genuine curved mode-4 mesh. Render snow off/on, sand off/on, explicit rain-dry/wet ground, additional mist layer on wet ground. Match camera, sun, clock and geometry for each A/B; check positive visual delta, unchanged top-sky pixels, **exact 0 low-quality difference**, fog separately visible; persist seven original PNGs and hashes for review.
- `.github/workflows/godot-planetary-material-admission.yml`: official Godot 4.7.2 import; S1 context, S2 mesh invariance and S3 real OpenGL capture; attempt artifact upload even if GitHub hosted artifact storage limits prevent retention. A green report without an accessible actual image **cannot** establish human visual acceptance.

## Acceptance and boundaries

| Gate | Required evidence | Meaning |
| --- | --- | --- |
| S0/source | #511 exact parent, diff audit; no secret/canon or copy-pasted competing branches | isolated review source |
| S1/context | 44-check `Cart.sample` native context pass | correct pure climate + explicit-weather selection |
| S2/native terrain | real 3D curved mesh, same vertices/water before and after, reversible material override | **actual existing worldmap geometry** receives optical material in detached scene |
| S3/native visuals | 7 actual 960×640 GL captures; snow/sand/ground A/B, fog, sky-mask and low-detail pixel parity | shader compiles/renders and changes only the intended review surface |
| S4/playability | inside actual `planetary_worldmap.tscn` low-sky/tiles path; user input, camera/LOD movement; accessibility, palette and silhouette review | **NOT DONE by this detached native material study** |
| S5/production | Forward+/Compatibility QA, representative Windows GPU FPS/VRAM/thermal, terrain streaming seams and biome boundaries, creator visual approval, merge/release authorization | OPEN |

Critically, the attached shader selects one dominant Cart biome at the chosen **local reference center**. It is not yet a production per-pixel bioclassifier or seamless mixed-biome border renderer. No assumption that all vertices of a multi-biome patch share the same biome is authorized beyond this small bounded test. Worldmap mode 4 and live cloud/fog are deliberately untouched. Sea-ice and ocean are excluded by S1.

**Windows QA guard:** existing [Defender real-time disabled failure](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40616021091) is a separate host-security HOLD and must never be bypassed for a visual pilot.

**Next step if accepted:** attach per-tile/pixel mask to *one* true worldmap mode-4 or cube-sphere tile through a user-toggle **after** resolving snow vs wet-earth art from #448/#483 and #420's weather authority; then verify movement across biome border, seam and physical landing continuity, review authoring against the project Visual Bible, and target GPU. Never conflate this prototype with full planetary atmosphere/physics or canon locations.

## First GL failure — preserve the negative result

Initial exact head `9c31ea9de2f6fa65906f78bad3246078b9abf36b` [native admission run 40624507460](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624507460) **FAILED S3** while S1 context 44 checks and S2 actual curved mesh 42 checks **PASSED**. [Failed native image artifact #12789185808](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624507460/artifacts/12789185808) downloaded and examined: every frame had exactly **one background sky color**, no visible terrain. Thus snow/sand/rain A/B `pixels=0`, and fog changed entire frame (153,600 sampled positions). This is NOT evidence the shader was too subtle or the GL camera lacked coverage; the existing `worldmap_local_terrain.gd::_ready()` deliberately sets `visible=false` by default, and the detached study had not turned that actual mode-4 visibility gate on.

Correction at `50fc8ca7...` activates `patch.visible=true` **only inside the detached native capture** and adds a foreground pixel-count floor before evaluating any A/B. Native CI now demands that foreground receipt too. No shader brightness, terrain data, source mesh, collider, geography, weather controller or game-scene behavior was changed to conceal the failure. A new exact-head replay with inspected actual images is required before S3 can be marked verified.
