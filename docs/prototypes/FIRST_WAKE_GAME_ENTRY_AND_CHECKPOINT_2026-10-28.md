# First Wake — playable native Godot game entry and postflight checkpoint

**2026-10-28 | DRAFT / UNMERGED | gameplay integration candidate, not approved production release or completed Chapter I.**

## Why this exists

The default Godot `project.godot` scene on the visual-study branch still opened a **different, older Lyra-first signal/crossing Chapter I review**. That state machine's `aetherwake.first-wake.chapter1.v1` save format forbids Ionia joining during the early signal stage, in direct conflict with the revised creator-directed Ender job-flyer → Ionia recruitment → brief engine test flight → physical ocean splashdown → later Lyra/Talen chronology. A production promotion must **not** silently splice those quest states or reinterpret legacy saves.

## New playable integration, source boundaries

On this isolated branch only, `godot/project.godot` now runs `res://scenes/first_wake_game.tscn` with **normal Godot F5**. New `first_wake_game.gd` owns native scene handoff and session lifetime. It instantiates the **existing verified** `first_wake_job_preview.tscn` with playable Ender, authentic Ionia-flyer dialogue and three engineering inspections, and preserves the real original `first_wake_flight_water_review.tscn`. The flight scene already displays the original-source wide 3D Aureate Wake with its four independent wings, warning motif from [PR #546](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/546), and uses only its actual `RigidBody2D` hull and `Area2D` local water sensor to decide when the ship is waterborne.

Only upon verified water contact **and** stable flotation does `first_wake_game_session.gd` accept the local physics snapshot. After a short presentation hold the game switches automatically to a **new controllable shipboard scene** `first_wake_postflight_game.tscn` where Ender walks and inspects the actual empty-reserve console by pressing E and advancing three Ionia/Ender dialogue lines. This action calls the **existing revised** story's `inspect_postflight_reserve(true)` only after the player observes the console. It deliberately does **not** recruit Lyra, reveal or confirm the fuel's harmonic material formula, use combat magic, award story energy or trigger the secret ship mode. Original reference art remains provisional.

## New isolated save + load

`first_wake_game_checkpoint.gd` is a **distinct** strict schema `tstss.first-wake.first-flight.v1`. It holds only the verified postflight checkpoint, Ender+Ionia, recorded historic local 2D water contact and float, the inspected-depleted-reserve fact, and unknown specialized fuel. It is *not* a migration of `aetherwake.first-wake.chapter1.v1`, and it cannot encode arbitrary precontact, Lyra-first, complete moon route, final ocean or invented fuel states. F5 saves only after valid interactive inspection and actual physical water contact; F9 resumes the postflight shipboard scene in a new game instance. A validated temporary file, backup generation and corrupt-primary recovery are included. Loaded physical evidence is marked **historical checkpoint provenance**, never a new simulated contact or a claim of 3D ocean physics. No legacy files are modified.

## Exact-head test admission

- `godot/tests/first_wake_game_entry_test.gd` loads the *configured normal project main scene*, executes real flyer dialogue, Ionia hire, real gangway, authentic three inspections and checklist, the real Godot original-source 3D ship, actual native `RigidBody2D` + `Area2D` water contact, the postflight scene regain-control interaction, pre-inspection save rejection, E-triggered reserve dialogue, valid F5 checkpoint, new-game F9 reload, strict schema rejections and verified backup recovery.
- It must run under pinned, hash-verified Godot 4.7.2 at **its own exact branch head**, in `.github/workflows/godot-first-wake-pilot.yml`. Previous [#546](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/546) engine warning, [#539](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/539) wide ship, [#492](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/492) source-camera, legacy Chapter I save, tests, physics and unchanged Defender host security gates remain intact.
- Source-parent CI and scripted SceneTree assertions cannot substitute for uncoached player acceptance, Windows device security, representative GPU, accessibility/legibility, device controller mapping, full in-engine capture, final ship/shore VFX/audio/art, chapter chronology beyond this checkpoint or installable export.

**Next feature increments:** visual continuity after the splashdown, proper shipboard interior authored art and encounter pacing; independently verified postflight Lyra/Talen introduction at the correct later chapter beat; two clue observations plus joint fuel theory and Ionia's Denith recollection; resonance shanty as the *late* alignment answer; expanded save content and backward compatibility after explicit design, not by implicit migration. Creator approval required for canon, art promotion, merge and release.

**Do not claim:** ready-to-ship game, 3D physical sea/hull, completed globally explorable planet, accepted secret moon modes, finished fuel solution or Windows security clearance.
