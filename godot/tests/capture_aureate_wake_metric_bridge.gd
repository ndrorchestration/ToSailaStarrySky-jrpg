extends SceneTree
## Actual Godot native 960x640 renders of unified metric cabin/dome/foredeck.
const StudyScene = preload("res://scenes/aureate_wake_metric_bridge_study.tscn")
const ROOT := "res://review-evidence/aureate-wake-metric/"
var _errors: int = 0

func _initialize() -> void:
    call_deferred("_render")

func _capture(name: String) -> Image:
    for step in range(7):
        await process_frame
        await RenderingServer.frame_post_draw
    var shot: Image = root.get_texture().get_image()
    if shot == null or shot.get_size() != Vector2i(960, 640):
        push_error("AUREATE_WAKE_METRIC_CAPTURE_FAIL invalid actual viewport")
        _errors += 1
        return null
    var output: String = ProjectSettings.globalize_path(ROOT.path_join(name))
    if shot.save_png(output) != OK:
        push_error("AUREATE_WAKE_METRIC_CAPTURE_FAIL write: " + name)
        _errors += 1
        return null
    print("AUREATE_WAKE_METRIC_NATIVE_FRAME: ", name,
        " 960x640 ", FileAccess.get_sha256(output))
    return shot

func _render() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(ROOT)) != OK:
        push_error("AUREATE_WAKE_METRIC_CAPTURE_FAIL directory")
        quit(1)
        return
    var scene = StudyScene.instantiate()
    root.add_child(scene)
    await process_frame
    var cam: Camera3D = scene.get_node("MetricShipStudyCamera")

    # Source-identical framing, real transform of the physical hatch.
    cam.position = Vector3(7.1, 5.1, -7.4)
    cam.fov = 51.0
    cam.look_at(Vector3(0.0, 1.08, -1.45), Vector3.UP)
    scene.set_hatch_open(true)
    var open_img: Image = await _capture("metric-bridge-open.png")
    scene.set_hatch_open(false)
    await physics_frame
    var shut_img: Image = await _capture("metric-bridge-closed.png")
    scene.set_hatch_open(true)
    await physics_frame
    cam.position = Vector3(10.0, 9.0, 6.8)
    cam.fov = 55.0
    cam.look_at(Vector3(0.0, 0.90, -0.1), Vector3.UP)
    var layout: Image = await _capture("metric-cabin-and-deck.png")

    if open_img != null and shut_img != null:
        var different: int = 0
        for y in range(115, 590, 4):
            for x in range(170, 820, 4):
                if open_img.get_pixel(x, y) != shut_img.get_pixel(x, y):
                    different += 1
        if different < 30:
            push_error("AUREATE_WAKE_METRIC_CAPTURE_FAIL door not visible in actual GL capture")
            _errors += 1
        else:
            print("AUREATE_WAKE_METRIC_DOOR_AB_PASS changed_grid=", different)
    if layout == null:
        _errors += 1
    scene.queue_free()
    await process_frame
    if _errors == 0:
        print("AUREATE_WAKE_METRIC_RENDER_PASS shots=3",
            " scene=ISOLATED_NONCANON")
        quit(0)
    else:
        quit(1)
