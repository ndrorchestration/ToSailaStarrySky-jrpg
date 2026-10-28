extends SceneTree
## Read-only comparisons are computed on cloned gear, and only deliberate
## confirmation may move one owned item. The modal owns input focus, not
## combat turns, plot magic, persistent inventory, or story equip privileges.

const Loadout = preload("res://scripts/battle_equipment_loadout.gd")
const TrialInventory = preload("res://scripts/battle_equipment_trial_inventory.gd")
const Inspector = preload("res://scripts/battle_equipment_inspector.gd")
const Scene = preload("res://scenes/first_wake_chapter1_player_preview.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _rng() -> float:
    return 0.5

func _fail(why: String) -> void:
    push_error("AETHERWAKE_GEAR_INSPECTOR_FAIL: " + why)
    quit(1)

func _verify() -> void:
    var loadout = Loadout.new("ender")
    var inventory = TrialInventory.new()
    var inspector = Inspector.new()
    var stats := {"might":3, "grace":4, "wits":8, "spirit":12, "presence":4}
    if not inspector.reset(loadout, inventory):
        _fail("inspector rejected valid starting owner and bag")
        return
    var original: Dictionary = inspector.describe(loadout, inventory, stats)
    if original.is_empty() or original.get("status", "") != "practice-inspect-no-canon":
        _fail("read-only item details missing practice authority disclaimer")
        return
    if original["slot"] != "mainWeapon" or original["itemId"] != "ender-starter-staff":
        _fail("starting weapon/slot not selected")
        return
    if int(original["beforeStrike"]) != 6 or int(original["afterStrike"]) != 6:
        _fail("initial staff comparison changed combat stats")
        return

    var untouched_bag: Dictionary = inventory.snapshot()
    var untouched_slots: Dictionary = loadout.slots.duplicate(true)
    var untouched_revision: int = int(loadout.visual_revision)
    if not inspector.move_choice(1, loadout, inventory):
        _fail("alternate staff could not be previewed")
        return
    var inlay: Dictionary = inspector.describe(loadout, inventory, stats)
    if str(inlay.get("itemId", "")) != "ender-staff-inlay-review" or int(inlay["ownedInBag"]) != 1:
        _fail("preview not restricted to owned silver-inlay staff")
        return
    if int(inlay["beforeStrike"]) != 6 or int(inlay["afterStrike"]) != 9:
        _fail("staff damage comparison should be 6 to 9")
        return
    if loadout.slots != untouched_slots or inventory.snapshot() != untouched_bag or loadout.visual_revision != untouched_revision:
        _fail("preview changed inventory/loadout before confirmation")
        return
    if not inspector.commit(loadout, inventory):
        _fail("confirmed owned silver-inlay staff did not equip")
        return
    if loadout.item_id_for("mainWeapon") != "ender-staff-inlay-review" or inventory.count_in_bag("ender-starter-staff") != 1:
        _fail("confirmed swap failed to return starter staff")
        return
    var after_confirm: Dictionary = inspector.describe(loadout, inventory, stats)
    if not bool(after_confirm.get("alreadyEquipped", false)) or int(after_confirm["afterStrike"]) != 9:
        _fail("comparison didn't re-anchor to newly equipped trial staff")
        return

    if not inspector.move_slot(1, loadout, inventory) or inspector.current_slot() != "bodyArmor":
        _fail("could not navigate to chest guard")
        return
    if not inspector.move_choice(1, loadout, inventory):
        _fail("could not preview owned practice chest guard")
        return
    var chest: Dictionary = inspector.describe(loadout, inventory, stats)
    if int(chest["beforePhysicalDefense"]) != 5 or int(chest["afterPhysicalDefense"]) != 13:
        _fail("armor defense comparison mismatch")
        return
    if int(chest["beforePhysicalHit"]) != 11 or int(chest["afterPhysicalHit"]) != 10:
        _fail("armor protection comparison mismatch")
        return
    if not inspector.commit(loadout, inventory):
        _fail("could not confirm owned armor")
        return
    if not inspector.move_slot(1, loadout, inventory) or inspector.current_slot() != "accessory":
        _fail("could not navigate to accessory")
        return
    if not inspector.move_choice(1, loadout, inventory):
        _fail("could not preview owned practice charm")
        return
    var charm: Dictionary = inspector.describe(loadout, inventory, stats)
    if int(charm["beforeAetherDefense"]) != 16 or int(charm["afterAetherDefense"]) != 22:
        _fail("charm defense comparison mismatch")
        return
    if int(charm["beforeAetherHit"]) != 10 or int(charm["afterAetherHit"]) != 9:
        _fail("charm protection comparison mismatch")
        return
    if not inspector.commit(loadout, inventory) or not inventory.validate(loadout):
        _fail("valid final practice loadout not conserved")
        return
    var actual_bag: Dictionary = inventory.snapshot()
    if inventory.count_in_bag("ender-armor-overlay-review") != 0 or inventory.count_in_bag("ender-charm-review") != 0:
        _fail("preview commit failed to debit worn trial items")
        return
    if not inspector.reset(loadout, inventory) or not inspector.move_choice(1, loadout, inventory):
        _fail("could not inspect bagged starter staff after swap")
        return
    var back: Dictionary = inspector.describe(loadout, inventory, stats)
    if int(back.get("beforeStrike", 0)) != 9 or int(back.get("afterStrike", 0)) != 6:
        _fail("reverse staff comparison was not symmetric")
        return
    if inventory.snapshot() != actual_bag:
        _fail("reverse-preview mutated bag")
        return

    inventory.bag["ender-starter-staff"] = 10
    if inspector.describe(loadout, inventory, stats) != {} or inspector.commit(loadout, inventory):
        _fail("forged bag accepted as inspectable or equippable")
        return
    if inspector.reset(Loadout.new("reson"), TrialInventory.new()):
        _fail("unapproved actor received Ender equipment inspector")
        return

    var world = Scene.instantiate()
    root.add_child(world)
    await process_frame
    world.formula_encounter.rng_source = Callable(self, "_rng")
    if world.open_gear_inspector():
        _fail("inspector accessible outside active formula review")
        return
    if not world.start_formula_review() or not world.open_gear_inspector():
        _fail("inspector modal did not open during formula review")
        return
    if not world.gear_inspector_open or not world.gear_inspector_panel.visible:
        _fail("review didn't actually mount visible inspector overlay")
        return
    var initial_turns: int = world.formula_encounter.turns
    var initial_target_hp: int = world.formula_encounter.target["hp"]
    var initial_vit: int = world.formula_encounter.player["vit"]
    var world_bag: Dictionary = world.trial_inventory.snapshot()
    var world_visual: String = world.battle_equipment_view.visual_key()
    if not world.move_gear_inspector_item(1):
        _fail("live scene couldn't inspect owned alternate staff")
        return
    var current_preview: Dictionary = world.gear_inspector_panel.inspection
    if int(current_preview.get("beforeStrike", 0)) != 6 or int(current_preview.get("afterStrike", 0)) != 9:
        _fail("live inspector preview did not render 6->9 stat comparison")
        return
    if world.trial_inventory.snapshot() != world_bag or world.battle_equipment_view.visual_key() != world_visual:
        _fail("live preview equipped gear before confirmation")
        return
    if world.take_formula_review_action("staffStrike") or world.formula_encounter.turns != initial_turns:
        _fail("modal allowed a combat turn while player was inspecting")
        return
    if world.formula_encounter.target["hp"] != initial_target_hp or world.formula_encounter.player["vit"] != initial_vit:
        _fail("inspecting items changed target or player VIT")
        return
    if not world.confirm_gear_inspector_item():
        _fail("live selected staff confirmation rejected")
        return
    if world.battle_equipment_view.visual_key() == world_visual or world.trial_inventory.count_in_bag("ender-staff-inlay-review") != 0:
        _fail("live confirmed equip failed to change weapon and owned bag")
        return
    if not world.move_gear_inspector_slot(1) or not world.move_gear_inspector_item(1) or not world.confirm_gear_inspector_item():
        _fail("live inspector failed to equip armor")
        return
    if not world.move_gear_inspector_slot(1) or not world.move_gear_inspector_item(1) or not world.confirm_gear_inspector_item():
        _fail("live inspector failed to equip charm")
        return
    if not world.trial_inventory.validate(world.battle_loadout):
        _fail("live inspector violated conservation ledger")
        return
    if world.formula_encounter.turns != initial_turns or world.formula_encounter.enemy_turns != 0:
        _fail("equipping through modal consumed turn or enabled pressure")
        return
    world.close_gear_inspector()
    if world.gear_inspector_open or world.gear_inspector_panel.visible:
        _fail("inspector remained on screen after close")
        return
    if not world.toggle_training_pressure_review() or not world.take_formula_review_action("hold"):
        _fail("valid practice could not resume after inspection")
        return
    if int(world.formula_encounter.last_training_hit.get("damage", 0)) != 10:
        _fail("armor selected through inspector didn't affect live pressure")
        return
    if not world.take_formula_review_action("hold") or int(world.formula_encounter.last_training_hit.get("damage", 0)) != 9:
        _fail("charm selected through inspector didn't affect live aether pressure")
        return
    if not world.open_gear_inspector():
        _fail("cannot reopen inventory during active training")
        return
    var saved: Dictionary = world.export_save_snapshot()
    if saved.has("equipment") or saved.has("trialInventory"):
        _fail("preview inspector leaked into chapter save schema")
        return
    if not world.restore_save_snapshot(saved):
        _fail("Chapter I restore rejected normal save")
        return
    if world.gear_inspector_open or world.gear_inspector_panel.visible or not world.trial_inventory.validate(world.battle_loadout):
        _fail("save restore failed to clear inspector and reset trial equipment")
        return
    if world.formula_encounter.active or world.battle_loadout.item_id_for("mainWeapon") != "ender-starter-staff":
        _fail("old save now includes provisional equipment state")
        return
    if world.open_gear_inspector():
        _fail("restored scene allowed inspection outside battle")
        return
    world.queue_free()
    print("AETHERWAKE_GEAR_INSPECTOR_PASS: nonmutating gear comparisons, protected modal focus, owned confirmation, pressure mitigation and save reset")
    quit(0)
