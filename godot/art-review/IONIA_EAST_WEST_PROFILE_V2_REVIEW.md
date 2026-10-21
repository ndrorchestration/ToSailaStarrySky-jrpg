# Ionia east/west profile-readable v2 — review-only, no canonical art changes

This reversible draft sits on native fixed-anchor comparison PR #319 (`70d251c933857b259d6059a712bf7b4fa5ace494`), which confirmed actual distinct but poorly distinguishable **east/west** Ionia field poses despite valid 6-frame native imports.

This pass adds TWO **derived six-frame SVG files** `ionia-east-profile-v2-candidate.svg` and `ionia-west-profile-v2-candidate.svg`. The original #312 `ionia-east-sixframe-candidate.svg` and `ionia-west-sixframe-candidate.svg` remain unchanged and can be restored with a two-reference revert.

All six original arm/leg/coat/boot phases and 3072×768 sheet dimensions are preserved. A single later-layer facial-overlay group per 512×768 source frame adds a one-eye green side profile, ear, outward nose bridge, lips, and slight blonde hair overhang, oriented toward the intended side; the west facial patch mirrors its location only, **not the entire atlas, gait, or equipment**. The explicit layer after the existing curls is meant to make the face readable at 0.13× native field scale without losing the captain's blonde-hair identity.

Only the existing opt-in Ionia east/west source preloads in `pilot_actor.gd` change. Ionia front/back, Ender originals/v2s, first-wake placement, motion physics, surface layering, walk bounds, colliders, story, canonical source and production build remain unchanged.

**Verification required:** Godot 4.7.2 must import the two SVGs, validate six unique pose frames each, check six facial overlay groups and genuine fixed-anchor 960×640 full scene crops. Compare against PR #319 original east/west at the **same actor anchors and same dock**; do not claim a better silhouette until actually observed. Use private source-hash evidence custody already established on the draft stack.

These facial patches are a targeted visibility study, NOT human creator approval, canonical Ionia appearance selection, a complete side-body profile, or final gameplay art. Remaining relative Ender/Ionia scale, source-likeness parity, staff carry, other eight-way/diagonal poses, animation fluidity and release holds remain intact.

`VISUAL_ACCEPTANCE=PENDING`, `IONIA_SIDE_FACING_READABILITY=REVIEW_CANDIDATE`, `FIELD_PACK_READINESS=NOT_READY`, `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`, `RELEASE=NOT_AUTHORIZED`.
