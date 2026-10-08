# Ender field animation candidate — 2026-10-08

The creator-approved Ender appearance now has 32 staged frames across idle (8), walk (6), talk (4), focus (6), and attack (8). These are generated animation **candidates requiring motion/likeness review**, not admitted production assets.

Use `index-embedded.html?candidateFieldArt=1` to view Ender in the real runtime. The preview loads `art-staging/field/ender/candidate/field-{action}.png` only for Ender and only behind the existing review flag. Incorrect dimensions or missing files fall back through the existing candidate/procedural paths. The field manifest and readiness state remain unchanged.

## Sources and conversion

Approved proof: `approved-appearance-20261008.png`, SHA-256 `619517944ebe12b295bf5f780abb1a49bce2449230654fb8c49b11e8380546fd`, recorded in PR #261.

All five original generated source sheets plus the back-carry study are preserved under `art-staging/field/ender/sources/`. The walk source carries the staff on the back; other action sources hold it. Further carry/draw transition work is needed to prevent an abrupt switch.

`scripts/pack-ender-review-source.js` performs mechanical grid extraction, alpha thresholding, removal of disconnected export specks, nearest-neighbor resizing and foot-line alignment. It requires Sharp in the authoring environment; no gameplay dependency was added. Conversion parameters and original/source/strip hashes are in `candidate/conversion.json`. Individual 64×96 frames are retained under the five action directories. Every strip shares foot-line y=93 and transparent cell margins.

## Review findings and next corrections

- Compact diagonal attack poses fit the existing 64×96 cells; the first wide horizontal-thrust study was rejected because it forced inconsistent body scale.
- Walk motion is more varied but opposite-leg phase continuity, staff length and gait clearance need review in motion. It is not yet accepted as a polished loop.
- Grip/ferrule detail varies across generated sheets; preserve the approved wrapping at the shaft midpoint in the final authored pass.
- Body proportions and pixel detail must be judged at actual gameplay scale, including a comparison with Ionia.
- Back-carry attachment views are studies; idle/held-to-carried transitions remain unfinished.

No independent recognition test, human gameplay acceptance or field admission has been recorded.

## Documentation rule

Before an art tranche, reconcile the Notion Visual Bible, Character Art Direction & Implementation Contract, Character Art Library, character dossier and scene-specific authorities with repository contracts and the latest creator decisions. After the tranche, update affected records with actual artifacts, revision, approval scope, verification and remaining work, then read back. Historical evidence stays labeled as historical.

## Verification of first runtime candidate

Clean reviewed head `d7ca64ef862f07c3686216be9d03b152700bd7d7`: complete Chapter 1 visual suite and browser route + replay PASS. Candidate gameplay capture produced 18 frames and 4 timing samples at 1440×960 with 960×640 logical canvas. Evidence manifest SHA-256 `8fb1352707fc2bc25206b64b9d14fae6b8270ddb36692eea49740055c90665e9`. Actual dock, cabin and combat images show the staged Ender sprite. This is technical/review evidence, not aesthetic acceptance. The candidate manifest was copied without byte changes into the verifier’s fixed `visual-evidence/manifest.json` location for performance validation.

`tests/ender-field-review.html` is a self-contained animation viewer with action selection, play/pause, frame scrubbing and 1×–4× scale. Its source can be regenerated with `scripts/build-ender-review-page.js`. The review player is independent of gameplay; use the linked opt-in runtime for scene cohesion.
