extends SceneTree
## Real-scene contract for the native First Wake Chapter I migration review.

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

    if world.get_script() == null or not world.has_method("complete_signal_contact"):
        _fail("scene script did not load or parse")
        return
    if world.ender == null or world.chapter.stage_key() != "signal":
        _fail("initial player or signal stage missing")
        return
    if world.chapter.desired_active_party_ids() != ["ender", "lyra"]:
        _fail("initial party target mismatch")
        return
    if world.contacts.size() != 4:
        _fail("four native contact placeholders are not present")
        return
    var ionia = world.contacts["elder_farmer"]
    if ionia.is_review_art_enabled():
        _fail("unapproved Ionia art enabled by default")
        return

    for signal_id in ["harmonic_buoy", "below_frequency", "sky_lane_warning"]:
        if not world.complete_signal_contact(signal_id):
            _fail("signal interaction rejected: " + signal_id)
            return
    if world.chapter.stage_key() != "crossing" or world.chapter.contacts_met.size() != 3:
        _fail("signal phase did not carry three contacts into crossing")
        return

    for hazard_id in ["sky_predator", "wind_shear", "corporate_intercept"]:
        if not world.complete_hazard_review(hazard_id):
            _fail("hazard interaction rejected: " + hazard_id)
            return
    if world.chapter.stage_key() != "contact":
        _fail("crossing did not enter contact")
        return

    if not world.meet_ionia_for_choice():
        _fail("Ionia decision-boundary contact rejected")
        return
    if world.chapter.stage_key() != "choice" or not world.chapter.ionia_joined_for_choice:
        _fail("Ionia join/choice boundary missing")
        return
    if world.ender.player_controlled:
        _fail("player movement not paused during three-path choice")
        return
    if world.chapter.desired_active_party_ids() != ["ender", "lyra", "ionia"]:
        _fail("choice party target missing Ionia")
        return

    if not world.choose_path_review("path_c"):
        _fail("path_c review choice rejected")
        return
    if world.chapter.stage_key() != "wake" or not world.ender.player_controlled:
        _fail("choice did not enter playable Wake resolution")
        return
    if not world.resolve_wake_review():
        _fail("Wake review resolution rejected")
        return
    if world.chapter.stage_key() != "done" or not world.chapter.chapter_one_complete:
        _fail("real scene did not reach explicit Chapter I completion")
        return
    if world.ender.player_controlled:
        _fail("player control remained active after migration-review completion")
        return

    world.queue_free()
    await process_frame
    print("AETHERWAKE_GODOT_CHAPTER1_SCENE_PASS: real dock scene traverses Signal, Crossing, Contact, 3-path Choice, Wake and Done")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CHAPTER1_SCENE_FAIL: " + reason)
    quit(1)
