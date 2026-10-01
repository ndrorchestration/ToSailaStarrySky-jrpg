# Save Schema v2 / Route Network Proof

Status: **SOURCE/CONTRACT CANDIDATE — NOT RUNTIME-ADMITTED**

Base: protected persistence recovery candidate #213 at
`84bb0c26c66b4696657f5ef9ad90f2b3e97c99ed`.

## Purpose

Prove the migration and downgrade-safety contract required by Issue #214
without changing the playable runtime or current save schema.

## Separation of authority

Route knowledge remains owned by:

`AetherAirNavigation.discoveredRoutes`

New objective route condition is modeled separately by:

`AetherRouteNetworkState`

Operational states:
- OPEN
- PROVISIONAL
- SHIFTED
- CLOSED

OPEN is a sparse default.

## v1 -> v2 proof

The proof migration:
- requires a valid schema-v1 envelope;
- preserves existing `airNavigation` exactly;
- adds a neutral `routeNetwork` persistence record;
- advances the envelope schema to 2;
- recomputes checksum;
- does not invent route clues, shifted/provisional/closed state, or precedents.

## Downgrade proof

The protected schema-v1 save system recovered by #213 is exercised as the
"old build" against schema-v2 records.

Required outcomes:
- v2 primary cannot be overwritten;
- v2 backup cannot be overwritten;
- autosave skips v2 slots;
- all autosave slots v2 => fail closed;
- v1 migration rejects v2 load.

## Runtime boundary

This branch does not:
- change `AetherSaveSystem.SCHEMA_VERSION`;
- edit `aetherwake.js`;
- load route-network state in `index-embedded.html`;
- change the production payload validator;
- change air-navigation behavior;
- change visuals or Chapter 1 progression.

A later production candidate must deliberately integrate the proven contract.
