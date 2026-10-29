# Native Combat Transaction — review gate (2026-10-29)

This work belongs to draft PR #601, based on `feat/godot-first-wake-revised-checkpoint-v2-20261027`. It adds a pure single-action resolver and an atomic roster adapter; **it is not yet wired into the playable Chapter I scene**.

## Boundaries
- `godot/scripts/combat/turn_transaction.gd`: accepts only bounded integer damage/heal power and bounded MP/stamina costs, checks HP/resource eligibility, and returns copy-on-write projections.
- `godot/scripts/combat/roster_battle.gd`: uses stable unit IDs and merges same-unit healing/expense into one roster record; no roster update on failure.
- Current damage/heal `power` inputs are integration parameters, **not** approved damage formulas or finalized numeric balance.
- Does not own encounter authorization, turn sequencing, enemy behavior, abilities/unlocks, elemental reactions, save serialization, VFX, story advancement or party recruitment.
- No approval to replace older Chapter I code or canonical Ionia-first opening. Default Godot project entry still requires separate acceptance.

## Local Godot 4.7.2 verification (NOT YET EXECUTED)

From repository root:

```bash
godot --headless --path godot --editor --quit
godot --headless --path godot --script res://tests/native_combat_transaction_test.gd
godot --headless --path godot --script res://tests/native_roster_battle_test.gd
```

These commands must each exit 0; inspect all stderr, imports and warnings. Expected test markers: `NATIVE_COMBAT_TRANSACTION_PASS` and `NATIVE_ROSTER_BATTLE_PASS`.

## Next safe steps

1. Execute native tests on exact PR head SHA, pin the engine version and capture logs.
2. Review resolved action semantics for a shared actor/target, including zero-cost and zero-power behavior, against approved ability registry.
3. Add explicit authoritative turn order / action eligibility adapter only after current Chapter I party-state interface is reviewed.
4. Wire battle results into real UI and VFX only after scene/encounter placement approval; no standalone visual playback passes as a production combat acceptance.
5. Preserve installer Defender-on, signing, provenance, visual review and explicit release approval as independent gates.

**Status:** Source committed, unit test scripts authored; native execution **UNVERIFIED**. GitHub commit status API returned no status entries on head `1eaee41e6c735a440afaa7da75f43d9b30bf3dc3`. Do not infer test pass or mergeability.
