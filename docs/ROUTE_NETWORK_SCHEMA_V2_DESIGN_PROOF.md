# Route Network / Save Schema v2 Design Proof

Status: **DESIGN PROOF ONLY — NOT RUNTIME-ADMITTED**

Base: PR #223 exact head `69ea1438eeca008634ef46c066c794ce543a094d`.

This proof exercises the contract recorded in GitHub Issue #214 and the Notion route-state/schema-v2 design page without changing the live save schema or loading any new module in the browser.

## What the proof establishes

### Separate axes

Route knowledge remains owned by existing `airNavigation.discoveredRoutes`:
- unknown;
- discovered.

Operational condition remains a separate route-network domain:
- open;
- provisional;
- shifted;
- closed.

### Sparse route conditions

`OPEN` is the authored default and is not redundantly serialized as an override.

### Conservative v1 → v2 migration

Migration:
- preserves existing `airNavigation` route knowledge exactly;
- adds an empty/default routeNetwork record;
- does not infer shifted/provisional/closed;
- does not invent clues;
- does not invent `LOCAL_ROUTE_ASSISTANCE`.

### Fail-closed validation

The design proof rejects:
- unknown route IDs;
- unknown route-condition values;
- unknown route-network keys;
- unknown clues;
- unknown precedents;
- unsupported route-network persistence versions.

## What this proof does not establish

It does not:
- bump `AetherSaveSystem.SCHEMA_VERSION`;
- add `routeNetwork` to the live payload validator;
- alter `aetherwake.js`;
- load the module from `index-embedded.html`;
- write schema-v2 saves;
- prove v1-build downgrade protection against real v2 saves;
- wire Rootline West into gameplay.

Those remain gated behind the protected persistence baseline and explicit Issue #214 implementation authority.

## Next admissible use

This proof should be used as a migration/validation fixture when a future schema-v2 implementation candidate is authorized.

Do not treat a passing proof as schema-v2 runtime admission.
