extends SceneTree
## Real-scene contract for native Chapter I durable snapshot export/restore.

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var packed: PackedScene = load("res://scenes/first_wake_chapter1_review.tscn")
    if packed == null:
        _fail("scene import failed")
        return
    var world = packed.instantiate()
    root.add_child(world)
    await process_frame

    for signal_id in ["harmonic_buoy", "below_frequency", "sky_lane_warning"]:
        world.complete_signal_contact(signal_id)
    for hazard_id in ["sky_predator", "wind_shear", "corporate_intercept"]:
        world.complete_hazard_review(hazard_id)
    world.meet_ionia_for_choice()
    world.choose_path_review("path_c")
    if world.chapter.stage_key() != "wake":
        _fail("could not reach Wake before snapshot")
        return

    world.review_hull_integrity = 73
    world.review_morale = 61
    world.review_engine_integration = 58
    var wake_snapshot: Dictionary = world.export_save_snapshot()
    if wake_snapshot.has("dialogue") or wake_snapshot.has("pending_signal_id"):
        _fail("transient scene state leaked into save")
        return

    world.resolve_wake_review()
    if world.chapter.stage_key() != "done":
        _fail("mutation to Done failed")
        return
    if not world.restore_save_snapshot(wake_snapshot):
        _fail("valid Wake snapshot rejected by real scene")
        return
    if world.chapter.stage_key() != "wake":
        _fail("real scene did not restore Wake stage")
        return
    if world.chapter.choice_path != "path_c" or world.chapter.choice_variant != "10+":
        _fail("choice identity changed on restore")
        return
    if world.chapter.desired_active_party_ids() != ["ender", "lyra", "ionia"]:
        _fail("restored party target lost Ionia")
        return
    if world.review_hull_integrity != 73 or world.review_morale != 61 or world.review_engine_integration != 58:
        _fail("resolver stats changed on scene restore")
        return
    if world.dialogue.open or not world.pending_signal_id.is_empty() or not world.pending_contact_id.is_empty():
        _fail("transient dialogue state survived restore")
        return
    if not world.ender.player_controlled:
        _fail("Wake restore did not resume player movement")
        return

    var before_invalid: Dictionary = world.chapter.snapshot()
    var bad := wake_snapshot.duplicate(true)
    bad["stage"] = "done"
    bad["epilogue_id"] = ""
    bad["chapter_one_complete"] = true
    if world.restore_save_snapshot(bad):
        _fail("invalid save admitted by real scene")
        return
    if world.chapter.snapshot() != before_invalid:
        _fail("invalid restore mutated current scene state")
        return

    world.queue_free()
    await process_frame
    print("AETHERWAKE_GODOT_CHAPTER1_SAVE_SCENE_PASS: real scene restores Wake state/stats and rejects invalid snapshots without mutation")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CHAPTER1_SAVE_SCENE_FAIL: " + reason)
    quit(1)
