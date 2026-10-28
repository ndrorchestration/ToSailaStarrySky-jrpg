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
