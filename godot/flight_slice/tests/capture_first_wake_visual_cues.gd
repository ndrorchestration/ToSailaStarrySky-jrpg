extends SceneTree
## Actual native OpenGL3 frames of the existing 3D Aureate Wake with story-cue
## driven light/fog/rain and same ship/camera/time for controlled comparisons.
## This does NOT validate flight, real ocean physics or safe family meeting.
const Scene = preload("res://main.tscn")
const SHOTS = [
    ["first-lift", "test_flight", "airborne_test", "first_lift", "monitor_phase_and_containment"],
    ["controlled-descent", "test_flight", "controlled_descent", "first_lift", "monitor_phase_and_containment"],
    ["ocean-afloat-study", "waterborne", "ocean_afloat", "ship_ocean_afloat", "verify_ship_and_crew_afloat"],
    ["recovery-checks", "postflight_diagnosis", "ocean_afloat_engines_offline", "shipboard_recovery_review", "inspect_reserve_and_recovery_readiness"],
]

func _initialize() -> void:
    call_deferred("_render")

func _packet(shot: Array) -> Dictionary:
    return {
        "ok": true,
        "schema": "tstss.review.first_wake_pipeline.v1",
        "authority": "prototype_only",
        "chapter": "first_wake",
        "story_phase": str(shot[1]),
        "story_party": ["ender", "ionia"],
        "visual_cue": str(shot[3]),
        "quest_cue": str(shot[4]),
        "ship_state": str(shot[2]),
        "recovery_checks": [],
        "recovery_readiness_observed": false,
        "reunion_fixture_only": false,
        "observed_clues": [],
        "fuel_explanation": "unknown",
        "gameplay_combat_grants": [],
        "world_navigation_authorized": false,
        "production_ocean_verified": false,
        "real_family_meeting_verified": false,
        "production_save_write_authorized": false,
        "canon_promotion_authorized": false,
    }

func _rgb_delta(one: Image, two: Image) -> float:
    var sum: float = 0.0
    # Exclude the top study HUD and the bottom cue label to ensure deltas come
    # from the real rendered atmosphere/ship/terrain, never only changed text.
    for y in range(150, 525, 13):
        for x in range(90, 860, 13):
            var a: Color = one.get_pixel(x, y)
            var b: Color = two.get_pixel(x, y)
            sum += absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
    return sum

func _render() -> void:
    var scene = Scene.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene._clock = 9.0
    scene._update_scene(0.0)
    var ship_transform: Transform3D = scene.ship.global_transform
    scene.overlay.visible = false
    var folder: String = ProjectSettings.globalize_path("res://evidence/first-wake-cues")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("FIRST_WAKE_3D_CUE_CAPTURE_DIR_FAILED")
        quit(1)
        return
    var pictures: Dictionary = {}
    var failures: int = 0
    for shot in SHOTS:
        var name: String = str(shot[0])
        var envelope: Dictionary = _packet(shot)
        if not scene.preview_first_wake_visual_cue(envelope, 0.0):
            push_error("FIRST_WAKE_3D_CUE_APPLY_FAILED: " + name)
            failures += 1
            continue
        scene.visuals.set_clock(9.0, false)
        # Same fixed hero camera across all four frames, independent of the
        # different scene-camera offsets tested in the separate contract test.
        scene.camera.position = scene.ship.position + Vector3(8.5, 5.4, -12.3)
        scene.camera.fov = 47.0
        scene.camera.look_at(scene.ship.position + Vector3(0.0, 0.2, 0.0), Vector3.UP)
        scene.terrain.update_detail(scene.camera.position, 0.35)
        scene.visuals.set_camera_frame(scene.camera)
        for warmup in range(8):
            await process_frame
            await RenderingServer.frame_post_draw
        var frame: Image = root.get_texture().get_image()
        if frame == null or frame.get_size() != Vector2i(960, 640):
            push_error("FIRST_WAKE_3D_CUE_CAPTURE_SIZE_FAILED: " + name)
            failures += 1
            continue
        var output_path: String = folder.path_join(name + ".png")
        if frame.save_png(output_path) != OK:
            push_error("FIRST_WAKE_3D_CUE_CAPTURE_SAVE_FAILED: " + name)
            failures += 1
        else:
            pictures[name] = frame.duplicate()
            print("FIRST_WAKE_3D_CUE_CAPTURE: ", output_path, " 960x640 REVIEW_ONLY")
        if scene.ship.global_transform != ship_transform:
            push_error("FIRST_WAKE_3D_CUE_SHIP_POSITION_DRIFT: " + name)
            failures += 1
    var comparisons: int = 0
    for pair in [
        ["first-lift", "controlled-descent"],
        ["first-lift", "ocean-afloat-study"],
        ["controlled-descent", "recovery-checks"]
    ]:
        if not pictures.has(pair[0]) or not pictures.has(pair[1]):
            failures += 1
            continue
        var delta: float = _rgb_delta(pictures[pair[0]], pictures[pair[1]])
        print("FIRST_WAKE_3D_CUE_RGB_DELTA: ", pair[0], " / ", pair[1], " value=", delta)
        if delta <= 3.0:
            failures += 1
            push_error("FIRST_WAKE_3D_CUE_NOT_VISUALLY_DISTINCT: " + str(pair))
        else:
            comparisons += 1
    scene.queue_free()
    await process_frame
    if failures == 0 and pictures.size() == 4 and comparisons == 3:
        print("FIRST_WAKE_3D_CUE_CAPTURE_PASS frames=4 comparisons=3")
        quit(0)
    else:
        quit(1)
