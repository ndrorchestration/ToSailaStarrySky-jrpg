# Aureate Wake ship-spaces → First Wake native prototype pipeline

**2026-10-27 | PUBLIC-SAFE / TEST-ONLY / NOT CANON ART APPROVAL**

## What this actually integrates

The active development engine is **Godot 4.7.2 GDScript**. Historical JavaScript on `main` is **not** a target for new gameplay. This prototype stacks on **native Chapter I draft PR #494** (which itself stacks on the Ionia-first v2 checkpoint PR #480). It integrates an **opt-in 2D study projection into the actual playable First Wake employment/engineering scene**, not the independent 3D ship model.

- **Source evidence:** standalone Godot flight-lab [draft PR #482](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/482), immutable head `8f7112d0f8ed3afcad8faa76b5d0b224d25cdce9`, [native Godot evidence](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40608998147).
- **Destination:** actual `res://scenes/first_wake_job_preview.tscn`, using its established real Ionia-first flyer, hiring dialogue, gangway, three engineering checks, and v2 checkpoint. Opt-in overlay script `res://scripts/first_wake_ship_spaces_handoff.gd`, instantiated from `first_wake_job_preview.gd`.
- **Transferred facts:** ordinary open forward deck, translucent geodesic helm, separate cabin/engineering location, a nonauthorizing door concept, original study provenance, and a real **blocked scale/egress boundary**. Only these public-safe semantic roles/constraints transfer. No ship art bytes or shaders are copied to the Chapter I branch, and there is **no playable 3D bridge or cinematic** in this pilot.

## Admission boundary

The overlay is **hidden by default**. It is visible only via a direct review-only call **after the real native flyer → Ionia hiring → gangway sequence** puts the scene into `engineering` or `preflight` with the Ionia-first party. It does not bind a player input, create interactable nodes, alter actor bounds, set quest flags, grant combat/resonance, modify existing saves or change dialogue. Restore clears the temporary review toggle.

Source pilot dimensions are still **incompatible**: source dome 3.80 m diameter against 2.35 m independent entry-cabin width, with summit height 1.825 m versus 2.05 m headroom review minimum. This is a **cross-study incompatibility** at a **provisional conversion**, not an actual certified ship hull measurement. `BLOCKED_ON_HULL_SCALE_AND_EGRESS` is the only acceptable admission status until an integrated metre-based hull is authored/tested. Do **not** borrow the old mini-scene door as proof the dome's real front face has an opening. The ordinary glass dome must not advertise undisclosed vessel features; separate author-controlled story records retain private specifics.

## Native pipeline QA

- `godot/tests/first_wake_ship_space_handoff_test.gd`: instantiate the **real playable scene**; prove correct flyer/hiring/boarding order; default-off and pre-boarding rejection; opt-in after boarding; source SHA/boundary invariants; checkpoint equality, actor position/bounds, objective, Resonance LOCKED and node-count invariants; reject fabricated room/roster/time; and clear overlay on save restore.
- `godot/tests/capture_first_wake_ship_space_handoff.gd`: native 960×640 Godot Compatibility A/B of the same real engineering scene: default off vs opt-in review plate, with positive visible pixel differences and unmodified story/checkpoint.
- [Scoped exact Godot workflow](../.github/workflows/godot-first-wake-ship-space-handoff.yml): verified exact editor ZIP SHA256, native import, real scene test, existing Ionia-first route and save regressions, true GL screenshot capture, raw artifacts. Evidence categories are **native code/test**, **native rendered frame**, **performance separately**, **creator visual approval separately**, and **release separately**.

## Future real integration gate — not implemented here

1. Resolve a **single metre-scale hull/cabin/bridge** and obtain creator approval for gross volume, occupancy, bridge seating, standing height and actual foredeck width.
2. Introduce the real geodesic bridge 3D mesh to a **quarantined Godot native asset staging area**, source pinned and hash verified, not as Chapter I story physics.
3. Add a true hull-and-glass **door aperture**, collider, guardrails, exit and accessible paths; verify an adult capsule from sheltered helm through closed/open door to ordinary foredeck in the *same* 3D scene, plus water/pressure boundary tests separately.
4. Add optional Chapter I camera glimpses and meaningful crew conversations only after a playable and spoiler-safe scene exists. Keep unrevealed travel systems gated and unavailable until explicit creator approval.
5. Re-run native import, physics, QA screenshots and representative GPU/Windows tests; obtain separate artist/player approvals before merge, promotion or shipping.

**Status:** PROTOTYPE BRANCH ONLY. DO NOT MERGE AUTOMATICALLY, REWRITE CANON, CHANGE SAVE FORMAT OR PUBLISH.
