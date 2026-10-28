extends SceneTree
## Actual Godot Compatibility renders of a physically walking crew capsule.
## Anonymous prototype avatar is never presented as an approved protagonist.
const Study = preload("res://scenes/aureate_wake_metric_bridge_study.tscn")
const OUTPUT := "res://review-evidence/aureate-wake-crew-walk/"
var problems: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _walk_to(actor: CharacterBody3D, destination_z: float) -> bool:
    actor.set_test_direction(Vector2(0, -1))
    var arrived: bool = false
    for step in range(230):
        await physics_frame
        if actor.position.z <= destination_z:
            arrived = true
            break
    actor.set_test_direction(Vector2.ZERO)
    await physics_frame
    return arrived

func _frame(file_name: String) -> Image:
    for cycle in range(7):
        await process_frame
        await RenderingServer.frame_post_draw
    var img: Image = root.get_texture().get_image()
    if img.is_empty() or img.get_size() != Vector2i(960, 640):
        problems.append("invalid_native_960x640_" + file_name)
        return null
    var path: String = ProjectSettings.globalize_path(OUTPUT.path_join(file_name))
    if img.save_png(path) != OK:
        problems.append("failed_to_write_" + file_name)
        return null
    print("AUREATE_WAKE_CREW_NATIVE_FRAME: ", file_name,
        " 960x640 sha256=", FileAccess.get_sha256(path))
    return img

func _run() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("AUREATE_WAKE_CREW_CAPTURE_FAIL cannot create evidence path")
        quit(1)
        return
    var ship = Study.instantiate()
    root.add_child(ship)
    await process_frame
    var actor = ship.crew_walker
    actor.manual_controls_enabled = false
    actor.set_test_direction(Vector2.ZERO)
    for cycle in range(30):
        await physics_frame
    var camera: Camera3D = ship.get_node("MetricShipStudyCamera")
    camera.position = Vector3(4.3, 3.4, -5.1)
    camera.fov = 42.0
    camera.look_at(Vector3(0.0, 1.04, -2.58), Vector3.UP)

    if not await _walk_to(actor, -1.62):
        problems.append("actor_cannot_reach_helm")
    ship.set_hatch_open(false)
    await physics_frame
    var closed: Image = await _frame("crew-at-helm-hatch-closed.png")
    ship.set_hatch_open(true)
    await physics_frame
    var open_image: Image = await _frame("crew-at-helm-hatch-open.png")
    if not await _walk_to(actor, -4.35):
        problems.append("actor_cannot_reach_foredeck")
    var deck: Image = await _frame("crew-walked-onto-foredeck.png")
    if closed != null and open_image != null:
        var delta: int = 0
        for y in range(120, 585, 4):
            for x in range(170, 820, 4):
                if closed.get_pixel(x, y) != open_image.get_pixel(x, y):
                    delta += 1
        if delta < 80:
            problems.append("physical_hatch_state_not_visible")
        print("AUREATE_WAKE_CREW_HATCH_AB_DELTA=", delta)
    if deck == null:
        problems.append("no_deck_render")
    if not actor.is_on_floor() or actor.position.z > -4.20:
        problems.append("actor_was_not_on_real_open_deck")
    ship.queue_free()
    await process_frame
    if problems.is_empty():
        print("AUREATE_WAKE_CREW_RENDER_PASS shots=3 actor=PHYSICS_MOVED")
        quit(0)
    else:
        for problem in problems:
            push_error("AUREATE_WAKE_CREW_CAPTURE_FAIL " + problem)
        quit(1)
