## P-03 independent offline equipment save contract (draft, no live save migration)

The [P-03 isolated save-contract review](EQUIPMENT_P03_SAVE_CONTRACT_REVIEW.md) explores a strict versioned item-instance envelope and a **test-only** atomic/backup storage slot. An existing Chapter I v1 save becomes **pending authorization with zero item grants**, not permanent loot or a production-upgraded inventory. The real `first_wake_chapter1_save_codec.gd`, `first_wake_chapter1_save_store.gd` and player save path are deliberately unchanged. Native exact-head tests and creator authorization are required before any production persistence claim.

# Native battle equipment visual slice — review only

**Source line:** stacked on Chapter I / party-combat-authority draft PR #347, not merged into `main` or the independent planetary/flight draft branches. **Engine target:** Godot 4.7.2 Standard + GDScript.

## Player-facing review

In the native Chapter I scene, enter the formula review with **C** or reach the authored Wind Shear battle. During combat:

- **5** cycles the equipped Ender fighting-staff **appearance** (default brass-ferruled staff versus a silver-inlay style study).
- **6** adds/removes a provisional chest-guard **armor overlay**.
- **7** adds/removes a provisional **charm overlay**.
- **9** opens a dedicated item inspector during **noncanonical Formula Review only**. Use arrow keys or controller D-pad to select slot/item, **Enter / controller A** to equip confirmed owned gear, and **Escape / controller B** to close. Nothing equips while merely browsing. The inspector also blocks combat inputs while open.
- **8** toggles *optional practice pressure* against the noncanonical formula target. It is disabled by default, never available in story combat, and makes the dummy respond after accepted turns using alternating physical/aether hits.

All equipment changes pass through a **conserved, temporary trial inventory** and update a **socketed** battle-actor review rig immediately, without closing combat or consuming a turn. The lower-right inventory readout shows the number of unused trial staff, guard and charm studies. The arm and hand socket follow the current combat pose. This remains a neutral stand-in silhouette, not approved character art. The staff always remains a full-length, physical fighting staff. No magic casting prerequisite is imposed.

