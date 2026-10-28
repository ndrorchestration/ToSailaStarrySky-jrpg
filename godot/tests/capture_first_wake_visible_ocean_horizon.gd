extends SceneTree
## Real GPU/OpenGL Godot camera evidence: sky vs visible water in same shot.
const Scene = preload("res://scenes/first_wake_optional_shipboard_3d_review.tscn")
const Codec = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
const OUTPUT := "res://review-evidence/first-wake-visible-horizon/"
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _shot(filename: String) -> Image:
    for i in range(7):
        await process_frame
        await RenderingServer.frame_post_draw
    var img: Image = root.get_texture().get_image()
    if img == null or img.get_size() != Vector2i(960, 640):
        errors.append("invalid_native_frame_" + filename)
        return null
    var destination: String = ProjectSettings.globalize_path(OUTPUT.path_join(filename))
    if img.save_png(destination) != OK:
        errors.append("write_failure_" + filename)
        return null
    print("FIRST_WAKE_VISIBLE_HORIZON_FRAME: ", filename,
        " 960x640 sha256=", FileAccess.get_sha256(destination))
    return img

func _walk(actor: CharacterBody3D, goal: float) -> bool:
    actor.set_test_direction(Vector2(0, -1))
    var reached: bool = false
    for frame in range(255):
        await physics_frame
        await process_frame
        if actor.position.z <= goal:
            reached = true
            break
    actor.set_test_direction(Vector2.ZERO)
    await physics_frame
    await process_frame
    return reached

func _run() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("FIRST_WAKE_VISIBLE_HORIZON_CAPTURE_FAIL output directory")
        quit(1)
        return
    var review = Scene.instantiate()
    root.add_child(review)
    await process_frame
    var fixture: Dictionary = {
        "schema": Codec.SCHEMA, "step": "engineering", "flyer_read": true,
        "room": "engineering", "inspections": [],
        "player_position": {"x": 226.0, "y": 470.0}
    }
    if not review.chapter.restore_revised_checkpoint(fixture) or not review.request_3d_ship_review(true):
        errors.append("invalid_ionia_first_start")
    var actor: CharacterBody3D = review.ship.crew_walker
    for i in range(26):
        await physics_frame
    var cabin: Image = await _shot("01-real-cabin-and-dawn-sky.png")
    if not await _walk(actor, -1.45):
        errors.append("actor_failed_helm_walk")
    review.ship.set_glass_art_review("source_low_glare")
    if not review.inspect_review_helm():
        errors.append("real_helm_F_unavailable")
    var helm: Image = await _shot("02-real-geodesic-helm.png")
    if not await _walk(actor, -4.30):
        errors.append("actor_failed_bow_walk")
    var water: Image = await _shot("03-foredeck-with-real-visible-ocean.png")
    review.maritime_atmosphere.ocean.visible = false
    var no_water: Image = await _shot("04-exact-foredeck-water-disabled-control.png")
    review.maritime_atmosphere.ocean.visible = true
    if not review.cycle_camera_review():
        errors.append("real_camera_C_unavailable")
    var elevated: Image = await _shot("05-elevated-physical-rail-review.png")
    if water != null and no_water != null:
        var changed: int = 0
        var changed_upper: int = 0
        for py in range(170, 575, 3):
            for px in range(35, 910, 3):
                if water.get_pixel(px, py) != no_water.get_pixel(px, py):
                    changed += 1
                    if py < 370:
                        changed_upper += 1
        print("FIRST_WAKE_VISIBLE_HORIZON_WATER_AB_CHANGED=", changed,
            " upper_half=", changed_upper)
        # Same real scene, same camera, same ship: the sea must be visible.
        if changed < 2600 or changed_upper < 500:
            errors.append("real_ocean_does_not_visibly_render_beyond_bow")
    if cabin == null or helm == null or elevated == null:
        errors.append("missing_real_in_engine_capture")
    if not review.request_3d_ship_review(false):
        errors.append("could_not_return_to_original_2d")
    if review.chapter.export_revised_checkpoint() != fixture:
        errors.append("ionia_first_v2_checkpoint_drift")
    review.queue_free()
    await process_frame
    if errors.is_empty():
        print("FIRST_WAKE_VISIBLE_HORIZON_RENDER_PASS shots=5",
            " water=RENDERED_COMPARISON",
            " actor=ACTUAL_CHARACTERBODY3D",
            " story=UNCHANGED production=BLOCKED")
        quit(0)
    else:
        for problem in errors:
            push_error("FIRST_WAKE_VISIBLE_HORIZON_CAPTURE_FAIL: " + problem)
        quit(1)
