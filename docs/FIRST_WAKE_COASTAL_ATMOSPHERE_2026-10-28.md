# First Wake opt-in 3D coastal environment — original water asset integration

**2026-10-28 | Godot 4.7.2 | G3 visual/atmosphere study | DRAFT / NO RELEASE**

## Why
The genuine 2D→3D Chapter I shipboard walk at [draft #560](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/560) passed 30 native camera, crew, helm feedback and checkpoint checks. However real in-engine images still showed largely blank flat-dark sky around the accessible geodesic helm and foredeck. Filling the actual **player view** with environmental visuals matters more than further isolated hero geometry.

## Actual Godot implementation
- The existing [PR #476](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/476) **exact original** `water_ripple_detail.png` 128×128 Texture2D is already staged in the Godot project's `art-staging/environment-study` directory, Git blob `b92fc645a777ee2a5abe549cf96aa19bba109926`. This PR **reuses those exact bytes**, not a fake texture or third-party stock image. The staging manifest records the source.
- New `godot/shaders/first_wake_coastal_ocean_review.gdshader` provides modest geometry wave displacement, two scales of texture-derived perceptual micro-wave normals, warm reflected glints and gentle day/dusk surface tint. This is a **stylized 3D water shader**, **not physical fluid simulation** or water collision.
- New isolated `godot/scripts/first_wake_coastal_atmosphere_review.gd` creates a **152m visual sea plane** at provisional sea y -1.75m beneath the actual ship's real walking-floor colliders. Configures Godot `WorldEnvironment` with genuine `ProceduralSkyMaterial` and adjusts the already present `DirectionalLight3D` sunlight; no second conflicting environment is created. Palette is explicitly **a temporary art study**, not canonical weather/ship position/time of day.
- Profiles `flat` (restore exactly original resource/light settings and hide ocean), `coastal_dusk` (default for the opt-in 3D review), `coastal_clear` (alternate) are available. Player can press **V** in 3D to change dusk/clear palettes and **H** to toggle a distinct forward-facing ship lookout view where ocean meets the visible sky; 2D controls refuse both. Existing **C** follow/elevated views are unchanged. The existing 2D→3D→2D *B*, nearby hatch *E*, read-only helm *F*, glass *G*, camera *C*, walking controls and v2 checkpoint remain unchanged.

## Evidence gates
`godot/tests/first_wake_coastal_atmosphere_test.gd` verifies the original unchanged source PNG manifest Git blob, Godot Texture2D 128×128 import, real ShaderMaterial and PlaneMesh, actual procedural sky, real sun variations, reversible neutral profile and refusal of unrecognized modes; real `CharacterBody3D` retains walkable ship floors and bow railing, with zero ocean colliders, no save field, plot, Resonance or ship secret permission. `godot/tests/capture_first_wake_coastal_atmosphere.gd` captures four actual Godot 960×640 images: **same physically moved actor, old flat environment vs dusk vs clear**, and a genuine forward-facing **scenic lookout horizon** dusk view. It asserts a minimum actual pixel delta for profile A/B.

Dedicated [SHA-pinned official native Godot CI](../.github/workflows/godot-first-wake-coastal-atmosphere.yml) imports the real project, runs collision/provenance checks and genuine Compatibility-rendered frames with artifact SHA receipts. Inherited exact-head #560 player camera, 2D/3D roundtrip, Chapter I, Ionia and repository smoke must remain valid.

## Do not mistake these for
- Canonical geography, coast layout, ship location, actual controlled splashdown or ocean hazard; this is a **static isolated sea visualization and artistic palette experiment**.
- Ship buoyancy, real ocean fluid, environmental pressure, weather system, submersion, flight, wing deploy, auroral ladder, moon mechanics, or any plot revelation.
- Creator-approved final hull art, Ender skeletal character, high-end animation, cinematic HDR/volumetric rendering, accessible camera, measurable Windows device FPS, signed installer or release.

All engineering is **G3 opt-in reversible visual feasibility**, NOT production or canonical admissions. Keep all PRs draft/unmerged and Windows Defender release gate unchanged. Verify actual screenshots before judging visual approval.

### Next desirable work
Inspect same-camera screenshots at native resolution. If visually promising, evaluate per-zone sun glare, under-helm reflections, foreground camera readability, low-sky contrast, day/night accessibility and true GPU profiling. Then separately create higher-quality approved-reference Ender model/animation candidates rather than canonizing this anonymous motion proxy.

## First screenshot review correction

Initial native render exposed an actual visual defect: the existing following/elevated camera pointed downward enough that the new ocean texture filled nearly the entire frame and **no sky/horizon was visible**, despite sky/texture test passes. The revised draft therefore adds a separate **H scenic lookout shot** (not a replacement for C gameplay cameras) with a forward physical Camera3D aim and shallower ocean texture frequency/lighter palette. Native end-to-end test now explicitly checks a real camera angle, reversibility and refused 2D operation. Fourth native render is revised from downward elevated deck to actual dusk **ocean/sky horizon**. Do not count initial technical screenshot PASS as cinematic art approval.
