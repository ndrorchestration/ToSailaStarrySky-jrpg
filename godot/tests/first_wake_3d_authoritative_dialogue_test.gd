extends SceneTree
## Verifies original creator-approved First Wake dialogue is REUSED, not cloned.
## Only physical Area3D E presses invoke original JobScene.interact() methods.
## Gated 3D gangway never claims actual engineering or a checkpoint.
const Stage = preload("res://scenes/first_wake_3d_visual_slice.tscn")
var checks := 0
var errors: Array[String] = []

func _check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        errors.append(message)
        push_error("TSTSS_3D_AUTHORITATIVE_DIALOGUE_FAIL:" + message)

func _walk(action: String, ticks: int) -> void:
    Input.action_press(action)
    for i in range(ticks):
        await physics_frame
    Input.action_release(action)
    for i in range(3):
        await physics_frame

func _press_e(stage) -> bool:
    var key := InputEventKey.new()
    key.keycode = KEY_E
    key.pressed = true
    var before_receipts: int = stage.interaction_receipts.size()
    var before_dialogue: String = stage.authoritative_story_bridge.story_snapshot().get("dialogue_line", "")
    stage._unhandled_input(key)
    return stage.interaction_receipts.size() > before_receipts or (
        stage.authoritative_story_bridge.story_snapshot().get("dialogue_line", "") != before_dialogue
    )

