# Weapon choreography — native review pass 2

**Status: IMPLEMENTED REVIEW FIXTURE / PROPOSED TECHNIQUES / NOT PRODUCTION-CANON ART.** All source lives on an isolated stacked branch above [draft PR #415](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/415).

## Changes

- A deterministic `weapon_action_timeline.gd` produces 5 named phases — anticipation, formation, release, impact, aftermath — for **idle, attack, guard and victory** in each of the four preliminary weapon families (16 combinations).
- Angles, body lean, step offsets, contact effects and rifle recoil are family-specific rather than cloned animations. Animation clocks are deterministic and clamped; invalid weapon/action inputs produce no pose.
- A neutral **mannequin battle study** depicts local depth planes, rigged geometric weapon silhouette, braced feet, a static practice target and restrained physical contact cues. It is *not* an approved protagonist sprite, an authored enemy or a complete gameplay battle scene.
- Independent `weapon_choreography_review.tscn` at 960×640 supports weapon selection, action selection, play/replay, 0.1s step and timeline scrubbing. A reduced-motion toggle removes flashes, recoil, bobbing, foot advances and rotational flourish while preserving readable action-phase labels.
- Existing `weapon_silhouette_review.gd` now supports an optional backplate-free presentation for the same actual weapon art node. Previous weapon-tree UI retains its backplate and behavior.

## Authority / exclusions

**ESTABLISHED:** Ender’s full-length midpoint-wrapped, double-ferruled staff; Reson’s rifle, sword and pike vocabulary; chosen job/class skill paths do not erase the five story-energy affinities.

**PROPOSAL:** weapon item details, technique names, battle choreography and timing, material cues and stage design. The training mannequin is intentionally anonymous to avoid superseding creator-approved character appearances.

**NOT IMPLEMENTED:** attacks are not executable, HP is unchanged, ammo is not modeled, resources are not consumed, input is not bound to actual combat turns, no actor obtains permissions, no loot or saves change, and no release/merge is authorized. The 16 studies cover *visual action families*, not 16 authorized learned skills.

## Evidence protocol

Official pinned **Godot 4.7.2** CI imports the native project, reruns base tree tests, exercises choreography state determinism and its instantiated stage nodes, and renders four 960×640 comparison PNGs with OpenGL/Xvfb. Runner hashes and frame-difference checks distinguish visual states, not polish or correctness of animation arcs. Existing hosted artifact storage restrictions may prevent full-frame delivery.

Execute locally with the Godot project open and run `res://scenes/weapon_choreography_review.tscn` using F6; do not alter the Chapter I main scene. Native test command:

    godot --headless --path godot --script res://tests/weapon_choreography_review_test.gd

CI visual captures use the rendered script `res://tests/capture_weapon_choreography_review.gd`.

## Next acceptance gates

1. Review actual authored rendered frames / video, posing anatomy and weapon pivot stability at native 960×640.
2. Replace geometric mannequin/weapon placeholders with provenance-tracked layered art and per-character directional rigs, without replacing locked character appearances.
3. Define author-approved animation events, hit window, target/collision contract and resource-cost policy before any executable weapon action.
4. Connect equipment to battle scene rendering only after compatible slot/permission matrices and persistence behavior are approved.
5. Keep reduced-motion and accessibility behavior, regression tests, native Windows/Defender custody, and creator visual acceptance as independent gates.
