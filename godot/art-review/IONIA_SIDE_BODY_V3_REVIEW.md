# Ionia true east/west side-body v3, six frames each (review only)

Derived from failed visual-readability study PR #320 at exact head `f1aff7723e0413620b9df153abff0504a67015f1`. Do not overwrite the original #312 directional SVG atlases or #320's unaccepted V2 facial overlays.

**Change:** two standalone, independently constructed 3072×768 vector atlases (6 × 512×768 cells). They draw Ionia in narrow east- or west-facing full body profile rather than retaining a rear-facing coat/feet with a superimposed nose. Each frame includes side-oriented torso and shoulders, asymmetric ivory blouse/leather jacket, gold epaulet, one visible green eye, projecting nose and chin, curls to the rear of the head, crossbody band/satchel, differently layered arms, and walking-stride feet and boots. Her blonde curly hair, ivory/brown leather captain outfit, brass details and green eye remain recognizable. Body orientation uses separately authored geometry per side; **no full-sheet horizontal mirror or reused rear torso/legs**.

**Deliberate boundaries:** full-size 512×768 source per pose matches existing opt-in 0.13× native scale, retains y≈730 foot baseline and six motion phases. Only two Ionia opt-in east/west preloads in `pilot_actor.gd` change. Native First Wake, Ender art, Ionia north/south, movement bounding, collision, dock scene, story/canon, production pack and protected main remain untouched. Original #312, V2 #320 and source-approved Ender #261 are retained.

**Tests:** existing 6-frame native pixel-uniqueness, four-direction route and fail-closed option tests; source v3 body/face/leg id groups; source raster waist-span check against original V2 (at source-space y460) to ensure a material narrow side silhouette, not another subtle face patch. Fixed-anchor full native 960×640 Ender/Ionia comparisons and exact private image evidence required before judging readability.

**Acceptance:** CI proves geometry/import/capture, not art. Human review at 1× scene scale must evaluate whether east/west actually read side-on, appearance/costume continuity vs north/south, walking weight, shadow/foot contact and Ender–Ionia style parity. If not, retain negative result and do not promote.

`VISUAL_ACCEPTANCE=PENDING`; `IONIA_SIDE_PROFILE_V3=UNAPPROVED`; `FIELD_PACK_READINESS=NOT_READY`; `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`; `RELEASE=NOT_AUTHORIZED`.
