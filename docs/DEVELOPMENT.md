# Aetherwake Development Guide

## Current stage

Aetherwake is a late-prototype / pre-alpha project.

The development branch now has a verified playable baseline plus the first persistent-party architecture phase: `ROSTER[5]` and reference-based `ACTIVE_PARTY[3]`. The next architecture gate is the first explicit effect vocabulary; ability/progression extraction remains downstream.

## Source-of-truth rules

### Runtime

Current browser runtime:

1. `index-embedded.html`
2. `modules/party-state.js`
3. `aetherwake.js`
4. `modules/char-create.js`
5. bundled `p5.min.js`

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
