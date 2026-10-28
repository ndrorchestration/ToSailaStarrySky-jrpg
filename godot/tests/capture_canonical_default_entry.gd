extends SceneTree
# Render exact configured startup scene, not an alternate scripted story fixture.
func _initialize() -> void:
    call_deferred("_capture")
func _capture() -> void:
    var scene_path: String = str(ProjectSettings.get_setting("application/run/main_scene", ""))
    if scene_path != "res://scenes/first_wake_job_preview.tscn":
        push_error("CH1_STARTUP_CAPTURE_FAIL: noncanonical entry")
        quit(1)
        return
    var scene = load(scene_path).instantiate()
    root.size = Vector2i(960, 640)
    root.add_child(scene)
    current_scene = scene
    await process_frame
    await RenderingServer.frame_post_draw
    var frame = root.get_texture().get_image()
    if frame.is_empty() or frame.get_width() != 960 or frame.get_height() != 640:
        push_error("CH1_STARTUP_CAPTURE_FAIL: invalid viewport")
        quit(2)
        return
    var output: String = ProjectSettings.globalize_path("res://review-evidence/chapter1-startup-candidate/ionia-default-startup-960x640.png")
    DirAccess.make_dir_recursive_absolute(output.get_base_dir())
    if frame.save_png(output) != OK:
        push_error("CH1_STARTUP_CAPTURE_FAIL: save failed")
        quit(3)
        return
    print("TSTSS_IONIA_DEFAULT_NATIVE_RENDER_PASS:960x640:" + FileAccess.get_sha256(output))
    quit(0)
