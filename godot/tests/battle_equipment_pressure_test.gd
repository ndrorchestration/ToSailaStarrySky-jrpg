extends SceneTree
## Real Godot regression for optional practice enemy turns. Producing a
## smaller VIT hit is the admission criterion, not merely a stat projection.
## The normal target remains nonretaliating and story hazards never opt in.

const Encounter = preload("res://scripts/first_wake_formula_encounter.gd")
const Equipment = preload("res://scripts/battle_equipment_training_profile.gd")
const Loadout = preload("res://scripts/battle_equipment_loadout.gd")
const Scene = preload("res://scenes/first_wake_chapter1_player_preview.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _rng() -> float:
    return 0.5

func _fail(why: String) -> void:
    push_error("AETHERWAKE_EQUIPMENT_PRESSURE_FAIL: " + why)
    quit(1)

func _verify() -> void:
    var basic = Loadout.new("ender")
    var profile = Equipment.new()
    var primary: Dictionary = {"might": 3, "grace": 4, "wits": 8, "spirit": 12, "presence": 4}
    var default_hit: Dictionary = profile.resolve_practice_hit(
        primary, 1, profile.bonuses_for(basic), "physical"
    )
    var default_ward: Dictionary = profile.resolve_practice_hit(
        primary, 1, profile.bonuses_for(basic), "aether"
    )
    if int(default_hit.get("damage", -1)) != 11 or int(default_ward.get("damage", -1)) != 10:
        _fail("baseline fixed-input physical/aether pressure contract drifted")
        return
    if profile.resolve_practice_hit(primary, 1, profile.bonuses_for(basic), "unknown") != {}:
        _fail("unknown damage type bypassed fixture")
        return
    if profile.resolve_practice_hit(primary, 1, {"armorDefense": 999.0, "aetherDefense": 0.0}, "physical") != {}:
        _fail("forged armor quantity bypassed cap")
        return
    if profile.resolve_practice_hit(primary, 1, {"armorDefense": -1.0, "aetherDefense": 0.0}, "physical") != {}:
        _fail("negative armor was admitted")
        return

    var armed = Loadout.new("ender")
    if not armed.equip("bodyArmor", "ender-armor-overlay-review"):
        _fail("training armor equip rejected")
        return
    if not armed.equip("accessory", "ender-charm-review"):
        _fail("training charm equip rejected")
        return
    var armored_hit: Dictionary = profile.resolve_practice_hit(primary, 1, profile.bonuses_for(armed), "physical")
    var warded_hit: Dictionary = profile.resolve_practice_hit(primary, 1, profile.bonuses_for(armed), "aether")
    if int(armored_hit.get("damage", -1)) != 10 or int(armored_hit.get("mitigatedByGear", -1)) != 1:
        _fail("equipped armor did not reduce actual practice damage 11 to 10")
        return
    if int(warded_hit.get("damage", -1)) != 9 or int(warded_hit.get("mitigatedByGear", -1)) != 1:
        _fail("equipped charm did not reduce actual practice damage 10 to 9")
        return

    var no_pressure = Encounter.new(Callable(self, "_rng"))
    if no_pressure.set_training_pressure(true):
        _fail("pressure accepted outside an active encounter")
        return
    if not no_pressure.start() or not no_pressure.set_training_loadout(armed):
        _fail("normal review could not start")
        return
    if not no_pressure.take_action("hold") or no_pressure.enemy_turns != 0:
        _fail("default optional formula review unexpectedly retaliated")
        return
    if no_pressure.last_training_hit != {}:
        _fail("disabled practice produced an incoming hit")
        return

    var practice = Encounter.new(Callable(self, "_rng"))
    if not practice.start() or not practice.set_training_loadout(armed):
        _fail("practice could not start")
        return
    if not practice.set_training_pressure(true):
        _fail("opt-in pressure rejected")
        return
    if practice.turns != 0 or practice.enemy_turns != 0:
        _fail("training toggle consumed combat turns")
        return
    var initial_vit := int(practice.player["vit"])
    if not practice.take_action("hold") or practice.enemy_turns != 1:
        _fail("first accepted action did not produce physical pressure")
        return
    if int(practice.last_training_hit.get("damage", -1)) != 10 or str(practice.last_training_hit.get("kind", "")) != "physical":
        _fail("physical pressure did not use equipped chest armor")
        return
    if int(practice.player["vit"]) != initial_vit - 10:
        _fail("real VIT was not reduced by 10")
        return
    if not practice.take_action("hold") or practice.enemy_turns != 2:
        _fail("second accepted action did not produce aether pressure")
        return
    if int(practice.last_training_hit.get("damage", -1)) != 9 or str(practice.last_training_hit.get("kind", "")) != "aether":
        _fail("aether pressure did not use equipped charm")
        return
    if int(practice.player["vit"]) != initial_vit - 19:
        _fail("real VIT did not account for both pressure hits")
        return
    if practice.take_action("sharedDream") or practice.enemy_turns != 2:
        _fail("blocked plot action triggered enemy damage")
        return

    # Change armor midbattle; later damage immediately follows the new items.
    if not armed.equip("bodyArmor", "") or not armed.equip("accessory", ""):
        _fail("optional training gear could not be removed")
        return
    if not practice.set_training_loadout(armed) or not practice.take_action("hold"):
        _fail("new gear was not rebound during practice")
        return
    if int(practice.last_training_hit.get("damage", -1)) != 11:
        _fail("removing chest guard failed to restore original physical hit")
        return
    if not practice.take_action("hold") or int(practice.last_training_hit.get("damage", -1)) != 10:
        _fail("removing charm failed to restore original aether hit")
        return
    var prior_enemy_turns: int = practice.enemy_turns
    if not practice.set_training_pressure(false):
        _fail("practice pressure could not be disabled")
        return
    if not practice.take_action("hold") or practice.enemy_turns != prior_enemy_turns:
        _fail("disabling training pressure did not stop counterattacks")
        return
    var practice_snapshot: Dictionary = practice.snapshot()
    if not practice.close() or practice.set_training_pressure(true):
        _fail("closed practice accepted opt-in pressure")
        return
    practice.reset()
    if practice.training_pressure_enabled or not practice.last_training_hit.is_empty():
        _fail("pressure leaked across reset")
        return
    if int(practice_snapshot["enemyTurns"]) != 4 or str(practice_snapshot["encounterKind"]) != "formula_review":
        _fail("temporary practice trace lost encounter provenance")
        return

    var hazard = Encounter.new(Callable(self, "_rng"))
    var current_story := {
        "id":"wind-shear-test", "name":"Wind Shear test",
        "hp":26, "maxHp":26, "weakness":"EMP seam",
        "encounterKind":"authored_hazard", "ability":"galeForce", "abilityDamage":3,
        "productionDerivedStats":{"aetherDefense":20, "evasion":10},
    }
    if not hazard.start_with_target(current_story):
        _fail("authored story encounter could not start")
        return
    if hazard.set_training_loadout(Loadout.new("ender")) or hazard.set_training_pressure(true):
        _fail("authored story encounter admitted review-only gear effects")
        return
    var before_story_vit := int(hazard.player["vit"])
    if not hazard.take_action("hold") or int(hazard.player["vit"]) != before_story_vit - 3 or hazard.enemy_turns != 1:
        _fail("authored retaliation changed from original 3 damage")
        return
    if hazard.training_pressure_enabled or not hazard.last_training_hit.is_empty():
        _fail("training pressure leaked into authored hazard")
        return

    var world = Scene.instantiate()
    root.add_child(world)
    await process_frame
    world.formula_encounter.rng_source = Callable(self, "_rng")
    if not world.start_formula_review():
        _fail("real Chapter I review scene could not start")
        return
    if not world.equip_review_item("bodyArmor", "ender-armor-overlay-review"):
        _fail("scene equip armor failed")
        return
    if not world.equip_review_item("accessory", "ender-charm-review"):
        _fail("scene equip charm failed")
        return
    if not world.toggle_training_pressure_review():
        _fail("scene could not enable practice pressure")
        return
    var start_vit := int(world.formula_encounter.player["vit"])
    var start_turns := int(world.formula_encounter.turns)
    if not world.take_formula_review_action("hold"):
        _fail("admitted scene hold failed")
        return
    if int(world.formula_encounter.player["vit"]) != start_vit - 10:
        _fail("scene physical practice hit failed to reduce VIT")
        return
    if not world.take_formula_review_action("hold"):
        _fail("second admitted scene hold failed")
        return
    if int(world.formula_encounter.player["vit"]) != start_vit - 19:
        _fail("scene aether practice hit failed to reduce VIT")
        return
    if world.formula_encounter.turns != start_turns + 2 or world.formula_encounter.enemy_turns != 2:
        _fail("scene pressure changed formula action accounting")
        return
    if not world.toggle_training_pressure_review() or world.formula_encounter.training_pressure_enabled:
        _fail("scene practice pressure toggle did not disable")
        return
    if not world.close_formula_review():
        _fail("scene pressure review failed to close")
        return
    if world.toggle_training_pressure_review():
        _fail("scene pressure toggled outside battle")
        return
    var save: Dictionary = world.export_save_snapshot()
    if not world.restore_save_snapshot(save):
        _fail("existing chapter save snapshot no longer restores")
        return
    if world.formula_encounter.training_pressure_enabled or not world.formula_encounter.last_training_hit.is_empty():
        _fail("training pressure persisted after chapter save restore")
        return
    world.queue_free()
    print("AETHERWAKE_EQUIPMENT_PRESSURE_PASS: actual 11->10 physical and 10->9 aether damage, scene VIT changes, authored 3-damage Gale Force isolation")
    quit(0)
