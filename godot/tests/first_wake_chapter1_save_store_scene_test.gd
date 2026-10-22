extends SceneTree
## Real-scene filesystem integration for native Chapter I F5/F9 save/load.

const REVIEW_SCENE = preload("res://scenes/first_wake_chapter1_player_preview.tscn")
const TEST_PATH := "user://aetherwake-tests/first-wake-save-store-scene.json"

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world = REVIEW_SCENE.instantiate()
    root.add_child(world)
    await process_frame
    world.save_store.delete_slot(TEST_PATH)

    for signal_id in world.chapter.SIGNAL_IDS:
        if not world.complete_signal_contact(signal_id):
            _fail("could not reach Crossing for save integration")
            return
    if world.chapter.stage_key() != "crossing":
        _fail("scene did not enter Crossing")
        return

    var crossing_snapshot: Dictionary = world.chapter.snapshot()
    if not world.save_progress_to_disk(TEST_PATH):
        _fail("scene F5-equivalent save failed")
        return

    if not world.complete_hazard_review("sky_predator"):
        _fail("could not create second generation")
        return
    if world.chapter.completed_hazards != ["sky_predator"]:
        _fail("second generation hazard state unexpected")
        return
    if not world.save_progress_to_disk(TEST_PATH):
        _fail("second scene save failed")
        return
    if not FileAccess.file_exists(TEST_PATH + ".bak"):
        _fail("second scene save did not preserve previous generation")
        return

    if not world.start_formula_review():
        _fail("formula review did not start before restore")
        return
    if not world.take_formula_review_action("uncoverTruth"):
        _fail("formula review analysis failed before restore")
        return
    if not world.formula_encounter.active:
        _fail("formula review unexpectedly inactive before restore")
        return

    # Simulate a damaged newest generation; load must recover the prior valid
    # crossing snapshot and close all transient review state.
    var corrupt := FileAccess.open(TEST_PATH, FileAccess.WRITE)
    if corrupt == null:
        _fail("could not corrupt scene save primary")
        return
    corrupt.store_string("{ corrupt-primary")
    corrupt.close()

    if not world.load_progress_from_disk(TEST_PATH):
        _fail("scene did not recover from backup")
        return
    if world.formula_encounter.active or world.dialogue.open:
        _fail("transient review/dialogue survived durable restore")
        return
    if world.chapter.snapshot() != crossing_snapshot:
        _fail("backup recovery did not restore previous durable generation")
        return
    if world.last_message.find("backup recovery") < 0:
        _fail("scene did not surface backup recovery")
        return
    if not world.ender.player_controlled:
        _fail("exploration control did not resume after recovered load")
        return

    var before_missing: Dictionary = world.chapter.snapshot()
    if world.load_progress_from_disk(TEST_PATH + ".missing"):
        _fail("missing slot load unexpectedly succeeded")
        return
    if world.chapter.snapshot() != before_missing:
        _fail("failed load mutated live Chapter I state")
        return

    world.save_store.delete_slot(TEST_PATH)
    world.save_store.delete_slot(TEST_PATH + ".missing")
    world.queue_free()
    await process_frame

    print("AETHERWAKE_GODOT_CHAPTER1_SAVE_STORE_SCENE_PASS: real scene saves, backup-recovers, closes transient review state and fails closed without mutation")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CHAPTER1_SAVE_STORE_SCENE_FAIL: " + reason)
    quit(1)
