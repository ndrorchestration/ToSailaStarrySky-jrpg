# Native battle equipment visual slice — review only

**Source line:** stacked on Chapter I / party-combat-authority draft PR #347, not merged into `main` or the independent planetary/flight draft branches. **Engine target:** Godot 4.7.2 Standard + GDScript.

## Player-facing review

In the native Chapter I scene, enter the formula review with **C** or reach the authored Wind Shear battle. During combat:

- **5** cycles the equipped Ender fighting-staff **appearance** (default brass-ferruled staff versus a silver-inlay style study).
- **6** adds/removes a provisional chest-guard **armor overlay**.
- **7** adds/removes a provisional **charm overlay**.

All changes update the equipment held by the procedural battle-pose dummy immediately, without closing combat or consuming a turn. The staff always remains a full-length, physical fighting staff. No magic casting prerequisite is imposed.

`battle_equipment_loadout.gd` keeps stable item IDs and actor/slot restrictions; `battle_equipment_visual.gd` draws the exact equipped family and slot overlays. Starter families are Ender/staff, Lyra/chakram, Ionia/mace, Reson/sword + secondary rifle, Aepex/martial arts, taken from the earlier equipment-system working-authority draft (#227), not inferred from elemental affinities. A `hold_weapon_slot("secondaryWeapon")` call changes Reson's representation from sword to rifle, but Reson **does not acquire a combat turn** in the existing Ender-only Chapter I encounter.

This is a **visual engineering prototype**, not approved party combat artwork, loot acquisition, upgraded weapon stats, canonical named items, class equip permissions, durable inventory, or an equipped-gear save schema. Only the basic weapon families are an established design lock. Alternate cosmetics and all armor/charm items are provisional. The chapter restore intentionally resets these nonpersistent preview choices rather than silently changing the save codec.

## Native QA

After Godot editor import:

```sh
godot --headless --path godot --script res://tests/battle_equipment_loadout_test.gd
godot --headless --path godot --script res://tests/battle_equipment_scene_test.gd
xvfb-run -a -s "-screen 0 960x640x24" godot --rendering-driver opengl3 --resolution 960x640 --path godot --script res://tests/capture_battle_equipment_review.gd
```

The renderer records matched baseline, changed staff, and changed armor/accessory full-frame images and rejects unchanged native framebuffer pixels in the equipment region. Genuine images are runner-local unless separately recovered; test success alone does **not** mean accepted high-quality art or platform performance.

## Next implementation gates

1. Establish creator-approved inventory acquisition and equipment modification flow, with transaction validation and selected job permissions.
2. Port the item-stat/effect mapping into the existing production combat formula, with before/after damage and defense tests. Until then, equipment studies change **appearance only**.
3. Bind independently layered wielded assets to the five accepted character models, across idle, attack, dodge, magic, sheathe and cutscene animation. Avoid baking weapons into the character sprite, including Ender's already-painted directional staff art; author removable composite parts under art review.
4. Add legitimate per-character loadouts to a versioned durable save migration, then test corruption/rollback and parity.
5. Prove actual native animation/camera screenshots, accessibility, small-screen layout, frame timings, and creator approval separately.

**Authority:** existing Chapter I formula actions, party joins, hidden story information, accepted likeness, ongoing renderer/planetary drafts, and release holds remain untouched.
