# Ionia Original Pixel Art Study (2026-10-19)

Status: **REVIEW_ONLY / NOT ACCEPTED / INCOMPLETE ANIMATION / P0 STILL OPEN**.

## What this branch actually contains
- A **reproducible procedurally hand-authored sprite study**, created by `scripts/make-ionia-walk-review.py`. Six different leg-stance poses were drawn as layered RGBA pixel illustrations with curl clusters, adult captain's white shirt/navy-and-gold coat, epaulettes, sash, leather boots, facial features and hard-edged shading.
- `art-staging/field/ionia/review/ionia-walk-source-6frame.png`: 1152×288 (six 192×288 source cells); derived `ionia-walk-6frame-review.png`: six 64×96 cells, alpha bounds recorded in `source-receipt.json`, with SHA-256; short demonstrator GIF included.
- A **two-flag opt-in** `?candidateFieldArt=1&ioniaReviewArt=1` in the existing PR #262 candidate renderer, which routes `walk` to this 6-frame strip and routes `idle` to a **single static first pose** for screenshot composition only. No authored talk/focus/attack/idle animation exists in this study; those actions fall back as before.
- No production sprite pack status or asset readiness changed. Portrait/costume consistency remains a creator review question. The new source is artwork, not a machine-learned image extracted from a hypothetical marketing poster.

## Important negative finding
The new six-frame source is original and more captain-coded than the old tiny brown placeholder, but currently **stylized procedural chibi art with limited anatomy, little real material depth, limited curl volume, and visibly repetitive motions**. It does *not* match the visual sophistication of Ender's existing approved-likeness-derived high-resolution art and is not the user's requested finished expressive anime 2.5D presentation. Better future artwork should be painted/illustrated at high source resolution with genuine directional views, lighting passes, and separate hand-timed gait/cloth movement.

## Validation boundaries
- Existing opt-in guard test `tests/ionia-art-review-contract.test.js` ensures no review loads without both flags and `isFieldReady('ionia')` remains false.
- Browser and Chapter 1 tests remain necessary but are technical-only.
- Direct capture must show Ionia in the actual dock scene, not merely PNG transparency sheets. Record exact source SHA, clean working tree, image hashes, and screenshots; visual quality remains **PENDING/FAIL** until creator approves.
- Do not merge this into main or substitute a review for final Ionia art.

## Next production steps
1. Obtain approved Ionia full-body high-detail image turnaround (front/three-quarter/profile/back), respecting age 28, blonde shoulder-length curly hair and experienced captain design; reconcile any costume decisions with existing canon.
2. Paint real 64×96 frame set at target rendered scale using that turnaround rather than algorithmic shape assembly; adapt palette to Ender's source and intended lighting.
3. Complete and inspect real idle (8), walk (6), talk (4), focus (6), attack (8) *distinct frames*, directional walking and gait-contact timing. Do not claim action coverage from mirrored/reused poses.
4. Compare two characters together at actual 960×640 logical scene size with physically supporting authored dock geometry and admitted art identity.
5. Human art review, field-pack provenance/admission and player acceptance remain independent gates.

References: [Draft PR #295](https://github.com/ndrorchestration/aetherwake-jrpg/pull/295), [Visual Recovery Plan](https://app.notion.com/p/3fef5bad238b81358ee3e85a1fc27467).
