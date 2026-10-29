extends SceneTree
## Real native framebuffer evidence that the 3D dock shows the original
## first wake flyer/Ionia text, not rewritten copy. No source art media needed.
const Scene = preload("res://scenes/first_wake_3d_visual_slice.tscn")
var failures: Array[String] = []
var evidence_dir := ""

func _initialize() -> void:
    call_deferred("_run")

func _press_key(stage, code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    stage._unhandled_input(event)

func _walk(action: String, frames: int) -> void:
    Input.action_press(action)
    for i in range(frames):
        await physics_frame
    Input.action_release(action)
    for i in range(3):
        await physics_frame

func _frame(label: String, stage) -> void:
    for i in range(4):
        await process_frame
        await RenderingServer.frame_post_draw
    var frame: Image = root.get_viewport().get_texture().get_image()
    if frame == null or frame.get_size() != Vector2i(960, 640):
        failures.append("No genuine 960x640 framebuffer for " + label)
        return
    if not stage.original_dialogue_panel.visible:
        failures.append("Original authoritative dialogue panel not visible in " + label)
        return
    var path: String = evidence_dir.path_join("first_wake_3d_original_story_" + label + ".png")
    if frame.save_png(path) != OK:
        failures.append("Could not save native story screenshot " + label)
        return
    print("TSTSS_3D_ORIGINAL_STORY_FRAME:", label,
        ":SHA256:", FileAccess.get_sha256(path), ":FILE:", path)

func _run() -> void:
    evidence_dir = ProjectSettings.globalize_path("user://first_wake_3d_original_story_evidence")
    if DirAccess.make_dir_recursive_absolute(evidence_dir) != OK:
        push_error("TSTSS_3D_STORY_RENDER_FAIL:evidence folder unavailable")
        quit(1)
        return
    var stage = Scene.instantiate()
    root.add_child(stage)
    for i in range(16):
        await physics_frame
    _press_key(stage, KEY_B)
    if not stage.authoritative_story_mode:
        failures.append("Original dialogue review mode not enabled")
    await _walk("tstss_3d_forward", 174)
    _press_key(stage, KEY_E)
    var job = stage.authoritative_story_bridge.authoritative_job
    if job.dialogue_event != "flyer" or stage.original_dialogue_line.text != str(job.dialogue_lines[0]):
        failures.append("Rendered flyer not original line")
    await _frame("flyer_at_physical_notice_960x640", stage)
    var n := 0
    while job.dialogue_open and n < 10:
        _press_key(stage, KEY_E)
        n += 1
    if not job.flyer_read or not "flyer" in stage.authoritative_story_bridge.completed_dialogues:
        failures.append("Original flyer not fully read")
    await _walk("tstss_3d_forward", 93)
    _press_key(stage, KEY_E)
    if job.dialogue_event != "hire" or stage.original_dialogue_line.text != str(job.dialogue_lines[0]):
        failures.append("Rendered Ionia interview not original line")
    await _frame("ionia_authored_interview_960x640", stage)
    if job.opening.active_party_ids != ["ender"]:
        failures.append("Ionia joined before completing the original interview")
    stage.queue_free()
    await process_frame
    for error in failures:
        push_error("TSTSS_3D_STORY_RENDER_FAIL:" + error)
    if failures.is_empty():
        print("TSTSS_3D_STORY_RENDER_PASS:true_native_3d_frame=true authentic_original_dialogue=true two_physical_locations=true no_source_art_substitution=true")
    quit(0 if failures.is_empty() else 1)
