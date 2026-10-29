# First Wake: authoritative 3D dock dialogue integration — 29 Oct 2026

**Authority:** Draft [PR #600](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/600), stacked on [PR #591](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/591). **Not merged, not released, and not a complete Chapter I 3D conversion.**

## Architectural decision

**Do not duplicate the First Wake narrative or invent dialogue for the 3D scene.** The 3D dock now creates a hidden/nonprocessing instance of the existing `res://scenes/first_wake_job_preview.tscn`, keeps the original `job.opening`, and binds that exact object via the existing `first_wake_game_session.gd::bind_job_scene()`. The 3D scene calls the **real** `job.interact()` and advances its authored conversation by `E`. No independent quest sequence, invented character speech or second state machine is introduced.

New adapter: `res://scripts/first_wake_3d_story_bridge.gd`.

### 3D interaction behavior

- **B**: toggle the real original story interaction mode on/off; ordinary spatial-only inspection remains the backward-compatible default. This is a review control, not a finished game UX decision.
- Move the real `CharacterBody3D` with **WASD** into the actual notice `Area3D`, press **E**. The original three-line Ender job notice appears; subsequent E advances original `JobScene` dialogue, and `flyer_read` updates only after the final original line.
- Walk to Ionia's true 3D `Area3D` and press **E**. The original longer Captain Ionia and Ender hiring dialogue appears; only after the final original line does the **same** existing `Opening.accept_ionia_job()` recruit Ionia, changing the actual party from `[ender]` to `[ender, ionia]`, and stage from `job_search` to `engineering`.
- An original-text speaker/body panel is visible on the 3D dock during dialogue. Its content is drawn directly from the hidden original job `dialogue_speaker` and current `dialogue_lines`; the actual words and sequencing are not duplicated. The dark panel is mouse-transparent for input accessibility.
- The 3D gangway is deliberately **NOT** implemented as boarding or an engineering-room change. Attempting it reports that the room remains gated; it cannot call the underlying `_enter_engineering_room()` until the actual physical 3D engineering interior exists.

The normal Godot F5 entry remains `res://scenes/first_wake_game.tscn`, which retains its verified flight, emergency splashdown, shipboard inspection and save checkpoint. No 3D interaction is allowed to manufacture real water contact, preflight success, reserve inspection, checkpoint eligibility, unrelated crew recruitment, or Moon Bridge/ship travel unlocks.

## Verified evidence and remaining acceptance work

The first implementation head `c8f372f0ba9cf54ef56d8b09c89ffdbdaec5cb5c` passed official Godot 4.7.2 Linux CI [run #40932589182](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40932589182):

| Gate | Result |
|---|---|
| Existing true 3D CharacterBody/Area3D movement and collision | 46 assertions PASS |
| Original JobScene and Session identity + physics-driven flyer/Ionia dialogue + gated gangway | 39 assertions PASS |
| Existing physical splashdown, party, postflight and save/resume | 48 assertions PASS |
| Existing 3D coastal rendering | PASS |

The later source-accurate dialogue UI pass adds visible speaker/text parity assertions and requests **native 960×640 GitHub GPU captures** of Ender's flyer and Ionia's original interview. Treat this as pending until its own exact-head CI and capture receipts pass; do not extrapolate the earlier passing test.

**Windows remains UNVERIFIED for this PR**: the user's Desktop Commander connection is offline, and the earlier Windows `PLAY FIRST WAKE - 3D Coastal Preview` shortcut still points at draft PR #590's older 3D scene. Do not promise it runs PR #600 until an exact-head Windows checkout, genuine GPU capture, and shortcut retargeting are verified.

**Art acceptance remains HOLD:** the turquoise non-character locator is still not the correct rigged Ender GLB; the real Ionia 3D character model and animation, art-directed PBR harbor and ship, cinematic UI, engineering-room 3D transition and Windows installer/security gate remain unfinished.

### Next authorized increment

1. Model and rig the correct creator-approved Ender and Ionia, replacing diagnostic location cursor only after all visual/animation and source-custody checks pass.
2. Implement a physically enterable 3D Aureate Wake engineering room, reusing original `JobScene` station dialogue and `Opening.complete_engineering_checks()` instead of writing a second story implementation.
3. Demonstrate true native Windows 3D dialogue and engineering gameplay with original source assets and full prior-flight/save parity.
4. Preserve reviewer approval, merge and release gates; no unauthorized mainline change.
