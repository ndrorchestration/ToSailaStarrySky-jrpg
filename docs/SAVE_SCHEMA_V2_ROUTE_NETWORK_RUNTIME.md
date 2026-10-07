# Production Save Schema v2 / Neutral Route Network — 2026-10-01

Status: **IMPLEMENTED CANDIDATE / NO ROUTE GAMEPLAY / NOT MERGED**

Base:
- transactional protected-v1 persistence candidate #218
- exact base `de2e513f3b88813e2e69e3ccfc038227d4d1daaf`

Depends on:
- #213 protected storage recovery;
- #217 semantic backup recovery;
- #218 transactional apply rollback;
- #214 versioning gate;
- #215 schema-v2 source proof.

## Purpose

Promote the previously source-only schema-v2 design into the playable persistence architecture **without changing route gameplay**.

This tranche establishes only the durable state substrate required for later bounded route-state work.

## Whole-game schema

`AetherSaveSystem.SCHEMA_VERSION = 2`

Save-system implementation version:
`1.2.0`

The storage key namespace intentionally remains:
`aetherwake.save.v1.`

That namespace is now historical/stable storage addressing, not a schema claim. Changing it would orphan existing schema-v1 saves before migration.

## Migration

`MIGRATIONS[1]`:
- requires a valid v1 envelope/payload;
- refuses a v1 payload that already contains `routeNetwork`;
- adds a neutral route-network record;
- advances to schema 2;
- relies on the canonical migration pipeline to recompute checksum.

Neutral record:

```json
{
  "persistenceVersion": 1,
  "operationalStates": {},
  "discoveredClues": [],
  "precedents": []
}
```

No route condition, clue, or precedent is inferred.

## Runtime ownership

Existing:
- route knowledge remains `airNavigation.discoveredRoutes`.

New:
- `routeNetworkState` owns objective route condition/clues/bounded precedents.

At setup:
- neutral route-network state is created;
- authority is exposed as `window._routeNetwork`;
- live state is exposed as `window._routeNetworkState`.

Save:
- `buildSavePayload()` exports routeNetwork.

Preflight:
- payload validator requires routeNetwork;
- route-network authority validates its own persistence version and contents;
- `prepareSaveEnvelopeForApply()` rehydrates the route state before mutation.

Apply/rollback:
- transactional load applies prepared route state;
- rollback snapshot captures it;
- rollback restores it.

## Semantic validator

Validator version:
`1.1.0`

Schema-v2 payloads require:
- runtime;
- world;
- quest;
- party;
- airNavigation;
- routeNetwork.

Unknown top-level keys fail closed.

## Permanent fixtures

Retained:
- `tests/fixtures/saves/schema-v1-manual-1.json`

Added:
- `tests/fixtures/saves/schema-v2-manual-1.json`

The v1 fixture must migrate deterministically to v2.
The v2 fixture must validate directly.

## Cross-version downgrade proof

Dedicated workflow checks out:
- current schema-v2 candidate;
- exact protected-v1 baseline `de2e513f...`.

The old v1 build must:
- refuse overwrite of v2 primary;
- refuse overwrite of v2 backup;
- skip v2 autosave slot;
- fail closed if all autosaves are v2;
- reject v2 load.

This is the production counterpart to source-proof PR #215.

## Scope boundary

This tranche does **not**:
- mark Rootline West shifted;
- reveal `rootline-west-upper-trace`;
- record `LOCAL_ROUTE_ASSISTANCE`;
- alter flight speed;
- alter route UI;
- change Chapter 1 story progression;
- admit High Sky/Auroral systems;
- change visual/art authority.

All routeNetwork gameplay values remain neutral.

## Next gate

Only after exact-head v2 migration, persistence, browser, Chapter 1, and downgrade guards pass may a separate bounded runtime PR:
1. expose one route clue;
2. perform one `OPEN → SHIFTED` transition;
3. persist/reload it;
4. consume one local revisit consequence.

Human route readability remains a separate acceptance gate.
