# Ender native north/south detail + grip v2 (review only)

**Stacked on draft PR #317**, base `f106e2bdd3eb4a5bf4880186168b2cec97e9be83`. This isolated branch reuses existing Godot 4.7.2 6-contact-phase north/south motion; original `ender-north-sixframe-candidate.svg` and `ender-south-sixframe-candidate.svg` remain unmodified for rollback. Only two opt-in Ender sprite references are switched in `pilot_actor.gd` under R review mode. West v2 and original east remain as-is.

**Visual defect being addressed:** approved Ender source PR #261 and the original east raster have higher costume/goggle/staff detail than front/back Godot field SVGs. The older north-facing draft also showed *front-facing green goggle lenses on the back of the head*, an orientation mismatch.

**Independent six-pose v2 edits:**
- North: remove rear-facing duplicated front goggle lenses, replace with auburn rear hair texture and dark back-of-head goggle strap; add olive clothing creases, stitched vest/back crossbody strap and side satchel.
- South: add cream collar/shirt opening, brass buttons, coat seams, satchel/strap, auburn hair highlights, subtle eye/goggle details.
- Both: make a vertical full-length staff visibly separate at local x53, y8–88, brass ferrules at top/bottom, centered leather-wrapped grip y45–57, and hand overlap adjacent to grip around y49–56. Six gait poses remain distinct and default-hidden.

**Technical checks:** exact SHA-256 creator-approved appearance reference remains unchanged; Godot-native import and directional movement checks require six source IDs and six shaft/grip patterns each, unchanged 384×96 sheet geometry and 6 unique motion phases; native scene capture is required at real 960×640 and resulting lossless pixels must be recovered under private custody.

**Not proven:** physically approved staff grip, canonical handedness/carrying, final costume parity to richer east raster, artist likeness acceptance, Ionia parity, final Chapter 1 map, combat/quest/save production parity, production migration, signed merge, or release. The separate generated four-view concept sheet is not imported; its masking/pose defects preclude promotion.

`VISUAL_ACCEPTANCE=PENDING`, `STAFF_CONTINUITY=NOT_ACCEPTED`, `FIELD_PACK_READINESS=NOT_READY`, `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`, `RELEASE=NOT_AUTHORIZED`.