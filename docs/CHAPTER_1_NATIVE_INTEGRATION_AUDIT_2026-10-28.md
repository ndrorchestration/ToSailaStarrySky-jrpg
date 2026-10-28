# Chapter 1 Native Integration Audit — 2026-10-28

**Authority:** read-only GitHub PR metadata and base-to-head compare; *not* code integration, CI reexecution, runtime capture or creator approval. Prepared after main roadmap documentation updates. This is an observation snapshot; refresh remote heads before any actual cherry-pick, rebase, or merge.

## Key result
Selected native PRs are **draft and unmerged**, and compare to current `main` as diverged: PR #558 ahead 519 / behind 11; #562 ahead 532 / behind 11; #565 ahead 554 / behind 11; #573 ahead 558 / behind 11; #582 ahead 563 / behind 11; #584 ahead 570 / behind 11; #586 ahead 570 / behind 11. Counts are cumulative ancestry, **not** per-PR new feature counts. Do not merge cumulative heads directly into main without dependency/file/release review.

## Confirmed PR base relationships (from live GitHub metadata)
| PR | Purpose | Its immediate base | Head at audit |
|---|---|---|---|
| [#558](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/558) | Opt-in 3D deck walkthrough | `prototype/aureate-wake-deck-architecture-crew-sightlines-20261028` | `a5bf4a915628c9e53b917992bc3de176df4e3a0f` |
| [#562](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/562) | Playable physical local berth | `visual/first-wake-cinematic-deck-20261028` | `c561fc0264b8fa51cc419ceaf42575c296bcab94` |
| [#565](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/565) | Windows installer candidate | `visual/first-wake-cinematic-deck-20261028` | `200133d566f7883ce09745dcfdf6fc7785832124` |
| [#568](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/568) | F5 physical opening to family/harmonic review | `feat/first-wake-game-entry-checkpoint-20261028` | `69b9bcd716657db224f976f27365f928082edcbb` |
| [#571](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/571) | Stage save v2 | `feat/first-wake-f5-family-harmonic-bridge-20261028` (PR #568) | `614e13f8d97d1653e4984e83725261a2dd1854b2` |
| [#573](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/573) | Berth physics to family gate | `visual/first-wake-local-berth-cinematic-pass-20261028` | `8b61719f022601f083d04c9fd9fbccfd687da440` |
| [#582](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/582) | 3D/JRPG cohesion audit | `visual/ch1-3d-ocean-motion-accessibility-20261028` | `ed1de147606034e3e6352e26e7df97db8c01c5db` |
| [#584](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/584) | Player-led crew diagnosis | `audit/ch1-3d-combat-progression-cohesion-20261028` (PR #582) | `edd6e8d849ffaa94b0ec4a41037b9b37143811e0` |
| [#583](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/583) | Creator-art native actor opt-in | `visual/first-wake-painted-coastal-sky-20261028` | `58281c6517317683565aada7a7ca43d8c22cb233` |
| [#585](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/585) | Matte refinement | `review/first-wake-creator-field-standee-20261028` (PR #583) | `463ff4e0e9c191922e78ddedd9003c604bf71305` |
| [#586](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/586) | Grounded actor/light A/B | `review/first-wake-creator-field-matte-v2-20261028` (PR #585) | `bfd7c0e60e3051c6e643321508c0a062f6ee2d38` |

## Recommended integration order (proposal, not authorization)
1. **Pin one native Chapter 1 baseline**: choose exact candidate branch/SHA and run import, native First Wake walk/splashdown/berth captures, gameplay smoke and save tests. Record `main` vs candidate diff and relevant parent PRs.
2. **Story/physics admission**: select the correct canonical Ionia-first route; reconcile #562/#573 and #568 without duplicating quest or local-berth gates. Require normal F5 progression.
3. **Persistence**: reconcile #571 stage v2 and #561 salvage v3 as different checkpoints; define one long-lived save contract before promotion, never silently reinterpret old saves.
4. **JRPG interaction**: derive actionable issues from #582 and verify #584 against the active party, stats, leveling, combat, cost, magic and quest progression contracts.
5. **Art and presentation**: retain #583 → #585 → #586 order on the visual stack; compare creator reference against *actual rendered* game. Current stills are opt-in source-art previews, not finished walk animations. Ship 3D, ocean, lighting, camera and accessibility must pass independent visual tests.
6. **Windows**: keep #565 security verification separate from the demonstrated functional install/launch path; do not label Defender-off hosted run as Defender-on acceptance. Link a public installer only after verified release artifact and permission.

## Follow-up blockers / evidence missing
- Exact full diff and conflict classification between native candidate and `main` (compare summaries here show cumulative paths, not per-PR change isolation).
- Native Windows end-to-end chapter-path proof at a pinned prospective integration SHA.
- Verified canonical save migration policy across stage, salvage and historical packages.
- Creator artistic approval of native characters and Aureate Wake; animation completeness.
- Independent Windows Defender-on acceptance, player testing and one-click installer release.
- Complete Chapter 1 start-to-end proof.

**Milestone alignment:** November 30, 2026 integrated baseline; March 31, 2027 feature-complete alpha; May 31, 2027 beta planning target. See [beta roadmap](CHAPTER_1_BETA_ROADMAP.md).

**No merges, runtime changes or public releases were performed by this audit.**
