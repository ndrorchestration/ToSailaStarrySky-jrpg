extends SceneTree
## Real-scene contract for the authored Wind Shear combat binding.

const Encounter = preload("res://scripts/first_wake_formula_encounter.gd")
const REVIEW_SCENE = preload("res://scenes/first_wake_chapter1_player_preview.tscn")

class Sequence:
    extends RefCounted
    var values: Array
    var index: int = 0

    func _init(next_values: Array) -> void:
        values = next_values.duplicate()

    func next():
        if index >= values.size():
            return 0.5
        var value = values[index]
        index += 1
        return value

func _initialize() -> void:
    call_deferred("_verify")

func _deterministic_encounter():
    var sequence = Sequence.new([
        0.5, 0.99, 0.5, 0.99, 0.5, 0.99, 0.5, 0.99,
        0.5, 0.99, 0.5, 0.99, 0.5, 0.99, 0.5, 0.99,
        0.5, 0.99, 0.5, 0.99, 0.5, 0.99, 0.5, 0.99,
    ])
    return Encounter.new(sequence.next)

func _verify() -> void:
    var world = REVIEW_SCENE.instantiate()
    root.add_child(world)
    await process_frame

    for signal_id in ["harmonic_buoy", "below_frequency", "sky_lane_warning"]:
        if not world.complete_signal_contact(signal_id):
            _fail("could not reach Crossing through signal phase")
            return
    if world.chapter.stage_key() != "crossing":
        _fail("signal phase did not enter Crossing")
        return

    if world.start_hazard_encounter("sky_predator"):
        _fail("Loose Cargo Sweep incorrectly opened combat")
        return
    if world.start_hazard_encounter("corporate_intercept"):
        _fail("Dock Authority Hold incorrectly opened combat")
        return

    # A started Wind Shear fight is transient. Save/restore before confirmation
    # must close it and award no Crossing progress.
    world.formula_encounter = _deterministic_encounter()
    if not world.start_hazard_encounter("wind_shear"):
        _fail("Wind Shear encounter did not start")
        return
    if world.active_hazard_encounter_id != "wind_shear":
        _fail("active hazard identity missing")
        return
    if str(world.formula_encounter.target.get("id", "")) != "windShear":
        _fail("real scene did not bind current Wind Shear target")
        return
    if str(world.formula_encounter.target.get("name", "")) != "Harmonic Shear Elemental":
        _fail("real scene target name drifted")
        return
    if not world.take_formula_review_action("uncoverTruth"):
        _fail("authored encounter rejected Uncover Truth")
        return
    if not world.formula_encounter.weakness_revealed():
        _fail("authored encounter did not expose Wind Shear weakness")
        return
    if "wind_shear" in world.chapter.completed_hazards:
        _fail("combat start/action prematurely completed the hazard")
        return

    var transient_save: Dictionary = world.export_save_snapshot()
    if not world.restore_save_snapshot(transient_save):
        _fail("durable restore failed during active Wind Shear encounter")
        return
    if world.formula_encounter.active or not world.active_hazard_encounter_id.is_empty():
        _fail("durable restore did not clear transient authored combat")
        return
    if "wind_shear" in world.chapter.completed_hazards:
        _fail("durable restore awarded unconfirmed Wind Shear progress")
        return

    # Restart and clear the authored encounter deterministically.
    world.formula_encounter = _deterministic_encounter()
    if not world.start_hazard_encounter("wind_shear"):
        _fail("Wind Shear encounter did not restart")
        return
    var guard := 0
    while not world.formula_encounter.completed and guard < 24:
        if int(world.formula_encounter.player["staffCharges"]) == 0:
            if not world.take_formula_review_action("hold"):
                _fail("Hold failed during Wind Shear completion")
                return
        else:
            if not world.take_formula_review_action("staffStrike"):
                _fail("Staff Strike failed during Wind Shear completion")
                return
        guard += 1
    if not world.formula_encounter.completed:
        _fail("Wind Shear target did not clear")
        return
    if "wind_shear" in world.chapter.completed_hazards:
        _fail("cleared target mutated Chapter I before close confirmation")
        return
    if not world.close_formula_review():
        _fail("cleared Wind Shear encounter did not close/confirm")
        return
    if "wind_shear" not in world.chapter.completed_hazards:
        _fail("confirmed Wind Shear clear did not complete the hazard")
        return
    if world.formula_encounter.active or not world.active_hazard_encounter_id.is_empty():
        _fail("encounter state remained active after confirmation")
        return

    # The other two current Chapter I hazards remain their existing noncombat
    # interactions. Completing all three must preserve normal stage progression.
    if not world.complete_hazard_review("sky_predator"):
        _fail("Loose Cargo Sweep direct hazard flow regressed")
        return
    if not world.complete_hazard_review("corporate_intercept"):
        _fail("Dock Authority Hold direct hazard flow regressed")
        return
    if world.chapter.stage_key() != "contact":
        _fail("three Crossing hazards did not advance to Contact")
        return

    world.queue_free()
    await process_frame
    print("AETHERWAKE_GODOT_WIND_SHEAR_COMBAT_SCENE_PASS: only authored Wind Shear requires production-formula combat; save/cancel is fail-closed and confirmed clear advances Crossing")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_WIND_SHEAR_COMBAT_SCENE_FAIL: " + reason)
    quit(1)
