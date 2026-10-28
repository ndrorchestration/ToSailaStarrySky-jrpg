# First Wake — Neutral Ship-Pose Presentation Port (real-scene contract)

**2026-10-27 | TEST-ONLY / PUBLIC-SAFE / PROTOTYPE → PRODUCTION ADMISSION STEP A**

## Purpose

The Aureate Wake's **neutral four-wing visual pose** needs a testable interface into the actual Ionia-first Godot Chapter I story scene. This draft does **not** integrate the experimental 3D vessel, modify the level, alter the canonical order or authorize an additional gameplay action. It only tests a visual cue delivered to an explicitly supplied test renderer sink.

## Source and exact provenance

- Base: [native ship-space handoff PR #497](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/497), pinned head `d341d367c005b3c00d758336982d0e34d5e95839` on the real Chapter I job/engineering scene.
- Public-safe visual-source interface: [PR #490](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/490), exact head `7abee4f14971868f52626d032d238c7140e0c457`, source `godot/flight_slice/wing_pose_pipeline.gd`, blob `6b8f1ebf735f4630ab4248598bdef8269c6c9fd0`.
- Same GDScript timeline contents are copied into `godot/scripts/ship_visual_pose_timeline.gd` so a realistic scene test runs without importing a second Godot project. This is **code API reuse**, not a new 3D asset, wing collision shape, or evidence of final visual quality.
- `godot/scripts/first_wake_ship_visual_pose_port.gd` mediates a cue strictly after the real on-stage job flyer → Ionia hiring → gangway → engineering sequence *and* after explicit ship-space review opt-in. Exact expected story party: Ender and Ionia.
- The true native scene `godot/scripts/first_wake_job_preview.gd` gains three methods for test-only injection: request, advance, clear. **No new player input binding, runtime loop, save key, quest flag, physical flight mode, or animation autoplay.**

## Fail-closed requirements

Tests must reject early job-search, pre-boarding, non-opt-in, absent-sink and unknown cue requests. A valid bounded cue must interpolate through the original 1.8-second timeline, reverse from its current pose, reject NaN time, and allow reduced-motion immediate stabilization. Opt-out, save restore, or loss of scene eligibility must block further cue advancement. Explicit cleanup can return the test sink to the neutral pose.

**Authority boundaries:** scene job/state progression, actor position and collision bounds, active two-character opening party, objective/dialogue/lock text, saved v2 checkpoint and original ship-space diagram should be unchanged by cue transitions. This contract is an ordinary appearance-only control, not a new player-facing configuration.

## Native admission QA

- `godot/tests/first_wake_ship_pose_port_test.gd`: instantiate *real* playable Ionia-first chapter scene and issue stage-gated requests to a nonrendered native `Node3D` test double `godot/tests/first_wake_ship_pose_test_sink.gd`.
- New [native CI workflow](../.github/workflows/godot-first-wake-ship-pose-admission.yml): official Godot 4.7.2 SHA-verified editor, source import, ship pose port, inherited real ship-space, job-scene and v2 checkpoint regressions.
- No rendered wing animation is claimed by this test because the real chapter project does not have an admitted 3D ship mesh. Existing [#490](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/490) supplies isolated 3D visual evidence only, not scene-integrated evidence.
- [Public production admission requirements](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/docs/ship-pose-production-handoff-20261027/docs/SHIP_POSE_PROTOTYPE_TO_PRODUCTION_ADMISSION.md) track later physical 3D rig/occupied deck/door/bridge-scale compatibility and hardware + creator review.

**NO AUTOMATIC MERGE / NO RELEASE.** If the exact-head CI run is not successful, status is implementation candidate with failed native admission.
