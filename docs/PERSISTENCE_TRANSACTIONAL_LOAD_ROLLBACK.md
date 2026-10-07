# Persistence Transactional Load Rollback — 2026-10-01

Status: **BOUNDED RUNTIME-PERSISTENCE RECOVERY CANDIDATE / NOT MERGED**

Base:
- semantic-backup recovery PR #217
- exact base `b2da40d86e3e5b3ec88d1014b7451c433c403419`

Issue:
- #216 — Persistence coordinator: recover semantic backup fallback and transactional load safety

## Purpose

Current load preflight is already strong: semantic validation and subsystem preparation complete before the first canonical mutation.

This tranche addresses the remaining failure window:
a late exception after canonical mutation begins must not leave a partially loaded runtime.

## Current-specific transaction

Before mutation, the runtime captures:
- `world.snapshotPersistentState()`;
- canonical five-record roster;
- active-party IDs;
- air-navigation persistent state;
- playtime/session clocks;
- game state and transient Chapter 1 persistence coordinator fields.

The apply transaction then exposes bounded fault seams:
- `before-apply`;
- `after-party`;
- `after-world`;
- `before-commit`.

On failure:
1. restore canonical roster identity/values;
2. restore active-party IDs;
3. restore world + quest through current `preparePersistentState` / `restorePersistentState`;
4. restore air-navigation through its persistence authority;
5. restore runtime/transient coordinator state;
6. record `window._lastLoadRollback`.

If rollback itself fails, load fails closed with:
`LOAD_APPLY_AND_ROLLBACK_FAILED:<apply>|<rollback>`

## Browser fault proof

The existing Playwright persistence route now fault-injects:
- after party mutation;
- after world mutation.

For each case it requires the captured post-failure runtime to equal the exact pre-attempt rollback snapshot.

It also injects a rollback-start failure and requires:
- combined fail-closed error;
- `_lastLoadRollback.restored === false`;
- preservation of both primary apply error and rollback error.

## Scope boundary

No:
- schema v2;
- routeNetwork runtime;
- route gameplay;
- air-navigation behavior change;
- visual/art change;
- save payload expansion.

This tranche only makes existing load application transactional.

## Promotion evidence

Required:
- transactional static contract;
- persistence foundation;
- extended Playwright persistence round trip;
- Chapter 1 core/visual/browser;
- full smoke;
- exact-head hosted execution.

Automated green remains separate from merge/current-runtime authority and from human visual acceptance.
