extends SceneTree
## Exact 960×640 Godot frames of *live* 2D Chapter I / 3D review / return.
const Scene = preload("res://scenes/first_wake_optional_shipboard_3d_review.tscn")
const Codec = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
const OUTPUT := "res://review-evidence/first-wake-opt-in-3d/"
var problems: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _shot(filename: String) -> Image:
    for i in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    var frame: Image = root.get_texture().get_image()
    if frame == null or frame.get_size() != Vector2i(960, 640):
        problems.append("invalid_native_frame_" + filename)
        return null
    var output: String = ProjectSettings.globalize_path(
        OUTPUT.path_join(filename))
    if frame.save_png(output) != OK:
        problems.append("write_failure_" + filename)
        return null
    print("FIRST_WAKE_OPTIONAL_3D_FRAME: ", filename,
        " 960x640 sha256=", FileAccess.get_sha256(output))
    return frame

func _drive_to(actor: CharacterBody3D, target_z: float) -> bool:
    actor.set_test_direction(Vector2(0, -1))
    var reached: bool = false
    for tick in range(210):
        await physics_frame
        if actor.position.z <= target_z:
            reached = true
            break
    actor.set_test_direction(Vector2.ZERO)
    await physics_frame
    return reached

func _run() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("FIRST_WAKE_OPTIONAL_3D_CAPTURE_FAIL directory")
        quit(1)
        return
    var review = Scene.instantiate()
    root.add_child(review)
    await process_frame
    var fixture: Dictionary = {
        "schema": Codec.SCHEMA,
        "step": "engineering",
        "flyer_read": true,
        "room": "engineering",
        "inspections": [],
        "player_position": {"x": 226.0, "y": 470.0}
    }
    if not review.chapter.restore_revised_checkpoint(fixture):
        problems.append("invalid_staged_legal_chapter_fixture")
    var saved: Dictionary = review.chapter.export_revised_checkpoint()
    var first: Image = await _shot("01-2d-ionia-engineering-before.png")

    if not review.request_3d_ship_review(true):
        problems.append("post_ionia_3d_review_refused")
    var actor: CharacterBody3D = review.ship.crew_walker
    for i in range(35):
        await physics_frame
    if not await _drive_to(actor, -1.53):
        problems.append("actual_actor_failed_to_reach_helm")
    review.ship.set_glass_art_review("source_low_glare")
    var helm: Image = await _shot("02-3d-crew-geodesic-helm.png")
    if not await _drive_to(actor, -4.38):
        problems.append("actual_actor_failed_to_reach_foredeck")
    var foredeck: Image = await _shot("03-3d-crew-open-foredeck.png")
    if not review.request_3d_ship_review(false):
        problems.append("could_not_return_to_2d")
    var returned: Image = await _shot("04-2d-ionia-engineering-return.png")

    if review.chapter.export_revised_checkpoint() != saved:
        problems.append("source_checkpoint_drift")
    if not review.chapter.visible or review.ship.visible:
        problems.append("wrong_scene_visibility_after_return")
    if first != null and helm != null:
        var changed: int = 0
        for y in range(80, 600, 4):
            for x in range(100, 840, 4):
                if first.get_pixel(x, y) != helm.get_pixel(x, y):
                    changed += 1
        print("FIRST_WAKE_OPTIONAL_3D_MODE_DELTA=", changed)
        if changed < 2000:
            problems.append("2d_and_3d_not_visually_distinct")
    if foredeck == null or returned == null:
        problems.append("missing_deck_or_return_render")
    review.queue_free()
    await process_frame
    if problems.is_empty():
        print("FIRST_WAKE_OPTIONAL_3D_RENDER_PASS shots=4",
            " transition=REAL_2D_TO_3D_TO_2D",
            " story=UNCHANGED",
            " production=BLOCKED")
        quit(0)
    else:
        for problem in problems:
            push_error("FIRST_WAKE_OPTIONAL_3D_CAPTURE_FAIL: " + problem)
        quit(1)
