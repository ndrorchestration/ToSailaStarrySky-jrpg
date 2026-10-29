extends SceneTree
## Four fully AUTHORED First Wake engineering interactions in actual 3D.
## Original JobScene and FirstWakeGameSession are not duplicated or bypassed.
const Stage = preload("res://scenes/first_wake_3d_visual_slice.tscn")
var failed: Array[String] = []
var count := 0

func verify(ok: bool, reason: String) -> void:
    count += 1
    if not ok:
        failed.append(reason)
        push_error("TSTSS_3D_ENGINEERING_FAIL:" + reason)

func _ready_test() -> void:
    call_deferred("_run")

func _initialize() -> void:
    call_deferred("_run")

func _walk(action: String, ticks: int) -> void:
    Input.action_press(action)
    for i in range(ticks):
        await physics_frame
    Input.action_release(action)
    for i in range(5):
        await physics_frame

func _complete(stage, event: String) -> void:
    var job = stage.authoritative_story_bridge.authoritative_job
    var i := 0
    while job.dialogue_open and i < 15:
        verify(stage.inspect_nearest_probe(), "E cannot advance original " + event + " authored line")
        i += 1
    verify(not job.dialogue_open and event in stage.authoritative_story_bridge.completed_dialogues,
        "Original authored " + event + " completion receipt missing")

func _approach_and_interact(stage, action: String, frames: int, event: String) -> void:
    await _walk(action, frames)
    for i in range(3):
        await physics_frame
    verify(stage.navigation_body.is_on_floor(), "3D floor support lost when approaching " + event)
    verify(stage.inspect_nearest_probe(), "E failed real 3D Area3D station " + event)
    var job = stage.authoritative_story_bridge.authoritative_job
    verify(job.dialogue_open and job.dialogue_event == event,
        "Not the original First Wake JobScene dialogue for " + event)
    verify(stage.original_dialogue_panel.visible and
        stage.original_dialogue_line.text == str(job.dialogue_lines[0]),
        "3D panel is not showing original " + event + " dialogue")
    _complete(stage, event)

