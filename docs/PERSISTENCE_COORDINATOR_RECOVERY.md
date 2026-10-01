# Persistence coordinator recovery — 2026-10-01

Status: **BOUNDED RECOVERY CANDIDATE / NOT MERGED AUTHORITY**

This tranche is stacked on persistence storage recovery PR #213.

## Provenance

Historical runtime authority at `990ab803056bc8bc8fef338b939d6172219ec91a` contained stronger persistence coordinator behavior that is absent from the V46 convergence runtime.

The lost behaviors include:

- semantic payload validation before manual save/autosave writes;
- semantic primary/backup candidate selection;
- preserving a validated backup after recovery;
- using semantic candidate resolution during autosave rotation;
- transactional load apply with rollback if a late subsystem mutation fails;
- machine-visible recovery and rollback evidence.

## Current recovery strategy

This branch does **not** transplant historical `aetherwake.js`.

Instead it adapts only persistence-owned behavior to the current V46 authorities:

- current `world.snapshotPersistentState()`;
- current `world.preparePersistentState()`;
- current `world.restorePersistentState()`;
- current canonical ROSTER / ACTIVE_PARTY identities;
- current AetherAirNavigation export/restore contract;
- current Chapter 1 runtime markers.

## Files changed

- `aetherwake.js`
- `tests/persistence-coordinator-recovery.test.js`
- `package.json`
- this provenance note

## Explicit non-goals

No:
- route-state runtime integration;
- schema-v2 implementation;
- gameplay progression change;
- visual redesign;
- character-art admission;
- save UI redesign;
- faction/reputation work.

## Required evidence

Before any promotion claim:

1. `npm run test:persistence-foundation`
2. Chapter 1 core
3. complete Chapter 1 browser route
4. manual browser persistence round trip
5. full smoke
6. exact-head hosted execution
7. visual evidence technical regression remains green

Automated success does not equal human/player visual acceptance.

## Authority impact

If verified, this tranche restores the semantic coordinator needed underneath future schema-v2 work.

It still does not authorize schema v2 or durable route state by itself.
