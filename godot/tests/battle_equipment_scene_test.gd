extends SceneTree
## Scene-level smoke. Checks that an equip changes the actual drawing node's
## model inputs without granting a new action or changing encounter outcomes.

const REVIEW_SCENE = preload("res://scenes/first_wake_chapter1_player_preview.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world = REVIEW_SCENE.instantiate()
    root.add_child(world)
    await process_frame
    if world.battle_equipment_view == null or world.battle_equipment_view.visible:
        _fail("battle equipment view missing or leaking outside battle")
        return
    if not world.start_formula_review():
        _fail("formula battle did not start")
        return
    if not world.battle_equipment_view.visible:
        _fail("equipped model not shown during combat")
        return
    var key_before: String = world.battle_equipment_view.visual_key()
    var turns_before: int = int(world.formula_encounter.turns)
    if not world.equip_review_item("mainWeapon", "ender-staff-inlay-review"):
        _fail("review battle staff equip rejected")
        return
    if world.battle_equipment_view.visual_key() == key_before:
        _fail("equipped staff failed to change battle drawing model")
        return
    if not world.equip_review_item("bodyArmor", "ender-armor-overlay-review"):
        _fail("review armor did not equip")
        return
    if not world.equip_review_item("accessory", "ender-charm-review"):
        _fail("review accessory did not equip")
        return
    if not world.battle_equipment_view.visual_key().contains("brass-plate|small-charm"):
        _fail("armor and accessory not reflected by battle renderer")
        return
    if world.equip_review_item("mainWeapon", "reson-starter-sword"):
        _fail("wrong-actor equip mutated scene")
        return
    if world.formula_encounter.turns != turns_before:
        _fail("cosmetic equip consumed combat turn")
        return
    if world.take_formula_review_action("sharedDream"):
        _fail("cosmetic equipment bypassed blocked action")
        return
    var restored: Dictionary = world.export_save_snapshot()
    if not world.restore_save_snapshot(restored):
        _fail("original save codec no longer restores")
        return
    if str(world.battle_loadout.appearance()["weaponVisual"]) != "staff-brass":
        _fail("transient sample look persisted outside save ownership")
        return
    world.queue_free()
    print("AETHERWAKE_BATTLE_EQUIPMENT_SCENE_PASS: live equipped visual, layered armor/charm, authority and transient restore boundary")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_BATTLE_EQUIPMENT_SCENE_FAIL: " + reason)
    quit(1)
