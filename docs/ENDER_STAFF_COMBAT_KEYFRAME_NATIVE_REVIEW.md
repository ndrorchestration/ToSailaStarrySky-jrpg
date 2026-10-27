# Ender directional staff combat pose authoring — Godot native review

**Status:** IMPLEMENTED candidate code / UNAPPROVED procedural combat art / no executable battle integration.

**Parent:** draft PR #453. The creator-approved 1024×1536 Ender appearance source at `godot/art-review/ender-approved-reference.png` remains unmodified. Existing directional *walking* candidates remain separate, with their documented visual and source-identity limitations. The new pose rig is **original authoring**, not a relabeling of walking frame 0.

## Authored physical beat framework
- `godot/scripts/ender_staff_combat_keyframe_review.gd`: four explicit directional rigs (**east, west, south, north**), each with six transition keys defining initial stance, anticipation, formation, release/strike, recovery and restored stance. Each rig interpolates staff angle, forward/backward step, knee bend, torso inclination, stance width and two-handed grip.
- Original body-layer drawing includes boots/legs, olive field coat, cream details, satchel, auburn hair, brass-green goggles or rear strap, two articulated arms and independently rendered wooden fighting staff. This is an intentionally simple production-planning geometry study, **not** accepted Ender combat sprite artwork.
- Staff total visual length: 168 native drawing units; center leather wrap spans ±23 around its midpoint; brass ferrules end-cap both ends. Two hands attach at points ±11 along the staff's center axis, constrained inside the wrap through all rotations.
- Foot-contact geometry preserves the deck plane at local y=112 in every frame; bodily anticipation/launch/recoil move the knees, hips and shoulders instead of sliding the footwear off the deck.
- Source identity `ORIGINAL_PROCEDURAL_COMBAT_CANDIDATE_NOT_ACCEPTED_ART`. Authored per-facing motion channels are not Godot `Sprite2D.flip_h` tricks and do not change the existing walking images or claim exact canonical appearance.

## UI and optical constraints
Open `res://scenes/weapon_directional_cinematic_review.tscn` with Godot 4.7.2 and F6. The original A/B **walking directional candidates vs. geometric mannequin** is preserved. Use the independent **Combat keyframes** button to compare the newly authored four-direction animation; stage actor, old geometric staff and mismatched mannequin contact trails are hidden whenever these authored poses are shown. Playback, scrub, step, four facings and reduced motion work independently of gameplay.

The script is fed only through the existing `Ender + full_length_staff + staffStrike` visual-intent route, after checking Chapter I party and formula authority. **No combat command is issued.** No hitbox/hurtbox, damage, HP/resource expenditure, enemy retaliation, gear assignment, encounter progression, chapter state, save writes, merge or release is changed.

The reduced-motion setting retains accessible textual phases but freezes drawn physical geometry at the grounded opening stance. It also removes the optional stage zoom, displacement and target contact flash. This is a preliminary accessibility implementation, not a substitute for full controller/screen-reader testing.

## Verification and evidence
- `godot/tests/ender_staff_combat_keyframe_review_test.gd` checks **20 physical beat samples** (five progress points × four facings), hand-to-wrap attachment, full staff length, body/weapon change per beat, planted feet, distinct facings, reduced-motion freeze, non-execution and rejection of spoofed actors/weapons/actions.
- Previous native weapon mastery, choreography, visual adapter and directional comparison regressions rerun unchanged.
- `godot/tests/capture_ender_staff_combat_keyframes.gd` captures **20 native 960×640 stage frames plus one reduced-motion frame**; hashes and a stage-only 5×4 storyboard thumbnail (plus the reduced frame) are emitted to GitHub workflow logs. The lossless full frames remain CI-runner-only. Hashes and downsampling do not establish animation polish or provenance acceptance.

## Next artistic acceptance gates
1. Inspect actual frames at native resolution for hand anatomy, facing parity, goggle lens orientation, stance silhouette, floor contact, wrapped staff continuity, and distance to practice target.
2. Refine turn silhouettes and per-direction arm/torso articulation; create distinct pixel/painted production-ready combat assets and confirm visual agreement against approved Ender likeness without changing that source.
3. Add keyframe export with layer provenance, timing events, animation atlas/texture import and performance QA only after candidate review. Captured PNGs in CI are not shipped sprite sheets.
4. Integrate a strictly authorized visual playback event after a separate formula/turn/weapon/equipment permission review and backward-compatible save contract.
5. Resolve Chapter I storyboarding conflicts, Windows Defender security custody, controller/reduced-motion accessibility and creator approval independently. No draft PR may silently promote this candidate to canon or production.

## Actual native storyboard QA — October 27

The 21-frame rendered Godot contact sheet was inspected. It shows four independently authored direction tracks, staff angles changing across anticipation through recovery, a full-length wrapped and double-ferruled staff, and planted boots. These visual studies are schematic and require much more detailed character and weapon art.

A neutral ferrule-tip-following motion arc and small boot dust cue were added only during release/contact. They are optical, nonmagical, and are disabled by reduced-motion mode. Native tests enforce their timing and nonexecution.

The optical addition initially introduced a duplicate-local-variable Godot parse error. Direct source diagnostics located the second `axis` declaration, which was renamed. The corrected native Godot 4.7.2 run passed its full choreography, native-scene, old regression, and 21-frame capture gates. Keep the direct parser guard in the workflow.

Remaining visual gaps: torso profile is still stiff at several keyed beats; boots are grounded but simplistic; hands and staff materials require author-quality textures; the practice target does **not** receive a physical staff hit; new pose studies do not match the production fidelity of the creator-approved Ender portrait. No sprite atlas, combat hitbox/reaction, audio, user-facing integration, full PNG delivery, or artistic acceptance has been established.
