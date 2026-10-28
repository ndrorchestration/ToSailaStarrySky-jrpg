# P-03 equipment durability contract — offline prototype (NOT a production save)

**Status:** Draft, unmerged, test-only, **no active game save integration**. Forward engine Godot 4.7.2/GDScript. Built above the P-02 volatile ownership handoff in [draft #520](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/520). P-01/P-02 are scene/volatile state proofs, not item acquisition authorization.

## Safety constraint

The live Chapter I v1 codec/store `first_wake_chapter1_save_codec.gd` / `first_wake_chapter1_save_store.gd` remain unchanged and authoritative for old story progression. The production path `user://first_wake_chapter1_save.json` is untouched by this experiment.

**New isolated code:**

- `res://scripts/equipment_save_contract_review.gd`: strict standalone envelope `tstss.equipment.study.v0`, wrapping an exact validated Chapter I v1 snapshot, five starter-family equipment identities, and **exactly nine known developer-fixture item instances** (Ender primary staff + inlay/guard/charm, Lyra chakram, Ionia mace, Reson sword/rifle, Aepex martial arts). Instances are uniquely identified and each must have exactly one holder/location. All declared quantities are one. No real item drops, rarities, prices, consumables or jobs are implemented.
- `res://scripts/equipment_save_store_review.gd`: separate **hard-coded** `user://aetherwake-tests/equipment-p03-study.json` test slot. Temp-file verification, SHA-256 receipt and validated previous-generation backup are tested only here; never pass an arbitrary path or use the active chapter save slot. If primary is corrupt, recover the known-good backup; if both are corrupt, fail.
- `res://tests/equipment_save_contract_review_test.gd`: round-trip and malformed/forged/duplicate instance negatives; tests atomic test-slot write, backup preservation, valid old story restore, corrupt primary recovery, two-invalid-generation rejection and clean-up.
- CI `.github/workflows/godot-equipment-save-contract-proof.yml`: official hash-pinned Godot 4.7.2 editor and focused P-03/P-02/Chapter I save tests.

## Two distinct authorities / migration cannot grant loot

`preview_legacy_migration(existingChapterV1)` accepts only an already valid Chapter I v1 save and returns `state=legacy-pending-authorization`, `roster={}`, `instances=[]`, `ready=false`. This is **not** an inventory bootstrap. A backwards-compatible v1 save can be inspected and preserved **without inventing items** or pretending that an unapproved gear table existed.

`encode_test_fixture(P02Session, existingChapterV1)` is a separate developer-only operation. It creates a **bounded** fixture envelope, `state=review-fixture-only`, using only known single-instance IDs and P-02's owned fixed equipment state. It records each instance as `fixture:<definitionId>`, `developer-fixture-not-loot`. These unique IDs are test-fixture labels, **not** an approved algorithm for real item-instance IDs. A full production schema will need generated, server- or save-scoped, collision-resistant item identities and carefully specified provenance.

Neither function auto-applies, auto-saves, grants party combat turns, changes class/elemental magic, changes Chapter I join order or authorizes a new ship compartment. `inspect` returns detached copies only, not a live mutable inventory. A legacy save in `legacy-pending-authorization` is **not playable/equippable as production inventory**.

## P-03 candidate validation rules

1. Exactly defined envelope and actor/slot fields with correct types, schema/version and recognized authority state. Reject unknown fields/schema and malformed nested records.
2. The included Chapter I v1 story snapshot must pass original `SaveCodec.validate`; refuse `inventory`, `equipment`, `trialBag` leakage into the old schema.
3. Exactly five actor records in this *fixture* schema, each with all four slots and a valid held weapon. Non-Ender equipment remains locked to starter families and Reson rifle is secondary. This is item identity, **not** native story-party membership or turn rights.
4. In fixture-ready form exactly nine unique instance IDs and nine distinct definitions, with matching owner, slot and location. A bag instance may have no equipped owner/slot. A worn instance must point to exactly one compatible actor/slot, with a matching reciprocal roster link.
5. All instances have known fixture-only provenance. No implicit trading, acquisition, item multiplication, inventory stacking or unlocks from reading legacy saves.
6. Invalid snapshots must not modify the working primary file, the backup, the in-memory P-02 session or the active story save. A backup recovery is labelled `recovered=true` and may restore the previous generation (including an older pending migration).
7. A successful test proof is **not** a production authorization. The creator must separately approve real items, explicit legacy starter bootstrap rules, permanent save schema/version, item-instance ID policy, file commit/power-failure semantics, portable backup rules and cross-platform compatibility.

## Promotion gates remaining

| Gate | Requirement | State |
|---|---|---|
| P-01 | Real native equipment study bench and combat loop | Prior separate draft proof PASS |
| P-02 | Five-cast starter identity, volatile Ender ledger across actual scene reload | Prior exact native proof PASS |
| P-03a | Offline schema, no-grant legacy adapter, instance conservation, independent test-slot corruption recovery | **Requires exact-head hosted native result** |
| P-03b | Creator-approved persistent roster, real acquisition, real save upgrade and rollback on player files | **NOT IMPLEMENTED; HOLD** |
| P-04 | Approved field character art/sockets, accessible menus, controller player acceptance | PENDING |
| P-05 | Protected Windows installed build, performance, external playtest, release | HOLD |

**Documentation follow-up:** Reference this file in Godot README and equipment authority review, preserve full receipt in Notion ledger and the separate [main-targeted promotion handoff PR #498](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/498). Do not mark the old production save schema migrated. No merges or releases.
