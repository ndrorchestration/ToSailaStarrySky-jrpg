# Ionia cohesive four-view study — front/rear V5 (2026-10-21)

**Review-only.** Stacked on native art PR #323 exact head `7554cfe618e4d762963512dc3d25635b46393fc0`. This is NOT an approved character sprite set, production engine migration, story/canon update or release artifact.

## Evidenced reason for the change

Authentic native Godot 4.7.2 960×640 fixed-anchor images were inspected: enhanced Ionia V4 east/west hair and leather coat silhouettes read substantially fuller, while forward and rear shots inherited different curls, wardrobe details and rendering density. Tests of frame count alone had no bearing on this cross-view inconsistency.

## Exact isolated artwork

- `ionia-front-cohesion-v5-candidate.svg`: six 512×768 separately posed cells derived from the **unchanged** layered front atlas; added curled-hair edge highlights, small opposing step-dependent edge curls, cream blouse collar, dark leather harness/utility pouch, captain epaulets/brass accents and articulated coat tails.
- `ionia-north-cohesion-v5-candidate.svg`: six separate cells derived from the **unchanged** rear atlas; smooth shoulder-length blonde mass and fewer larger curls (rather than circular ringlets alone), leather cross-straps/satchel with small brass trim, coherent hem lines and motion-dependent curl/coat elements.

Both retained the original contact and boot geometry and all baseline source SVGs for reversible compare. Their existing colors remain referential, not a creator-approved material design. The two new sources are loaded **only** in the existing unapproved opt-in front/rear Ionia Sprite2D controls; the accepted Ender appearance and v4 east/west profiles are not edited.

## Native evidence contract

Current `ionia_four_direction_test.gd` must pass original four-way real Godot bounded walking/idle/default-off checks and native importer checks. Each of the six forward/rear V5 cells must have its own cohesive hair, coat and utility layers that actually change native raster pixels within head and fabric regions **while the boot/ground-contact region stays unchanged**. This is a structural/art-footprint invariant, not a measure of aesthetic improvement. The existing fixed-anchor native renderer and private full-frame PNG custody remain the authoritative way to inspect real 960×640 character comparisons.

## Admission and parallel draft

PR #322 is a **sibling** of the art stack and changes `pilot_actor.gd` for conversational pausing. Nothing in V5 implies those independently tested actor-state changes are integrated. Before either is admitted, reconcile #322 and the completed art stack in one isolated branch, run dialogue/movement/render tests, and obtain explicit human review. Avoid a merge that rewrites the artistic or state boundaries.

`VISUAL_ACCEPTANCE=PENDING`, `IONIA_FRONT_REAR_V5=UNAPPROVED`, `FIELD_PACK_READINESS=NOT_READY`, `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`, `RELEASE=NOT_AUTHORIZED`; Defender #293 continues to hold.
