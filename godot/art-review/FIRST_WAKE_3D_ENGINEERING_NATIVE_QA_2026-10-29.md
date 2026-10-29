# First Wake — physical 3D Aureate Wake engineering room (2026-10-29)

**Status:** Draft [PR #602](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/602), stacked on [PR #600](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/600). **Actual spatial 3D engineering implementation and native CI verified at earlier heads; final refinements pending exact-head CI.** Not merged; not a full 3D chapter conversion, artistically accepted build, Windows installer, or public release.

## Proven architectural advancement

The 3D dock first verifies the canonical flyer and Ionia interview from the ORIGINAL `first_wake_job_preview.tscn`, bound to its existing `FirstWakeGameSession` object. Once Ionia actually joins, **physical** 3D gangway `Area3D` overlap with the `CharacterBody3D` invokes the original `JobScene.interact()` / `_enter_engineering_room()`. Only that authoritative transition constructs the new physically walkable 3D interior, moves the real player collider inside, and places an actual spatial camera.

The interior contains solid deck and side/bulkhead collision geometry; an enclosed ceiling, brass structural beams and service conduits; four independently modeled instrument consoles with glass/light studies, three types of floor markings and a far-bulkhead regulator composition; plus four real local 3D light sources. These are **geometry/material staging assets**, not final PBR models, approved ship engineering mechanics, or cinematic-quality artwork.

Within the room, four actual `Area3D` probes map to the ORIGINAL `JobScene.interact()` positions:

| Physical 3D inspection | Existing authoritative event |
|---|---|
| Phase reference | `inspect_reference` |
| Containment | `inspect_containment` |
| Fuel reserve | `inspect_fuel` |
| Ionia's safety checklist | `preflight` |

Every line of the original Ender/Ionia dialogue remains authoritative and shown in the 3D dialogue panel. The single original `Opening.complete_engineering_checks()` advances to `preflight` only after three completed station inspections and the final dialogue line. Early checklist access, repeated inspection and an unauthorized gangway are rejected.

**Important:** The real 3D flight/water simulation does **not** exist yet. The 3D scene now explicitly says flight is not implemented instead of incorrectly advertising the original F key; only the existing normal First Wake scene is allowed to launch its already tested flight, sea touchdown, postflight reserve and save sequence. This new room does not imply the Aureate Wake's submersible or Moon Bridge capability is unlocked.

## Native evidence and visual acceptance boundary

The first true engineering head `274b0e6938fe4c8ee6ba141ae5341aa6b0af47b9` passed official Godot 4.7.2 [GitHub Actions run #40937168061](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40937168061): **46** existing 3D navigation, **48** original flyer/Ionia/boarding, **80** full physical engineering and preflight, and **48** original First Wake flight/water/save regression checks. The scene and original 3D coast also rendered in actual CI.

The separate native [visual capture run #40937547028](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40937547028) produced **three actual 960×640 Godot OpenGL images**, showing engineering arrival, original phase-reference dialogue, and completed preflight. The images and `SHA256SUMS.txt` are retained in review-only artifact `first-wake-3d-engineering-real-gpu-evidence`. These demonstrated the real room and UI, but exposed an unsatisfactory outside-looking-in camera.

The subsequent interior-composition pass [native run #40938154384](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40938154384) passed **all** dedicated CI steps, including the stronger roof/camera/lighting assertions, and recaptured three native frames. Artist review confirms enclosed camera/ceiling and clearer engineering focus, but **final cinematic visual acceptance remains withheld**. The colored cubes are temporary debug interaction beacons, and the source-approved 3D Ender and Ionia character models do not yet exist.

The last code change makes the 3D preflight message explicitly deny unimplemented flight. **Final exact-head CI must pass before this last UI revision is certified.**

## Production boundary and next work

- The owner’s Windows Desktop Commander remained **offline** during PR #602; therefore Windows native performance/visual acceptance and Windows shortcut promotion are **not verified** for this PR. The existing local preview still targets an older branch.
- Normal Godot F5 remains the earlier native First Wake; no main merge, original-party save modification, canon revision, unapproved creator-art distribution, or Windows release/security bypass occurred.
- Replace diagnostic floor cursor and colored beacons with creator-approved rigged Ender/Ionia, authored station props and accessibility-compliant environmental interaction affordances.
- Model detailed PBR engineering materials, sea/ship interior relationships, accessible camera behavior and cinematic lighting on representative Intel Iris Xe hardware.
- Then implement and verify the transition into actual **3D flight physics** with genuine water contact and save-equivalence proofs; **do not fabricate continuity from the 2D fallback**.
- Require independent creator art acceptance, gameplay regression, Windows Defender-on verification and explicit release authorization before production promotion.

**The intended outcome is a complete, playable, source-authoritative 3D Chapter One—this slice is an important tested increment, not the finished result.**
