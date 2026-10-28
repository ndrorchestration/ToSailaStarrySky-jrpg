extends SceneTree
## Actual Godot rendering A/B of SAME PHYSICS guards, two visual treatments.
const ShipScene = preload("res://scenes/aureate_wake_metric_bridge_study.tscn")
const PATH := "res://review-evidence/aureate-wake-architecture/"
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _capture(file_name: String) -> Image:
    for i in range(6):
        await process_frame
        await RenderingServer.frame_post_draw
    var img: Image = root.get_texture().get_image()
    if img == null or img.get_size() != Vector2i(960, 640):
        errors.append("invalid viewport " + file_name)
        return null
    var location: String = ProjectSettings.globalize_path(
        PATH.path_join(file_name))
    if img.save_png(location) != OK:
        errors.append("could not write " + file_name)
        return null
    print("AUREATE_WAKE_ARCHITECTURE_NATIVE_FRAME: ", file_name,
        " 960x640 sha256=", FileAccess.get_sha256(location))
    return img

func _run() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(PATH)) != OK:
        push_error("AUREATE_WAKE_ARCHITECTURE_CAPTURE_FAIL directory")
        quit(1)
        return
    var ship = ShipScene.instantiate()
    root.add_child(ship)
    await process_frame
    var actor = ship.crew_walker
    actor.manual_controls_enabled = false
    actor.set_test_direction(Vector2.ZERO)
    var camera: Camera3D = ship.get_node("MetricShipStudyCamera")
    camera.position = Vector3(3.25, 3.10, -7.35)
    camera.fov = 49.0
    camera.look_at(Vector3(0, 0.75, -4.35), Vector3.UP)
    var trim = ship.get_node("AureateMaritimeRailArtReview")
    trim.set_design_review_enabled(false)
    var old_image: Image = await _capture("legacy-five-level-fence.png")
    trim.set_design_review_enabled(true)
    var new_image: Image = await _capture("maritime-timber-brass-rails.png")
    if old_image != null and new_image != null:
        var changed: int = 0
        for y in range(85, 595, 3):
            for x in range(100, 870, 3):
                if old_image.get_pixel(x, y) != new_image.get_pixel(x, y):
                    changed += 1
        print("AUREATE_WAKE_ARCHITECTURE_AB_CHANGED=", changed)
        if changed < 300:
            errors.append("rail visual treatment does not materially change image")
    ship.set_glass_art_review("source_low_glare")
    camera.position = Vector3(6.60, 5.20, -7.50)
    camera.fov = 50
    camera.look_at(Vector3(0, 1.15, -2.35), Vector3.UP)
    var full: Image = await _capture("icosphere-and-maritime-rail-overview.png")
    if full == null:
        errors.append("missing full ship visual")
    ship.queue_free()
    await process_frame
    if errors.is_empty():
        print("AUREATE_WAKE_ARCHITECTURE_RENDER_PASS shots=3",
            " source=ACTUAL_GODOT",
            " physics=UNCHANGED",
            " production=BLOCKED")
        quit(0)
    else:
        for failure in errors:
            push_error("AUREATE_WAKE_ARCHITECTURE_CAPTURE_FAIL: " + failure)
        quit(1)