func _complete_dialogue(stage, expected_event: String) -> void:
    var bridge = stage.authoritative_story_bridge
    var iterations := 0
    while bridge.authoritative_job.dialogue_open and iterations < 14:
        _press_e(stage)
        iterations += 1
    _check(not bridge.authoritative_job.dialogue_open,
        "original authored " + expected_event + " conversation did not close")
    _check(expected_event in bridge.completed_dialogues,
        "original first wake completion event not fired: " + expected_event)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var stage = Stage.instantiate()
    root.add_child(stage)
    for i in range(15):
        await physics_frame
    var bridge = stage.authoritative_story_bridge
    _check(bridge != null and bridge.bridge_ready, "original JobScene/Session integration not bound")
    if bridge == null or not bridge.bridge_ready:
        stage.queue_free()
        quit(1)
        return
    var job = bridge.authoritative_job
    var session = bridge.authoritative_session
    var player = stage.navigation_body
    _check(job.visible == false and job.ui_layer.visible == false,
        "a duplicate 2D First Wake scene is being rendered")
    _check(job.process_mode == Node.PROCESS_MODE_DISABLED,
        "original hidden JobScene must not receive separate gameplay inputs")
    _check(job.opening == session.opening,
        "3D story adapter created a second story authority instead of binding the original")
    _check(job.opening.step_key() == "job_search" and job.opening.active_party_ids == ["ender"],
        "Ionia-first initial party contract not preserved")
    _check(not bridge.story_snapshot().get("checkpoint_available", true),
        "3D study incorrectly granted a save checkpoint")
    _check(not bridge.story_snapshot().get("physical_contact_recorded", true),
        "3D story adapter forged actual water landing evidence")
    _check(not bridge.interact_at_verified_probe("IoniaArrival_ReviewOnly"),
        "cannot recruit Ionia without original flyer")
    _check(job.opening.active_party_ids == ["ender"] and not job.flyer_read,
        "rejected early conversation mutated original state")

    var toggle := InputEventKey.new()
    toggle.pressed = true
    toggle.keycode = KEY_B
    stage._unhandled_input(toggle)
    _check(stage.authoritative_story_mode,
        "B key failed to enable original narrative bridge review")
    await _walk("tstss_3d_forward", 174)
    _check(player.is_on_floor() and player.global_position.z < -5.5,
        "3D marker did not physically reach the original job notice probe")
    _check(_press_e(stage), "physical notice E did not start original flyer dialogue")
    _check(job.dialogue_open and job.dialogue_event == "flyer",
        "3D notice interaction didn't use original flyer event")
    _check(stage.original_dialogue_panel.visible,
        "3D dialogue panel did not open when the original flyer conversation began")
    _check(stage.original_dialogue_line.text == str(job.dialogue_lines[0]) and
        stage.original_dialogue_speaker.text == job.dialogue_speaker.text,
        "3D HUD dialogue must exactly reproduce original scene text and speaker")
    _check("harmonic levitation" in " ".join(job.dialogue_lines).to_lower(),
        "original author-approved job notice text was not reused")
    _check(not job.flyer_read and job.opening.active_party_ids == ["ender"],
        "read flyer progressed before the final authored dialogue line")
    _complete_dialogue(stage, "flyer")
    _check(not stage.original_dialogue_panel.visible,
        "3D dialogue panel did not hide after original flyer completion")
    _check(job.flyer_read and job.opening.step_key() == "job_search",
        "flyer completion changed party/story stage incorrectly")
    _check(job.opening.active_party_ids == ["ender"],
        "Ionia joined before the actual original hiring dialogue")

    await _walk("tstss_3d_forward", 93)
    _check(player.is_on_floor() and player.global_position.z < -10.6,
        "real 3D movement failed to reach Ionia's spatial position")
    _check(_press_e(stage), "physics Ionia E did not start original hiring dialogue")
    _check(job.dialogue_open and job.dialogue_event == "hire",
        "3D Ionia conversation must be original hiring event")
    _check(stage.original_dialogue_panel.visible and
        stage.original_dialogue_line.text == str(job.dialogue_lines[0]),
        "Ionia 3D dialogue panel does not present unchanged original first line")
    _check("Welcome aboard" in " ".join(job.dialogue_lines),
        "the original creator-directed Ionia dialogue was replaced or shortened")
    _check(job.opening.active_party_ids == ["ender"],
        "Ionia joined prematurely before the last authored line")
    _complete_dialogue(stage, "hire")
    _check(not stage.original_dialogue_panel.visible,
        "Ionia dialogue completion did not close the original-source panel")
    _check(job.opening.active_party_ids == ["ender", "ionia"],
        "real original opening contract failed to recruit Ionia exactly once")
    _check(session.opening == job.opening and session.opening.step_key() == "engineering",
        "original session no longer owns engineering transition")
    _check(not session.can_checkpoint(),
        "Ionia interview must not grant landing/reserve-dependent checkpoint")
    _check(not session.physical_landing_observed and not session.reserve_inspected,
        "3D dock interaction forged water or reserve proof")
    _check(job.room == "dock",
        "3D Ionia event incorrectly advanced into an unavailable engineering interior")

    # Enter the new real 3D engineering space ONLY after original hiring.
    player.global_position = Vector3(-3.4, 0.1, -10.0)
    for i in range(5):
        await physics_frame
    _check(stage.inspect_nearest_probe(),
        "verified 3D gangway was not authorized by original Ionia hire")
    _check(job.room == "engineering" and session.opening.step_key() == "engineering",
        "gangway failed to call original engineering room transition")
    _check(stage.engineering_room_instantiated and stage.interaction_probes.size() == 7,
        "physical 3D engineering interior and four Area3D stations were not created")
    _check(player.global_position.x > 50.0 and player.is_on_floor() == false,
        "3D boarding did not position the player in actual engineering geometry")
    for frame in range(12):
        await physics_frame
    _check(player.is_on_floor(), "engineering has no real walkable physics floor")
    _check(session.opening.active_party_ids == ["ender", "ionia"],
        "new 3D room incorrectly changes canonical party")
    _check(not session.can_checkpoint(),
        "entering engineering is not proof of physical splashdown or postflight reserves")

    toggle.keycode = KEY_B
    stage._unhandled_input(toggle)
    _check(not stage.authoritative_story_mode and
        session.opening.active_party_ids == ["ender", "ionia"],
        "review visual toggle erased the original session's story progression")
    var snapshot: Dictionary = stage.quality_snapshot()
    _check(snapshot.get("original_story_contract_bridge_bound") and
        snapshot.get("uses_same_original_first_wake_opening"),
        "3D quality report claims story state without original authoritative binding")
    _check(snapshot.get("original_dialogue_panel_uses_source_lines") == true,
        "production-quality dialogue panel does not use original source lines")
    _check(snapshot.get("3d_gangway_canonical_boarding_ready") == true and
        snapshot.get("3d_engineering_stations_present") == true,
        "original gangway boarding or physical 3D engineering stations missing")
    _check(not snapshot.get("playable_chapter_one_3d_migrated"),
        "3D review falsely claims full first wake migration")
    stage.queue_free()
    await process_frame
    if errors.is_empty():
        print("TSTSS_3D_AUTHORITATIVE_DIALOGUE_PASS checks=", checks,
            " original_job_text=true original_opening_identity=true physical_notice=true physical_ionia=true verified_gangway=true 3d_engineering_floor=true save_untouched=true")
    quit(0 if errors.is_empty() else 1)
