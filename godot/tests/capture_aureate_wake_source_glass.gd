extends SceneTree
## Same-pose Godot 4.7.2 GL screenshots for exact source shader vs low-glare.
const StudyScene = preload("res://scenes/aureate_wake_metric_bridge_study.tscn")
const OUTPUT := "res://review-evidence/aureate-wake-source-glass/"
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_capture")

func _shot(name: String) -> Image:
    for t in range(7):
        await process_frame
        await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image.is_empty() or image.get_size() != Vector2i(960, 640):
        failures.append("invalid_gl_frame_" + name)
        return null
    var path: String = ProjectSettings.globalize_path(OUTPUT.path_join(name))
    if image.save_png(path) != OK:
        failures.append("write_failed_" + name)
        return null
    print("AUREATE_WAKE_GLASS_NATIVE_FRAME: ", name,
        " 960x640 sha256=", FileAccess.get_sha256(path))
    return image

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("AUREATE_WAKE_SOURCE_GLASS_CAPTURE_FAIL could not create folder")
        quit(1)
        return
    var ship = StudyScene.instantiate()
    root.add_child(ship)
    await process_frame
    ship.crew_walker.manual_controls_enabled = false
    ship.crew_walker.set_test_direction(Vector2.ZERO)
    ship.set_hatch_open(true)
    var cam: Camera3D = ship.get_node("MetricShipStudyCamera")
    cam.position = Vector3(3.8, 3.15, -5.60)
    cam.fov = 44.0
    cam.look_at(Vector3(0.0, 1.30, -1.90), Vector3.UP)
    if not ship.set_glass_art_review("source_clear"):
        failures.append("source_clear_unavailable")
    var clear: Image = await _shot("source-glass-clear.png")
    if not ship.set_glass_art_review("source_low_glare"):
        failures.append("source_low_glare_unavailable")
    var low: Image = await _shot("source-glass-low-glare.png")
    if clear != null and low != null:
        var delta: int = 0
        for y in range(40, 565, 3):
            for x in range(70, 680, 3):
                if clear.get_pixel(x, y) != low.get_pixel(x, y):
                    delta += 1
        print("AUREATE_WAKE_GLASS_AB_DELTA=", delta)
        if delta < 110:
            failures.append("source_shader_profile_not_visibly_different")
    ship.set_glass_art_review("metric_proxy")
    ship.queue_free()
    await process_frame
    if failures.is_empty():
        print("AUREATE_WAKE_SOURCE_GLASS_RENDER_PASS shots=2 source=EXACT_REVIEW_ONLY")
        quit(0)
    else:
        for problem in failures:
            push_error("AUREATE_WAKE_SOURCE_GLASS_CAPTURE_FAIL " + problem)
        quit(1)
