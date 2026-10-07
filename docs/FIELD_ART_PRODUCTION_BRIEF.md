# Aetherwake Field Art Production Brief — Ender + Ionia

Status: ACTIVE / ASSET-PRODUCTION LANE
Authority: docs/CHARACTER_ART_ASSET_CONTRACT.md
Tracking: GitHub Issue #207
Visual lane: Visual V46 / PR #206
Artist handoff: docs/FIELD_ART_HANDOFF_PACKET.md
Human silhouette procedure: docs/FIELD_SILHOUETTE_RECOGNITION_KIT.md

## Purpose
Produce production-ready JRPG field art that visually belongs inside the authored Aetherwake environments.

This brief does not promote any candidate asset. The runtime remains fail-safe and procedural until a full pack passes the strict readiness gate.

## Shared production contract
- transparent PNG strips;
- 64 × 96 frame cells;
- consistent grounded foot line;
- consistent character scale, palette, and camera orientation;
- three-quarter gameplay-facing presentation;
- readable silhouette at actual runtime scale;
- no baked UI, labels, shadows, or background art.

## Required runtime strips
- idle: 8 frames, 512 x 96
- walk: 6 frames, 384 x 96
- talk: 4 frames, 256 x 96
- focus: 6 frames, 384 x 96
- attack: 8 frames, 512 x 96

## Identity requirements
Ender: lean young-adult field scholar with very short dark copper-brown/auburn hair, bright green eyes, green-lensed brass/bronze goggles, practical olive/green + tan/cream clothing, focused stance, and staff-primary silhouette.
Ionia: confident young-adult captain/explorer with shoulder-length curly blonde hair, green eyes, cream/light blouse, brown leather harness/utility layers, restrained brass hardware, elegant feminine silhouette, and mace-primary silhouette.

These requirements are subordinate to `docs/PROTAGONIST_VISUAL_ALIGNMENT_V1.md`; if the prose here ever conflicts with that creator-approved authority, the alignment document wins and this brief must be reconciled before asset review.

## Current production-reference candidates
- Ionia Canva MEDIA: MAHWb1JSSeI, 1536 x 1024. Reference sheet only.
- Ender Canva MEDIA: MAHWb1sPKPY, 1536 x 1024. Reference sheet only.

These references do not change manifest status and are not runtime strips.

## Admission sequence
1. Review reference sheets against canon.
2. Produce all five strips per character.
3. Run `npm run verify:field-pack-readiness:strict`. This is the **pre-promotion mechanical completeness gate**: exact action set, canonical frame counts, 64×96 cells, exact strip dimensions, PNG validity, alpha capability, per-frame cell-edge clearance, and grounded foot-line consistency within and across all five actions.
4. Regenerate exact-head runtime evidence and compare the production strips against the provisional bridge art at actual display scale.
5. Complete the independent human silhouette-recognition check (minimum 5 participants; ≥80% correct), complete a human likeness review against the creator-approved `docs/PROTAGONIST_VISUAL_ALIGNMENT_V1.md` authority, and record both results plus the exact-head runtime review using `docs/field-art-admission-template.json`. The receipt must explicitly set `likenessReview.status=PASS`, preserve the preparer's alignment-document/reference hashes, and explicitly record **PASS** for the Chapter 1 visual suite, complete browser route + replay, exact-head evidence capture, visual-performance verification, and before/after cohesion review; a single summary PASS is insufficient.
6. Only after steps 3–5 pass, change the character manifest status to `ready` / `field-ready`.
7. Run `npm run verify:field-pack-admission`. This is the **post-promotion admission gate** and requires both ready status and valid evidence receipts.
8. Run the Chapter 1 visual/browser/performance regression gates and regenerate the final exact-head evidence bundle.
9. Human/player G4 acceptance remains a separate final visual gate and is not implied by field-art admission.



## Geometry quality gate
`scripts/verify-field-art-geometry.py` provides the production-sheet geometry check that dimensions alone cannot establish. For every 64×96 frame it inspects alpha bounds and fails closed on empty frames, horizontal cell-edge contact, top-edge contact, excessive vertical occupancy, implausibly tiny silhouettes, per-strip foot-line drift greater than 1px, or cross-action foot-line drift greater than 1px.

Commands:
- `npm run verify:field-art-geometry` — development-state report; missing production strips report NOT_READY without pretending success.
- `npm run test:field-art-geometry` — synthetic regression coverage.
- `npm run verify:field-pack-readiness:strict` — now composes file completeness plus geometry and blocks while either fails.
- `npm run verify:field-pack-admission` — also rechecks geometry after promotion/evidence.


## Asset provenance binding
Every production strip is SHA-256 hashed by the field-pack readiness verifier. The per-character admission receipt must record the exact hashes under `assetSha256.idle|walk|talk|focus|attack`. Post-promotion admission compares those recorded hashes to the actual PNG bytes and fails closed on any mismatch.

This means the strips that pass human silhouette/runtime review must be byte-identical to the strips later admitted. Re-exporting, optimizing, or replacing any reviewed PNG invalidates the receipt until review evidence is rebound to the new hashes.


## Receipt preparation workflow
After production strips are mechanically complete and fresh exact-head visual evidence has been captured, prepare the non-authorizing receipt skeleton with:

- `npm run prepare:field-art-admission:ender`
- `npm run prepare:field-art-admission:ionia`

The preparer refuses a dirty worktree, resolves the full 40-character Git head, hashes all five strip PNGs, hashes `visual-evidence/manifest.json`, hashes the creator-approved protagonist-alignment document, binds the approved visual-reference SHA-256 plus per-character locked likeness status, and writes the corresponding receipt under `assets/characters/v1/admission/`.

The generated receipt remains **PENDING** for likeness, silhouette, and runtime review fields. Preparing a receipt is not admission and must never be treated as evidence that human or runtime gates passed.


## Raw silhouette-recognition evidence
Do not enter an aggregate participant count or correct-rate by hand. The admission receipt records at least five pseudonymous raw observations under `silhouetteRecognition.participants[]`, each with:
- unique participant ID;
- `independentOfImplementation: true` only when established;
- raw `correct: true|false` recognition outcome.

The verifier derives the participant count, correct count, and correct rate. Duplicate IDs, non-independent participants, incomplete correctness fields, fewer than five observations, or a derived recognition rate below 80% fail closed.


## Exact-head admission transition rule
`runtimeReview.exactHead` records the **reviewed candidate head**, not the later bookkeeping commit that admits it.

The verifier accepts exactly two states:
1. **Reviewed-head worktree:** current HEAD is the reviewed candidate head while receipt/manifest changes are being prepared, and every dirty path is restricted to the manifest and Ender/Ionia admission receipt files.
2. **Bounded admission child:** current HEAD is exactly one child commit after the reviewed head, the worktree is clean, and that child changes only:
   - `assets/characters/v1/manifest.json`
   - `assets/characters/v1/admission/ender.json`
   - `assets/characters/v1/admission/ionia.json`

Any other child commit, grandchild commit, unrelated documentation/code change, dirty post-commit worktree, or mismatched evidence-manifest bytes invalidates admission.

This avoids the self-invalidating receipt paradox while preserving exact-head review provenance.
