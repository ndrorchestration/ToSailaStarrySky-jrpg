extends SceneTree
## Real-scene contract for authored multi-line First Wake dialogue integration.

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

    # Signal contact: opening dialogue must not mutate quest progress early.
    world.ender.position = world.SIGNAL_POINTS["harmonic_buoy"]
    if not world.interact_nearest():
        _fail("Wakeheart dialogue did not open")
        return
    if not world.dialogue.open or world.dialogue.speaker_name() != "Wakeheart":
        _fail("Wakeheart dialogue state missing")
        return
    if world.chapter.completed_signals.size() != 0:
        _fail("signal progressed before dialogue closed")
        return
    if world.ender.player_controlled:
        _fail("movement remained enabled during dialogue")
        return
    if world.dialogue.lines.size() != 5:
        _fail("Wakeheart dialogue did not bind five packaged lines")
        return

    for index in range(4):
        if not world._advance_dialogue_review():
            _fail("Wakeheart dialogue advance rejected at " + str(index))
            return
        if not world.dialogue.open:
            _fail("Wakeheart dialogue closed too early")
            return
    if not world._advance_dialogue_review():
        _fail("Wakeheart final dialogue close rejected")
        return
    if world.dialogue.open:
        _fail("Wakeheart dialogue remained open after fifth line")
        return
    if "harmonic_buoy" not in world.chapter.completed_signals:
        _fail("Wakeheart signal not credited after dialogue close")
        return
    if not world.ender.player_controlled:
        _fail("movement did not resume after signal dialogue")
        return

    # Finish remaining signal/hazards directly to reach the Ionia contact gate.
    world.complete_signal_contact("below_frequency")
    world.complete_signal_contact("sky_lane_warning")
    for hazard_id in ["sky_predator", "wind_shear", "corporate_intercept"]:
        world.complete_hazard_review(hazard_id)
    if world.chapter.stage_key() != "contact":
        _fail("could not reach Contact for Ionia dialogue")
        return

    world.ender.position = world.CONTACT_POINTS["elder_farmer"]
    if not world.interact_nearest():
        _fail("Ionia dialogue did not open")
        return
    if world.dialogue.speaker_name() != "Ionia" or world.dialogue.lines.size() != 5:
        _fail("Ionia five-line authored dialogue missing")
        return
    if world.chapter.ionia_joined_for_choice:
        _fail("Ionia joined before dialogue completion")
        return

    for index in range(5):
        if not world._advance_dialogue_review():
            _fail("Ionia dialogue advance/close rejected at " + str(index))
            return
    if world.chapter.stage_key() != "choice" or not world.chapter.ionia_joined_for_choice:
        _fail("Ionia dialogue close did not establish decision boundary")
        return
    if world.ender.player_controlled:
        _fail("movement should remain paused for Choice after Ionia dialogue")
        return

    world.queue_free()
    await process_frame
    print("AETHERWAKE_GODOT_CHAPTER1_DIALOGUE_SCENE_PASS: authored five-line Wakeheart/Ionia dialogue gates progress and movement")
    quit(0)

func _fail(reason: String) -> void:
    push_error("AETHERWAKE_GODOT_CHAPTER1_DIALOGUE_SCENE_FAIL: " + reason)
    quit(1)
