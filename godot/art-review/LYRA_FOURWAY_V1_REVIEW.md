# Lyra directional art review v1 — NOT APPROVED

**Status: candidate implementation**, 2026-10-27. Stacked on draft PR #421. No engine-wide playable actor migration, formal creator costume signoff, final field-pack admission, save changes, or lore reveal.

## Original source atlas inventory

- Existing south: `lyra-south-sixphase-v1-unapproved.svg` (unchanged; authored in PR #421).
- New north: `lyra-north-sixphase-v1-unapproved.svg` (original back-facing hair and garment geometry).
- New east: `lyra-east-sixphase-v1-unapproved.svg` (independently drawn profile, hair framing and pink-spirit accent).
- New west: `lyra-west-sixphase-v1-unapproved.svg` (separate left-facing anatomy, no horizontal flip).
- Each: six original vector pose groups in a 480×128 source atlas (six 80×128 cells). All four are retained as editable SVG source rather than source-less raster snapshots.

**Creator-locked details preserved:** Lyra is an adult woman of 24 and Talen's mother; her long red hair must remain legible from every view. Water is her innate *plot resonance*, while pink spirit-energy is a separate established visual motif. Neither grants a playable combat spell or final job. Costume design (blue travel layers, ivory panels, brass detail) is a reversible proposal for review, not confirmed canon. Other three party members' artwork remains exactly as before.

## Reviewer controls

In the isolated Godot 4.7.2 First Wake pilot, press **L** to open the five-person review board. **F** cycles only Lyra through south → west → north → east; **[ / ]** scrubs all characters' six phases; **M** changes the review zoom/native authored scale. **L / Esc** closes it and restores the live actors. This does not animate Lyra in gameplay or authorize her recruitment.

## Verification contract

`godot/tests/lyra_fourway_review_test.gd` requires:
- Four different original SVG sources with their expected names and distinct art;
- Native Godot 480×128 texture import (not XML-only assertions);
- Six nonidentical baked frame pixels per direction;
- No mirroring of opposite-side art;
- Exactly one Lyra source visible at a time, coordinated frame indices;
- Invalid input refusal, deterministic direction cycle, scale toggling, and world pause/restore.

`godot/tests/capture_lyra_fourway_review.gd` captures four **actual native Godot** 960×640 OpenGL frames at the same review anchor and phase. It emits size-bounded JPEG inspection crops in CI logs. Original PNGs remain local to the workflow runner if artifact quota is blocked. Image inspection, movement contact validity, visual quality, character likeness and creator acceptance are **separate** decisions.

## Remaining P0/P1

- Inspect four original renderer frames at native and magnified scales, especially hair continuity, left/right asymmetry, gown/skirt occlusion, feet and material consistency.
- Verify real physics-world traversal and planted-foot windows before using these candidate frames in the playable Chapter I scene.
- Author portrait/expression and hand-gesture work only from creator-reviewed sketches; do not inadvertently turn the visual pink accent into a compulsory spellcasting job.
- Keep art review isolated from engine migration, unrelated World Map PRs and public-release approval.
