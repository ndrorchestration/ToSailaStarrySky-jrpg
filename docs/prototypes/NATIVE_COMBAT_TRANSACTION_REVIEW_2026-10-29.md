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

## 2026-10-29 ability-to-turn adapter continuation (unverified)

- `godot/scripts/combat/ability_turn_adapter.gd` adds an isolated ID-based catalog bridge to the existing turn queue. It rejects missing/unknown abilities, invalid descriptors and improper self/ally/enemy targeting before the turn transaction.
- The input catalog and faction map are **review fixtures**, not the canonical character/ability databases, and do not establish unlock eligibility, enemy encounter approval, class/job rules or damage balance.
- The adapter adds only an `ability_id` reference to the successful event log, preserving copy-on-write behavior.
- `godot/tests/native_combat_ability_adapter_test.gd` covers bad ability IDs, friendly-fire rejection, invalid self-targets, successful same-unit heal with MP cost, event attribution, immutability and out-of-turn denial.
- Run `godot --headless --path godot --script res://tests/native_combat_ability_adapter_test.gd` alongside the three earlier tests on the exact head.
- **No Godot execution, approved canonical ability integration, 3D battle screen or gameplay acceptance is claimed.**

## 2026-10-29 isolated turn-queue hardening

- The ordered turn queue now advances its round counter when the next eligible participant wraps to an earlier index, including when the last participant is incapacitated. Defeated units remain in the declared order but cannot act.
- `native_combat_turn_queue_test.gd` includes an isolated three-participant knockout/round-rollover regression and checks the prior roster remains unchanged.
- **Execution remains unverified**: these changes are authored and committed, not proven with Godot 4.7.2 or native scene playthrough. No encounter, party registry, ability registry, battle UI, VFX, or release wiring was changed.
- Exact commands for the additional test: `godot --headless --path godot --script res://tests/native_combat_turn_queue_test.gd`. Inspect engine exit status and stderr, not just the printed PASS marker.

## First Wake party preview bridge (2026-10-29; untested)

`godot/scripts/combat/first_wake_party_preview.gd` reads the real `first_wake_revised_opening_contract.gd` snapshot without mutating it. It accepts only recruited party identities, caps the proposed crew at three combatants, rejects duplicates and overlapping enemy IDs, and returns a separately labeled **unauthorized review preview** with a copied turn state. It does not authorize encounters, modify story or saves, or install a battle scene. Run `godot --headless --path godot --script res://tests/first_wake_party_preview_test.gd` on the current PR head; the new test targets Ionia-before-hire rejection, Lyra-before-reunion rejection, Ionia-after-hire preview, uniqueness, and story immutability. **Native execution not performed.**

## Further regression coverage — sole-survivor turn order

The turn queue test now exercises the case where only the first participant is conscious and the next participant is incapacitated. It expects a successful self-heal, a rollover to round 2, no mutation of the input state, and continued eligibility for the survivor. This test is **authored, not confirmed executed**, and does not grant encounter or release approval.

Verification commands (from repository root, with Godot 4.7.2):

```sh
godot --headless --path godot --editor --quit
godot --headless --path godot --script res://tests/native_combat_transaction_test.gd
godot --headless --path godot --script res://tests/native_roster_battle_test.gd
godot --headless --path godot --script res://tests/native_combat_turn_queue_test.gd
godot --headless --path godot --script res://tests/native_combat_ability_adapter_test.gd
godot --headless --path godot --script res://tests/native_ability_learning_guard_20261029_test.gd
godot --headless --path godot --script res://tests/first_wake_party_preview_test.gd
```

Do not infer that general First Wake render/smoke workflow successes executed these exact combat tests. Record exact-head logs and exit codes before promotion.

## Read-only UI projection queue-validation gate

The isolated `battle_ui_projection.gd` now rejects missing/out-of-range/non-integer cursors, empty participant order, repeated participant identities, and invalid round counts instead of showing malformed queue data as an accepted view. The native UI projection test adds failure cases and checks that failed projection attempts do not mutate the source state.

Run `godot --headless --path godot --script res://tests/native_battle_ui_projection_test.gd` on the exact PR head using the project's required Godot version; collect the process exit code and stderr. **Not executed or visually approved in this session.** No scene hookup, player-facing HUD, encounter authorization, merge, or release approval follows from this code change.
