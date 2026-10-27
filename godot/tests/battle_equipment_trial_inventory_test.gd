extends SceneTree
## Exact Godot review of ownership, conservation, zero-turn equips and
## practice-only combat. This is NOT a permanent party inventory or loot drop.

const Loadout = preload("res://scripts/battle_equipment_loadout.gd")
const TrialInventory = preload("res://scripts/battle_equipment_trial_inventory.gd")
const Scene = preload("res://scenes/first_wake_chapter1_player_preview.tscn")
const Encounter = preload("res://scripts/first_wake_formula_encounter.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _rng() -> float:
    return 0.5

func _fail(message: String) -> void:
    push_error("AETHERWAKE_TRIAL_INVENTORY_FAIL: " + message)
    quit(1)

func _verify() -> void:
    var ender = Loadout.new("ender")
    var trial = TrialInventory.new()
    if not trial.validate(ender):
        _fail("seed inventory and starter equipped staff do not conserve ownership")
        return
    if trial.count_in_bag("ender-starter-staff") != 0 or trial.count_in_bag("ender-staff-inlay-review") != 1:
        _fail("wrong starting staff ownership")
        return
    if trial.count_in_bag("ender-armor-overlay-review") != 1 or trial.count_in_bag("ender-charm-review") != 1:
        _fail("armor/charm trial items not owned")
        return

    var before_slots: Dictionary = ender.slots.duplicate(true)
    var before_revision: int = int(ender.visual_revision)
    var before_bag: Dictionary = trial.snapshot()["bag"]
    for invalid in [
        ["mainWeapon", ""],
        ["mainWeapon", "reson-starter-sword"],
        ["mainWeapon", "missing-item"],
        ["secondaryWeapon", "reson-starter-rifle"],
        ["bodyArmor", "ender-staff-inlay-review"],
        ["accessory", "ender-armor-overlay-review"],
        ["invalidSlot", "ender-charm-review"],
    ]:
        if trial.transfer(ender, str(invalid[0]), str(invalid[1])):
            _fail("unowned or wrong-slot equip admitted: " + str(invalid))
            return
    if ender.slots != before_slots or ender.visual_revision != before_revision or trial.snapshot()["bag"] != before_bag:
        _fail("rejected gear transaction changed loadout/bag/visual revision")
        return

    var leaked_snapshot: Dictionary = trial.snapshot()
    var copied_bag: Dictionary = leaked_snapshot["bag"]
    copied_bag["ender-staff-inlay-review"] = 900
    if not trial.validate(ender) or trial.count_in_bag("ender-staff-inlay-review") != 1:
        _fail("inventory snapshot leaked writable references")
        return

    if not trial.transfer(ender, "mainWeapon", "ender-staff-inlay-review"):
        _fail("owned alternate staff could not be equipped")
        return
    if trial.count_in_bag("ender-starter-staff") != 1 or trial.count_in_bag("ender-staff-inlay-review") != 0:
        _fail("weapon swap did not return the old staff to the bag")
        return
    if not trial.validate(ender) or str(ender.appearance().get("weaponVisual", "")) != "staff-silver-inlay":
        _fail("weapon swap invalid or equipped visual mismatched")
        return
    var revision_after: int = int(trial.revision)
    if not trial.transfer(ender, "mainWeapon", "ender-staff-inlay-review") or trial.revision != revision_after:
        _fail("equipping already-held item should be an idempotent no-op")
        return
    if trial.transfer(ender, "bodyArmor", "ender-staff-inlay-review"):
        _fail("one already-equipped staff was double-spent into armor")
        return

    if not trial.cycle_ender_review(ender, "mainWeapon"):
        _fail("can't switch original staff back from bag")
        return
    if ender.item_id_for("mainWeapon") != "ender-starter-staff" or trial.count_in_bag("ender-staff-inlay-review") != 1:
        _fail("weapon switching back did not restore bag count")
        return

    if not trial.transfer(ender, "bodyArmor", "ender-armor-overlay-review"):
        _fail("can't equip owned review armor")
        return
    if not trial.transfer(ender, "accessory", "ender-charm-review"):
        _fail("can't equip owned review charm")
        return
    if not trial.validate(ender) or trial.count_in_bag("ender-armor-overlay-review") != 0 or trial.count_in_bag("ender-charm-review") != 0:
        _fail("newly worn items are duplicated in inventory")
        return
    if not trial.transfer(ender, "bodyArmor", "") or not trial.transfer(ender, "accessory", ""):
        _fail("can't unequip optional armor/charm")
        return
    if trial.count_in_bag("ender-armor-overlay-review") != 1 or trial.count_in_bag("ender-charm-review") != 1:
        _fail("optional unequip did not return items")
        return

    # Reject inventory forgery AND direct rogue mutation of the equipped
    # model before the next transaction. No attempt should mint duplicates.
    trial.bag["ender-charm-review"] = 2
    if trial.validate(ender) or trial.transfer(ender, "accessory", "ender-charm-review"):
        _fail("excess unearned charm count admitted")
        return
    trial.bag["ender-charm-review"] = 1
    if not trial.validate(ender):
        _fail("ledger did not recover after restoring its valid bag")
        return
    ender.slots["mainWeapon"] = "reson-starter-sword"
    if trial.validate(ender) or trial.transfer(ender, "bodyArmor", "ender-armor-overlay-review"):
        _fail("cross-actor equipped item bypassed ledger")
        return
    ender.reset_to_starter()
    trial.reset()
    if not trial.validate(ender):
        _fail("explicit trial reset did not restore owned starter contract")
        return
    if trial.validate(Loadout.new("reson")) or trial.transfer(Loadout.new("reson"), "mainWeapon", "reson-starter-sword"):
        _fail("Reson has unauthorized Ender training inventory authority")
        return

    var world = Scene.instantiate()
    root.add_child(world)
    await process_frame
    world.formula_encounter.rng_source = Callable(self, "_rng")
    if not world.trial_inventory.validate(world.battle_loadout) or not world.start_formula_review():
        _fail("real Chapter I battle cannot start with owned trial stock")
        return
    var initial_turns: int = int(world.formula_encounter.turns)
    var original_weapon_key: String = world.battle_equipment_view.visual_key()
    if not world.equip_review_item("mainWeapon", "ender-staff-inlay-review"):
        _fail("real battle can't equip owned staff inlay")
        return
    if world.battle_equipment_view.visual_key() == original_weapon_key:
        _fail("owned equip did not update in-battle character weapon pixels contract")
        return
    if not world.equip_review_item("bodyArmor", "ender-armor-overlay-review") or not world.equip_review_item("accessory", "ender-charm-review"):
        _fail("real battle can't equip owned armor and charm")
        return
    if world.formula_encounter.turns != initial_turns or world.formula_encounter.enemy_turns != 0:
        _fail("trial inventory consumed battle turn / triggered enemy attack")
        return
    var battle_bag: Dictionary = world.trial_inventory.snapshot()["bag"]
    if int(battle_bag["ender-staff-inlay-review"]) != 0 or int(battle_bag["ender-armor-overlay-review"]) != 0 or int(battle_bag["ender-charm-review"]) != 0:
        _fail("real battle didn't debit owned bag quantities")
        return
    if world.equip_review_item("mainWeapon", "reson-starter-sword") or world.equip_review_item("accessory", "ender-staff-inlay-review"):
        _fail("real scene accepted unowned or mismatched trial item")
        return
    if not world.trial_inventory.validate(world.battle_loadout) or world.trial_inventory.snapshot()["bag"] != battle_bag:
        _fail("rejected scene equip changed bag state")
        return
    if not world.toggle_training_pressure_review():
        _fail("practice pressure not available with owned armor")
        return
    var start_vit: int = int(world.formula_encounter.player["vit"])
    if not world.take_formula_review_action("hold") or int(world.formula_encounter.player["vit"]) != start_vit - 10:
        _fail("owned armor didn't actually reduce physical practice VIT loss")
        return
    if not world.take_formula_review_action("hold") or int(world.formula_encounter.player["vit"]) != start_vit - 19:
        _fail("owned charm didn't actually reduce aether practice VIT loss")
        return
    if not world.equip_review_item("bodyArmor", "") or not world.equip_review_item("accessory", ""):
        _fail("could not remove owned armor/charm after pressure hits")
        return
    if not world.take_formula_review_action("hold") or int(world.formula_encounter.last_training_hit.get("damage", 0)) != 11:
        _fail("removing trial armor didn't change next actual VIT hit")
        return
    if not world.take_formula_review_action("hold") or int(world.formula_encounter.last_training_hit.get("damage", 0)) != 10:
        _fail("removing trial charm didn't change next actual aether hit")
        return
    if world.take_formula_review_action("sharedDream"):
        _fail("ownership changes granted blocked narrative combat magic")
        return

    var existing_save: Dictionary = world.export_save_snapshot()
    if existing_save.has("trialInventory") or existing_save.has("equipment"):
        _fail("review-owned gear escaped into official save schema")
        return
    if not world.restore_save_snapshot(existing_save):
        _fail("original chapter save no longer restores")
        return
    if not world.trial_inventory.validate(world.battle_loadout):
        _fail("save restore didn't reset inventory and worn items atomically")
        return
    if world.trial_inventory.count_in_bag("ender-staff-inlay-review") != 1:
        _fail("trial bag after restore missing original staff inlay")
        return
    if world.battle_loadout.item_id_for("mainWeapon") != "ender-starter-staff" or world.formula_encounter.active:
        _fail("save restore didn't close temporary battle and reset staff")
        return
    world.queue_free()
    print("AETHERWAKE_TRIAL_INVENTORY_PASS: conserved owned practice items, atomic swap, live 11->10/10->9 armor effects, reject forgery, transient save boundary")
    quit(0)
