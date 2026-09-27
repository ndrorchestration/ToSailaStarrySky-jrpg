# Aetherwake Field Art Production Brief — Ender + Ionia

Status: ACTIVE / ASSET-PRODUCTION LANE
Authority: docs/CHARACTER_ART_ASSET_CONTRACT.md
Tracking: GitHub Issue #207
Visual lane: Visual V46 / PR #206

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
3. Run npm run verify:field-pack-readiness:strict.
4. Change manifest status only after the strict gate can pass.
5. Regenerate exact-head visual evidence.
6. Compare before/after player-eye results.
7. Complete human silhouette recognition check.

