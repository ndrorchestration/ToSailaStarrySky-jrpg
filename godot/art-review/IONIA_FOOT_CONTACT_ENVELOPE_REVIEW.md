# Native Ionia contact-envelope regression ? evidence only

**Scope:** draft PR #324, source art candidate V4, Godot 4.7.2. The purpose is to prevent geometry regression while preserving `VISUAL_ACCEPTANCE=PENDING` and `FIELD_PACK_READINESS=NOT_READY`.

On the authorized `neontic` Windows Intel Iris Xe OpenGL host, the first original native Godot 6-phase four-way Ionia captures were reviewed at actual 960?640 scene scale. Exact imported RGBA atlases were then independently extracted using the same Godot 4.7.2 runtime. For each of 24 source cells (4 facings ? 6 phases), the proposed native check scans the final opaque source row within the low 88 pixels of its 512?768 source cell. It checks for image presence and a bounded lower-pixel row: expected east 734 for all six frames, west 734 for all six, south 739 for all six, north 740/740/740/736/740/740. These are **observed import results**, not claimed anatomical foot-bone locations.

A fail-closed native test rejects a missing/wrong-dimension atlas, missing or implausibly displaced lower-row content, more than **4 source pixels** of bottom-row drift inside one facing or more than **8 source pixels** across the four facings. Baseline cross-facing range is **6 source pixels**, approximately 0.78 scene pixels at 0.13 scale before any engine filtering. The existing native Ionia V3/V4 test independently proves that V4 preserves entire rasterized head and lower-leg source regions unchanged relative to V3, which prevents this costume-volume pass from reposing feet unnoticed.

**Limitations:** an opaque bottom-row test is a *sprite-footprint alignment check*, not an IK test, foot-plant/slide analysis in real motion, anti-slip physics proof, gait beauty score, human aesthetic approval, or production-quality declaration. It does not validate the fractional-screen-pixel aliasing of a swinging foot or the entire runtime collision mesh. Do not promote based on green CI.

**Reversibility:** the test and one workflow invocation are additive; no gameplay, sprite shapes, level geometry, import scale, colliders, or canonical assets change. V3 stays intact. Release and production-engine migration remain held.

`IONIA_CONTACT_ENVELOPE=VERIFIED_LOCAL_WINDOWS`; `PLANTED_FOOT_SLIDE=NOT_ESTABLISHED`; `VISUAL_ACCEPTANCE=PENDING`; `FIELD_PACK_READINESS=NOT_READY`; `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`; `RELEASE=NOT_AUTHORIZED`.
