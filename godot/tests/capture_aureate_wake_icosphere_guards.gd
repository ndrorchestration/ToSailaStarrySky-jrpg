extends SceneTree
## Genuine software-GL views of PR #471-derived METRIC icosphere and guard infill.
const Study = preload("res://scenes/aureate_wake_metric_bridge_study.tscn")
const OUTPUT := "res://review-evidence/aureate-wake-icosphere-guards/"
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _shot(name: String) -> Image:
    for tick in range(7):
        await process_frame
        await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image.is_empty() or image.get_size() != Vector2i(960, 640):
        failures.append("invalid_960x640_" + name)
        return null
    var path: String = ProjectSettings.globalize_path(OUTPUT.path_join(name))
    if image.save_png(path) != OK:
        failures.append("could_not_write_" + name)
        return null
    print("AUREATE_WAKE_ICOSPHERE_NATIVE_FRAME: ", name,
        " 960x640 sha256=", FileAccess.get_sha256(path))
    return image

func _run() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("AUREATE_WAKE_ICOSPHERE_CAPTURE_FAIL output")
        quit(1)
        return
    var ship = Study.instantiate()
    root.add_child(ship)
    await process_frame
    var actor = ship.crew_walker
    actor.manual_controls_enabled = false
    actor.set_test_direction(Vector2.ZERO)
    var cam: Camera3D = ship.get_node("MetricShipStudyCamera")
    cam.position = Vector3(5.8, 4.3, -6.4)
    cam.fov = 48
    cam.look_at(Vector3(0, 1.1, -1.75), Vector3.UP)
    ship.set_glass_art_review("source_clear")
    ship.set_hatch_open(true)
    var main: Image = await _shot("source-icosphere-helm-and-guards.png")
    ship.set_glass_art_review("source_low_glare")
    var low: Image = await _shot("source-icosphere-low-glare.png")
    cam.position = Vector3(3.2, 2.8, -7.1)
    cam.fov = 55
    cam.look_at(Vector3(0.0, 0.76, -4.0), Vector3.UP)
    var rails: Image = await _shot("physically-collidable-bow-infill.png")
    if main != null and low != null:
        var changed: int = 0
        for y in range(55, 575, 4):
            for x in range(70, 800, 4):
                if main.get_pixel(x, y) != low.get_pixel(x, y):
                    changed += 1
        print("AUREATE_WAKE_ICOSPHERE_GLASS_DELTA=", changed)
        if changed < 100:
            failures.append("glass_profiles_not_visually_different")
    if rails == null:
        failures.append("missing_rail_infill_render")
    ship.queue_free()
    await process_frame
    if failures.is_empty():
        print("AUREATE_WAKE_ICOSPHERE_RENDER_PASS shots=3",
            " visual=REVIEW_ONLY production=BLOCKED")
        quit(0)
    else:
        for f in failures:
            push_error("AUREATE_WAKE_ICOSPHERE_CAPTURE_FAIL " + f)
        quit(1)
