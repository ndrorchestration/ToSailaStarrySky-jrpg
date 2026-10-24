# To Sail the Starry Sky — Development Guide

**Title:** To Sail the Starry Sky (formerly Aetherwake). Source/package/save identifiers remain under backwards-compatibility controls. Public source is not release authorization; review [public-source issue #360](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/360) and [Defender hold #293](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/issues/293) before distributing builds.

## Current stage

To Sail the Starry Sky is a late-prototype / pre-alpha project.

The authoritative `main` line now contains the authored First Wake onboarding path, persistent `ROSTER[5]`, validated reference-based `ACTIVE_PARTY[1..5]`, the JRPG combat/formula and magic contract stack, open-sky navigation, live dialogue/shop/ledger paths, and fail-closed compatibility guards. The runtime baseline before the documentation-only reconciliation was `875503662d9a9cff64eb6ec1bbbeedbfcc3ccbe3`; documentation-only merges may advance `main` without changing player-runtime bytes; GitHub main branch protection was verified **disabled** on 2026-10-24 (governance issue #303). Preview 0.1 remediation/review candidate PR #250 is separately bound to exact head `46f50c581d992bf581bb6b6d7961a9421b8b779d`; do not project candidate-only changes onto `main` before merge.

## Desktop / release authority

The current production desktop structure is intentionally separate from the development repository root.

- `scripts/stage-memories-desktop.js` builds a clean staged runtime at `.desktop-runtime/`.
- The staged launcher root contains a minimal `package.json` with `main: "www/index-embedded.html"`.
- The game payload lives under `www/`; tests, docs, GitHub metadata, npm development files, and other repository-only material are not player-runtime authority.
- `npm run package:windows` packages only that staged runtime.
- `scripts/build-windows-release.ps1` is the maintainer-local Windows fallback and must reach `LOCAL_WINDOWS_RELEASE=PASS` only after build, installer compilation, clean installation, launch smoke, and hash generation.
- Historical Preview 0.1 CI evidence (2026-10-06): Exact candidate `46f50c581d992bf581bb6b6d7961a9421b8b779d` passed smoke run `37557721548` and Windows workflow-dispatch run `37559269564`.
- The published installer from that exact run was independently downloaded, SHA-256 verified, installed, and launched on NeonPC. Technical candidate verification is therefore `PASS` for that exact source.
- Human review, visual acceptance, and human/player acceptance remain separate gates and are still pending.

Launcher-layout correction lineage: `304835c12555e35061870a54d61f7c95996d0bdd`.

## Visual / cinematic authority

Visual work is governed by three current-main documents:

- `docs/VISUAL_BIBLE.md` — canonical cross-project visual grammar;
- `docs/VISUAL_BENCHMARK_SCENE.md` — Dragonfly Dusk Dock acceptance target;
- `docs/CINEMATIC_CLIP_CONTRACT.md` — media format, manifest, failover, transition, and accessibility rules.

The existing Notion Character Art Direction & Implementation Contract remains subordinate character-specific authority rather than being replaced.

Visual branches and stale migration PRs do not become art authority merely by existing or being visually richer. Before promotion, reconcile them to the Bible and prefer a single coherent current-main visual foundation.

The first propagation gate is four near-final scenes:

1. benchmark dock scene;
2. representative dialogue scene;
3. representative combat scene;
4. representative Dragonfly flight scene.

Do not scale expensive effects project-wide until those four establish reusable rules.

## Source-of-truth rules

### Runtime

Current browser runtime authority is the script load order declared by `index-embedded.html`, including the active contract modules for effects, abilities/progression, character canon, JRPG stats/formulas, magic, First Wake, party state, air navigation, the integrated `aetherwake.js` runtime, compatibility-only char-create provenance, and bundled `p5.min.js`.

Do not infer runtime authority from a file merely existing under `modules/`; only the entrypoint load order and integrated runtime establish executable authority.

The other files under `modules/` are useful historical/modular mirrors, but they are not guaranteed to match the integrated runtime.

Do not assume a change to `modules/core.js` or `modules/combat.js` changes the playable browser build unless the build process is explicitly changed to consume those files.

### Branches

- `main` — authoritative repository source line.
- `dev/progression-build` — historical preservation/migration branch. It remains useful as provenance for unextracted work, but it is not current executable authority and must not be merged wholesale into `main`.

Stale feature PRs based on `dev/progression-build` must be rebuilt or cleanly extracted onto current `main` in dependency order.

## Smoke gate

Canonical command:

```bash
npm run test:smoke
```

## Player evidence capture

When technical gates are green but human/player acceptance remains pending, generate a local evidence bundle instead of treating CI artifact availability as visual approval:

```bash
npm run capture:player-evidence
```

The command captures the current `index-embedded.html` browser route into `evidence/player-acceptance/<source-sha>-<timestamp>/`, writes a `manifest.json`, and keeps `humanAcceptance`, `visualAcceptance`, and `gameplayCaptureInspected` explicitly pending. This bundle is review input only; it does not establish visual approval or player acceptance.

The smoke workflow guards the capture lane with:

```bash
npm run test:player-evidence-capture
```

### Preview 0.1 human acceptance boundary

The exact current acceptance target is documented in `docs/PREVIEW_0_1_ACCEPTANCE.md`.

Current boundary:

```text
SOURCE_SHA=46f50c581d992bf581bb6b6d7961a9421b8b779d
INSTALLER_SHA256=7feb6de364264617095a59dd9329a99ebfa77a144b0f5887a7ae7ff064f6221d
TECHNICAL_CANDIDATE_VERIFICATION=PASS
HUMAN_REVIEW=NOT_RUN
VISUAL_ACCEPTANCE=PENDING
HUMAN_PLAYER_ACCEPTANCE=PENDING
```

A creator self-test may discover defects but does not substitute for the uncoached human/player acceptance run. Do not merge or rebind the historical one-click Drive handoff solely from technical verification.

The smoke test should verify:

```text
boot/title
→ authored First Wake opening
→ Ender-only ACTIVE_PARTY start
→ Lyra joins at Sequence 06 / The Wrong Song
→ canonical ROSTER[5] / ACTIVE_PARTY[1..5] reference invariants
→ WORLD with world.player === ROSTER[0] === ACTIVE_PARTY[0]
→ exercise live world/overlay interactions
→ start combat
→ resolve production actions / analysis paths
→ write combat results back to the canonical lead record
→ return to the correct originating state
```

The test intentionally uses real keyboard input for player-facing state transitions and action execution. Reference equality is part of the gate; equal values in separate character copies are not sufficient.

## Historical verified development checkpoint

On 2026-09-19, smoke run `35456148594` passed on commit `be896474c97271084c989f7d5e0d61f27ae72769`. It verified:

- roster IDs `ender|lyra|ionia|reson|aepex`,
- active IDs `ender|lyra|ionia`,
- direct reference identity for all three active entries,
- `world.player === ROSTER[0]`,
- legacy `window.party === ACTIVE_PARTY`,
- Reson/Aepex remaining unimplemented runtime shells,
- combat state write-back into the canonical lead record.

This 2026-09-19 checkpoint is retained as provenance. Authored First Wake onboarding, the five-character roster architecture, 1–5 active-party capacity, and the later JRPG/magic migration have since advanced on `main`; it must not be read as current implementation status.

## Effect/registry checkpoint

On 2026-09-19:

- run `35457176667` passed on `fda1512e9643c0b70738af200c1714f5174ecaca`, establishing effect vocabulary v0.1 and action-profile coverage;
- run `35457323324` passed on `1f45d888f62b5f77bb1157c946f2522e40727f42`, verifying extracted ability/progression registries and full browser behavior;
- all eight runtime actions are created from `modules/ability-defs.js`;
- level 3/4/5 unlocks are read from `modules/progression-defs.js`;
- `resolveTurn()` remains unchanged as the active mechanics executor;
- declared-but-not-applied prototype semantics remain explicitly marked rather than silently treated as implemented.

Canonical verification commands:

```bash
npm run test:effects
npm run test:registries
npm run test:resolver
npm run test:resolver-integration
npm run test:enemy-metadata
npm run test:combat-input
npm run test:resource-eligibility
npm run test:progression-reachability
npm run test:secondary-action
npm run test:magic-defs
npm run test:magic-mastery
npm run test:character-magic-profile
npm run test:party-magic-profile
npm run test:magic-field-reactions
npm run test:elemental-spell-trees
npm run test:non-elemental-spell-trees
npm run test:magic-spell-access
npm run test:magic-study
npm run test:smoke
```

## Resolver integration checkpoint

On 2026-09-19:

- resolver scaffold commit `5dd753524fa2874d2df7f726670961f8ce7c62dc` passed run `35457611114`;
- live integration commit `13c84e00d3097429f70bf6616294bbc08b377618` passed run `35457776908`;
- ordinary damage, vitality restoration, and resource deltas inside `resolveTurn()` route through `modules/effect-resolver.js`;
- CI source-checks `resolveTurn()` so ordinary direct mutations cannot silently reappear;
- browser smoke verifies live combat actually performs resolver-backed mutations;
- PbtA roll bands, action-specific branch selection, logs, randomness, XP, level-up rules, and the explicit defeat floor remain outside this resolver layer;
- modifier/reveal/status/movement semantics are not claimed as implemented by the resolver.

This is a partial establishment of migration step 6, not completion of the full generic combat resolver.

## Action eligibility checkpoint

On 2026-09-19, commit `d38827c0c8df9d0b92ce2376a775a8ddf0dafcae` passed run `35458285333`.

It establishes:

- stable eight-action ordering remains unchanged;
- Staff Strike and Hold are baseline actions;
- other current actions require their ID in `player.unlockedAbilities`;
- level-1 eligible actions are Staff Strike, Uncover Truth, Shared Dream, Mycelial Ledger, and Hold;
- Wind Ward/Aether Seal/Rest are rejected before turn/resource consumption until learned;
- combat UI keeps stable 1–8 slots and marks locked actions rather than renumbering them;
- the UI displays the same legacy `tier + cost` resource amount used by runtime resolution.

This enforces the existing progression data without introducing school mastery, job gating, or new unlock semantics.

## Use/progression/secondary checkpoint

On 2026-09-19:

- transactional use-eligibility implementation `a25c901125e65331e5d7f10d2ca6bdb1620015c0` initially exposed one stale source assertion in run `35463662627`; no runtime/browser claim was made from that failed run;
- test-only correction `d93dea34e9b512319f3a94e229e5769e695c8f22` passed run `35463741004`, verifying centralized `tier + cost`, pooled Echo+Aether preflight, zero partial spending on rejected actions, UI/runtime cost agreement, and full browser behavior;
- victory-progression correction `a753ac5809b52534576bba15c7ef37e66d07373f` passed run `35463872395`, proving normal XP award paths can cross level 2 → 3 and unlock Wind Ward;
- secondary-state correction `ba36e59a332adb95cc3d1f9b40681bd2c9d8106e` passed run `35464000671`, proving secondary opportunities are not stale and are offered only when the repeated ability remains usable.

Historical boundaries at that checkpoint:
- cost amounts were **not** redesigned;
- school/job/mastery prerequisites were not yet implemented;
- modifier/reveal/status/movement execution remained outside that resolver subset;
- `main` had not yet incorporated the later migration work.

These statements are checkpoint provenance, not current-main status.

## Architecture migration rule

Do not rewrite authored onboarding, party state, combat resolution, progression, and persistence simultaneously.

Preferred order:

1. stabilize a playable baseline — **established historically**,
2. establish persistent `ROSTER[5]` — **established**,
3. establish validated `ACTIVE_PARTY[1..5]` references/IDs — **established**,
4. define effect vocabulary and fail-closed compatibility boundaries — **established**,
5. extract ability/progression and magic contracts — **established**,
6. migrate production action resolution to the JRPG formula line — **established for the current production-native subset**,
7. migrate normal New Game to authored First Wake onboarding — **established**,
8. continue school/job/mastery and character-kit implementation without inventing unresolved canon,
9. add later-recruitment formation/presentation and combination systems only when their contracts are authored,
10. expand campaign content while preserving source/canon/runtime authority boundaries.

## Persistent-state rule

The production architecture should have one canonical persistent character schema.

World, combat, formation, UI, and progression systems should operate on character IDs/references or explicit interfaces rather than creating unrelated partial copies.

Temporary state-copying in the preservation baseline is migration debt and should be removed as the roster architecture lands.

## Build outputs

The following are generated/deployment artifacts and should not be edited as independent source trees:

- `standalone/`
- `nw-package/`
- downloaded NW.js archives

Long term, self-contained runtime bundles should be generated from one canonical source tree.

## Documentation roles

- `README.md` — project overview and runnable current state.
- `SPEC.md` — current implementation versus target architecture.
- `gap_analysis.md` — dated/snapshot conformance audit.
- `memories_adaptation_catalog.md` — adaptation/provenance reference.
- this file — repository development workflow and authority rules.
