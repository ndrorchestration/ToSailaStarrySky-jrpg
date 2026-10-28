extends SceneTree
## Physics-backed native 3D controller and E interaction acceptance.
## NO canonical Ionia First Wake dialogue, save, party or ship unlock is mutated.
const Scene = preload("res://scenes/first_wake_3d_visual_slice.tscn")
var failures: Array[String] = []
var assertions := 0

func check(ok: bool, message: String) -> void:
    assertions += 1
    if not ok:
        failures.append(message)
        push_error("TSTSS_NAVIGATION_3D_FAIL:" + message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    check(ProjectSettings.get_setting("application/run/main_scene") ==
        "res://scenes/first_wake_game.tscn", "normal F5 playable chapter entry changed")
    var stage = Scene.instantiate()
    root.add_child(stage)
    for i in range(12):
        await physics_frame
    var player: CharacterBody3D = stage.navigation_body
    check(player is CharacterBody3D, "no native 3D physics player")
    check(player.collision_layer == 2 and player.collision_mask == 1,
        "physics/mask isolation against pier is broken")
    check(player.get_node("MeasuredHumanFootprintForFutureGLB") is CollisionShape3D,
        "real capsule collider absent")
    check(player.get_node("VisualAnchor_ApprovedCharacterGLBWillAttachHere") is Node3D,
        "approved future rigged GLB attachment point absent")
    check(player.get_node("VisualAnchor_ApprovedCharacterGLBWillAttachHere").get_child(0).name ==
        "ExplicitNonCharacterFootprintCursor",
        "missing model was faked instead of explicit review locator")
    check(stage.interaction_probes.size() == 3, "three real spatial inspection probes not found")
    check(stage.physics_root.get_child_count() == 8,
        "physical dock, two rails, plaza, one actor and three areas incomplete")
    var floor_count := 0
    for child in stage.physics_root.get_children():
        if child is StaticBody3D:
            floor_count += 1
            check(child.get_child_count() == 1 and child.get_child(0) is CollisionShape3D,
                "real static collider not bound to geometry bounds")
        if child is Area3D:
            check(child.collision_mask == 2 and child.get_child(0) is CollisionShape3D,
                "interaction region does not detect real player body")
    check(floor_count == 4, "actual floor and boundary physics body count wrong")
    check(player.is_on_floor(), "player not supported by actual 3D floor after gravity settled")
    check(absf(player.global_position.y - 0.10) < 0.25,
        "initial boot anchor not aligned with physical pier")
    var baseline_z: float = player.global_position.z
    var input_action := "tstss_3d_forward"
    check(InputMap.has_action(input_action), "3D WASD actions not registered")
    Input.action_press(input_action)
    for i in range(174):
        await physics_frame
    Input.action_release(input_action)
    for i in range(4):
        await physics_frame
    var displacement: float = baseline_z - player.global_position.z
    check(displacement > 10.0, "W input did not physically walk actual 3D player")
    check(player.travel_facing == "north", "walk input did not resolve north orientation")
    check(player.traveled_distance > 10.0, "travel not measured by real body displacement")
    check(player.is_on_floor(), "controller lost true pier support during travel")
    check(player.ground_contact_frames > 120, "floor collision not sustained during walking")
    check(stage.inspect_nearest_probe(), "real Area3D notice did not detect walking player")
    check(stage.interaction_receipts.back() == "NoticeBoard_ReviewOnly",
        "notice inspection hit wrong 3D probe")
    check("Canonical job-flyer dialogue" in stage.navigation_status.text,
        "spatial inspection misrepresented narrative authority")
    var notice_count: int = stage.interaction_receipts.size()
    Input.action_press(input_action)
    for i in range(93):
        await physics_frame
    Input.action_release(input_action)
    for i in range(3):
        await physics_frame
    check(player.global_position.z < -10.7, "unable to walk toward actual Ionia arrival region")
    check(stage.inspect_nearest_probe(), "physics Ionia spatial interaction unavailable")
    check(stage.interaction_receipts.back() == "IoniaArrival_ReviewOnly",
        "3D Ionia reference point lost despite correct physical approach")
    check(stage.interaction_receipts.size() == notice_count + 1,
        "inspection failed to record isolated event receipt")
    check("pending" in stage.navigation_status.text,
        "Ionia 3D interaction incorrectly claims character art/quest readiness")

    # Actual collision test against the physical edge protection; no teleport.
    var start_x: float = player.global_position.x
    Input.action_press("tstss_3d_right")
    for i in range(125):
        await physics_frame
    Input.action_release("tstss_3d_right")
    await physics_frame
    check(player.global_position.x > start_x + 2.5, "D input did not move right")
    check(player.global_position.x < 4.4, "true safety rail failed; player moved over water")
    check(player.is_on_floor(), "actor crossed dock boundary into unsupported sea")
    var follow_key := InputEventKey.new()
    follow_key.keycode = KEY_C
    follow_key.pressed = true
    stage._unhandled_input(follow_key)
    check(stage.camera_follow_navigation, "C key did not enable orbit camera following")
    check(stage.camera is Camera3D and stage.camera.current,
        "3D player camera was replaced by non-3D view")
    stage._unhandled_input(follow_key)
    check(not stage.camera_follow_navigation, "C cannot restore static artwork comparison")
    var end_state: Dictionary = stage.quality_snapshot()
    check(end_state.get("navigation_3d_ready") and
        int(end_state.get("interactive_probes", 0)) == 3,
        "3D navigation readiness incorrectly reported")
    check(not end_state.get("chapter_1_3d_story_connected") and
        not end_state.get("3d_debug_marker_is_character_art"),
        "test scene claimed canonical story or creator-approved hero art")
    check(not end_state.get("playable_chapter_one_3d_migrated"),
        "native 3D physics wrongly marked full game migrated")
    check(player.movement_snapshot().get("story_authority") == false,
        "review controller was granted narrative state authority")
    stage.queue_free()
    await process_frame
    if failures.is_empty():
        print("TSTSS_NAVIGATION_3D_PASS checks=", assertions,
            " real_CharacterBody3D=true actual_pier_collision=true WASD_physical=true Area3D_inspection=true story_untouched=true")
    quit(0 if failures.is_empty() else 1)
