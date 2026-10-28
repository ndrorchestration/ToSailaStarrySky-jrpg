# First Wake Evidence Notebook — Native Integration and Acceptance Ledger
**Date:** 2026-10-28. **Branch:** `feat/ch1-evidence-ledger-player-hook-20261028`. **Tested exact head:** `42e8022cbfe46c0fb1b4a3d05f4e18aedc0f2a42`. **Draft PR:** [#584](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/584). **Status:** NATIVE STRUCTURAL / F6 PREVIEW PASS; POSTFLIGHT GAMEPLAY AND ART ACCEPTANCE OPEN.

## Player-facing scope actually implemented
- `godot/scripts/first_wake_job_preview.gd` instantiates a real `first_wake_evidence_comparison_panel.gd` Godot Control in the playable F6 job/engineering preview. **J** toggles the notebook. Initial clues are all disabled until recorded in the authentic story model.
- `first_wake_evidence_comparison_review.gd` compares **exactly two distinct recorded clues** (phase readings, depleted reserve, Lyra observation) only after authentic safe postflight Lyra reunion and party chronology are satisfied. Returns legible evidence and next dialogue prompt; fuel composition remains unknown.
- Panel is hidden initially, cannot spend resources or modify story, save, combat, skills, magic or Resonance authorization. A checkpoint restore rebinds its story reference and hides the transient overlay.
- The **F6 preview stops at preflight**. No postflight clues are currently earned through this preview and this UI is **not** integrated into the normal F5 complete Chapter I route. Do not market this as a complete interactive diagnosis encounter.

## Exact-head evidence
At `42e8022cbfe46c0fb1b4a3d05f4e18aedc0f2a42`:
- [Chapter I 3D and RPG Cohesion (review only) run 40698360426](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40698360426): **SUCCESS** (includes source/cohesion, evidence logic, native panel and F6 mount tests).
- [First Wake native pilot 40698360474](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40698360474): **SUCCESS**.
- [Ionia native render review 40698360624](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40698360624): **SUCCESS**.
- [Ship Space Handoff 40698360354](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40698360354): **SUCCESS**.
- [Repo smoke 40698360372](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40698360372): **SUCCESS**.
- [Godot Exact Windows QA 40698360431](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/actions/runs/40698360431): **FAILURE**; no Windows release approval. Independent Defender-on security closure is still required.

## Dependency sequence, with explicit admission boundaries
1. Inspect current PR #584 and compatible physical splashdown/family-berth source stack; document story/checkpoint API differences before porting.
2. Integrate the notebook into the *real* postflight F5 scene only when collected observations originate from genuinely authorized player actions. Keep Talen noncombat and Ender→Ionia→Lyra chronology.
3. Test player selection, denial before reunion, actual checkpoint cold restore, duplicate clue handling and unauthorized magic/story effects. Preserve old saves and the physical contact gate.
4. Bind presentation to real resolved comparison output; attach cinematography/engine light effects only as visual consumers. Capture native Godot frames and independently review creator-approved art.
5. Measure player comprehension and scene production cost; separately gate narrative, gameplay, balance, art, accessibility, performance, and Windows release.

**Source-of-truth warnings:** The legacy Crossing Ender+Lyra combat metadata conflicts with Ionia-first opening and remains quarantined. Level-one baseline stat budget (25) differs from listed Ender (31) and Ionia (26), requiring owner design resolution. PRs #576/#579/#580 contain distinct cinematic implementations, not one merged playable 3D production build. No merge, canon change, or installer release is authorized.

**Related:** `docs/production/CHAPTER1_VERTICAL_SLICE_ACCEPTANCE_CONTRACT_2026-10-28.md` and `docs/production/JRPG_100_POINT_QUALITY_GATE_MAPPING_2026-10-28.md`.
