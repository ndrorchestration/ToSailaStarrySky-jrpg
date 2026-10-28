extends SceneTree
## Native 960x640 opt-in A/B capture of the REAL Ionia-first engineering scene.
## Review plate is not a source asset imported from the flight-lab 3D project.
const Preview = preload("res://scenes/first_wake_job_preview.tscn")
const OUTPUT := "res://review-evidence/ship-space-handoff/"
var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _finish_dialogue(world: Node) -> bool:
    for step in range(20):
        if not world.dialogue_open:
            return true
        if not world.interact():
            return false
    return false

func _save(name: String) -> Image:
    for frame in range(6):
        await process_frame
        await RenderingServer.frame_post_draw
    var shot: Image = root.get_texture().get_image()
    if shot.is_empty() or shot.get_size() != Vector2i(960, 640):
        push_error("SHIP_SPACES_CAPTURE_FAIL: wrong Godot viewport")
        failures += 1
        return null
    var file: String = OUTPUT.path_join(name)
    var full_path: String = ProjectSettings.globalize_path(file)
    if shot.save_png(full_path) != OK:
        push_error("SHIP_SPACES_CAPTURE_FAIL: could not save " + name)
        failures += 1
        return null
    print("NATIVE_SHIP_SPACE_HANDOFF_CAPTURE: ", name,
        " 960x640 ", FileAccess.get_sha256(full_path))
    return shot

func _run() -> void:
    root.size = Vector2i(960, 640)
    var world = Preview.instantiate()
    root.add_child(world)
    await process_frame
    world.ender.set_physics_process(false)
    world.ionia.set_physics_process(false)
    world.ender.position = world.FLYER_POSITION
    if not world.interact() or not _finish_dialogue(world):
        push_error("SHIP_SPACES_CAPTURE_FAIL: flyer")
        quit(1)
        return
    world.ender.position = world.IONIA_DOCK_POSITION
    if not world.interact() or not _finish_dialogue(world):
        push_error("SHIP_SPACES_CAPTURE_FAIL: interview")
        quit(1)
        return
    world.ender.position = world.GANGWAY_POSITION
    if not world.interact() or world.room != "engineering":
        push_error("SHIP_SPACES_CAPTURE_FAIL: gangway")
        quit(1)
        return
    if DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("SHIP_SPACES_CAPTURE_FAIL: output directory")
        quit(1)
        return
    if world.ship_spaces_handoff.visible:
        push_error("SHIP_SPACES_CAPTURE_FAIL: unwanted default-on view")
        quit(1)
        return

    var story_before: Dictionary = world.opening.snapshot()
    var checkpoint_before: Dictionary = world.export_revised_checkpoint()
    var off: Image = await _save("engineering-original.png")
    if not world.set_ship_spaces_review_enabled(true):
        push_error("SHIP_SPACES_CAPTURE_FAIL: approved opt-in refused")
        quit(1)
        return
    var on: Image = await _save("engineering-spaces-review.png")
    if off == null or on == null:
        quit(1)
        return
    # All visual difference comes from opt-in overlay in upper-right corner.
    var changed: int = 0
    for y in range(37, 196, 3):
        for x in range(592, 935, 3):
            if off.get_pixel(x, y) != on.get_pixel(x, y):
                changed += 1
    if changed < 1000:
        push_error("SHIP_SPACES_CAPTURE_FAIL: actual on-screen review image barely changed")
        failures += 1
    if (story_before != world.opening.snapshot()
            or checkpoint_before != world.export_revised_checkpoint()):
        push_error("SHIP_SPACES_CAPTURE_FAIL: screenshot toggle mutated real story/save")
        failures += 1
    world.set_ship_spaces_review_enabled(false)
    if world.ship_spaces_handoff.visible:
        push_error("SHIP_SPACES_CAPTURE_FAIL: opt-in panel persisted after disable")
        failures += 1
    world.queue_free()
    await process_frame
    if failures == 0:
        print("FIRST_WAKE_SHIP_SPACE_AB_PASS changed_grid=", changed,
            " story=UNCHANGED layout=REVIEW_ONLY")
        quit(0)
    else:
        quit(1)
