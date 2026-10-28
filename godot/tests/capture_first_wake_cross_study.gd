extends SceneTree
## Matched Godot screenshots for cross-branch real art: original wing rig,
## source-exact deck and dome, moving wings. Geometry remains NONADMITTED.
const Scene = preload("res://scenes/first_wake_job_preview.tscn")
const Port = preload("res://scripts/first_wake_ship_visual_pose_port.gd")
const OUTPUT := "res://review-evidence/ship-geometry-cross-study/"
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _finish_dialogue(world: Node) -> bool:
    for i in range(20):
        if not world.dialogue_open:
            return true
        if not world.interact():
            return false
    return false

func _image(name: String) -> Image:
    for i in range(9):
        await process_frame
        await RenderingServer.frame_post_draw
    var screenshot: Image = root.get_texture().get_image()
    if screenshot.is_empty() or screenshot.get_size() != Vector2i(960, 640):
        failures.append("invalid source screenshot " + name)
        return null
    var path: String = ProjectSettings.globalize_path(OUTPUT.path_join(name + ".png"))
    if screenshot.save_png(path) != OK:
        failures.append("png write " + name)
        return null
    print("FIRST_WAKE_CROSS_STUDY_CAPTURE: ", name,
        " 960x640 ", FileAccess.get_sha256(path))
    return screenshot

func _delta(a: Image, b: Image) -> int:
    var count: int = 0
    for y in range(250, 469, 3):
        for x in range(550, 939, 3):
            var p: Color = a.get_pixel(x, y)
            var q: Color = b.get_pixel(x, y)
            var movement: float = absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b)
            if movement > 0.055:
                count += 1
    return count

func _run() -> void:
    root.size = Vector2i(960, 640)
    var world = Scene.instantiate()
    root.add_child(world)
    await process_frame
    world.ender.set_physics_process(false)
    world.ionia.set_physics_process(false)
    world.ender.position = world.FLYER_POSITION
    if not world.interact() or not _finish_dialogue(world):
        failures.append("invalid first flyer route")
    world.ender.position = world.IONIA_DOCK_POSITION
    if not world.interact() or not _finish_dialogue(world):
        failures.append("invalid Ionia hiring")
    world.ender.position = world.GANGWAY_POSITION
    if not world.interact() or world.room != "engineering":
        failures.append("crew boarding route failed")
    if not world.set_ship_spaces_review_enabled(true):
        failures.append("test-only ship-space opt-in unavailable")
    if DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(OUTPUT)) != OK:
        failures.append("output directory unavailable")
    if not failures.is_empty():
        for reason in failures:
            push_error("FIRST_WAKE_CROSS_STUDY_CAPTURE_FAIL: " + reason)
        quit(1)
        return
    var story: Dictionary = world.opening.snapshot()
    var save: Dictionary = world.export_revised_checkpoint()
    var without: Image = await _image("00-chapter-without-3d")
    if not world.set_ship_pose_3d_review_enabled(true):
        failures.append("no original 3D rig")
    var base: Image = await _image("01-original-wings")
    var review = world.ship_pose_3d_review
    if not review.set_geometry_cross_study_enabled(true):
        failures.append("source deck/dome intake blocked")
    var report: Dictionary = review.assess_geometry_cross_study()
    if bool(report["physical_integration_ready"]) or
            str(report["admission"]) != "BLOCKED_ON_HULL_SCALE_EGRESS_AND_SWEPT_VOLUME":
        failures.append("cross-study wrongly certified")
    var assembled: Image = await _image("02-foredeck-dome-original-wings")
    if not world.request_ship_pose_3d_review(Port.CUE_GENTLE_SWEEP):
        failures.append("actual wing rig refused ordinary sweep")
    if not world.advance_ship_pose_3d_review(1.8, false):
        failures.append("actual wing timeline refused advancing")
    var swept: Image = await _image("03-foredeck-dome-swept-wings")
    var onset: int = 0
    var new_geometry: int = 0
    var wing_motion: int = 0
    if without != null and base != null and assembled != null and swept != null:
        onset = _delta(without, base)
        new_geometry = _delta(base, assembled)
        wing_motion = _delta(assembled, swept)
        if onset < 400:
            failures.append("original ship model absent from chapter pixels")
        if new_geometry < 50:
            failures.append("source foredeck and dome changes not visible")
        if wing_motion < 30:
            failures.append("actual 3D wing sweep not visible after assembly")
    if story != world.opening.snapshot() or save != world.export_revised_checkpoint():
        failures.append("source mesh review changed story or v2 save")
    world.set_ship_spaces_review_enabled(false)
    if world.ship_pose_3d_review != null:
        failures.append("transient geometry and rig survive opt-out")
    world.queue_free()
    await process_frame
    if failures.is_empty():
        print("FIRST_WAKE_CROSS_STUDY_AB_PASS frames=4 original_grid=", onset,
            " overlay_grid=", new_geometry, " wing_grid=", wing_motion,
            " safety=BLOCKED story=UNCHANGED")
        quit(0)
    else:
        for reason in failures:
            push_error("FIRST_WAKE_CROSS_STUDY_CAPTURE_FAIL: " + reason)
        quit(1)
