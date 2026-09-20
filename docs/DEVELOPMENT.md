# Aetherwake Development Guide

## Current stage

Aetherwake is a late-prototype / pre-alpha project.

The development branch now has a verified playable baseline, persistent `ROSTER[5]` / reference-based `ACTIVE_PARTY[3]`, effect vocabulary v0.1, extracted current ability/progression registries, and live fail-closed resolver routing for ordinary damage/restoration/resource mutations. Higher-order resolver semantics remain staged work.

## Source-of-truth rules

### Runtime

Current browser runtime:

1. `index-embedded.html`
2. `modules/effect-vocabulary.js`
3. `modules/effect-resolver.js`
4. `modules/ability-defs.js`
5. `modules/progression-defs.js`
6. `modules/party-state.js`
7. `aetherwake.js`
8. `modules/char-create.js`
9. bundled `p5.min.js`

The other files under `modules/` are useful historical/modular mirrors, but they are not guaranteed to match the integrated runtime.

Do not assume a change to `modules/core.js` or `modules/combat.js` changes the playable browser build unless the build process is explicitly changed to consume those files.

### Branches

- `main` — authoritative stable repository baseline.
- `dev/progression-build` — preservation/stabilization branch for the September 18–19 development build and subsequent baseline fixes.

Do not promote `dev/progression-build` to `main` until the smoke gate passes.

## Smoke gate

Canonical command:

```bash
npm run test:smoke
```

The smoke test should verify:

```text
boot/title
→ character creation
→ canonical ROSTER[5] / ACTIVE_PARTY[3] references
→ WORLD with world.player === ROSTER[0]
→ start combat
→ resolve a normal action
→ resolve an ability
→ write combat results back to the canonical lead record
→ return to WORLD
```

The test intentionally uses real keyboard input for player-facing state transitions and action execution. Reference equality is part of the gate; equal values in separate character copies are not sufficient.

## Dual-entrypoint boot gate

Both `index-embedded.html` (embedded/NW.js launch) and `index.html` (browser launch) are supported playable entrypoints. They must load the same runtime dependency chain in order:

```text
effect vocabulary → resolver → ability/progression registries → party/airship state
→ airship bridge/UI → audio → aetherwake.js → character creation → p5.js
```

Each entrypoint includes a hidden `#aetherwake-init-error` status surface. Missing runtime dependencies fail closed through `showInitializationFailure()` instead of entering a partially initialized game, and the launcher reports a visible timeout if p5/canvas creation never completes. The debug overlay remains opt-in through `?debug=1`.

Validate the entrypoint contracts before browser testing:

```bash
npm run test:runtime-contracts
npm run test:smoke
npm run test:all
```


## Verified development checkpoint

On 2026-09-19, smoke run `35456148594` passed on commit `be896474c97271084c989f7d5e0d61f27ae72769`. It verified:

- roster IDs `ender|lyra|ionia|reson|aepex`,
- active IDs `ender|lyra|ionia`,
- direct reference identity for all three active entries,
- `world.player === ROSTER[0]`,
- legacy `window.party === ACTIVE_PARTY`,
- Reson/Aepex remaining unimplemented runtime shells,
- combat state write-back into the canonical lead record.

This checkpoint does not mean the authored-roster onboarding, formation system, three-character combat, ability extraction, or progression architecture is complete, and it does not mean `dev/progression-build` has been promoted to `main`.

## Comprehensive runtime-repair checkpoint

On 2026-09-20, GitHub Actions smoke run `35508703162` passed on commit
`0ef2eff19334b616f7c11982843373c6be693489` after the comprehensive runtime
repair defined by
`docs/superpowers/specs/2026-09-20-aetherwake-bug-repair-design.md`.

The verified gate includes:

- dependency-complete, fail-closed boot for both `index-embedded.html` and `index.html`;
- current-key input ordering and immediate first-step world movement;
- first-contact dialogue, overlay return-state isolation, and core-owned state transitions;
- synchronized world coordinates, lore sidecar storage, data-driven crossing completion, and a read-only ledger API;
- stable-ID, scrap-based, transactional Repair Cafe purchases with explicit capacity caps;
- complete World → Combat → World player-state round-trip and per-encounter transient reset;
- fail-closed enemy preflight before any one-shot airship state can be consumed;
- bounded Dragonfly airship-to-combat handoff with one-shot transfer semantics;
- combat-log rendering from authoritative combat state;
- canonical night-state vignette and visible grass-wind strokes;
- optional prerecorded dialogue TTS gated off by default because the current repository does not ship the `tts/` MP3 asset pack;
- regression coverage for malformed hazard configuration and p5 `text()` renderer shadowing.

The smoke path uses real browser input and verifies the playable flow through
character creation, world interaction, dialogue, shop behavior, combat,
Dragonfly boarding/system actions, combat handoff, canonical party write-back,
and return to WORLD without uncaught page or console errors.

This checkpoint verifies the source branch only. Generated `standalone/` and
`nw-package/` trees and any desktop executable remain post-validation build
artifacts and are not established by this CI result. `main` remains untouched
by this repair sequence.

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

Current explicit boundaries:
- cost amounts were **not** redesigned;
- school/job/mastery prerequisites are not yet implemented;
- modifier/reveal/status/movement execution remains outside the current generic resolver subset;
- `main` remains untouched.

## Architecture migration rule

Do not rewrite character creation, party state, combat resolution, progression, and save state simultaneously.

Preferred order:

1. stabilize current playable baseline,
2. establish persistent `ROSTER[5]`,
3. establish `ACTIVE_PARTY[3]` as references/IDs,
4. define effect vocabulary,
5. extract ability and progression registries,
6. generalize combat resolution,
7. migrate to authored roster onboarding,
8. add school/job/mastery progression,
9. add formation, Dual Arts, and Triple Arts,
10. expand campaign content.

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
