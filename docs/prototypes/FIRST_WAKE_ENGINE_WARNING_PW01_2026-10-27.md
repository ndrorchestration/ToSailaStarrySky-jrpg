# PW-01 — first combined native Chapter I engine-warning VFX rehearsal

**Status:** staged Godot review-only implementation; exact-source native tests and actual GL captures required. Stacked on cinematic handoff [draft PR #492](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/492) at `2b9626220894a352925dfc267196f11211073aea`; **NOT** part of `main`, an approved playable chapter or production Aureate Wake art.

## Existing source reconciliation

- Original first-flight physics and Ionia-first party state: [#447](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/447) → [#492](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/492). Real RigidBody2D / Area2D contact and stable local flotation remain authoritative. True fuel formula UNKNOWN, Lyra NOT on initial flight, golden-clear default.
- Cinematic design cues and bounded five-phase lookdev methods: [#411](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/411) → [#496](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/496), **different Git ancestry**, separately proven. This study adapts **timing/motion/quality methods** (five phases, controlled radial ShaderMaterial/CanvasItem blending) rather than importing five-character spell art. No cross-branch merge, affinity-triggered casts, or direct use of #496's `manual_visual_review` channel.
- [Public-safe production handoff and gate proposals in draft #500](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/500). This prototype attempts only PW-01, not P2–P6 acceptance.

## Runnable Godot review

Open `res://scenes/first_wake_engine_warning_review.tscn` in Godot **4.7.2**. `E` launches/accepts safe descent through the *existing real flight input*; `V` toggles visual, `I` interrupts a running cue, `M` toggles reduced motion, `Q` cycles bounded quality, ESC exits. The new wrapper creates valid Ionia-first preflight through the original state model, instantiates the existing flight scene, and attaches a small, neutral engine-warning shader/ring effect directly to the ship `RigidBody2D` visual hierarchy.

A live `first_wake_cinematic_handoff.gd` descriptor is read **from that scene** on every render frame, and the engine cue is admitted only in the real `warning` phase, with the expected stern-quarter camera ID, party and golden-clear grade. It never writes chapter/ship physics or saves, never invents fuel, never reveals hidden ship configurations and never grants character or resonance abilities. The VFX and engine math remain deliberately fictional/nonfinal; the five-phase presentation envelope is distinct from actual harmonic-engine repair equations.

## Native evidence gates

- `godot/tests/first_wake_engine_warning_vfx_test.gd`: three full real-physics flight trials, with the visual **enabled, disabled, interrupted**; confirm only one warning onset, reduced motion static by default, strict bounded values, no early Lyra, no invented fuel or premature contact, legitimate descent and actual settled waterborne state in all three.
- `godot/tests/capture_first_wake_engine_warning_vfx.gd`: six native **960×640** frame captures for standby, warning on/off, warning interrupted, descent, real waterborne; match same exact physical-state warnings and compare actual local GPU pixels and unchanged HUD. Hashes logged runner-side; external art assessment still pending.
- Existing #492 first-flight native story/physics and other repository smoke tests remain required. Existing Windows Defender real-time protection security preflight is unchanged; Linux pass is never Windows or release approval.

## Not established

Production ship model/wing rig/dome; genuine full 3D camera integration; soundtrack/visual storytelling; memory/performance/frame-time; long-form accessibility/playtest; final visual quality/art approval; authorized plot/canon changes; headless GPU benchmark or Windows installed game. All drafts and releases HOLD pending review.

## Exact-source native execution receipts — 2026-10-27

**Executable SHA: `34b722727e9c69d6b6305beb9aedae674f7780d2`.** Real Godot **4.7.2** hosted proof:

- [Native first-flight gameplay, physics and PW-01 contract](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624631273) **SUCCESS**; explicit `TSTSS_PW01_ENGINE_VFX_PASS`, **57 checks**, three actual RigidBody2D/Area2D water-contact and stable-buoyancy runs with engine cue **enabled, disabled, interrupted**. Uses the original Ionia-first source FSM/handoff and verifies no extra Lyra, invented fuel, visual-driven state/save/combat transitions, repeated warning activation or lingering cue after descent.
- [Native GL Compatibility screenshot comparison](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624631246) **SUCCESS**; six actual **960×640** frames with SHA-256 in job log. Real engine-warning on and off frames differ in controlled ship-region pixels; warning interrupted and warning off match; top and bottom HUD regions match; descent and actual afloat frames are produced from the same native scene.
- [Repository smoke](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624631268) **SUCCESS**.
- Defect lineage retained: initial source `81ef6ba89408df7bda25dc04ec79fbd7d45ca9be` produced a passing native renderer but its [contract run](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624508325) **FAILED** because `float("nan")` yielded a regular number and the test incorrectly expected NaN rejection. Exact-source `34b72272` uses native `NAN` and passes without relaxing the test gate.

**Limits:** This proves a **combined local 2D moving-flight scene and neutral engine cue**, not an authentic 3D ship engine, finalized glow, finished environmental cinematography, art approval, playable Chapter I storyboard, performance on representative GPUs, formal accessibility testing, or protected Windows export. Evidence PNGs are runner-local and full-size images were not human-reviewed. Any documentation-only successor commit inherits no automatic native code certification; cite this exact source separately. Draft and release HOLD.
