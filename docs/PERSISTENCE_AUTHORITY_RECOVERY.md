# Persistence authority recovery — 2026-10-01

Status: **BOUNDED RECOVERY CANDIDATE / NOT MERGED RUNTIME AUTHORITY**

## Why this exists

The V45/V46 convergence lineage retained save/load foundation v1.1.0 but lost stronger game-save hardening that is still documented in the project authority records.

Historical provenance was recovered at exact commit:

- `990ab803056bc8bc8fef338b939d6172219ec91a`
- parent checkpoint `727e4d1065ed6f99aeba9f9de3a67b1143e6aca8`

The historical implementation includes:

- future-schema primary/backup detection;
- fail-closed manual overwrite protection;
- autosave exclusion of future-schema slots;
- explicit primary/backup reads and recovery provenance;
- backup-only slot discovery;
- backup-preserving write after recovery;
- browser/localStorage previous-generation backup.

## Current-base reconciliation

This candidate is rebuilt from V46 exact head:

`8e14230c0d045652508ca78e2cb31e14e602697f`

It preserves the later V46 isolated-save-root behavior:

`AETHERWAKE_SAVE_ROOT_OVERRIDE`

rather than replacing `modules/save-system.js` wholesale with the older historical file.

## Scope

Changed runtime authority:

- `modules/save-system.js`

Changed regression contract:

- `tests/save-system-contract.test.js`

Documentation:

- this file

No change to:

- Chapter 1 progression;
- combat;
- navigation;
- route-state proof;
- character art;
- visual presentation;
- save envelope schema version (still v1);
- payload semantics.

## Required verification

Before promotion:

1. `npm run test:persistence-foundation`
2. `npm run test:persistence-roundtrip`
3. Chapter 1 core/browser regression
4. exact-head hosted execution
5. confirm `AETHERWAKE_SAVE_ROOT_OVERRIDE` still works
6. confirm future-schema manual overwrite fails closed
7. confirm autosave rotation skips protected future-schema slots
8. confirm backup-only recovery remains discoverable

## Authority boundary

This recovery repairs lost persistence safety. It does **not** authorize route-state persistence or schema v2 by itself.
