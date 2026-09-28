# Aetherwake Field Art Production Brief — Ender + Ionia

Status: ACTIVE / ASSET-PRODUCTION LANE
Authority: docs/CHARACTER_ART_ASSET_CONTRACT.md
Tracking: GitHub Issue #207
Visual lane: Visual V46 / PR #206
Artist handoff: docs/FIELD_ART_HANDOFF_PACKET.md

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
Ender: compact field-scholar silhouette, goggles, green/tan vest, focused stance.
Ionia: composed captain/engineer, blonde shoulder curls, structured gray/black tailoring, elegant feminine silhouette.

## Current production-reference candidates
- Ionia Canva MEDIA: MAHWb1JSSeI, 1536 x 1024. Reference sheet only.
- Ender Canva MEDIA: MAHWb1sPKPY, 1536 x 1024. Reference sheet only.

These references do not change manifest status and are not runtime strips.

## Admission sequence
1. Review reference sheets against canon.
2. Produce all five strips per character.
3. Run `npm run verify:field-pack-readiness:strict`. This is the **pre-promotion mechanical completeness gate**: exact action set, canonical frame counts, 64×96 cells, exact strip dimensions, PNG validity, and alpha capability.
4. Regenerate exact-head runtime evidence and compare the production strips against the provisional bridge art at actual display scale.
5. Complete the independent human silhouette-recognition check (minimum 5 participants; ≥80% correct) and record the result plus the exact-head runtime review using `docs/field-art-admission-template.json`. The runtime receipt must explicitly record **PASS** for the Chapter 1 visual suite, complete browser route + replay, exact-head evidence capture, visual-performance verification, and before/after cohesion review; a single summary PASS is insufficient.
6. Only after steps 3–5 pass, change the character manifest status to `ready` / `field-ready`.
7. Run `npm run verify:field-pack-admission`. This is the **post-promotion admission gate** and requires both ready status and valid evidence receipts.
8. Run the Chapter 1 visual/browser/performance regression gates and regenerate the final exact-head evidence bundle.
9. Human/player G4 acceptance remains a separate final visual gate and is not implied by field-art admission.

