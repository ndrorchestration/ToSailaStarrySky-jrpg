# Ender image resampling review, 2026-10-19
Parent PR #262 ff6ae22. Review branch art/ender-conversion-review-20261019; not approved production.
scripts/review-ender-resampling.py derives LANCZOS and BICUBIC alternatives from saved source sheets and conversion receipt.
10 RGBA strips at 64x96, 64 frame instances; opaque foot baseline y=93; review-manifest.json hashes all variants.
Only both candidateFieldArt=1 and enderReviewResample=lanczos or bicubic enable the alternate renderer; normal paths unchanged.
Automated opt-in/fallback test: tests/ender-resample-preview-contract.test.js.
Capture with AETHERWAKE_CANDIDATE_FIELD_REVIEW=1 and AETHERWAKE_ENDER_RESAMPLE_REVIEW=lanczos or bicubic.
These alternative resamplings preserve shading, not real source-scale detail or corrected gait/carry/weapon behavior. Human art review pending.
Ionia needs independent quality source production; not fabricated or admitted.
FIELD_PACK_READINESS=NOT_READY; VISUAL_ACCEPTANCE=PENDING; HUMAN_PLAYER_ACCEPTANCE=PENDING.
