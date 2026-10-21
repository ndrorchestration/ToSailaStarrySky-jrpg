# Ender appearance: immutable review binding (2026-10-21)

Status: SOURCE_BOUND_BY_GIT_BLOB; SHA256_RUNTIME_VERIFICATION_PENDING; FRONT_BACK_POSES_NOT_AUTHORED; VISUAL_ACCEPTANCE_PENDING.

The approved appearance was recorded on [draft PR #261](https://github.com/ndrorchestration/aetherwake-jrpg/pull/261), commit `1e54efdc313067c7361a74438fda201112167cca`. The source itself remains unmodified: Git blob `61e8ebaf121100efbbdce321afd98d6d880fe5a4`, bound here at `godot/art-review/ender-approved-reference.png` by Git object identity, not resampling. The documented SHA-256 receipt is `619517944ebe12b295bf5f780abb1a49bce2449230654fb8c49b11e8380546fd` (1,352,358 bytes, 1024×1536 RGBA). The receipt is checked independently in CI using `godot/tests/verify_ender_provenance.py`; adding the Git blob does not itself independently attest its SHA-256.

The approval is **appearance only**: auburn hair, green eyes, brass goggles with green lenses, olive/cream field scholar outfit, satchel, boots, centered leather staff grip, wood exposed on each side, modest brass ferrules. Source of authority: `docs/ENDER_APPROVED_APPEARANCE_2026_10_08.md` on PR #261 and `docs/PROTAGONIST_VISUAL_ALIGNMENT_V1.md` from PR #295. The latter visual-alignment instructions override earlier prototype-era character-art text.

The separate six-frame side strip `godot/art-review/ender-walk-candidate.png` derives from PR #295 commit `133bb175d95b8b28772f8c802ec68b5ee8836842`, Git blob `d398f0525fd47b20d4a354a22a0acabfd600a149`. It is NOT an approved likeness authority, nor a final gait or staff-carry asset. Existing Godot pilot behavior remains unchanged.

**Directional assets are deliberately missing.** Do not mislabel the side strip or horizontal mirroring as authored front/back, diagonal, idle, or back-carry artwork. Before accepting any new 64×96 pose: record author/origin, exact SHA-256, transparent pixel format, foot baseline, consistent equipment-side mapping, and human 1× scene-scale review. Art must not appear by default; a distinct explicit opt-in is required. Missing candidates must fail closed.

A separate native Ender+Ionia capture creates genuine 960×640 renderer comparisons; Ionia's SVG is also unapproved. Captures in GitHub Actions runners are **not durable evidence** if Actions artifact upload is quota-blocked. A private evidence custodian must store the original PNG bytes, per-file hashes, source/engine/run/commit identifiers, and verify a recipient download before marking DELIVERY_VERIFIED.

Holds: `FIELD_PACK_READINESS=NOT_READY`; `VISUAL_ACCEPTANCE=PENDING`; `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`; `RELEASE=NOT_AUTHORIZED`. Draft branch only; no protected-main merge or visual acceptance.
