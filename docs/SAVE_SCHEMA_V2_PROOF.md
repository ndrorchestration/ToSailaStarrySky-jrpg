# Save Schema v2 Proof

**Status:** DESIGN/TEST CANDIDATE — NOT RUNTIME-ADMITTED

**Base:** persistence recovery PR #213 exact head `84bb0c26c66b4696657f5ef9ad90f2b3e97c99ed`.

## Purpose

Prove the migration and downgrade-safety assumptions required by Issue #214 before changing the playable save format.

This tranche does **not**:
- change `AetherSaveSystem.SCHEMA_VERSION`;
- load schema-v2 logic into the browser;
- write v2 from the playable runtime;
- wire route-state gameplay;
- change V46 visuals.

## Proven model

Two independent axes remain separate:

- route knowledge: existing `airNavigation.discoveredRoutes`;
- route condition: future `routeNetwork.operationalStates`.

Schema-v2 proof adds a candidate `routeNetwork` container:

```json
{
  "persistenceVersion": 1,
  "operationalStates": {},
  "discoveredClues": [],
  "precedents": []
}
```

`OPEN` is the sparse default and is not redundantly serialized.

## Migration rule

v1 → v2:
- preserves existing `airNavigation.discoveredRoutes`;
- adds an empty/default routeNetwork;
- does not invent PROVISIONAL, SHIFTED, CLOSED, clues, or precedents.

## Downgrade proof

The test treats the recovered #213 schema-v1 save system as the older supported writer and requires it to:
- refuse overwrite of a v2 primary;
- refuse overwrite when v2 exists only in backup;
- skip v2 autosave slots;
- fail closed when every autosave slot is v2.

## Boundary

This proves the versioning direction is technically coherent. It does not authorize runtime migration or save-schema promotion.
