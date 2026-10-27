# Native battle equipment visual slice — review only

**Source line:** stacked on Chapter I / party-combat-authority draft PR #347, not merged into `main` or the independent planetary/flight draft branches. **Engine target:** Godot 4.7.2 Standard + GDScript.

## Player-facing review

In the native Chapter I scene, enter the formula review with **C** or reach the authored Wind Shear battle. During combat:

- **5** cycles the equipped Ender fighting-staff **appearance** (default brass-ferruled staff versus a silver-inlay style study).
- **6** adds/removes a provisional chest-guard **armor overlay**.
- **7** adds/removes a provisional **charm overlay**.

All changes update a **socketed** battle-actor review rig immediately, without closing combat or consuming a turn. The arm and hand socket follow the current combat pose. This remains a neutral stand-in silhouette, not approved character art. The staff always remains a full-length, physical fighting staff. No magic casting prerequisite is imposed.

`battle_equipment_loadout.gd` keeps stable item IDs and actor/slot restrictions; `battle_equipment_visual.gd` now assembles separate `battle_equipment_attachment.gd` CanvasItem children for armor, accessory, currently held weapon and overlaid grip hand. The weapon and hand share a moving combat-pose socket; the body is a removable placeholder, and equip transactions leave attack/guard/analyze/rest poses intact. Starter families are Ender/staff, Lyra/chakram, Ionia/mace, Reson/sword + secondary rifle, Aepex/martial arts, taken from the earlier equipment-system working-authority draft (#227), not inferred from elemental affinities. A `hold_weapon_slot("secondaryWeapon")` call changes Reson's representation from sword to rifle, but Reson **does not acquire a combat turn** in the existing Ender-only Chapter I encounter.

This is a **review prototype**, not approved party combat artwork, loot acquisition, canonical named items, class equip permissions, durable inventory, or an equipped-gear save schema. The separate equipment-training fixture below is an isolated numerical experiment, not final upgraded weapon balance. Only the basic weapon families are an established design lock. Alternate cosmetics and all armor/charm items are provisional. The chapter restore intentionally resets these nonpersistent preview choices rather than silently changing the save codec.

## Native QA

After Godot editor import:

```sh
godot --headless --path godot --script res://tests/battle_equipment_loadout_test.gd
godot --headless --path godot --script res://tests/battle_equipment_training_test.gd
godot --headless --path godot --script res://tests/battle_equipment_socket_test.gd
godot --headless --path godot --script res://tests/battle_equipment_scene_test.gd
xvfb-run -a -s "-screen 0 960x640x24" godot --rendering-driver opengl3 --resolution 960x640 --path godot --script res://tests/capture_battle_equipment_review.gd
xvfb-run -a -s "-screen 0 960x640x24" godot --rendering-driver opengl3 --resolution 960x640 --path godot --script res://tests/capture_battle_equipment_cast_gallery.gd
```

The renderer records matched baseline, changed staff, changed armor/accessory, and strike-pose full-frame images and rejects unchanged native framebuffer pixels in the equipment region. A separate source-safe review gallery shows five starter identities and an A/B comparison of Reson's sword versus his secondary rifle (it does not authorize Reson combat turns). The pose is a deterministic review hold, **not** approved attack animation. Genuine images are runner-local unless separately recovered; test success alone does **not** mean accepted high-quality art or platform performance.

## Next implementation gates

1. Establish creator-approved inventory acquisition and equipment modification flow, with transaction validation and selected job permissions.
2. Expand the isolated equipment-training fixture into creator-reviewed item/stat balance, verified physical and aether damage/mitigation, legitimate owned inventory, and authorized jobs before integrating effects into authored story encounters. The current optional training fixture proves an equipment bonus through the existing damage model; **story combat still treats review equipment as appearance-only**.
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

**Important:** the defensive figures are derived-stat **projections**, not damage mitigation in a playable enemy turn. The noncanonical Formula Review target has no retaliation. Before authoring any armor protection, damage types, armor breakage or enemy defense behavior, design, tune and obtain approval.

The live optional Formula Review battle now displays `PRACTICE STRIKE 6 > 9 | ARMOR +8 | WARD +6` after gear is equipped, reflecting deterministic noncritical, midpoint-variance math. Pressing **5/6/7** applies the sample gear instantly with no consumed turn. A successful `Staff Strike` in that encounter actually uses the equipped practice power. All other actions and turn authorization remain unchanged.

**Safety boundary:** `set_training_loadout` is rejected if the encounter is not active, is completed/defeated, or is not `formula_review`. Authored hazards call neither the gate nor the fixture; they reset actor stats and retain exact original `Gale Force` damage, maximum vitality and chapter progression. Changing equipped cosmetics in those battles affects *visuals only*. Resetting or restoring the chapter removes the transient training modifiers. An actor cannot equip another actor's item. This trial does **not** grant Reson a combat turn or require an element/magic affinity to use a weapon.

The test `godot/tests/battle_equipment_training_test.gd` verifies both numerical movement and unchanged canonical hazards, forbidden actions, baseline damage parity and reset isolation. The CI proof must pass on the exact PR head before this capability is reported as verified.
