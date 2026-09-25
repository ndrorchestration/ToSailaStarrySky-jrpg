# Chapter 1 Closure Audit — 2026-09-24

Status: **implementation-converged / installer-tail re-execution pending**

This audit is intentionally bounded to Chapter 1 / First Wake. It does not authorize Chapter 2 expansion.

## Independent review lanes

### 1. Route and narrative
PASS at implementation level.
- First Wake Sequences 05–09 are player-driven.
- SIGNAL requires three contacts.
- CROSSING requires four real hazard victories.
- CONTACT requires four voices.
- Choice resolves deterministically into WAKE/DONE and replay.
- Stale three-hazard / three-voice / Meridian / Holt residue is regression-guarded.

### 2. Combat and balance
PASS at implementation level and previously executed on Windows head `f8c255565bf89e20eaeb1305623f6fe9a81239cc`.
- Real Chapter 1 encounters initialize from the live world player.
- Production JRPG stats are attached before first combat.
- Admitted actions use the formula engine.
- Legacy dice compatibility remains bounded behind non-admitted actions and is not player-facing Chapter 1 resolution.
- Four mandatory hazards have a numerical balance contract and retry recovery.
- Human/player calibration remains a final acceptance concern rather than an implementation blocker.

### 3. UI and visual presentation
PASS at bounded automated-gate level on Windows head `f8c255565bf89e20eaeb1305623f6fe9a81239cc`.
- Character sheet renders live production stats/resources.
- Undefined gear-row coordinate fixed.
- Compact HUD renders live vitals and quest progress.
- Ender fallback portrait reconciled toward current visual canon.
- Bounded Chapter 1 visual suite covers title, First Wake, dialogue, combat, flight, visual-package integration, 16-bit world composition and character sheet.
- Desktop staged manifest identifies Chapter 1 rather than Preview 0.1.
- Uncoached human/player visual acceptance remains pending.

### 4. Audio
PASS for governed Chapter 1 admission and readiness on Windows head `f8c255565bf89e20eaeb1305623f6fe9a81239cc`.
- Skyward Arpeggio: title/menu.
- Amonigio Umulula: opening/cinematic progression.
- Solar Punk Airship: exploration/airship.
- Nocturnal Resolve: combat/Crossing hazards.
- Open Sky Signal: Ender / First Note leitmotif.
- All five governed source files are admitted on the Chapter 1 branch and exact-hash verified.
- Title and scene controllers remain state-separated; transition is bounded title fade → scene cue.

### 5. Packaging, persistence and release evidence
Portable/runtime proof is established on Windows head `f8c255565bf89e20eaeb1305623f6fe9a81239cc`; installer-tail proof remains pending on the current head.
- Desktop staging recursively includes modules and assets.
- Windows execution passed Chapter 1 core, bounded visual, full browser route, desktop package contract, fresh package provenance, standalone runtime-ready/first-frame, and standalone save → close → relaunch → Continue.
- The device disconnected during installer creation/install/evidence verification, so those later claims were not promoted.
- Audit of the interrupted path found a real fallback defect: IExpress installed to fixed LocalAppData while smoke verification expected NSIS-style isolated `/D=` semantics.
- Current branch hardens the fallback with an inherited `AETHERWAKE_CHAPTER1_INSTALL_ROOT_OVERRIDE`, engine-specific installer arguments, cleanup, and `tests/chapter1-installer-fallback-contract.test.js` wired into `test:chapter1-core`.
- Fresh hosted runs on the hardened head again terminated with zero steps and no logs; they remain infrastructure non-execution, not application evidence.

## Evidence boundary

The Windows PASS on `f8c255565bf89e20eaeb1305623f6fe9a81239cc` remains valid evidence for the unchanged gameplay/runtime path through portable persistence. A Git compare from that tested head through the current release-hardening line shows only closure/player-acceptance documentation, `package.json` test wiring, Windows release scripts, and release regression tests; no gameplay runtime, modules, assets, or authored content changed. The current branch still requires fresh Windows installer-tail execution before current-head release evidence is claimed.

## Promotion chain after acceptance

Current clean stack:
- PR #149 `release/preview-0.1` → `main`;
- PR #150 `integration/preview-persistence-foundation-2026-09-24` → PR #149 branch;
- PR #151 `integration/chapter1-first-wake-convergence-2026-09-24` → PR #150 branch.

Observed ancestry is clean with no behind drift, and all three PRs are currently mergeable/draft.

After the exact PR #151 candidate passes Windows release evidence and uncoached player acceptance, preserve the tested tree by promoting **top-down through the stack**:
1. merge #151 into #150;
2. verify #150's resulting tree matches the accepted #151 candidate tree;
3. merge #150 into #149;
4. verify #149's resulting tree still matches the accepted candidate tree;
5. merge #149 into `main`;
6. verify protected `main` has the same tree as the accepted candidate.

Prefer merge commits for this promotion. A squash, rebase, conflict resolution, or content edit that changes the candidate tree requires re-verification before calling the landed result equivalent to the accepted candidate.

## Remaining closure gates

Only evidence-producing gates remain:
1. Reconnect the Windows device and execute the current Chapter 1 branch through installer creation, isolated install, installed first-frame/provenance, and installed save → close → relaunch → Continue.
2. Run `npm run verify:chapter1:release-evidence` against the resulting ZIP, Setup.exe, SHA256SUMS and evidence JSON and require PASS.
3. Correct only defects actually revealed by that current-head run.
4. Perform uncoached player acceptance on the exact verified standalone candidate using `docs/CHAPTER1_PLAYER_ACCEPTANCE.md`.

Until those are observed, PR #151 remains draft and Chapter 1 is not represented as fully accepted.
