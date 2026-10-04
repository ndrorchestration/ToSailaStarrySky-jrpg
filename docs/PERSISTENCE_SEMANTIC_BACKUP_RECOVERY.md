# Persistence Semantic Backup Recovery — 2026-10-01

Status: **BOUNDED RUNTIME-PERSISTENCE RECOVERY CANDIDATE / NOT MERGED**

Base:
- protected storage recovery PR #213
- exact base `84bb0c26c66b4696657f5ef9ad90f2b3e97c99ed`

Issue:
- #216 — Persistence coordinator: recover semantic backup fallback and transactional load safety

## Scope

This tranche restores only semantic candidate recovery and backup-preserving writes.

Recovered:
- `loadSemanticallyValidSaveCandidate(slot)`;
- semantic-invalid primary → `.bak` fallback through full `prepareSaveEnvelopeForApply`;
- explicit recovery provenance;
- backup-aware save-index classification;
- manual `preserveBackup` after recovery;
- autosave `candidateResolver` using the same semantic candidate chain;
- success/error evidence cleanup;
- player-visible recovery/future-save preservation messages.

## Already-current behavior retained

Current V46 already performs semantic pre-write validation inside `buildSavePayload()`.
This tranche does not replace that path.

## Explicit non-goals

Not included:
- schema v2;
- routeNetwork runtime;
- route-state gameplay;
- transactional load rollback;
- save UI redesign;
- visual/art changes.

Transactional apply rollback remains a separate second tranche under Issue #216.

## Browser proof

The existing player-path persistence round-trip now additionally proves:

1. create a valid primary + valid backup;
2. replace the primary with a checksum-valid but semantically impossible payload;
3. runtime semantic resolver selects the valid backup;
4. F9/Load uses that recovered backup;
5. recovery provenance contains the primary semantic failure;
6. F5/Save to the recovered slot requests `preserveBackup`;
7. the known-good backup bytes remain unchanged.

## Required promotion evidence

- `npm run test:persistence-foundation`;
- `npm run test:persistence-roundtrip`;
- Chapter 1 core;
- Chapter 1 browser;
- full smoke;
- exact-head hosted execution.

Automated pass does not imply merge/promotion or human visual acceptance.
