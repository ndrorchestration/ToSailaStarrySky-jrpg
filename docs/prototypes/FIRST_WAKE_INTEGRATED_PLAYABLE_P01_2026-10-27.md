# First Wake — Integrated Playable Candidate P-01

**Classification:** isolated playable engineering pilot (draft/unmerged). **Not** full vertical slice, final chapter, accepted canon dialogue, world navigation, production ocean, saved campaign or releasable Windows build.

## Goal and traceability

The first native Godot 4.7.2 cross-scene candidate with a **continuous player interaction route** from Ender seeking work to his and Ionia's successful **physical local ocean flotation**, followed by witnessed reserve diagnosis and a three-station aboard-ship recovery-readiness checklist. The story safely **stops at unresolved recovery geography** rather than admitting a synthetic safe Lyra/Talen reunion or invented fuel solution.

The existing launchable `res://scenes/first_wake_integrated_p01.tscn` uses the tested employment/engineering `first_wake_job_preview.gd`, which already launches the real `RigidBody2D`/`Area2D` flight review and original-source visual 3D ship inset from public draft [#525](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/525), commit `32eb4cc221c0573d4e05cf8662f46435f63a7e7d`.

The recovery-checklist native scene and script were imported **unaltered as exact Git blobs** from draft [#477](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/477), commit `658d225177bb22d9e64147207ce218d0117de6d0`:
- `godot/scripts/first_wake_recovery_readiness_review.gd` Git blob `e4e4ebd6417de59a41cb27d3194e0ed9ff9d4149`.
- `godot/scenes/first_wake_recovery_readiness_review.tscn` Git blob `d93d67377532a45b06f0c07e976ced4c1d3d031f`.

The only new gameplay composition is a small bridge inside the existing `first_wake_flight_water_review.gd`: E presents three postflight reserve observations **after** measured contact and sustained buoyancy; final acknowledgement calls the preexisting `Opening.inspect_postflight_reserve(true)` once and exposes a same-source receipt. Only then F opens the exact-source, self-contained shipboard crew/engine/message checklist. This review is not a navigation method, communication delivery, rescue, or party join.

## User route (single local scene tree)

1. Open `godot/scenes/first_wake_integrated_p01.tscn` in Godot 4.7.2 Compatibility / F6.
2. Move Ender to the job flyer and **E** to read, then speak to Ionia; the captain is first story companion.
3. Walk to gangway and **E** to enter engineering. Inspect phase reference, containment and special reserve in any order, finishing each dialogue.
4. At safety checklist **E** and complete dialogue. **F** enters real bounded first-flight scene; **E** launches, then **E** during phase warning orders controlled descent.
5. Wait for actual native `Area2D` sensor body contact, buoyancy and sustained safe flotation. **E** observes reserve diagnosis; E cycles all three lines.
6. **F** enters shipboard recovery readiness. **1/2/3** select crew, engine, contact plan (any order); E reads each observation until recorded. The screen stops at **ROUTE HOLD**, with no invented recovery plan.

**No direct menu entry to postflight, Lyra, harmonic repair, new class/spell, moon navigation or real world flight**. An independent scripted QA fixture on another draft can rehearse the reunion, but it must not be exposed as legitimate player progression.

## Evidence gates

- New native Godot `godot/tests/first_wake_integrated_p01_test.gd` starts from the dedicated scene; drives the original player `interact()` and native progression, prohibits premature flight, water, diagnosis, duplicate proof, synthetic party joins, route success, message receipt or invented fuel solution. Physics is advanced in the actual engine and ends with the RigidBody frozen at a real detected-water state.
- Optional native GL A/B/C: same test with `-- --capture` captures actual 960×640 images of physically afloat, reserve diagnosis and recovery-route hold; requires meaningful pixel delta. Use screenshot inspection to judge **legibility**, not CI pixel delta alone.
- Existing source Godot First Wake physics, Ionia model, ship 3D inset, original Chapter I save/party/combat and project checks remain required. New branch does not make existing project main scene the revised opening.
- Windows exact QA security custody (Defender real-time) remains independent and mandatory before any Windows release candidate. A successful CI run on this branch alone is **not** an installable accepted vertical slice.

## Remaining vertical-slice critical path

**P0** one selected native *default* entry point with Intro/Resume/New Game, no F6 or developer route; integrate approved safe family geography, Lyra/Talen lived scene and noncombat family introduction; integrate provisional cooperative fuel theory and material + Denith song harmonic bench with actual item collection not preloaded fixture; one story-legitimate combat encounter and return; unified cross-scene v2 save/restore with corruption tests; meaningful choice/failed attempt; audio and visual depth in Godot; full route physical-keyboard/controller playthrough with user acceptance.

**P1** coherent cinematic transition out of the 3D ship picture-in-picture, authored final sprites/forest/ocean/weather, full quality settings and hardware performance. Full globe/Moon Bridge/secret wing configuration are intentionally outside P-01 and not launch blockers.

**Creative authority:** Five Lights, party chronology Ender → Ionia → Lyra, separate story Lights/combat, Talen nonparty, Aureate Wake unique ship and Denith memory preserved. Exact melody/fuel chemistry and safe journey remain **undecided**.
