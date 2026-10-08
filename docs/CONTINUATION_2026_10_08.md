# Aetherwake continuation checkpoint — 2026-10-08

This is an observed checkpoint, not acceptance or merge authority. Refresh heads before resuming.
Goal: a playable, visually coherent anime-inspired 2.5D solarpunk JRPG, with the approved five protagonists and a recognizable Dragonfly.

## Recovered active lanes

| Lane | Inspected version | Established result | Remaining step |
| --- | --- | --- | --- |
| Preview 0.1 / #250 | 46f50c581d992bf581bb6b6d7961a9421b8b779d | Current PR and #249 record smoke, Windows install/launch, hashes and published candidate | Exact-candidate human review; installed local version must be identified before comparing its appearance with V46 |
| V46 / #206 | 148e97592aa584befdd9596d40fb46aa2c65c5e5 | Richer authored art exists on a separate draft stack | Field sprites, Dragonfly/scene cohesion and human visual acceptance remain open |
| Rift investigation / #258 | d4145ab9aedbfd70640fc2bac9890f0459d3d927 | Hosted smoke gameplay job and Chapter 1 core/visual/browser pass | Review actual optional investigation and upstream V46 integration |
| Hybrid jobs / #257 | 7f952bb7f4e51456aa409d661331ed1c88c49bf6 | Hosted smoke run 37725493536 succeeds | Design contract only; no job catalog, runtime menu, equipment permissions or save migration admitted |
| Main evidence retention / #255 | 0beedca6a6d1754b934482006cc52ba6dcc13e76 | Hosted smoke run 37709851373 succeeds | Review; smoke alone does not prove evidence upload recovery |
| V46 evidence retention / #256 | 5e6b63393786cc2c7fdb4174fcec046b54f67f65 | Four workflow lines reduce 14 days to 1 | Upload remains quota-blocked; do not close #222 |
| Release source binding / #254 | 1c40f0c101a3802c346966a6783d4a46f5ec1829 | Hosted smoke run 37563586482 succeeds | Review two-file prevention of incorrect release-tag source; no new publication |
| Codex guidance / #259 | 1256cd6c30f01f8177264b4679b59706ff57ddd2 | Draft scoped repository instructions inspected | Owner review and applicable checks |

Historical Windows stack #234/#236/#238/#240 remains provenance. #240's 7a32497dc7aa1bc664999d24e5d3a90d46c17201 is not the newer Preview #250 identity.
Issue #233's October 1 ancestry is a historical checkpoint, not today's main pointer. Do not merge the historical stack mechanically.

## Evidence-delivery findings

- #256 run 37710144141: gameplay smoke job 113093902160 succeeds; visual job 113093902233 captures 18 evidence files / 4 performance samples, then upload fails.
- The log explicitly confirms retention-days: 1 and GitHub artifact storage quota exhaustion. Artifact API returns an empty artifact list.
- #258 run 37727064504: smoke job 113147550491 succeeds, including the Rift investigation; visual job 113147550323 captures 18 files / 4 samples, then hits the same quota.
- #258 convergence run 37727064521: core, visual and browser jobs succeed.
- Reduced retention controls new artifact lifetime; it has not established publication/retrieval success.
- No artifacts deleted, quota controls weakened, or upload failures relabeled as visual PASS.

## New local observation and repair

On NeonPC, a clean checkout at #258 exact head produced 18 visual evidence files and four performance samples.
The verifier reports median/worst-window p95 around 16.7–16.8 ms for the four sampled scenes.
Original capture directory: C:/Temp/aetherwake-ender-rifts-v46-20261008/visual-evidence.
Original manifest SHA-256: 5951d068397f2b28cab203def51a9d1cfd8ece1038e0b16973d4146c47288c86.

Inspected unedited 1440x960 frames: opening world reveal, dock walk, cabin.
Observed defect: the arrival scene renders fallback narration during its intended quiet reveal, with the text box starting at the midpoint and extending outside the canvas.
The same box placement affects chapter-card prose.

The bounded repair restricts fallback prose to chapter cards and centers the chapter text rectangle within the canvas.
Real-browser regression coverage exercises reveal boundaries 0/141/142/193/194/240, interactive dock suppression and chapter-card bounds.
The regression failed on premature narration before the repair; with that repaired and the old chapter placement restored, it failed separately on chapter bounds.
A brittle source-string check was replaced by this renderer-level behavior coverage.
No story lines, progression, recruitment, saves, combat rules or art admission change.

The first expanded local visual-suite attempt stopped because the Python interpreter lacked Pillow. This is an environment dependency failure; rerun with the same pinned Pillow==12.3.0 used by the repository workflow. Consult the candidate PR for final test results and capture identity.

## Visual assessment and next production work

These are developer observations and reasoned aesthetic judgments, not human acceptance:
1. Opening: repair narration visibility/bounds, then compare the same exact scene before/after. This checkpoint's candidate performs that repair.
2. Dock/characters: ornate floating-island backdrop contrasts with simple articulated field figures and coarse ship geometry. Resume #207 Ender/Ionia authored field-pack work against current approved likeness, keeping provisional sprites non-admitted. Require actual runtime comparison, not just image dimensions.
3. Scene continuity: the cabin has detailed material/depth cues, but tiny simplified figures and dock presentation still need a coherent scale and style. Review dock, interior, combat and flight together before broad propagation.

## Remaining plan and dependencies

- First finish this small narration candidate: local regression/smoke, Chapter 1 visual + route/replay, exact-head capture, reviewable draft.
- Then resume #207's existing field-art lane. Preserve Ender's bright green eyes, short auburn/copper hair and goggles; Ionia's curly blonde hair; Lyra's red hair; approved Reson/Aepex identities. No silent candidate-art promotion.
- Continue #258 as a bounded in-session observation. It does not establish a persistent quest record, magic unlock, portal, or Auroral access.
- Continue #257 only within its design contract until job roster/admission, acquisition/XP, transferable skill slots, equipment permissions and save migration are resolved. Five-character menus and level-150+ campaign goals are longer-term requirements, not current runtime completion claims.
- Equipment, party-crafted upgrades, Best Fit and #227 weapon-mastery proposal remain distinct from admitted runtime behavior.
- Preserve Lyra-first recruitment, Ionia's command role, crew-dependent shielding and all-five-crew/harmonic requirements for high/Auroral lanes.
- Rootline travel-feel/uncoached play, save/replay lineage and #233 promotion require candidate-specific evidence; technical success does not close human gates.
- Keep #202 code signing and #152 build-dependency modernization as separate post-acceptance work unless concrete new evidence changes priority.
- Read current Notion dossiers before new lore decisions. Notion/Drive were not refreshed in this checkpoint; no claim of cross-service synchronization.
- Do not rebind older Drive launchers, publish a new release, merge protected main or claim visual/player acceptance from this checkpoint.

## Resumption

Working branch: fix/opening-narration-reveal-20261008, based on #258.
NeonPC worktree: C:/Temp/aetherwake-opening-narration-20261008.
The candidate PR is the review/verification receipt; source and this checkpoint are persisted through that branch.
Next observable art milestone: Ender/Ionia candidate field packs shown in the same dock/cabin scenes with explicit likeness and runtime review, without changing admission before its required evidence.
