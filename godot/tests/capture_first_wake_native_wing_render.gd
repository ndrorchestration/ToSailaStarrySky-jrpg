extends SceneTree
## Three genuine native screenshots in real Ionia-first engineering scene:
## test-only view disabled, same scene with original 3D rig neutral, rig swept.
const Scene = preload("res://scenes/first_wake_job_preview.tscn")
const Port = preload("res://scripts/first_wake_ship_visual_pose_port.gd")
const OUTPUT := "res://review-evidence/ship-wing-3d/"
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_capture")

func finish_dialogue(world: Node) -> bool:
    for i in range(20):
        if not world.dialogue_open:
            return true
        if not world.interact():
            return false
    return false

func capture(name: String) -> Image:
    for frame in range(9):
        await process_frame
        await RenderingServer.frame_post_draw
    var shot: Image = root.get_texture().get_image()
    if shot.is_empty() or shot.get_size() != Vector2i(960, 640):
        failures.append("invalid viewport image " + name)
        return null
    var target: String = OUTPUT.path_join(name + ".png")
    if shot.save_png(ProjectSettings.globalize_path(target)) != OK:
        failures.append("failed PNG write " + name)
        return null
    print("FIRST_WAKE_NATIVE_WING_CAPTURE: ", name, " 960x640 ",
        FileAccess.get_sha256(ProjectSettings.globalize_path(target)))
    return shot

func sample_difference(a: Image, b: Image) -> int:
    var changed: int = 0
    for y in range(252, 463, 3):
        for x in range(553, 934, 3):
            var p: Color = a.get_pixel(x, y)
            var q: Color = b.get_pixel(x, y)
            var delta: float = absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b)
            if delta > 0.055:
                changed += 1
    return changed

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world = Scene.instantiate()
    root.add_child(world)
    await process_frame
    world.ender.set_physics_process(false)
    world.ionia.set_physics_process(false)
    world.ender.position = world.FLYER_POSITION
    if not world.interact() or not finish_dialogue(world):
        failures.append("flyer not available")
    world.ender.position = world.IONIA_DOCK_POSITION
    if not world.interact() or not finish_dialogue(world):
        failures.append("Ionia hiring not available")
    world.ender.position = world.GANGWAY_POSITION
    if not world.interact() or world.room != "engineering":
        failures.append("gangway not available")
    if not world.set_ship_spaces_review_enabled(true):
        failures.append("ship-space opt-in unavailable")
    if DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(OUTPUT)) != OK:
        failures.append("evidence directory could not be created")
    if not failures.is_empty():
        for f in failures:
            push_error("FIRST_WAKE_NATIVE_WING_CAPTURE_FAIL: " + f)
        quit(1)
        return

    var before: Dictionary = world.opening.snapshot()
    var checkpoint: Dictionary = world.export_revised_checkpoint()
    var original: Image = await capture("no-3d-review")
    if not world.set_ship_pose_3d_review_enabled(true):
        failures.append("3D renderer not attached")
    var neutral: Image = await capture("original-wings-neutral")
    if not world.request_ship_pose_3d_review(Port.CUE_GENTLE_SWEEP):
        failures.append("real wing rig refused ordinary pose")
    if not world.advance_ship_pose_3d_review(0.9, false):
        failures.append("wing rig failed midpoint")
    var halfway: Image = await capture("original-wings-midpoint")
    if not world.advance_ship_pose_3d_review(0.9, false):
        failures.append("wing rig did not finish visual motion")
    var sweep: Image = await capture("original-wings-swept")
    var onset_pixels: int = 0
    var moving_pixels: int = 0
    var continuation_pixels: int = 0
    if original != null and neutral != null and halfway != null and sweep != null:
        onset_pixels = sample_difference(original, neutral)
        moving_pixels = sample_difference(neutral, halfway)
        continuation_pixels = sample_difference(halfway, sweep)
        if onset_pixels < 400:
            failures.append("real 3D renderer not visibly present in chapter")
        if moving_pixels < 30 or continuation_pixels < 30:
            failures.append("both real 3D wing motion stages must be visible")
    if (before != world.opening.snapshot()
            or checkpoint != world.export_revised_checkpoint()):
        failures.append("rendering changed real Chapter I/save state")
    world.set_ship_spaces_review_enabled(false)
    if world.ship_pose_3d_review != null:
        failures.append("3D rig remained active after opt-out")
    world.queue_free()
    await process_frame
    if failures.is_empty():
        print("FIRST_WAKE_NATIVE_WING_AB_PASS frames=4 inset_on_grid=",
            onset_pixels, " wing_mid_grid=", moving_pixels,
            " wing_end_grid=", continuation_pixels,
            " story=UNCHANGED renderer=REAL_3D scale=BLOCKED")
        quit(0)
    else:
        for f in failures:
            push_error("FIRST_WAKE_NATIVE_WING_CAPTURE_FAIL: " + f)
        quit(1)
