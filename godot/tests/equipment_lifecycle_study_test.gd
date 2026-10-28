extends SceneTree
## Actual isolated Godot field → owned inspector → battle → field session
## end-to-end P-01. No world item grants, save migration or canon edits.

const STUDY = preload("res://scenes/equipment_lifecycle_study.tscn")
const NORMAL = preload("res://scenes/first_wake_chapter1_player_preview.tscn")
const INPUT = preload("res://scripts/first_wake_chapter1_input_policy.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _rng() -> float:
    return 0.5

func _fail(detail: String) -> void:
    push_error("TSTSS_EQUIPMENT_LIFECYCLE_FAIL: " + detail)
    quit(1)

func _press(world: Node, action_id: String) -> void:
    var event := InputEventAction.new()
    event.action = action_id
    event.pressed = true
    world._unhandled_input(event)

func _verify() -> void:
    print("TSTSS_EQUIPMENT_DIAG: entered lifecycle test")
    var normal = NORMAL.instantiate()
    root.add_child(normal)
    await process_frame
    print("TSTSS_EQUIPMENT_DIAG: ordinary scene ready")
    normal.ender.position = Vector2(805, 465)
    if normal.equipment_station_review_enabled or normal.interact_nearest() or normal.open_gear_inspector():
        _fail("ordinary Chapter I scene acquired test-only station")
        return
    normal.queue_free()
    await process_frame

    print("TSTSS_EQUIPMENT_DIAG: ordinary scene closed")
    var world = STUDY.instantiate()
    root.add_child(world)
    await process_frame
    print("TSTSS_EQUIPMENT_DIAG: isolated scene ready")
    world.formula_encounter.rng_source = Callable(self, "_rng")
    if not world.equipment_station_review_enabled or world.field_gear_display == null:
        _fail("study scene did not instantiate real separate field rig")
        return
    var original_stage: String = world.chapter.stage_key()
    var original_snapshot: Dictionary = world.export_save_snapshot()
    var original_visual: String = world.field_gear_display.visual_key()
    var original_bag: Dictionary = world.trial_inventory.snapshot()
    if original_stage != "signal":
        _fail("starting stage changed from existing Chapter I review")
        return
    # Spawn at a location outside BOTH the test bench radius and existing
    # canonical signal interaction radii, avoiding a legitimate story cue.
    world.ender.position = Vector2(710, 465)
    if world.interact_nearest() or world.gear_inspector_open:
        _fail("station opened without an interaction-distance check")
        return

    world.ender.position = world.TRIAL_STATION_POSITION
    _press(world, INPUT.INTERACT)
    print("TSTSS_EQUIPMENT_DIAG: E interaction handled")
    if not world.gear_inspector_open or not world.gear_inspector_panel.visible or world.ender.player_controlled:
        _fail("nearby E action did not focus real equipment-station modal")
        return
    var no_commit_visual: String = world.field_gear_display.visual_key()
    if not world.move_gear_inspector_item(1):
        _fail("owned alternate staff unavailable for preview")
        return
    var projected: Dictionary = world.gear_inspector_panel.inspection
    if int(projected.get("beforeStrike", 0)) != 6 or int(projected.get("afterStrike", 0)) != 9:
        _fail("field preview did not use existing native 6 to 9 practice formula")
        return
    if world.field_gear_display.visual_key() != no_commit_visual or world.trial_inventory.snapshot() != original_bag:
        _fail("uncommitted field selection changed owned state or visuals")
        return
    if world.start_formula_review() or world.take_formula_review_action("staffStrike"):
        _fail("field inspector leaked into authorized combat before closing")
        return

    _press(world, INPUT.INSPECT_CONFIRM)
    if world.battle_loadout.item_id_for("mainWeapon") != "ender-staff-inlay-review":
        _fail("Enter did not commit owned inlay staff")
        return
    if world.field_gear_display.visual_key() == original_visual or world.trial_inventory.count_in_bag("ender-staff-inlay-review") != 0:
        _fail("field preview or bag did not update after confirmation")
        return
    if not world.move_gear_inspector_slot(1) or not world.move_gear_inspector_item(1) or not world.confirm_gear_inspector_item():
        _fail("could not equip the owned chest guard at station")
        return
    if not world.move_gear_inspector_slot(1) or not world.move_gear_inspector_item(1) or not world.confirm_gear_inspector_item():
        _fail("could not equip the owned charm at station")
        return
    if not world.trial_inventory.validate(world.battle_loadout):
        _fail("ownership not conserved after all station transfers")
        return
    if world.formula_encounter.active:
        _fail("inspector transactions accidentally started battle")
        return
    _press(world, INPUT.INSPECT_CLOSE)
    if world.gear_inspector_open or not world.ender.player_controlled:
        _fail("Escape did not recover Ender field input")
        return

    var stored_slots: Dictionary = world.battle_loadout.slots.duplicate(true)
    var stored_bag: Dictionary = world.trial_inventory.snapshot()["bag"]
    var field_key: String = world.field_gear_display.visual_key()
    _press(world, INPUT.FORMULA_REVIEW)
    print("TSTSS_EQUIPMENT_DIAG: entered practice battle")
    if not world.formula_encounter.active or not world.trial_inventory.validate(world.battle_loadout):
        _fail("battle boundary did not receive field-owned gear")
        return
    if world.battle_equipment_view.visual_key() != field_key:
        _fail("field gear and battle presentation are not the same validated item")
        return
    var turn_zero: int = world.formula_encounter.turns
    var hp_before: int = int(world.formula_encounter.target["hp"])
    if not world.take_formula_review_action("staffStrike"):
        _fail("authorized battle Staff Strike failed")
        return
    if hp_before - int(world.formula_encounter.target["hp"]) != 9:
        _fail("owned inlay staff didn't cause expected 9-point noncanon strike")
        return
    if not world.toggle_training_pressure_review():
        _fail("controlled practice pressure cannot be enabled")
        return
    var vit_before: int = int(world.formula_encounter.player["vit"])
    if not world.take_formula_review_action("hold") or int(world.formula_encounter.last_training_hit.get("damage", 0)) != 10:
        _fail("owned armor did not reduce physical practice counter-hit")
        return
    if not world.take_formula_review_action("hold") or int(world.formula_encounter.last_training_hit.get("damage", 0)) != 9:
        _fail("owned charm did not reduce aether practice counter-hit")
        return
    if int(world.formula_encounter.player["vit"]) != vit_before - 19:
        _fail("actual practice vitality did not match field-selected equipment")
        return
    if world.formula_encounter.turns != turn_zero + 3:
        _fail("station equip/preview leaked additional combat turns")
        return
    if world.take_formula_review_action("sharedDream"):
        _fail("equipment study granted forbidden narrative ability")
        return

    _press(world, INPUT.FORMULA_REVIEW)
    print("TSTSS_EQUIPMENT_DIAG: returned from practice battle")
    if world.formula_encounter.active or not world.ender.player_controlled:
        _fail("C did not return to field after practice")
        return
    if world.field_gear_display.visual_key() != field_key or world.battle_loadout.slots != stored_slots:
        _fail("field loadout did not persist across practice return")
        return
    if world.trial_inventory.snapshot()["bag"] != stored_bag:
        _fail("battle transition duplicated or lost owned items")
        return
    if world.chapter.stage_key() != original_stage or world.chapter.completed_signals.size() != 0:
        _fail("practice station changed canonical Chapter I progression")
        return
    if not world.interact_nearest() or not world.gear_inspector_open:
        _fail("test station cannot reopen after field/battle transition")
        return
    if world.gear_inspector_panel.inspection.get("currentId", "") != "ender-staff-inlay-review":
        _fail("reopened field inspector does not show current staff")
        return

    if original_snapshot.has("inventory") or original_snapshot.has("equipment"):
        _fail("preexisting Chapter I save already leaks gear")
        return
    print("TSTSS_EQUIPMENT_DIAG: performing durable restore")
    if not world.restore_save_snapshot(original_snapshot):
        _fail("legacy-format Chapter I state no longer restores")
        return
    if world.gear_inspector_open or world.battle_loadout.item_id_for("mainWeapon") != "ender-starter-staff":
        _fail("restore didn't clear study modal and reset transient loadout")
        return
    if world.trial_inventory.snapshot()["bag"] != original_bag["bag"] or world.field_gear_display.visual_key() != original_visual:
        _fail("restore didn't reset preview and item ownership together")
        return
    if world.chapter.stage_key() != original_stage:
        _fail("restore unexpectedly changed original story state")
        return

    world.queue_free()
    print("TSTSS_EQUIPMENT_LIFECYCLE_PASS: field E-inspect, read-only comparison, owned commit, real field/battle rig parity, 9 strike, 10/9 mitigation, conserved return and legacy restore")
    quit(0)
