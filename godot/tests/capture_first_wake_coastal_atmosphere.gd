extends SceneTree
## Four true in-engine same-ship captures, source-water & color review A/B.
const Review = preload("res://scenes/first_wake_optional_shipboard_3d_review.tscn")
const Codec = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
const OUTPUT := "res://review-evidence/first-wake-3d-coastal-atmosphere/"
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _shot(name: String) -> Image:
    for frame in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    var img: Image = root.get_texture().get_image()
    if img.is_empty() or img.get_size() != Vector2i(960, 640):
        failures.append("invalid_native_viewport_" + name)
        return null
    var path: String = ProjectSettings.globalize_path(OUTPUT.path_join(name))
    if img.save_png(path) != OK:
        failures.append("cannot_save_native_png_" + name)
        return null
    print("FIRST_WAKE_COASTAL_NATIVE_FRAME: ", name,
        " 960x640 sha256=", FileAccess.get_sha256(path))
    return img

func _walk_to(actor: CharacterBody3D, z: float) -> bool:
    actor.set_test_direction(Vector2(0, -1))
    var reached := false
    for frame in range(250):
        await physics_frame
        await process_frame
        if actor.position.z <= z:
            reached = true
            break
    actor.set_test_direction(Vector2.ZERO)
    await physics_frame
    return reached

func _diff(a: Image, b: Image) -> int:
    if a == null or b == null:
        return 0
    var changed: int = 0
    for y in range(65, 600, 4):
        for x in range(50, 900, 4):
            if a.get_pixel(x, y) != b.get_pixel(x, y):
                changed += 1
    return changed

func _run() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("FIRST_WAKE_COASTAL_CAPTURE_FAIL mkdir")
        quit(1)
        return
    var review = Review.instantiate()
    root.add_child(review)
    await process_frame
    var snapshot: Dictionary = {
        "schema": Codec.SCHEMA, "step": "engineering",
        "flyer_read": true, "room": "engineering", "inspections": [],
        "player_position": {"x": 226.0, "y": 470.0}
    }
    if not review.chapter.restore_revised_checkpoint(snapshot):
        failures.append("invalid_hired_story_fixture")
    if not review.request_3d_ship_review(true):
        failures.append("opt_in_3d_scene_refused")
    var actor: CharacterBody3D = review.ship.crew_walker
    for frame in range(30):
        await physics_frame
    if not await _walk_to(actor, -4.25):
        failures.append("no_actual_walk_to_foredeck")
    review.helm_feedback.visible = false  # Hide UI plate for identical atmospheric art A/B.
    var sky = review.atmosphere_review
    if not sky.set_review_profile("flat"):
        failures.append("flat_reference_denied")
    var before: Image = await _shot("01-deck-previous-flat-background.png")
    if not sky.set_review_profile("coastal_dusk"):
        failures.append("dusk_reference_denied")
    var dusk: Image = await _shot("02-deck-source-water-coastal-dusk.png")
    if not sky.set_review_profile("coastal_clear"):
        failures.append("clear_reference_denied")
    var clear: Image = await _shot("03-deck-source-water-coastal-clear.png")
    if not sky.set_review_profile("coastal_dusk"):
        failures.append("dusk_reentry_denied")
    if not review.toggle_scenic_horizon_review():
        failures.append("could_not_aim_actual_lookout_camera")
    review.helm_feedback.visible = false
    var elevated: Image = await _shot("04-lookout-scenic-sky-and-ocean.png")

    var flat_dusk: int = _diff(before, dusk)
    var dusk_clear: int = _diff(dusk, clear)
    print("FIRST_WAKE_COASTAL_FLAT_DUSK_DELTA=", flat_dusk)
    print("FIRST_WAKE_COASTAL_DUSK_CLEAR_DELTA=", dusk_clear)
    if flat_dusk < 1500:
        failures.append("source_water_and_sky_did_not_materially_render")
    if dusk_clear < 550:
        failures.append("clear_dusk_palette_not_visually_distinct")
    if elevated == null:
        failures.append("elevated_coastal_image_missing")
    if not review.request_3d_ship_review(false):
        failures.append("cannot_return_to_actual_2d_chapter")
    if review.chapter.export_revised_checkpoint() != snapshot:
        failures.append("inherited_2d_checkpoint_changed_by_visuals")
    review.queue_free()
    await process_frame
    if failures.is_empty():
        print("FIRST_WAKE_COASTAL_RENDER_PASS shots=4",
            " source=EXACT_STAGED_WATER_TEXTURE",
            " environment=COASTAL_SKY_WATER",
            " native=GODOT",
            " production=BLOCKED")
        quit(0)
    else:
        for f in failures:
            push_error("FIRST_WAKE_COASTAL_CAPTURE_FAIL: " + f)
        quit(1)
