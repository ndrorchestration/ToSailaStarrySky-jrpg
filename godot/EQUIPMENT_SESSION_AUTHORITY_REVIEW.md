# Equipment P-02 — Five-cast volatile session authority

**Source:** Stacked draft on [P-01 #509](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/509), with the earlier battle-gear and inspector work in draft #481. **Status:** noncanonical **in-memory** architecture experiment, **not** persistence, item acquisition, finalized job rules or production adoption. The native engine is Godot **4.7.2 + GDScript**. Keep all plots/reveals and the Five Lights out of this test.

## Problem P-01 did not solve

P-01 kept a single Ender loadout and trial bag consistent when moving *within one scene*, but a newly instantiated copy of the scene starts again with its own default objects. It did not prove state ownership across a real scene unload and new scene load. Duplicating inventories and characters per scene would become dangerous as exploration, menus, battles and ships are assembled into a game.

## Actual P-02 design

`res://scripts/battle_equipment_session_review.gd` owns **one** volatile Ender trial ledger plus **five** character loadouts (Ender staff, Lyra chakram, Ionia mace, Reson sword and secondary rifle, Aepex martial arts). Non-Ender records remain their starter gear **only**; they do not have acquired inventories, new jobs or executable battle turns. This working identity check does not change canonical active-party membership or Chapter I join order.

- `bind_study_scene(scene)` accepts *only* the explicitly opt-in noncanonical `equipment_lifecycle_study.tscn`-style Chapter I study script with a mounted rig. Validates all five loadouts, Ender's inventory conservation, target scene starter state and absence of modal, dialogue or battle **before changing any references**.
- On success the new scene receives the **same** Ender loadout and trial inventory objects. A detached original scene may be freed; the session authority outlives it. The field and battle review rigs are re-synced from that validated loadout. This is a reference handoff, not a serialized item import.
- `snapshot()` provides a **deep-copied, read-only-by-convention** observation receipt with status `volatile-noncanonical-equipment-session` and roster/bag contents. It **must not** be written to disk or added to Chapter I's save codec. Changing the snapshot cannot mutate the session authority.
- The existing `aetherwake.first-wake.chapter1.v1` save schema remains unchanged. A normal Chapter I restore intentionally resets shared Ender trial gear to the pre-seeded starter bag, just as P-01 did. No real character inventory migrations are implied.
- Preflight is fail-closed on unknown actor, foreign/forged/invalid gear or bag, ordinary chapter scene, active modal, ongoing combat or story dialogue. The forged state must not partially overwrite new scene references. This is not a loot economy, item trading, socket atlas or authorized new combat skill layer.

## Native tests and evidence boundaries

`res://tests/battle_equipment_session_review_test.gd` is the real-scene integration test, pinned to the new draft SHA. It loads an ordinary Chapter I scene and confirms test-authority rejection; binds a study scene to one central owner; equips an owned staff/guard/charm from field inspection; frees that entire Godot scene; instantiates and rebinds a **second** native study scene. It checks identity equality (not just copied values) for the Ender loadout and bag, matching field/battle rig appearance, exact 9-point outbound practice strike, 10/9 practice pressure mitigation, unchanged authored scene progression and combat authority, and null spell unlocks. It tests modal/battle rebind denial; a foreign Lyra-staff forgery fail-closed on a third scene; deep-copy isolation; and original v1 save restore resetting shared gear.

Dedicated new proof workflow: `.github/workflows/godot-equipment-session-proof.yml`. It downloads the SHA-256-verified official Godot 4.7.2 binary, headless editor imports scripts, executes exact session test with a bounded timeout, then exercises the existing P-01, inventory, loadout and save tests. The full Chapter I native workflow also gains this session test. Cite only successful actual run IDs, never the mere presence of the workflow.

| Gate | Requirement | Status |
|---|---|---|
| P-01 practice scene | Field/inspector/battle/return with real Godot frames | Previously PASS at exact draft #509 |
| P-02 volatile session | Full Godot scene unload/new scene rebind, five-cast starter records, one shared Ender bag | **Implementation submitted for native verification** |
| P-02 battle parity | New scene uses exactly the same owned staff/armor/charm during practice | **Test submitted; not an approved enemy or actual five-party combat** |
| P-03 durable player inventory | Versioned item ownership, acquisition, persistence, old save recovery, atomic writes | **NOT IMPLEMENTED** |
| P-04 approved field art and UX | Composited accepted Ender sprite, real weapon sockets, accessible UI and player review | **PENDING** |
| P-05 hardware/release | Real device GPU, secured Windows installed build, uncoached players, creator authorization | **HOLD** |

## Documentation routing and next production seams

- [godot/BATTLE_EQUIPMENT_REVIEW.md](BATTLE_EQUIPMENT_REVIEW.md): preserve practice-only damage/owned item wording, link this scene authority contract.
- [godot/README.md](README.md): note P-02 is session handoff **not** whole-game migration.
- [documentation-only P0–P5 main handoff draft #498](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/498): update status as a separate follow-up, keeping prototype proofs vs production admission distinct.
- Notion **Consolidated Development & Cinematic Visuals Ledger**: exact PR head and actual CI receipt; label the five-actor roster records as **identity-only, no gameplay turns**.
- Before real inventory/save: design a versioned item-instance registry with actual acquisition provenance and atomic migration, a job/actor equip-authorization contract, visual/pose/socket manifest, and old-save corruption/backup tests. No final item names, prices, rarity, or world station can be inferred from this prototype.

**Explicit hold:** ordinary Chapter I preview never binds the volatile session, no GDScript save schema change, no Lua/JS gameplay expansion, no moon/auroral/ship plot reveal, no merging source or releasing binaries.
