extends SceneTree
## Real-scene contract for the playable production-formula review encounter.

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

func _verify() -> void:
    var world = REVIEW_SCENE.instantiate()
    root.add_child(world)
    await process_frame

    var sequence = Sequence.new([
        0.5, 0.99, 0.5, 0.99, 0.5, 0.99, 0.5, 0.99,
        0.5, 0.99, 0.5, 0.99, 0.5, 0.99, 0.5, 0.99,
    ])
    world.formula_encounter = Encounter.new(sequence.next)

    var chapter_before: Dictionary = world.chapter.snapshot()
    if not world.start_formula_review():
        _fail("real scene did not start formula review")
        return
    if world.ender.player_controlled:
        _fail("exploration remained active during formula review")
        return
    if world.chapter.snapshot() != chapter_before:
        _fail("starting formula review mutated Chapter I progression")
        return

    if not world.take_formula_review_action("uncoverTruth"):
        _fail("scene rejected Uncover Truth")
        return
    if not world.formula_encounter.weakness_revealed():
        _fail("scene did not expose analysis state")
        return
    if not world.take_formula_review_action("staffStrike"):
        _fail("scene rejected Staff Strike")
        return
    if world.chapter.snapshot() != chapter_before:
        _fail("formula actions mutated Chapter I progression")
        return

    var durable_save: Dictionary = world.export_save_snapshot()
    if durable_save.has("formula_encounter") or durable_save.has("combat"):
        _fail("transient formula review leaked into durable Chapter I save")
        return
    if not world.restore_save_snapshot(durable_save):
        _fail("scene could not restore durable save during formula review")
        return
    if world.formula_encounter.active:
        _fail("formula review remained active after durable restore")
        return
    if world.chapter.snapshot() != chapter_before:
        _fail("durable restore changed Chapter I progression")
        return

    # Restart and finish the target using only the authorized action subset.
    if not world.start_formula_review():
        _fail("formula review did not restart")
        return
    var guard := 0
    while not world.formula_encounter.completed and guard < 24:
        if int(world.formula_encounter.player["staffCharges"]) == 0:
            if not world.take_formula_review_action("hold"):
                _fail("scene Hold failed during completion loop")
                return
        else:
            if not world.take_formula_review_action("staffStrike"):
                _fail("scene Staff Strike failed during completion loop")
                return
        guard += 1

    if not world.formula_encounter.completed:
        _fail("real scene formula target did not complete")
        return
    if world.chapter.snapshot() != chapter_before:
        _fail("completed formula review mutated Chapter I progression")
        return
    if not world.close_formula_review():
        _fail("real scene formula review did not close")
        return
    if not world.ender.player_controlled:
        _fail("exploration control did not resume after formula review")
        return

    world.queue_free()
    await process_frame
    print("AETHERWAKE_GODOT_FORMULA_REVIEW_SCENE_PASS: playable production-formula review pauses/resumes exploration and remains transient to Chapter I saves")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_FORMULA_REVIEW_SCENE_FAIL: " + reason)
    quit(1)
