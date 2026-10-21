# Measured Ionia east/west boot-sole world-motion risk — 2026-10-21

**Source of record:** draft PR #329, actual Godot 4.7.2 exact test commit `b02923dc3bd839b673e646fc3f260e55a6d27c2a`, [hosted native workflow #39679961260](https://github.com/ndrorchestration/aetherwake-jrpg/actions/runs/39679961260), job `119499557590`. This report contains the **observed output**, not an acceptance statement.

## Experimental setup

The test imported the existing native First Wake GDScript scene and ran Ionia's original bounded CharacterBody2D four-leg route. It read the **six separate authored rear/front boot path elements** from each of the opt-in V4 east and west 3072×768 SVG sheets, selected the geometrically lower vertex as a trace landmark, and projected that coordinate through the actual Sprite2D transform to world space during real native movement. Each imported sheet contains six 512×768 pose cells; the test checked source geometry, actual phase visibility, source boot positions and all six phases. It does **not** edit the sprite source or runtime motion.

The source-derived geometric marker is the **third polygon vertex of the boot path**, y=731 for the rear boot and y=727 for the front boot in all side phases. The lower rear vertex is *not* an authored or human-accepted stance/plant event. Tracking it answers whether the visible sole's underlying picture-point translates through world space while its source atlas frame is held—not whether it is the physically planted foot.

## Exact measured results

| Metric | East-facing V4 | West-facing V4 |
|---|---:|---:|
| Parsed rear/front authored boot pairs | 6 | 6 |
| Actual phases covered | 6/6 | 6/6 |
| Moving ticks where the selected same-frame marker was compared with its previous tick | 81 | 81 |
| Maximum world-space displacement across one held atlas frame | **13.6 px** | **13.6 px** |
| Cumulative selected lower-boot-marker movement across same-frame comparisons | **92.07 px** | **92.07 px** |
| Lower-boot motion risk diagnostic (≥3 px held-frame travel) | **OBSERVED** | **OBSERVED** |
| True planted-foot slide | **NOT ESTABLISHED** | **NOT ESTABLISHED** |

Existing independent route trace at the same exact head: 382 world pixels, 336 active physics ticks, all six phases on all four legs and maximum 13.6px translation of the root during held poses. The new boot point observations are correlated with root motion because the selected source point has no intra-phase offset. The test independently ties that displacement to an actual drawn boot vertex rather than substituting the root as a *foot* location.

**Interpretation:** The lower visible boot picture-point translates substantially while its shape does not update. It is a concrete **apparent-foot-motion risk** worth checking in a real native walking playback. It is *not* a validated planted-foot slip magnitude: the artist has not identified which foot should be contacting the dock, on which phases, or at what intervals. A foot may appropriately move during swing. No biomechanical, animation-beauty or zero-slip claim is authorized.

## First failure, correction, and custody

- First exact-head attempt `2af9eaaa20d18383c0f817370095ee62afa6c60f`, [native run #39679745023](https://github.com/ndrorchestration/aetherwake-jrpg/actions/runs/39679745023): **FAIL**. Godot parser rejected the inferred source path type at line 48. No boot-motion result was obtained, so it must not be cited as animation evidence.
- Child commit `b02923dc3bd839b673e646fc3f260e55a6d27c2a`: one-line explicit `var path: String` correction. [Native run #39679961260](https://github.com/ndrorchestration/aetherwake-jrpg/actions/runs/39679961260) **PASS** with the measurements above. Renderer and legacy smoke workflows also **PASS** at this exact head.
- Prior actual native moving-path screenshots and SHA-256/source receipts remain in [PR #328 private native evidence directory](https://github.com/ndrorchestration/aetherwake-jrpg/tree/d203aadeee44b7e21ca505a1e0f7aeaeb010e448/docs/reviews/native-evidence/2026-10-21-pr328); no new screenshots or screenshot custody are claimed by this measurement-only test.

## Reversible next test / acceptance requirements

The minimum next legitimate evidence should use a separate, provenance-bound annotation for each of the six east and six west poses, specifying **left/right stance or swing**, contact timing interval and heel/toe target with a real reviewer and source. The accompanying `IONIA_SIDE_STANCE_ANNOTATION_UNASSIGNED.json` explicitly keeps all such entries **UNASSIGNED**. Only after the separate author/reviewer annotation could a world-space 2D boot landmark trace quantify *candidate planted-foot slide* against a fixed dock reference, with native render/time-based inspection and an explicit acceptance threshold. Do not infer annotations merely because the rear polygon extends four source pixels lower.

No main merge, opt-in art promotion, canonical character rewrite, physics/body velocity adjustment or production release was made. The host `neontic` was offline when this trace was developed; Windows GPU replay is not claimed.

`SOLE_SOURCE_AND_RUNTIME_TRACE=TECHNICAL_PASS`; `LOWER_BOOT_MOTION_RISK=OBSERVED`; `STANCE_PHASE_LABELS=UNASSIGNED`; `PLANTED_FOOT_SLIDE=NOT_ESTABLISHED`; `HUMAN_VISUAL_ACCEPTANCE=PENDING`; `FIELD_PACK_READINESS=NOT_READY`; `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`; `RELEASE=NOT_AUTHORIZED`.
