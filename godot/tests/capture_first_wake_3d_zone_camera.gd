extends SceneTree
## Four actual Godot GL frames of new zone camera and articulated crew.
const Scene = preload("res://scenes/first_wake_optional_shipboard_3d_review.tscn")
const Codec = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
const OUT := "res://review-evidence/first-wake-3d-zone-camera/"
var issues: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _capture(name: String) -> Image:
    for tick in range(7):
        await process_frame
        await RenderingServer.frame_post_draw
    var screenshot: Image = root.get_texture().get_image()
    if screenshot == null or screenshot.get_size() != Vector2i(960, 640):
        issues.append("invalid_image_" + name)
        return null
    var path: String = ProjectSettings.globalize_path(OUT.path_join(name))
    if screenshot.save_png(path) != OK:
        issues.append("write_failed_" + name)
        return null
    print("FIRST_WAKE_ZONE_CAMERA_FRAME: ", name, " 960x640 sha256=",
        FileAccess.get_sha256(path))
    return screenshot

func _move(actor: CharacterBody3D, z: float) -> bool:
    actor.set_test_direction(Vector2(0, -1))
    var reached: bool = false
    for frame in range(250):
        await physics_frame
        await process_frame
        if actor.position.z <= z:
            reached = true
            break
    actor.set_test_direction(Vector2.ZERO)
    await physics_frame
    await process_frame
    return reached

func _run() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
        push_error("FIRST_WAKE_ZONE_CAMERA_CAPTURE_FAIL output directory")
        quit(1)
        return
    var review = Scene.instantiate()
    root.add_child(review)
    await process_frame
    var fixture: Dictionary = {
        "schema": Codec.SCHEMA, "step": "engineering",
        "flyer_read": true, "room": "engineering", "inspections": [],
        "player_position": {"x": 226.0, "y": 470.0}
    }
    if not review.chapter.restore_revised_checkpoint(fixture):
        issues.append("legitimate_story_fixture_denied")
    if not review.request_3d_ship_review(true):
        issues.append("actual_3d_transition_denied")
    var actor: CharacterBody3D = review.ship.crew_walker
    for frame in range(25):
        await physics_frame
        await process_frame
    var cabin: Image = await _capture("01-cabin-close-follow-readable-crew.png")
    if not await _move(actor, -1.45):
        issues.append("real_crew_did_not_walk_to_helm")
    review.ship.set_glass_art_review("source_low_glare")
    var helm: Image = await _capture("02-geodesic-helm-corrected-camera.png")
    if not await _move(actor, -4.30):
        issues.append("real_crew_did_not_walk_to_open_deck")
    var deck: Image = await _capture("03-open-deck-corrected-camera.png")
    if not review.cycle_camera_review():
        issues.append("cannot_switch_actual_camera")
    var wide: Image = await _capture("04-open-deck-elevated-camera.png")
    if deck != null and wide != null:
        var changed: int = 0
        for y in range(60, 595, 3):
            for x in range(75, 880, 3):
                if deck.get_pixel(x, y) != wide.get_pixel(x, y):
                    changed += 1
        print("FIRST_WAKE_ZONE_CAMERA_AB_CHANGED=", changed)
        if changed < 500:
            issues.append("camera_presets_do_not_render_different_perspective")
    if cabin == null or helm == null:
        issues.append("missing_cabin_or_helm_image")
    if review.ship.crew_camera.current:
        issues.append("old_camera_competing_during_review")
    if not review.request_3d_ship_review(false):
        issues.append("cannot_restore_original_2d_chapter")
    if review.chapter.export_revised_checkpoint() != fixture:
        issues.append("round_trip_checkpoint_modified")
    review.queue_free()
    await process_frame
    if issues.is_empty():
        print("FIRST_WAKE_ZONE_CAMERA_RENDER_PASS shots=4",
            " crew=ACTUAL_ANIMATED_PROXY",
            " scene=REAL_GODOT",
            " production=BLOCKED")
        quit(0)
    else:
        for issue in issues:
            push_error("FIRST_WAKE_ZONE_CAMERA_CAPTURE_FAIL: " + issue)
        quit(1)
