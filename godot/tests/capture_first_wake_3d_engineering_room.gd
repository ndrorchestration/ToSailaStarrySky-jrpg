extends SceneTree
## Native 960x640 spatial evidence. All transitions are actual walk/Area3D/
## original First Wake JobScene.interact, never a standalone fake room picture.
const Stage = preload("res://scenes/first_wake_3d_visual_slice.tscn")
var failures: Array[String] = []
var directory := ""

func _initialize() -> void:
    call_deferred("_run")

func _walk(action: String, frames: int) -> void:
    Input.action_press(action)
    for i in range(frames):
        await physics_frame
    Input.action_release(action)
    for i in range(4):
        await physics_frame

func _finish(stage, event: String) -> void:
    var job = stage.authoritative_story_bridge.authoritative_job
    var cursor := 0
    while job.dialogue_open and cursor < 16:
        if not stage.inspect_nearest_probe():
            failures.append("Original dialogue could not advance: " + event)
            break
        cursor += 1
    if event not in stage.authoritative_story_bridge.completed_dialogues:
        failures.append("Authored original dialogue event did not finish: " + event)

func _frame(stage, name: String) -> void:
    for i in range(5):
        await process_frame
        await RenderingServer.frame_post_draw
    var img: Image = root.get_viewport().get_texture().get_image()
    if img == null or img.get_size() != Vector2i(960, 640):
        failures.append("Native 960x640 framebuffer unavailable at " + name)
        return
    var path: String = directory.path_join("first_wake_actual_engineering_" + name + ".png")
    if img.save_png(path) != OK:
        failures.append("Could not save native frame " + name)
        return
    print("TSTSS_3D_ENGINEERING_FRAME:", name,
        ":SHA256:", FileAccess.get_sha256(path), ":FILE:", path)

func _run() -> void:
    directory = ProjectSettings.globalize_path("user://first_wake_actual_engineering_evidence")
    if DirAccess.make_dir_recursive_absolute(directory) != OK:
        push_error("TSTSS_3D_ENGINEERING_RENDER_FAIL:cannot create output folder")
        quit(1)
        return
    var stage = Stage.instantiate()
    root.add_child(stage)
    for i in range(18):
        await physics_frame
    stage.authoritative_story_mode = true
    await _walk("tstss_3d_forward", 174)
    if not stage.inspect_nearest_probe():
        failures.append("Original physical flyer was not activated")
    _finish(stage, "flyer")
    await _walk("tstss_3d_forward", 93)
    if not stage.inspect_nearest_probe():
        failures.append("Original physical Ionia interview was not activated")
    _finish(stage, "hire")
    await _walk("tstss_3d_left", 50)
    await _walk("tstss_3d_backward", 35)
    if not stage.inspect_nearest_probe() or not stage.engineering_room_instantiated:
        failures.append("Original physical gangway did not open 3D engineering")
    for i in range(35):
        await physics_frame
    if not stage.navigation_body.is_on_floor():
        failures.append("Engineering player is not supported by real 3D floor")
    stage._update_camera()
    await _frame(stage, "room_entry_960x640")
    await _walk("tstss_3d_forward", 60)
    if not stage.inspect_nearest_probe():
        failures.append("Phase reference 3D Area3D was not activated")
    var job = stage.authoritative_story_bridge.authoritative_job
    if job.dialogue_event != "inspect_reference":
        failures.append("Engineering did not show original phase reference dialogue")
    await _frame(stage, "source_reference_dialogue_960x640")
    _finish(stage, "inspect_reference")
    for steps in [60, 58, 57]:
        await _walk("tstss_3d_forward", steps)
        if not stage.inspect_nearest_probe():
            failures.append("Original engineering event inaccessible at station")
        _finish(stage, job.dialogue_event)
    if job.opening.step_key() != "preflight":
        failures.append("Original First Wake preflight state not reached")
    if stage.authoritative_story_bridge.authoritative_session.can_checkpoint():
        failures.append("Engineering forged postflight checkpoint")
    stage._update_camera()
    await _frame(stage, "completed_preflight_960x640")
    stage.queue_free()
    await process_frame
    for failure in failures:
        push_error("TSTSS_3D_ENGINEERING_RENDER_FAIL:" + failure)
    if failures.is_empty():
        print("TSTSS_3D_ENGINEERING_RENDER_PASS:frames=3 true_spatial_physics=true authored_dialogue=true original_preflight=true save_held=true")
    quit(0 if failures.is_empty() else 1)