`battle_equipment_loadout.gd` keeps stable item IDs and actor/slot restrictions; `battle_equipment_visual.gd` now assembles separate `battle_equipment_attachment.gd` CanvasItem children for armor, accessory, currently held weapon and overlaid grip hand. The weapon and hand share a moving combat-pose socket; the body is a removable placeholder, and equip transactions leave attack/guard/analyze/rest poses intact. Starter families are Ender/staff, Lyra/chakram, Ionia/mace, Reson/sword + secondary rifle, Aepex/martial arts, taken from the earlier equipment-system working-authority draft (#227), not inferred from elemental affinities. A `hold_weapon_slot("secondaryWeapon")` call changes Reson's representation from sword to rifle, but Reson **does not acquire a combat turn** in the existing Ender-only Chapter I encounter.

This is a **review prototype**, not approved party combat artwork, loot acquisition, canonical named items, class equip permissions, **durable player inventory**, or an equipped-gear save schema. The temporary seeded trial ledger below is a test boundary only. The separate equipment-training fixture below is an isolated numerical experiment, not final upgraded weapon balance. Only the basic weapon families are an established design lock. Alternate cosmetics and all armor/charm items are provisional. The chapter restore intentionally resets these nonpersistent preview choices rather than silently changing the save codec.

## Native QA

After Godot editor import:

```sh
godot --headless --path godot --script res://tests/battle_equipment_loadout_test.gd
godot --headless --path godot --script res://tests/battle_equipment_training_test.gd
godot --headless --path godot --script res://tests/battle_equipment_pressure_test.gd
godot --headless --path godot --script res://tests/battle_equipment_trial_inventory_test.gd
godot --headless --path godot --script res://tests/battle_equipment_inspector_test.gd
godot --headless --path godot --script res://tests/battle_equipment_socket_test.gd
godot --headless --path godot --script res://tests/battle_equipment_scene_test.gd
xvfb-run -a -s "-screen 0 960x640x24" godot --rendering-driver opengl3 --resolution 960x640 --path godot --script res://tests/capture_battle_equipment_review.gd
xvfb-run -a -s "-screen 0 960x640x24" godot --rendering-driver opengl3 --resolution 960x640 --path godot --script res://tests/capture_battle_equipment_cast_gallery.gd
```

The renderer records matched baseline, changed staff, changed armor/accessory, and strike-pose full-frame images and rejects unchanged native framebuffer pixels in the equipment region. A separate source-safe review gallery shows five starter identities and an A/B comparison of Reson's sword versus his secondary rifle (it does not authorize Reson combat turns). The pose is a deterministic review hold, **not** approved attack animation. Genuine images are runner-local unless separately recovered; test success alone does **not** mean accepted high-quality art or platform performance.

## Next implementation gates

1. Author creator-approved **real** inventory acquisition and job permissions. A temporary test-bag ownership and atomic-equip prototype now exists, but there are no loot drops, earned items, crafting, prices, or persistent player inventory.
2. Expand the isolated equipment-training and opt-in pressure fixtures into creator-reviewed item/stat balance, production-ready damage-type mitigation, legitimate owned inventory, and authorized jobs before integrating any effects into authored story encounters. The optional training fixture now proves bounded damage mitigation **in real practice VIT loss**, but story combat still treats review equipment as appearance-only. 
3. Bind these now-independent equipment nodes to creator-approved animated character models and authored per-direction hand-bone/socket metadata, across idle, attack, dodge, magic, sheathe and cutscene animation. The neutral mannequin is temporary. Avoid baking weapons into the character sprite, including Ender's already-painted directional staff art; author removable composite parts under art review.
4. Add legitimate per-character loadouts to a versioned durable save migration, then test corruption/rollback and parity.
5. Prove actual native animation/camera screenshots, accessibility, small-screen layout, frame timings, and creator approval separately.

**Authority:** existing Chapter I formula actions, party joins, hidden story information, accepted likeness, ongoing renderer/planetary drafts, and release holds remain untouched.

## 2026-10-27 socket composition increment (stacked draft)

- Implements detachable `ArmorAttachment`, `AccessoryAttachment`, `WeaponAttachment` and `GripHandAttachment` nodes under the existing native battle view; the staff retains center wrapping and both brass ferrules.
- Admitted Ender formula actions map **visual only** to deterministic poses: `staffStrike→strike`, `uncoverTruth→analyze`, `hold→guard`, `rest→rest`. Invalid/blocked actions cannot change pose; save restore and encounter closure return to idle. No new combat action grants or formulas.
- Renders a source-safe five-character martial-family gallery with separate sword→rifle A/B coverage for Reson. Art is provisional geometry only, and native render comparisons do not mean final silhouette or weapon ergonomics approval.
- Exact-head hosted regression and native frames must be checked before any PASS statement. Release remains HOLD.

## 2026-10-27 equipment formula training (further stacked draft)

**Experimental only:** the intentionally noncanonical Formula Review target now uses `battle_equipment_training_profile.gd`, an explicit hard-coded **QA fixture** with no save schema, price, skill-tree, inventory permissions or story economy. The stat model already exposes optional equipment fields; this slice adds a test-gated branch to pass limited fixture weapon power to the existing `jrpg_stat_model.gd` damage calculation. No magic requirement is associated with any weapon.

| Equipped item (provisional label) | Practice-only effect | Authored Wind Shear |
|---|---|---|
| Ender's original fighting staff | Baseline: +0 equipment power | Original production formula |
| Ender's silver-inlay staff look (study) | +4 equipment power in optional training; fixed-seed standard Staff Strike changes 6 → 9 damage | Look only; +0 power |
| Brass Guard chest overlay (study) | +8 projected physical defense | Look only; no reduction to Gale Force retaliation |
| Travel Charm overlay (study) | +6 projected aether defense | Look only; no reduction to Gale Force retaliation |

**Important:** the defensive figures were initially derived-stat projections. The subsequent pressure fixture below makes them cause real VIT mitigation only when explicitly enabled in optional practice. The default noncanonical Formula Review target **still has no retaliation**. These test-only damage-type assignments, incoming power, and balance numbers must not be treated as accepted armor design.

The live optional Formula Review battle now displays `PRACTICE STRIKE 6 > 9 | ARMOR +8 | WARD +6` after gear is equipped, reflecting deterministic noncritical, midpoint-variance math. Pressing **5/6/7** applies the sample gear instantly with no consumed turn. A successful `Staff Strike` in that encounter actually uses the equipped practice power. All other actions and turn authorization remain unchanged.

**Safety boundary:** `set_training_loadout` is rejected if the encounter is not active, is completed/defeated, or is not `formula_review`. Authored hazards call neither the gate nor the fixture; they reset actor stats and retain exact original `Gale Force` damage, maximum vitality and chapter progression. Changing equipped cosmetics in those battles affects *visuals only*. Resetting or restoring the chapter removes the transient training modifiers. An actor cannot equip another actor's item. This trial does **not** grant Reson a combat turn or require an element/magic affinity to use a weapon.

The test `godot/tests/battle_equipment_training_test.gd` verifies both numerical movement and unchanged canonical hazards, forbidden actions, baseline damage parity and reset isolation. The CI proof must pass on the exact PR head before this capability is reported as verified.

## 2026-10-27 optional physical/aether pressure study (further stacked draft)

The earlier armor/charm projection alone could not demonstrate whether protective equipment changes **what actually happens in battle**. The new reversible `battle_equipment_training_profile.gd.resolve_practice_hit()` uses the existing `jrpg_stat_model.gd.defense_multiplier()` and fixture-only 12-point incoming physical/aether hits. This only runs after the player actively toggles **8** in the optional `FORMULA REVIEW ENCOUNTER`; it is **OFF by default**, leaving all previously authorized combat and training behavior intact.

- **First accepted action:** practice dummy sends a physical pulse. Ender's baseline derived physical defense 5 yields 11 VIT damage; equipped provisional Brass Guard raises defense to 13, yielding **10 VIT damage**.
- **Second accepted action:** practice dummy sends an aether pulse. Ender's baseline derived aether defense 16 yields 10 VIT damage; equipped provisional Travel Charm raises it to 22, yielding **9 VIT damage**.
- Pulses alternate physical/aether, after **accepted** formula actions only, until practice completes, Ender is defeated or pressure is turned off. Failed actions and equipment toggles consume **no** turns or pressure hits. Equip/unequip during an active practice session updates the next incoming hit immediately.
- A native battle-HUD readout reports pressure mode, incoming damage type, actual damage and how much gear prevented. The accepted `staffStrike` action continues to use the opt-in weapon training formula independently; narrative Spirit affinity **never** grants a combat action.
- **Hard boundary:** `set_training_pressure()` rejects inactive/finished/defeated and all `authored_hazard` encounters. Story Wind Shear retains its *exact original* Gale Force VIT cost and party progression. No enemy definitions, canonical story contents, permanent item state or save schema were modified. Chapter restore resets mode and last hit.
- **QA evidence:** `battle_equipment_pressure_test.gd` verifies 11→10 physical, 10→9 aether, actual VIT loss, accepted action/turn counts, foreign/malformed cap rejection, gear removal, mode OFF parity, and authored-story isolation. The native framebuffer suite captures an extra `armor-pressure-native-960x640.png` review frame and compares changed UI pixels.
- **Not production:** these 12-point pressure hits, armor coefficients and alternating pattern are deliberate reproducible study fixtures. They do not define a canonical enemy attack, damage affinity, armor item rarity, job/class restriction, or final defensive balance. Release and art acceptance remain held.

**Next:** design and approve a physical/aether typed attack-resistance contract for authored enemies, then bind properly acquired gear to production encounters and durable saves in separate independently reviewed steps. Do not silently reclassify the story's existing elemental or Spirit energies as automatically learned magic.

## 2026-10-27 bounded trial-inventory ownership study (further stacked draft)

The prior practice equipment system checked **actor and slot**, but any known Ender item could be equipped without evidence that the party held it. `battle_equipment_trial_inventory.gd` closes that specific review gap with an **ephemeral, noncanonical** one-of-each ownership model:

| Review item | Worn at initial review state | Quantity in trial bag |
|---|---|---:|
| Ender's full-length fighting staff | Main hand | 0 |
| Silver-inlay fighting staff (study) | No | 1 |
| Brass Guard chest study | No | 1 |
| Travel Charm study | No | 1 |

The exact four-item budget never changes: equipping a trial item debits the bag, returning a currently worn item credits the bag, and rejected transactions mutate **neither** equipment, bag, held-weapon state nor visual revision. The demo input controls remain **5/6/7** (weapon/armor/charm), with **8** toggling opt-in counterpressure. The lower-right HUD shows `TRIAL BAG STAFF x ARMOR y CHARM z` to give the player immediate feedback that an actual item has moved. The real native screenshot harness checks the bounded bag region's pixels before and after ownership-checked swaps.

Ownership checks reject unknown items, cross-character weapons, wrong slots, attempted removal of Ender's basic fighting identity, spending a zero-count item, duplication, tampered bag totals and tampered equipped actors. The trial inventory uses copies for inspection. The existing visual, stat-training and armor-pressure fixtures remain independent: after a legal equip, practice staff power and physical/aether mitigation update on the next appropriate action; inventory transactions do not consume a turn, trigger pressure, create Reson party turns, or unlock plot magic. Story Wind Shear still treats these items as cosmetic previews.

**Not production:** The trial bag is pre-seeded for **QA only** and must never be represented as a canon discovery, treasure drop, owned story item, monetizable economy or approved equipment rarity. Chapter I's existing save format does not contain this ledger; successful restore returns the main staff and all three trial studies to the initial state. The suite `battle_equipment_trial_inventory_test.gd` exercises conservation, atomic rejection, wrong-actor denial, forged state, actual scene gear/mitigation, and reset/save isolation.

**Next separate authorization gates:** native player-facing acquisition and item inspection UX, balanced armor types, per-character and job permissions, five-cast animations using approved artwork, durable inventory save migration, then explicit creator review of any canon item names or equipment progression. No draft is merged by this work.

## 2026-10-27 inspect-before-equip UI (further stacked draft)

The previous Chapter I battle HUD displayed current trial-bag quantities but did not let a player **read an item's description or compare its effects before equipping**. This new native, reversible inspection layer addresses that limited UX gap.

- **9** (controller left shoulder) opens the inspector during the optional noncanonical Formula Review. **Up/Down** (D-pad) selects weapon/armor/accessory; **Left/Right** previews only currently equipped or actually owned items; **Enter** (controller A) confirms a valid ownership-conserving transaction; **Escape** (controller B) or **9** closes it. Existing **5/6/7** quick swaps and **8** opt-in pressure remain usable after closing.
- The inspector presents **current versus selected** ordinary Staff Strike damage, physical/aether defense, and sample incoming damage. Example comparisons under fixed noncritical practice inputs: silver-inlay staff **6 → 9** outbound damage; brass guard physical defense **5 → 13** and practice physical hit **11 → 10**; trial charm aether defense **16 → 22** and practice aether hit **10 → 9**. Prose makes clear these are *practice* stats, not canonical item balancing or story energies.
- `battle_equipment_inspector.gd` generates an independent simulated loadout and bag to calculate comparisons via the already-tested training profile. **Preview does not modify** real inventory counts, visual revision, combat target HP, turns, current VIT, or equipment. The live scene commits via `trial_inventory.transfer` only on explicit confirmation.
- `battle_equipment_inspector_panel.gd` is a real Godot-rendered high-contrast overlay above the battle rig. A modal focus gate consumes all battle/movement/save input events while it is open. No formula turn or enemy retaliation can execute through the scene action boundary until the overlay closes. Story Wind Shear disallows opening the inspector, leaving unchanged cosmetic options and original Gale Force.
- Existing input-map entries/remaps are preserved. Native tests cover wrong-actor/forged inventory, owned-only choices, nonmutating forward/reverse comparisons, real equipment confirmation, modal turn denial, return to pressure mitigation, and save-restore closure. Screenshot CI captures **three additional actual 960×640 Godot framebuffers**: current item → uncommitted candidate → confirmed ownership swap, with pixel assertions and hashes.

**Scope limits:** Descriptions are editorially neutral temporary study copy, **not** item lore approval; the panel is not the production equipment menu, has no acquisition pathway, audio narration, screen-reader semantics, character-artist accepted sprites, permanent saves, rarity balancing or class-based permission editor. Those are separate design and engineering gates. Story plot energies remain independent of magic job selection. No merges or releases.

## P-02 test: equipment session survives a real scene replacement (further draft)

The [five-cast temporary session authority](EQUIPMENT_SESSION_AUTHORITY_REVIEW.md) explicitly addresses a P-01 limitation: the old practice gear was conserved only within one mounted scene. The P-02 coordinator retains the same owned Ender gear and trial bag **by object identity** after the first study scene is freed and a new Godot study scene is instantiated. Lyra, Ionia, Reson and Aepex have fixed starter-family loadout records only, without new loot, magic or battle turns. Target scene and all actor/ownership validation happen before any rebind. Chapter I save schema remains unchanged and intentionally resets transient gear. This is an in-memory P-02 test, not permanent production inventory or a canonical equipment station; check exact new CI before asserting PASS.

## 2026-10-27 P-01 end-to-end noncanonical field-to-battle equipment lifecycle

**Draft implementation only; no production promotion.** The new isolated `res://scenes/equipment_lifecycle_study.tscn` sets `equipment_station_review_enabled=true` on the existing Chapter I review engine. That flag defaults **false** in both existing Chapter I scenes and is **not a canonical ship room, field location, item find, quest step or party join**. It draws a source-safe `GEAR STUDY` marker at a temporary test coordinate near Ender and a **detachable equipment review mannequin**; this is not a replacement for the approved field sprite or its painted staff.

**Manual native Godot 4.7.2 test:** Run Current Scene on `res://scenes/equipment_lifecycle_study.tscn`. Walk Ender with arrow keys to the `GEAR STUDY` marker, press **E** to open the owned-item inspector (9 also opens only in optional formula battle); navigate with Up/Down, Left/Right, Enter to equip and Escape to close. The field gear mannequin uses the same validated loadout appearance as the battle equipment rig. Press **C** to enter noncanonical formula practice; equipped training staff and guard/charm modify the already bounded practice math. Close with **C**, return to the study marker and inspect again. State and bag quantities are conserved across this field→battle→field session. Existing Chapter I saves explicitly **do not** persist any test item; restore resets study equipment, bag and field mannequin together.

**Exact gate and genuine evidence:**

```sh
godot --headless --path godot --editor --quit
godot --headless --path godot --script res://tests/equipment_lifecycle_study_test.gd
xvfb-run -a -s "-screen 0 960x640x24" godot --rendering-driver opengl3 --resolution 960x640 --path godot --script res://tests/capture_equipment_lifecycle_study.gd
```

- `equipment_lifecycle_study_test.gd`: real scene input E near station, denial outside radius, field modal previews that cannot change ownership or allow battle turns, 6→9 provisional outbound strike, 10/9 physical/aether practice mitigation, no item duplication, blocked narrative ability, exact field/battle appearance ID parity, post-battle inventory/gear survival, authentic unchanged story stage, and legacy-format save restoration.
- `capture_equipment_lifecycle_study.gd`: six **real native** 960×640 local PNGs, with A/B changed pixels during preview/confirm and field weapon before/after; field return must render the same gear rig as before battle. Captures and hashes are review evidence, not creator acceptance; actual PNG distribution remains subject to runner artifact quota.
- Hosted exact-head Godot native, native GL, legacy smoke, and protected Windows security must be checked separately before marking PASS. A successful scene contract is **not** equivalent to player-led cold playtesting.

**Promotion source-of-truth:** [standalone documentation-only draft #498](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/pull/498) contains [P0–P5 architecture, QA and documentation gates](https://github.com/ndrorchestration/ToSailtheStarrySky-jrpg/blob/docs/equipment-promotion-handoff-20261027/docs/design/EQUIPMENT_PROTOTYPE_TO_PRODUCTION_PIPELINE_2026-10-27.md). At P-01 the field icon is a test rig, the station location is not canon, and the engine still lacks a production persistent inventory, multi-character equipment actor art, confirmed job permissions, true production damage-type balance, and a Windows release. Any merge, lore, art admission or public deployment remains HOLD.
