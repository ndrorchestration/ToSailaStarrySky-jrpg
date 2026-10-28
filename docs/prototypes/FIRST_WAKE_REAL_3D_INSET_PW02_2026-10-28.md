# PW-02: Godot first-flight + authentic 3D Aureate Wake review inset

**Implemented as separate stacked draft, NOT production.** This is an **actual native Godot 4.7.2 Camera3D/SubViewport** rendered within the [PW-01 Ionia-first real-physics scene](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/519). The independently validated local 2D `RigidBody2D`/`Area2D` controls *all* flight, story and water contact. The 3D camera is an **inset cinematic composition**, not navigable 3D flight or accepted storyboarding.

## Exact source lineage and visual custody

- Inherited scene state from PW-01 / draft #519 and first-flight/cinematic authority draft #492.
- **Copied verbatim as a new separately named file** the original procedural 3D home ship `godot/flight_slice/ship.gd` from [Aureate Wake study PR #486](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/486) source `36a13d6063235ed2114bb25d2a2cc61d1d4c9f22` (Git blob `15156` bytes): `godot/scripts/aureate_wake_ship_3d_candidate.gd`. This source already contains procedural hull, four wing rig elements, original stern machinery and a *small simplified HelmGlass*, not the final creator-requested geodesic bridge. It has **no accepted production proportions**, no water/submersible physics, no secret fourth configuration and is **not** the larger Dragonfly.
- Original 3D flight lab remains separate; there is **no merge of #486 terrain, sky, ship motion, water, planetary coordinate system or weather**. The independent Godot world has a neutral golden-clear lighting environment, real 3D camera and a small optional stern-quarters engine-warning emissive ring and OmniLight3D. It lives in a camera-safe 428×240 inset, leaving top/bottom dialogue/telemetry UI untouched.
- Original PW-01 engine warning VFX is still the *one authority* for whether the new 3D lamp/ring is visible. `warning` is admitted only from the actual #492 descriptor; no character affinity/cast events.

## Exact native admission tests

`godot/tests/first_wake_engine_warning_3d_test.gd`: instantiate the native scene, inspect authentic 3D hull / 4 wings / engine mesh / HelmGlass, Camera3D and truly independent SubViewport world, assert lamp off until legitimate Ionia-first warning, reversible disable and interrupt, identical original story and ship transforms, then verify **actual physics water contact and stable flotation**.

`godot/tests/capture_first_wake_engine_warning_3d.gd`: real GL **960×640** capture from native Godot: before launch, real-engine warning on, warning off, warning interrupted and original physics waterborne. Test on/off changes actual 3D inset pixels, interrupt returns identical inset, and upper/lower Chapter I HUD regions do not change from VFX. Evidence SHA-256 in hosted job logs; full-resolution private artifact retrieval remains limited by existing quota.

**Must not claim before exact-head CI:** successful 3D GPU rendering, authored camera art quality, target FPS, verified full-resolution screenshots by human review, underwater abilities, full 3D ocean physics, production cinematic asset promotion or Windows QA/security signoff.

**After this gate:** profile frame times on representative Windows devices, test 3D cockpit/bridge occlusion and ship lighting at large and small zoom, author reviewed geodesic bridge/dome and ship-interior camera path; preserve the authority boundaries and opt-in reduced motion. Keep PR draft and main unmerged.
