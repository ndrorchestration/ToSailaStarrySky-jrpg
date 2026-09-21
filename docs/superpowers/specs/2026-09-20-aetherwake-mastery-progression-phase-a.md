# Aetherwake Mastery Progression Design — Phase A

**Date:** 2026-09-20  
**Branch:** `dev/progression-build`  
**Status:** Implementation contract for the non-mutating mastery-definition phase.

## Goal

Begin migration step 8 (school/job/mastery progression) without inventing unresolved
companion canon, redesigning combat, or silently changing the released save schema.

Phase A establishes **code-owned progression facts and uncertainty boundaries only**.
It does not yet award mastery points, create mastery ranks, add skill trees, or gate
current combat actions on new mastery state.

## Established facts

The current specification establishes:

- major magic/domain families: `elemental`, `arcane`, `psychic`, `spirit`;
- Ender special innate affinities:
  `aether`, `resonance`, `correspondence`, `lumen`;
- jobs and schools are distinct concepts;
- potential/affinity does not imply mastery;
- Lyra, Ionia, Reson, and Aepex do not yet have canonical native-job or affinity
  definitions established in runtime;
- the current Sky-Sailor / Engine-Wright / Aether-Weaver selections are temporary
  mechanics templates, not canonical authored jobs.

## Required API

Create `modules/mastery-defs.js` with a renderer-independent frozen API:

- `VERSION`;
- `DOMAIN_FAMILY_IDS`;
- `ENDER_SPECIAL_AFFINITY_IDS`;
- `getAuthoredAffinities(characterId)`;
- `getNativeJobStatus(characterId)`;
- `validate()`.

### Tri-state authored knowledge

The API must preserve the distinction between **known empty**, **known value**, and
**unknown**. For unresolved characters it must return an explicit status such as:

```js
{ status: 'unknown', ids: [] }
```

rather than treating the absence of data as proof that a character has no
affinities or no future job.

For Ender:

```js
{
  status: 'established',
  ids: ['aether', 'resonance', 'correspondence', 'lumen']
}
```

Ender's native job status is established as `rift-scholar`. Companion native-job
status remains `unknown`.

## Non-goals

Phase A MUST NOT:

- assign Lyra/Ionia/Reson/Aepex canonical affinities;
- assign companion canonical jobs;
- convert temporary mechanics templates into canon;
- add mastery ranks/XP;
- change ability costs, unlocks, or current combat eligibility;
- alter the existing level-3/4/5 prototype unlock behavior;
- add skill-tree content;
- add Dual/Triple Arts;
- modify save documents.

## Save compatibility boundary

Schema v2 is already released and player-facing. Mutable mastery state would be a
new persistent domain.

Therefore:

1. Phase A definition facts remain code-owned and do **not** change save schema.
2. The first mutable mastery-state implementation must introduce **save schema v3**.
3. v2 → v3 migration must initialize new mutable mastery fields without fabricating
   progress.
4. Canonical affinity/native-job facts remain code-owned even after v3; saves must
   not be allowed to rewrite authored identity canon.

## Runtime integration

Both playable entrypoints must load `modules/mastery-defs.js` before
`modules/party-state.js`.

Runtime setup must fail visibly if the mastery definition API is missing or invalid.

No current player state is mutated by Phase A.

## Verification

Automated tests must prove:

- exact major-domain family IDs;
- exact established Ender affinity IDs;
- explicit UNKNOWN for unresolved companion affinities;
- Ender native job established as `rift-scholar`;
- companion native jobs remain UNKNOWN;
- duplicate/invalid definition IDs fail validation;
- both playable entrypoints load the module in dependency order;
- current ability eligibility and browser smoke remain unchanged.

## Exit condition

Phase A is complete when the definitions module, tests, dual-entrypoint boot
contract, gameplay smoke, and Windows desktop package are green on the same runtime
state.

Only then should Phase B design mutable mastery state + save schema v3.
