extends SceneTree
## Fixed-input numerical proof. Review-only equipment values must change
## optional training math and NEVER alter baseline/canonical encounter actions.

const Loadout = preload("res://scripts/battle_equipment_loadout.gd")
const Equipment = preload("res://scripts/battle_equipment_training_profile.gd")
const Formula = preload("res://scripts/first_wake_combat_formula.gd")
const Encounter = preload("res://scripts/first_wake_formula_encounter.gd")
const Scene = preload("res://scenes/first_wake_chapter1_player_preview.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _rng_midpoint() -> float:
    return 0.5

func _verify() -> void:
    var ender = Loadout.new("ender")
    var profile = Equipment.new()
    var base_primary := {"might": 3, "grace": 4, "wits": 8, "spirit": 12, "presence": 4}
    var original: Dictionary = profile.project(ender, base_primary, 1)
    if original.is_empty() or int(original["baselineDamage"]) != 6 or int(original["equippedDamage"]) != 6:
        _fail("starter staff no longer preserves production formula 6-damage parity")
        return
    if int(original["physicalDefenseDelta"]) != 0 or int(original["aetherDefenseDelta"]) != 0:
        _fail("starter has unauthorized combat bonuses")
        return
    if not ender.equip("mainWeapon", "ender-staff-inlay-review"):
        _fail("inlay not equippable for practice")
        return
    if not ender.equip("bodyArmor", "ender-armor-overlay-review"):
        _fail("practice armor unavailable")
        return
    if not ender.equip("accessory", "ender-charm-review"):
        _fail("practice charm unavailable")
        return
    var equipped: Dictionary = profile.project(ender, base_primary, 1)
    if int(equipped["equippedDamage"]) != 9 or int(equipped["physicalDefenseDelta"]) != 8 or int(equipped["aetherDefenseDelta"]) != 6:
        _fail("stable numeric preview failed: strike +4 equipment power, armor +8, ward +6")
        return
    if int(equipped["baselineDamage"]) != int(original["baselineDamage"]):
        _fail("practice items changed baseline damage formula")
        return
    var bad = Loadout.new("ender")
    bad.slots["mainWeapon"] = "reson-starter-sword"
    if not profile.bonuses_for(bad).is_empty():
        _fail("tampered cross-actor loadout was given bonuses")
        return
    if not profile.bonuses_for(Loadout.new("reson")).is_empty():
        _fail("unapproved actor received Ender equipment modifiers")
        return

    var encounter = Encounter.new(Callable(self, "_rng_midpoint"))
    if encounter.set_training_loadout(ender):
        _fail("inactive encounter accepted equipment training")
        return
    if not encounter.start() or not encounter.set_training_loadout(ender):
        _fail("noncanonical encounter rejected valid equipment loadout")
        return
    if not bool(encounter.player.get("isNoncanonicalEquipmentReview", false)) or float(encounter.player.get("reviewEquipmentPower", 0)) != 4.0:
        _fail("equipped power did not bind to training-only combat actor")
        return
    if not encounter.take_action("staffStrike"):
        _fail("training staff strike not resolved")
        return
    if int(encounter.target["hp"]) != Encounter.TARGET_MAX_HP - 9:
        _fail("training staff damage was not actually increased")
        return
    if not encounter.close():
        _fail("training encounter not closable")
        return
    encounter.reset()
    if encounter.player.has("reviewEquipmentPower") or encounter.player.has("isNoncanonicalEquipmentReview"):
        _fail("provisional equipment modifier leaked into new encounter")
        return

    # Strong story boundary: authoritative enemy damage and battle formulas
    # continue to use their original constants even when gear is previewed.
    var hazard = Encounter.new(Callable(self, "_rng_midpoint"))
    var hazard_target := {
        "id": "wind-shear-fixture", "name": "Hazard fixture",
        "hp": 26, "maxHp": 26, "weakness": "Weather seam",
        "encounterKind": "authored_hazard",
        "ability": "galeForce", "abilityDamage": 3,
        "productionDerivedStats": {"aetherDefense": 20, "evasion": 10},
    }
    if not hazard.start_with_target(hazard_target):
        _fail("authored boundary fixture invalid")
        return
    if hazard.set_training_loadout(ender) or hazard.player.has("reviewEquipmentPower"):
        _fail("hazard adopted noncanonical equipment stats")
        return
    if not hazard.take_action("staffStrike"):
        _fail("original hazard action failed")
        return
    if int(hazard.target["hp"]) != 20 or hazard.enemy_turns != 1:
        _fail("authored hazard damage or retaliation drifted")
        return
    var base_vit := int(hazard.player["maxVit"])
    if int(hazard.player["vit"]) != base_vit - 3:
        _fail("training armor wrongly reduced story enemy retaliation")
        return

    var world = Scene.instantiate()
    root.add_child(world)
    await process_frame
    world.formula_encounter.rng_source = Callable(self, "_rng_midpoint")
    if not world.start_formula_review():
        _fail("native scene formula encounter would not open")
        return
    var scene_turns := int(world.formula_encounter.turns)
    if not world.equip_review_item("mainWeapon", "ender-staff-inlay-review"):
        _fail("native battle UI cannot equip training staff")
        return
    if world.formula_encounter.turns != scene_turns or not bool(world.formula_encounter.player.get("isNoncanonicalEquipmentReview", false)):
        _fail("equipment changed turn authority or did not enable training boundary")
        return
    if not world.equip_review_item("bodyArmor", "ender-armor-overlay-review"):
        _fail("training body armor does not update native battle scene")
        return
    if not world.equip_review_item("accessory", "ender-charm-review"):
        _fail("training charm does not update native battle scene")
        return
    var scene_profile: Dictionary = profile.project(world.battle_loadout, Dictionary(world.formula_encounter.player.get("productionStats", {})), 1)
    if scene_profile.is_empty() or int(scene_profile["equippedDamage"]) != 9:
        _fail("native battle data and practice stat projection disagree")
        return
    if not world.take_formula_review_action("staffStrike"):
        _fail("authorized real-scene staff strike did not run")
        return
    if int(world.formula_encounter.target["hp"]) != Encounter.TARGET_MAX_HP - 9 or int(world.formula_encounter.turns) != scene_turns + 1:
        _fail("live chapter review equipment math mismatches projected training")
        return
    if world.take_formula_review_action("sharedDream"):
        _fail("practice item granted unauthorized plot ability")
        return
    if not world.close_formula_review():
        _fail("live training battle did not close")
        return
    if world.formula_encounter.active:
        _fail("active battle leaked after close")
        return
    world.queue_free()
    print("AETHERWAKE_BATTLE_EQUIPMENT_TRAINING_PASS: 6-to-9 live damage, +8 physical/+6 ward projections, zero-turn swaps, authored hazard isolation")
    quit(0)

func _fail(message: String) -> void:
    push_error("AETHERWAKE_BATTLE_EQUIPMENT_TRAINING_FAIL: " + message)
    quit(1)
