# Fixed-position four-direction Ender + Ionia visual QA

**Review-only** script `res://tests/capture_joint_fourway_fixed_scene.gd`, stacked on PR #318 exact head `2ffb2be18b7ecc550a39a34c331eb5ff35aaab7d`.

Why: existing real Godot captures compare Ender/ Ionia while changing direction, movement phase and sometimes scene position. This makes silhouette, foot baseline, staff-side continuity and relative character scale harder to judge.

This fixture instantiates **one genuine native First Wake scene** in Godot 4.7.2 with depth dock, freezes physics on Ender and Ionia, sets anchored world coordinates Ender (350,462), Ionia (570,458), and selects a common motion phase (0). It captures the placeholder control + four Ender/Ionia facings (east, west, south, north) at the **same 960×640 viewport**, same anchored positions, same environment. It verifies precisely one direction per actor visible, unchanged anchors, actual pixel differences from placeholder in fixed 1× ROIs, and distinct image pixels across all four source facings. Source/capture hashing and private full-original byte transport use the pre-existing CI receipt system.

**Purpose:** produce direct native scene-evidence comparisons for human artistic alignment. This changes **no gameplay, canon, collision, input, art assets, approved appearance authority, production manifest, or default review toggle**. It is not an animation claim (still phases, not a continuous walk demonstration). It cannot establish actual physical staff continuity, sprite quality, independent human approval, or migration.

**Custody requirement:** until a separate reviewer recovers exact native full 960×640 PNGs from authorized private Actions logs and persists/hash-verifies them in the private draft branch, this new comparison is `RUNNER_CAPTURE_ONLY`. Existing #316 and #318 receipts remain independently immutable.

**Holds:** `VISUAL_ACCEPTANCE=PENDING`; `FIELD_PACK_READINESS=NOT_READY`; `STAFF_CONTINUITY=NOT_ACCEPTED`; `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`; `RELEASE=NOT_AUTHORIZED`.
