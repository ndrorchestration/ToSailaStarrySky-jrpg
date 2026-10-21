# Authentic Ionia native moving-route captures — private draft PR #328

These eight images are original, byte-identical **960×640 Godot 4.7.2 moving-path screenshots**, not static character composites, AI illustration or approved art. They were produced by actual CharacterBody2D traversal in the native First Wake scene at source commit `6072c3c3865cc9994ca4a4d0b9bf8e2ca1e3a26c`, hosted [Godot renderer run #39677396431](https://github.com/ndrorchestration/aetherwake-jrpg/actions/runs/39677396431), job `119490707082`.

All eight source PNG bytes were independently reconstructed from private renderer-job log chunks, SHA-256 recomputed, source dimensions and byte lengths checked, and then committed as immutable Git blobs to this **private draft only**. Each hash and blob identity is in `manifest.json`. Reviewer must inspect the images at 1× rather than treating a green renderer job as human visual acceptance.

Native physics test run [#39677396662](https://github.com/ndrorchestration/aetherwake-jrpg/actions/runs/39677396662) measured Ionia completing her four-leg 382px route in 336 moving physics ticks. The genuine renderer measured 335 moving ticks, and both completed all six actual atlas frames in all four directions. The largest measured translation of the actor root while a pose frame was unchanged was **13.6 world px**, indicating a *potential* foot sliding source. It does **not** identify the planted foot or quantify its true slide.

Review inspection shows an attached foot-ground shadow in the moving scenes. The observed sprite side-facing volume is still thinner than front/rear. No foot-contact physical constraint, temporal video quality, human acceptance, animation smoothing, character release, canonical environment or production migration has been admitted.

`MOVING_GAIT_TRACE=TECHNICAL_PASS`, `REAL_PNG_CUSTODY=8_VERIFIED`, `PLANTED_FOOT_SLIDE=NOT_ESTABLISHED`, `SHADOW_VISUAL_ACCEPTANCE=PENDING`, `FIELD_PACK_READINESS=NOT_READY`, `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`, `RELEASE=NOT_AUTHORIZED`.
