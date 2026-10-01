# First Wake Route-State Proof v0

**Status:** DESIGN/IMPLEMENTATION CANDIDATE — NOT RUNTIME-ADMITTED

**Stacked on:** V46 visual branch. This tranche is intentionally isolated and does not change the V46 player-facing runtime, Chapter 1 progression, collision, combat, field-art admission, release state, or existing air-navigation persistence contract.

## Purpose

Prove the smallest useful subset of the new world/traversal architecture before widening scope:

1. explicit per-route state;
2. favorable-direction sky-lane travel benefit;
3. a high-altitude clue that a known route has shifted;
4. a small fail-closed persistence domain for route state + clue discovery.

## Implemented candidate

`modules/route-state-proof.js` wraps the existing `AetherAirNavigation` contract without modifying it.

Prototype route states:

- `open`
- `provisional`
- `shifted`
- `closed`

The initial clue is `rootline-west-upper-trace`: a high-altitude trace near the existing Rootline West corridor suggesting the charted route may have shifted upward.

## Important non-canon numbers

The prototype lane speed multipliers are implementation-test constants, not worldbuilding canon and not final balance:

- open: 1.25×
- provisional: 1.10×
- shifted/closed: no lane benefit

Final speeds and travel-time scale remain an explicit creator/balance decision.

## Admission boundary

This tranche is **not loaded by the browser/runtime**. It does not alter the playable candidate.

Before runtime wiring:

- run `npm run test:route-state-proof`;
- rerun `npm run test:air-navigation`;
- establish clean exact-head local evidence;
- preserve V46 visual/player acceptance boundaries;
- define how this nested state enters the canonical save envelope before making persistence claims;
- wire one player-facing clue and one route-state consequence only.

## Next smallest runtime step

After technical verification and the current visual acceptance gate permits gameplay-system work:

1. load the proof module;
2. display the upper-route clue through existing flight UI;
3. allow one bounded event to mark Rootline West `shifted`;
4. show the status on the route map/HUD;
5. persist it through the canonical save system;
6. revisit and verify the state remains visible.

Do **not** add High Sky progression, Auroral mechanics, global factions, or Act II region content in this tranche.