func _run() -> void:
    var stage = Stage.instantiate()
    root.add_child(stage)
    for i in range(15):
        await physics_frame
    var bridge = stage.authoritative_story_bridge
    var job = bridge.authoritative_job
    var session = bridge.authoritative_session
    var player = stage.navigation_body
    verify(bridge.bridge_ready and job.opening == session.opening,
        "Original story authority is not bound")
    verify(not stage.engineering_room_instantiated and stage.interaction_probes.size() == 3,
        "Unhired player received a real 3D engineering room")
    stage.authoritative_story_mode = true
    player.global_position = Vector3(-3.4, 0.1, -10.0)
    for i in range(6):
        await physics_frame
    verify(not stage.inspect_nearest_probe(), "Gangway permitted boarding before original hiring")
    verify(not stage.engineering_room_instantiated and job.room == "dock",
        "Early boarding constructed or opened engineering room")
    player.global_position = Vector3(0, 0.14, 6.8)
    for i in range(8):
        await physics_frame
    await _approach_and_interact(stage, "tstss_3d_forward", 174, "flyer")
    verify(job.flyer_read and job.opening.step_key() == "job_search",
        "Original First Wake flyer state lost")
    await _approach_and_interact(stage, "tstss_3d_forward", 93, "hire")
    verify(job.opening.active_party_ids == ["ender", "ionia"] and
        session.opening.step_key() == "engineering",
        "Original Ionia hiring was not completed")
    verify(not session.can_checkpoint(), "Hiring alone creates illegal save eligibility")
    # Move physically to the gangway from the actual Ionia approach.
    await _walk("tstss_3d_left", 50)
    await _walk("tstss_3d_backward", 35)
    for i in range(4):
        await physics_frame
    verify(player.global_position.x < -2.5 and player.is_on_floor(),
        "Real player did not physically reach gangway")
    verify(stage.inspect_nearest_probe(), "Real Area3D gangway refused a fully hired player")
    verify(job.room == "engineering", "Did not call original First Wake room transition")
    verify(stage.engineering_room_instantiated and stage.interaction_probes.size() == 7,
        "Room floor, physical stations and four Area3D interaction zones absent")
    verify(stage.camera_follow_navigation and stage.camera_distance <= 20.0,
        "Real 3D camera did not relocate to engineering interior")
    verify(stage.visual_root.get_node_or_null("WakeEngineRoom_EnclosedRoof") is MeshInstance3D,
        "Engineering ceiling remains open-air instead of spatially enclosed")
    verify(stage.visual_root.get_node_or_null("WakeEngineering_BackBulkheadUnpoweredRegulatorStudy") is MeshInstance3D,
        "3D back bulkhead lacks native engineering regulator composition")
    for lamp_id in range(4):
        verify(stage.get_node_or_null("WakeEngineering_SpatialLamp_%02d" % lamp_id) is OmniLight3D,
            "Real spatial ceiling lighting missing")
    verify(stage.camera.global_position.x > 52.0 and stage.camera.global_position.x < 64.0 and
        stage.camera.global_position.z < 11.2 and stage.camera.global_position.y < 4.1,
        "Native interior camera remains outside room or above engineering ceiling")
    for i in range(18):
        await physics_frame
    verify(player.is_on_floor() and player.global_position.x > 50.0,
        "Player not standing on genuine 3D engineering floor")
    var snap = bridge.story_snapshot()
    verify(snap.get("3d_engineering_room_ready") and snap.get("engineering_checks", []).is_empty(),
        "Original engineering state advanced before any inspection")
    verify(not bridge.interact_at_verified_probe("EngineeringSafety_ReviewOnly"),
        "Original safety checklist accepted before three inspections")
    verify(job.opening.step_key() == "engineering",
        "Safety checklist incorrectly completed preflight early")

    await _approach_and_interact(stage, "tstss_3d_forward", 60, "inspect_reference")
    verify(job.inspected_items == ["reference"] and session.opening.step_key() == "engineering",
        "Phase reference order or original state is incorrect")
    verify(not bridge.interact_at_verified_probe("EngineeringReference_ReviewOnly"),
        "Repeat reference inspection should fail closed")
    await _approach_and_interact(stage, "tstss_3d_forward", 60, "inspect_containment")
    verify(job.inspected_items == ["reference", "containment"],
        "Containment should only complete original inspection receipt")
    await _approach_and_interact(stage, "tstss_3d_forward", 58, "inspect_fuel")
    verify(job.inspected_items == ["reference", "containment", "fuel"],
        "Original fuel inspection or stage sequence broke")
    verify(session.opening.step_key() == "engineering",
        "Three inspections must not automatically authorize flight")
    await _approach_and_interact(stage, "tstss_3d_forward", 57, "preflight")
    verify(job.opening.step_key() == "preflight" and
        session.opening.step_key() == "preflight",
        "Original completed preflight dialogue did not advance single opening FSM")
    verify("3D flight is not yet implemented" in bridge.bridge_status,
        "3D scene falsely advertises unavailable F/flight control after preflight")
    verify(not bridge.interact_at_verified_probe("EngineeringFuel_ReviewOnly"),
        "Already completed preflight can reopen station incorrectly")
    verify(not session.can_checkpoint() and not session.physical_landing_observed and
        not session.reserve_inspected,
        "3D engineering forged water contact, reserve or save rights")
    verify(not job.flight_review and not stage.quality_snapshot().get("playable_chapter_one_3d_migrated"),
        "Actual flight was silently started or falsely declared migrated")
    verify(stage.quality_snapshot().get("3d_engineering_preflight_completed") and
        stage.quality_snapshot().get("3d_engineering_stations_present"),
        "3D scene fails to report physically completed engineering status")
    verify(stage.camera.global_position.z > stage.ENGINE_ROOM_ORIGIN.z - 1.0,
        "Engineering camera is aiming through the back bulkhead rather than showing room context")
    verify(stage.interaction_receipts.size() == 7,
        "Exactly seven physical story transitions expected: flyer, hire, gangway, 4 stations")
    stage.queue_free()
    await process_frame
    if failed.is_empty():
        print("TSTSS_3D_ENGINEERING_PASS checks=", count,
            " true_3d_walk=true physical_gangway=true 4_real_stations=true original_preflight=true checkpoint_held=true")
    quit(0 if failed.is_empty() else 1)
