# First Wake — independently versioned salvage v3 checkpoint pilot

**Scope:** Opt-in, playable Chapter I review continuation from [two-area material recovery draft #557](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/557). This is a **new** isolated save format, not a migration of established main Chapter I v1 or preflight review v2. **No merges, release, narrative canon changes, or new ship/combat authority.**

## Implemented user flow

1. From the actual configured original main scene, press **F8** to enter the revised dock. Completing the entire revised opening, ocean splashdown, measured safe berth, Lyra/Talen family introduction and two-clue theory opens the existing two-area salvage investigation. While still in the salvage scene, **K** explicitly writes progress and **L** explicitly reloads it.
2. Quit and reopen the game. From the original configured scene, use **F8**, then press **J** *before taking the flyer or recruiting Ionia* to resume an existing dedicated v3 salvage checkpoint. Both old v1 play and v2 dock/engineering/preflight K/L controls remain unchanged. An absent, invalid, mismatched or corrupted v3 snapshot refuses the transition without changing the revised dock.
3. Restored salvage retains validated prior evidence-clue IDs, which temporary area Ender is in, his bounded location, and the exact recovered provisional material IDs plus source/custodian receipts. The scene creates a fresh `Opening` and `Core` contract through deterministic story-state replay, with in-memory identity consistency. A missing second object can still be found by walking to its separate depot; returning to the ship opens the original manual installation, failed retest and Denith-shanty test.
4. **K/L are refused after entering the repair workshop**, because no production-authorized v3 schema exists for installation, failed retest, song or launch. A postflight scene save while adrift is likewise not implied.

## Hard data contract

- Schema `tstss.first-wake.salvage.review.v3`, sole independent path `user://first_wake_salvage_review_v3.json`, using the existing verified temp/primary/backup SaveStore with a **separate v3 validator**.
- Fixed strict fields: `schema`, `step=working_theory`, `clues` (2–3 unique known independent IDs), `region` (quay/depot review), bounded finite `player_position`, and `custody` (0–2 exact item ID, source area, custodian Ender, physical scene interaction). Unknown fields, incorrect source pairing, duplicates, missing clues, nonfinite or out-of-bounds positions, old v1/v2 payloads and authority grants are rejected. The schema does **not** persist an active party roster or player-access/combat permission.
- The restore code calls the original step-ordered employment/flight/family/clue contract to reconstruct the **review model only**; `prior_physical_water_reverified=false` means loading a historical save is never asserted to reproduce a real current RigidBody2D landing or actual towing physics. It also reports `production_inventory=false`, `can_launch=false`, `can_execute_art=false`.
- In-scene L can rewind only when the active story remains the same crew with exactly the same clue set; it refuses alien saves from another family investigation rather than silently rewriting the parent ship and party object.
- F8 always exits to the **exact original volatile v1 scene**, not by writing a save or converting from a revised model. Main scene remains unchanged.
- No cryptographic signature, server provenance, save anti-cheat or trusted resource ledger is claimed. Like every local player save, a determined user can forge data, so v3's field validation is a crash/consistency boundary rather than proof of genuine earlier gameplay.

## Exact engine acceptance

- `godot/tests/first_wake_salvage_v3_checkpoint_test.gd`: actual two-area source pickup, two verified generations, K/L equivalent durable store calls, rollback, invalid schema/fields/source/position/authority refusal, independently loaded fresh-scene player/source reconstruction, corruption recovery from verified backup and byte-level custody check of older v1/v2 paths.
- `godot/tests/first_wake_salvage_v3_main_resume_test.gd`: actual configured startup F8 to fresh review, explicit v3 opt-in with missing-save refusal, recovered source and position in a new salvage scene, second item traversal and physical return, no mid-workshop saves, and exact F8 return to preserved original v1 state with no v1/v2 disk changes.
- The pinned Godot 4.7.2 CI includes **separate steps** with assertion sentinels, nonzero exit, script errors and negative gates. Existing salvage, family, main-to-melody, rendering, smoke and Windows custody workflows remain independent.

## Still missing before production

Approved real-world geographic source zones and part/material identities, genuinely trusted persistent shared inventory/quest ledger through the *entire* postflight/melody sequence, collision/navigation/UX refinement, controller-bound v3 resume parity (J is currently keyboard-only), automatic save slots/options menus and manual save recovery, final original Denith shanty and instrument-to-audio synchronization, realistic sea/ship recoveries, final Lyra/Talen artwork, accessible world traversal, uncoached player playtest, Windows Defender security clearance, installer signing and an authorized release. Do **not** label this as a complete Chapter I save system.
