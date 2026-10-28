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

## Exact-source native 3D evidence — 2026-10-28

**Executable source** `14139d1d0e149be0e9cd04746f9506b32d71941b`. [Godot native integration run #40630176921](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40630176921) **SUCCESS**; marker `TSTSS_PW02_3D_PASS` explicitly confirms actual procedural hull and four wing assemblies in separate 3D camera/viewport, warning-only 3D light, reversible disable/interrupt, unchanged original Ionia-first 2D RigidBody2D/Area2D descent and waterborne. It does **not** establish ship-system canonical specifications or physical 3D water contact.

[Real native GL Compatibility framebuffer run #40630176985](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40630176985) **SUCCESS**, five original **960×640** PNG frames, SHA-256 receipts in logs: preflight, warning-ON, warning-OFF, warning-INTERRUPTED and real physical 2D waterborne. The fixed 3D camera inset shows a measurable real pixel difference ON vs OFF; OFF and INTERRUPTED have byte-identical frames in this deterministic test, and the fixed top/bottom story UI regions remain unchanged. Human full-frame artistic inspection is **not** established by numeric pixels or hashes.

[Repository smoke #40630176942](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40630176942) **SUCCESS**. [Windows host QA #40630176919](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40630176919) has **FAILED** on unchanged Defender real-time-protection preflight; separate functional prerequisites are not a substitute for the security gate. No runtime protection was weakened.

**Production gating:** Exact source proves a *working procedural 3D ship rendering inset* and engine-warning light attached to the authentic local 2D story/physics timeline. It does not prove authored geodesic helm interior, original ship-approved dimensions, target GPU performance, 3D ocean buoyancy, ship mode transformations, narrative/lighting art approval, user-validated UI, full Chapter I playability, Windows installed launch signoff, or release. The branch remains stacked/draft/unmerged.

## PW-02b native camera-cut/light isolation extension (pending exact-head CI)

At executable source `7f3b2cace99247b6ea0f4fd310822d870f5462de` we added a **scene-state-owned 3D camera shot selector**: legitimate awaiting-launch/descent → `bow-quarter`; ascent → `wing-planform`; warning/waterborne → `stern-quarter`. The camera changes inside the real SubViewport according to the already-verifying #492 `first_wake_cinematic_handoff.gd` descriptor; the procedural ship remains noncanonical and does not control timeline, contact or narrative. This deliberately uses discrete reduced-motion-safe camera compositions, not a new untested motion rig.

Added a single-factor 3D material-light QA mode: hide only the decorative warning TorusMesh while keeping actual `OmniLight3D` active. The native capture must compare **light-only against a same-angle physical-light-OFF** frame, and fail if real engine/hull surfaces do not change. Added a real ascending wing-planform frame and requires it to differ from the original bow framing; original warning on/off/interrupt and upper/lower UI invariants remain in force. **7 actual 960×640 frames are expected**. Do not mark as PASS or profile/artist acceptance until [exact-source native tests](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40630594598) and [real GL capture](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40630594633) complete. All release and Windows Defender security holds unchanged.
