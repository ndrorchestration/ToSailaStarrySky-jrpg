# Aureate Wake — Actual Four-Wing Godot Rendering Inside Chapter I (Stage B0)

**2026-10-27 | REVIEW-ONLY / NONCANONICAL ART / NO RELEASE OR MERGE AUTHORITY**

## Exact lineage and claim

- Base [Ionia-first Chapter I Stage A adapter #507](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/507) at `e4c56486904d87875f440de32ec527c9360234f7`. This inherited native scene already validates real flyer → Ionia hiring → gangway → engineering → guarded visual cue; the last code-bearing Stage A head passed Godot native tests.
- Original 3D `ship.gd` source pinned to [neutral wing/pose #490](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/490) at `7abee4f14971868f52626d032d238c7140e0c457`, blob `b21327071e2120fd75113d6051af17dd2c45dbfd`. Copy to `godot/scripts/ship_visual_3d_rig_study.gd` intentionally preserves source without ingesting the second flight-slice project.
- **New visual proof:** `first_wake_ship_pose_3d_review.gd` creates an independent 480×270 Godot `SubViewport` with the **actual four-wing source model**, lighting and camera. A `TextureRect` presents it at 394×222 resolution in the actual 960×640 Chapter I engineering review scene only after explicit QA opt-in. It is not the 3D world vessel, walkable scene, or accepted ship art.
- A separate test-only scene method wraps existing neutral 1.8s pose-API requests and automatically releases the 3D render tree if the player changes room/story, opts out, or restores a v2 checkpoint. No bound gameplay input, automatic ship animation, story flag, resource/crew permission, route, story revelation, combat, save version or collision is introduced.
- Existing chapter gameplay runs without a `SubViewport` and with **zero default 3D ship instances**.

## Test matrix

| Stage | Test evidence | What it cannot prove |
| --- | --- | --- |
| Source | Byte-identical script blob from pinned #490, four original articulated membrane rigs | Final production asset/licensed model |
| Admission | Real Chapter I flyer/hiring/gangway, explicit existing ship-space opt-in, fail-closed earlier stage | The ship is navigable or flyable in Chapter I |
| Animation | Native actual wing Y rotations 0 → 7.5° → 15°, interrupted reverse, invalid delta, reduced-motion snap | Continuous cinematic quality / robust full pose modes |
| Persistence | Immutable party, actor bounds, objective, v2 checkpoint, Resonance locked; save/load and opt-out destroy temporary renderer | Saved legitimate production visual state |
| Native GL | Genuine 960×640 same-scene off/neutral/midpoint/swept screenshots with independent pixel changes through both visual motion stages | Windows GPU perf, motion-video, camera/player approval |
| Physical | Separate standalone test scene, no colliders or passenger geometry in this review | Actual wing-vs-dome/foredeck clearances or safety |
| Human art | Creator review still required | Final aesthetic fidelity or canonical geography |

### Physical scale still fail-closed

Independent cabin, glass bridge and boarding proposals are **not** interchangeable metre-scale representations. Existing bridge review [#482](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/482) exposes a provisional 3.80 m dome vs 2.35 m threshold and 1.825 m summit height vs 2.05 m review minimum. The ordinary foredeck [#452](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/452) and boarding [#461](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/461) remain another branch line. No scale conversion, pressure seam, collision or occupied-wing volume is authorized by matching pixels in a viewport. Do **not** move the full ship art into a player-collidable scene until a single unit system and complete hull/cabin/bridge/foredeck/entry layout are reconciled.

### Initial native visual receipt and refinement

At first implementation head `3149f6458c3abe905e3f62e87916b0805526be9b`, [Godot CI run #40624681728](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40624681728) completed **SUCCESS** with `FIRST_WAKE_NATIVE_WING_RENDER_PASS checks=43`, inherited pose-port 38 and ship-space 32 checks, and three authentic 960×640 captures. Godot screenshot receipt reported 9,017 sampled changed pixels for the inset and 586 for the full wing sweep. The preview showed the actual ship model and legible movement but the ship occupied too little of the inset for confident artistic review.

Follow-up changes narrow the **test camera field of view** and take **four** screenshots: off, neutral, 50% wing pose and final pose. The camera/art refinement modifies no physical geometry, story or controls. Its new head **must pass fresh exact-head CI** and the new frames must be inspected before claiming visual improvement. Neither the earlier three-frame CI result nor metadata from its commit can be inherited as evidence for the new head.

### Open production gates after this test

1. One creator-reviewed metre-scale whole-ship geometry contract, with deck/door/headroom and original four-wing root alignment.
2. Real physical Godot 3D scene with crew capsules, foredeck occupancy, masts, dome, wing swept-volume and closing/failure-state tests; no passenger clipping.
3. Noninterrupted/interruptible continuous wing animation at actual player-camera distance, weather transition, camera shot continuity and reduced-motion alternatives.
4. Exact-head Godot 4.7.2 CI, Windows Forward+/Compatibility GPU frame pacing/VRAM, accessibility, creator art signoff and game/save/player QA. Do not weaken hosted Defender custody prerequisites to clear Windows workflow failures.
5. Carefully approved branch reconciliation with independent Chapter I, physical ship and visual-art lineages, then separate merge/release decision.

No unreleased vessel mode names, private navigation/clue logic, or future destination details are present here. Protected design authority remains outside public GitHub.

**Approval:** TEST-ONLY STUDY / NOT A PUBLIC FEATURE / NO MERGE OR RELEASE.
