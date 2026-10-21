# Creator-approved Ender source ↔ current native directional stack

**Review-only integration — NOT art admission.** Exact parent: draft PR #313 at `66ae264071681ff7b3d2fd0e7663b450288acc20`. No protected main changes.

## Source authority
- Creator-approved appearance: draft PR #261, `art-staging/field/ender/approved-appearance-20261008.png` at commit `1e54efdc313067c7361a74438fda201112167cca`.
- Exact original Git blob: `61e8ebaf121100efbbdce321afd98d6d880fe5a4`, now referenced unchanged as `godot/art-review/ender-approved-reference.png`.
- Exact approved SHA-256 (checked by CI): `619517944ebe12b295bf5f780abb1a49bce2449230654fb8c49b11e8380546fd`; 1,352,358 bytes; 1024×1536 RGBA.
- Creator's visual rules: auburn hair, bright green eyes, green-glass brass goggles, olive-and-cream field-scholar clothes, leather satchel, boots, wooden fighting staff with *leather grip at center*, bare wood on either side and modest brass ferrules.
- Earlier prototypes and mirrored/independently authored directional strips cannot override this appearance proof.

## Existing directional and native review provenance (unchanged)
- Draft #310 already provides independently authored north/south six-frame SVGs, which are animation *candidates*, not creator-approved appearance equivalents.
- Draft #313 adds six independently posed west frames with opt-in, non-mirrored carry; the original east 384×96 PNG from #308 is preserved. CI verifies genuine Godot imported pixels, movement and reversible states.
- Draft #311 / #312 add grounded dock and four directional Ionia studies. Their artist approval is unestablished.
- Draft #314 separately demonstrated exact SHA-256 source recovery and four *runner-only* same-scene captures. This branch **reuses only the source blob and source-verification script**, rather than repeating renderer workflow and GitHub-artifact quota logic.
- `docs/reviews/Aetherwake_Actual_Godot_Ender_East_West_2026-10-21.svg` from #313 contains *real 480×320 lossy downsamples* of 960×640 native east/west scenes, not substitutes for retrievable original PNG evidence or human visual inspection.

## Review sequence
1. Verify original approved source SHA-256, size and dimensions in CI **before** running native Godot tests.
2. Compare every existing north/south/east/west frame at native 1× against approved costume silhouette, center-wrapped grip, staff hand/carry side and ground contact, documenting any discrepancy. Merely possessing approved source bytes does not establish that the candidates satisfy them.
3. Only after human evaluation, create corrective *new candidates* on a separate review branch, not overwrite existing source, and rerun real native capture tests.
4. Keep original lossless native capture bytes in approved private custody with exact-head/hash manifest and recipient download verification. CI logged hashes alone do not satisfy custody.

A separate ChatGPT art study of 64×96 front/back neutrals exists for comparison but is *not* submitted to this GitHub branch and has not been run in Godot; it must not be confused with #310's authored six-frame SVG work.

**Holds:** `APPEARANCE_REFERENCE=CREATOR_APPROVED` only; `DIRECTIONAL_SPRITE_ACCEPTANCE=PENDING`; `STAFF_CONTINUITY=NOT_ACCEPTED`; `FIELD_PACK_READINESS=NOT_READY`; `VISUAL_ACCEPTANCE=PENDING`; `EVIDENCE_CUSTODY=NOT_ESTABLISHED`; `PRODUCTION_ENGINE_MIGRATION=NOT_ADMITTED`; `RELEASE=NOT_AUTHORIZED`.
