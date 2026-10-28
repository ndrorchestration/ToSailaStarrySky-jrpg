extends SceneTree
## P-02: prove session-owned equipment survives REAL Godot scene replacement
## without editing durable First Wake v1 saves or earning/granting loot.

const Session = preload("res://scripts/battle_equipment_session_review.gd")
const Study = preload("res://scenes/equipment_lifecycle_study.tscn")
const Normal = preload("res://scenes/first_wake_chapter1_player_preview.tscn")
const Loadout = preload("res://scripts/battle_equipment_loadout.gd")
const Authority = preload("res://scripts/first_wake_party_combat_authority.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(reason: String) -> void:
    push_error("TSTSS_EQUIPMENT_SESSION_FAIL: " + reason)
    quit(1)

func _rng() -> float:
    return 0.5

func _verify() -> void:
    var session = Session.new()
    if not session.validate() or session.snapshot().get("status", "") != Session.STATUS:
        _fail("five-actor starter session did not validate as temporary-only")
        return
    var actor_keys: Array = session.snapshot()["roster"].keys()
    actor_keys.sort()
    if actor_keys != ["aepex", "ender", "ionia", "lyra", "reson"]:
        _fail("five party family records missing or malformed")
        return
    for actor_id in Session.ACTOR_IDS:
        var view = session.loadout_for(actor_id)
        if view == null or not view.validate() or view.actor_id != actor_id:
            _fail("unrecognized actor loadout in session: " + actor_id)
            return
        if view.slots != Loadout.STARTER_SLOTS[actor_id]:
            _fail("starter item family drift in session: " + actor_id)
            return
    var authority = Authority.new()
    if not authority.validate() or authority.can_take_formula_turn("lyra") or authority.can_take_formula_turn("ionia") or authority.can_take_formula_turn("reson"):
        _fail("session incorrectly grants combat or spell authority")
        return

    var normal = Normal.instantiate()
    root.add_child(normal)
    await process_frame
    var immutable_before: Dictionary = session.snapshot()
    if session.bind_study_scene(normal) or session.snapshot() != immutable_before:
        _fail("unmodified Chapter I scene wrongly admitted test-only shared gear")
        return
    normal.queue_free()
    await process_frame

    var first = Study.instantiate()
    root.add_child(first)
    await process_frame
    if not session.bind_study_scene(first):
        _fail("first isolated study scene cannot bind session authority")
        return
    if first.battle_loadout != session.loadout_for("ender") or first.trial_inventory != session.trial_inventory:
        _fail("first scene copied loadout or bag rather than binding references")
        return
    if session.transition_count != 1:
        _fail("first scene boundary wasn't counted exactly once")
        return
    first.ender.position = first.TRIAL_STATION_POSITION
    # Position is part of the existing durable v1 snapshot; record the
    # baseline AFTER walking to the station to isolate the gear-only change.
    var original_save: Dictionary = first.export_save_snapshot()
    var original_story: Dictionary = first.chapter.snapshot()
    if not first.interact_nearest() or not first.move_gear_inspector_item(1):
        _fail("owned inlay staff cannot be inspected from first field session")
        return
    var preview: Dictionary = first.gear_inspector_panel.inspection
    if int(preview.get("beforeStrike", 0)) != 6 or int(preview.get("afterStrike", 0)) != 9:
        _fail("uncommitted first field preview changed practice damage")
        return
    if session.trial_inventory.count_in_bag("ender-staff-inlay-review") != 1:
        _fail("preview consumed shared-owned item")
        return
    if not first.confirm_gear_inspector_item():
        _fail("first scene cannot commit owned staff to shared loadout")
        return
    if not first.move_gear_inspector_slot(1) or not first.move_gear_inspector_item(1) or not first.confirm_gear_inspector_item():
        _fail("first scene cannot commit owned physical guard")
        return
    if not first.move_gear_inspector_slot(1) or not first.move_gear_inspector_item(1) or not first.confirm_gear_inspector_item():
        _fail("first scene cannot commit owned aether charm")
        return
    first.close_gear_inspector()
    if not session.validate():
        _fail("first scene illegally duplicated or forged owned gear")
        return
    var first_visual: String = first.field_gear_display.visual_key()
    var first_state: Dictionary = session.snapshot()
    if str(first_state["roster"]["ender"]["slots"]["mainWeapon"]) != "ender-staff-inlay-review":
        _fail("session roster did not reflect selected field gear")
        return
    if first_state["trialBag"]["ender-staff-inlay-review"] != 0:
        _fail("shared session did not debit selected item")
        return
    if first.export_save_snapshot() != original_save:
        _fail("trial session gear altered Chapter I v1 persisted snapshot")
        return

    # Genuine scene unload/new scene load, not simply hiding one panel.
    first.queue_free()
    await process_frame
    if not session.validate() or session.snapshot() != first_state:
        _fail("freeing the real first scene lost session gear or duplicated items")
        return

    var second = Study.instantiate()
    root.add_child(second)
    await process_frame
    var new_scene_before: Dictionary = second.trial_inventory.snapshot()
    if not session.bind_study_scene(second) or session.transition_count != 2:
        _fail("second native scene failed to rebind live session state")
        return
    if second.trial_inventory == null or second.trial_inventory != session.trial_inventory:
        _fail("second scene has cloned/inconsistent bag reference")
        return
    if second.battle_loadout != session.loadout_for("ender"):
        _fail("second scene has cloned/inconsistent actor loadout reference")
        return
    if second.field_gear_display.visual_key() != first_visual or second.battle_equipment_view.visual_key() != first_visual:
        _fail("new field and battle scene rigs disagree with equipped gear")
        return
    if second.trial_inventory.snapshot()["bag"] == new_scene_before["bag"]:
        _fail("second scene retained its own starter bag instead of session inventory")
        return
    if second.chapter.snapshot() != original_story:
        _fail("new scene imported unauthorized story progression")
        return

    # Scene-state contract must block a rebind while a modal or battle is active.
    second.ender.position = second.TRIAL_STATION_POSITION
    if not second.interact_nearest() or not second.gear_inspector_open:
        _fail("retained session cannot reopen field inspector")
        return
    var second_snapshot: Dictionary = session.snapshot()
    if session.bind_study_scene(second) or session.snapshot() != second_snapshot:
        _fail("modal-time scene rebind mutated shared state")
        return
    if second.gear_inspector_panel.inspection.get("currentId", "") != "ender-staff-inlay-review":
        _fail("inspector does not show session-selected item")
        return
    second.close_gear_inspector()
    second.formula_encounter.rng_source = Callable(self, "_rng")
    if not second.start_formula_review():
        _fail("rehydrated session cannot start practice battle")
        return
    if session.bind_study_scene(second):
        _fail("active combat accepted session scene rebind")
        return
    var hp_before: int = int(second.formula_encounter.target["hp"])
    if not second.take_formula_review_action("staffStrike"):
        _fail("session gear denied legal Ender practice strike")
        return
    if hp_before - int(second.formula_encounter.target["hp"]) != 9:
        _fail("second native scene did not retain selected 9-point practice staff")
        return
    if not second.toggle_training_pressure_review() or not second.take_formula_review_action("hold"):
        _fail("second native scene didn't enable expected practice guard")
        return
    if int(second.formula_encounter.last_training_hit.get("damage", 0)) != 10:
        _fail("second native scene lost owned physical guard mitigation")
        return
    if not second.take_formula_review_action("hold") or int(second.formula_encounter.last_training_hit.get("damage", 0)) != 9:
        _fail("second native scene lost owned aether charm mitigation")
        return
    if second.take_formula_review_action("sharedDream"):
        _fail("session falsely unlocked blocked narrative magic")
        return
    if not second.close_formula_review() or not session.validate():
        _fail("end of second practice battle broke shared gear conservation")
        return

    # Tamper with an unauthorized actor's equipment record. Admission fails
    # before scene references are replaced; no custom gear/turn is granted.
    var third = Study.instantiate()
    root.add_child(third)
    await process_frame
    var original_lyra_slots: Dictionary = session.loadouts["lyra"].slots.duplicate(true)
    session.loadouts["lyra"].slots["mainWeapon"] = "ender-starter-staff"
    var third_loadout = third.battle_loadout
    var third_inventory = third.trial_inventory
    var count_before: int = session.transition_count
    if session.validate() or session.bind_study_scene(third):
        _fail("foreign actor equipment was accepted as valid")
        return
    if third.battle_loadout != third_loadout or third.trial_inventory != third_inventory or session.transition_count != count_before:
        _fail("failed session admission partially mutated third scene")
        return
    session.loadouts["lyra"].slots = original_lyra_slots
    if not session.validate():
        _fail("corrected cast loadout did not restore valid session")
        return
    if not session.bind_study_scene(third) or session.transition_count != 3:
        _fail("valid third scene could not reuse shared session")
        return

    # Durable restore is deliberately separate: v1 ignores all in-memory gear
    # and resets Ender's shared loadout and owned practice bag in place.
    if not third.restore_save_snapshot(original_save):
        _fail("existing Chapter I v1 restore failed in third scene")
        return
    if session.loadout_for("ender").item_id_for("mainWeapon") != "ender-starter-staff":
        _fail("v1 restore failed to reset session-owned temporary item")
        return
    if session.trial_inventory.snapshot()["bag"] != new_scene_before["bag"]:
        _fail("v1 restore didn't reset shared practice bag to pre-seeded starter")
        return
    if not session.validate() or third.chapter.snapshot() != original_story:
        _fail("v1 restore corrupted story or shared roster")
        return
    if third.export_save_snapshot().has("trialBag") or third.export_save_snapshot().has("roster"):
        _fail("transient session schema leaked into authored save codec")
        return

    var deep_copy: Dictionary = session.snapshot()
    deep_copy["roster"]["ender"]["slots"]["mainWeapon"] = "reson-starter-sword"
    deep_copy["trialBag"]["ender-starter-staff"] = 99
    if not session.validate() or session.loadout_for("ender").item_id_for("mainWeapon") != "ender-starter-staff":
        _fail("mutating detached observation snapshot corrupted session owner")
        return
    if not Session.new().validate() or session.loadout_for("missing") != null:
        _fail("unknown actor admission allowed or fresh session wasn't independent")
        return

    second.queue_free()
    third.queue_free()
    print("TSTSS_EQUIPMENT_SESSION_PASS: five-cast session owner, actual scene unload/rebind, Ender shared gear and 9/10/9 practice parity, forged-actor fail-closed, no v1 save leakage")
    quit(0)
