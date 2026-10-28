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

## 2026-10-28 Windows development worktree follow-up (read-only inspection)
- Connected machine: `neontic` (online), exact path `C:\\Users\\Admin\\Desktop\\TSTSS-FirstWake-Visual-Review`.
- Local branch `visual/first-wake-layered-coast-review-20261028` at `4d2ec5fb343a2bd9df40b26d6de75bc7654d0e81`.
- Local uncommitted change: `godot/scripts/first_wake_flight_water_review.gd` (+7 lines; no deletions). **Preserve** until owner/agent determines intent; no reset/rebase/merge performed.
- Godot native project file `godot/project.godot` exists locally. Another Git worktree at `Desktop/Aetherwake/Verification Sandbox/FirstWake-CreatorPortrait-QA-20261028` is detached at `849ea9c`.
- This is **source/worktree observation only**, not native playtest, scene rendering, CI confirmation, or integration acceptance. Current worktree is dirty: require a clean separate integration worktree, anchored to a verified exact source SHA, before conflict checks or promotion.

## 2026-10-28 isolated native Windows gate — observed PASS (bounded)
A **separate detached clean worktree** was created at `C:\Users\Admin\Desktop\TSTSS-Ch1-Integration-QA-20261028` from pinned SHA `4d2ec5fb343a2bd9df40b26d6de75bc7654d0e81`. The active visual worktree was not reset or modified. It advanced independently to `6a788b2` during verification; tests below **do not** cover that newer head.

Using genuine `C:\Temp\godot472\Godot_v4.7.2-stable_win64_console.exe`:
- Native headless editor import: **PASS, exit 0**.
- `res://tests/first_wake_main_entry_to_water_review_test.gd`: **PASS, exit 0**. Reported configured startup, Ionia job, actual water contact, reserve, berth sensor, family dialogue, crew clues, two salvage areas/custody and chosen melody with checkpoint return.
- `res://tests/first_wake_chapter1_state_test.gd`: **PASS**; finite-state Chapter 1 sequence and explicit completion.
- `res://tests/first_wake_chapter1_save_codec_test.gd`: **PASS**; versioned progression/position round-trip, legacy fallback and tamper rejection.
- `res://tests/first_wake_combat_formula_test.gd`: **PASS**; representative staff, analysis, hold, rest and RNG/SSOT guards.
- `res://tests/first_wake_chapter1_review_test.gd`: **PASS**; scene-based Signal–Crossing–Contact–Choice–Wake–Done route.

**Interpretation:** Pinned native source supports an unusually promising *bounded automated Chapter 1 regression baseline*. These are headless script checks and import, **not** actual human start-to-end playtesting, final cinematic art acceptance, installed Windows release or a mergeable PR against current `main`. Do not use this receipt to claim all Chapter 1 production mechanics are final or that #586's later art work was tested. Next gates: full dependency diff/conflict analysis against main, actual graphical Windows F5 capture/playtest at this exact SHA, save-format integration review, and security-gated installer acceptance.

## 2026-10-28 genuine Windows graphical capture — PASS with visible blocking discrepancies
At the **same pinned clean source** `4d2ec5fb343a2bd9df40b26d6de75bc7654d0e81`, launched official Godot 4.7.2 **without `--headless`**, using OpenGL Compatibility on Intel Iris Xe. The script `res://tests/capture_first_wake_chapter1_review.gd` produced **nine distinct real native 960×640 PNGs**, with `AETHERWAKE_GODOT_CHAPTER1_NATIVE_RENDER_PASS` and `ARTISTIC_ACCEPTANCE=PENDING`. Frames: Signal, Formula Review, Dialogue, Crossing, Wind Shear combat, Contact, Choice, Wake and Done. Output local-only `godot/review-evidence/chapter1-migration/`; no screenshots uploaded publicly.

Manual visual inspection of **Signal**, **Formula Review** and **Done** frames (not all nine) found:
- **P0 narrative admission gap:** main Chapter I review scene header says `ACTIVE ENDER + LYRA` on Signal, and displays `F8 REVISED OPENING / IONIA FIRST — OPT-IN PROTOTYPE (not story progression)`. This is the *legacy Lyra-first review scene*, not proof of the intended canonical Ionia-first default sequence. `Done` adds Ionia, but that alone does not resolve the conflict.
- **P1 UI and character-art gap:** visible overlapping/occluded labels and character sprites, mixed prototype character quality, older `AETHERWAKE / FIRST WAKE` branding. Formula overlay text occluded by sprites. This is not cinematic acceptance.
- The completion frame does visibly show `CHAPTER I COMPLETE`, but this capture is scripted progression, **not an unassisted human completion**.

**Recommended smallest reversible repair:** keep legacy scene and test as a distinct compatibility fixture; establish a separate `Ionia-first canonical entry` acceptance test and graphical capture using normal F5 game startup, with assertive party-order/canonical narrative checks and HUD-overlap review. Do not overwrite/relabel historical test receipts, weaken the current visual bar or infer a merge/release.

## Default-entry trace — 2026-10-28
Pinned source `4d2ec5fb`: `godot/project.godot` launches `first_wake_chapter1_player_preview.tscn`, which references `first_wake_chapter1_review.gd`. The main-entry regression intentionally tests legacy startup and uses F8 to reach the Ionia-first preview. A passing F8-based regression does not verify the intended default Ionia-first route. Promotion requires a separate normal-launch test with no F8 and preservation of the historical route.

## 2026-10-28 isolated implementation candidate — canonical startup, verified locally
**Remote branch:** [qa/ch1-ionia-default-entry-20261028](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/tree/qa/ch1-ionia-default-entry-20261028) at exact commit `513fa32a8c67b2471c8b701f03838c5bd17eefdf`. Created from clean `4d2ec5fb` in a separate worktree; existing active visual branch unchanged. **Unmerged.**

Changes: `godot/project.godot` defaults to `first_wake_job_preview.tscn` instead of the legacy Lyra-first Chapter I review scene; new `first_wake_canonical_default_entry_test.gd` asserts configured default starts Ender alone and recruits Ionia first with no F8. The prior `first_wake_main_entry_to_water_review_test.gd` now explicitly instantiates its historical legacy fixture while asserting the new default; historical state/return behavior remains testable. New `capture_canonical_default_entry.gd` captures the **actual configured** Godot entry on native Windows OpenGL 3.3 Intel Iris Xe at 960×640.

**Observed PASS:** canonical default entry test; revised opening story contract; versioned save codec; representative combat formula; historical fixture-to-water/berth/family regression; genuine native graphical startup capture with SHA-256 `4827aa27e2013e3a8487e3a1e1ec338791ecf69aacc1e136587527c9f2a92864`. Inspected frame visibly says `TO SAIL THE STARRY SKY / FIRST WAKE — PLAYABLE REVIEW`, `Story party: ender`, dock job notice and captain on pier. Art remains a preview, no creator artistic approval.

**Limitations and admission:** Default-entry actor/party and the old explicit F8 fixture are independently covered; **a complete no-F8 Ender→Ionia→physical berth→family end-to-end player run is not yet verified**. This stacked candidate has not been reconciled against newest native branch heads/main, has no merge authorization, and does not satisfy installed Windows security/release acceptance. Do not describe this as production/main or a public installer. A remote push only provides a reviewable source branch.
