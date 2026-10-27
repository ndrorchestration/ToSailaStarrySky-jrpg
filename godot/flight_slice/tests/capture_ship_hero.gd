extends SceneTree
## Genuine Godot software-GL ship frames. Camera/time/ship held fixed during
## environment changes. Noncanonical Aureate Wake != larger Dragonfly Frigate.
const StudyScene = preload("res://main.tscn")
const SHOTS = [
    ["bow-quarter", Vector3(6.5, 3.0, -7.0), 43.0, 0, 0, false],
    ["bow-halfway", Vector3(6.5, 3.0, -7.0), 43.0, 3, 3, true],
    ["stern-quarter", Vector3(-7.0, 2.8, 7.0), 45.0, 0, 0, false],
    ["wing-planform", Vector3(2.5, 10.5, 2.0), 50.0, 0, 0, false],
    ["bow-bluehour-rain", Vector3(6.5, 3.0, -7.0), 43.0, 2, 2, false],
    ["bow-storm-magic", Vector3(6.5, 3.0, -7.0), 43.0, 3, 3, true]
]

func _initialize() -> void:
    call_deferred("_capture")

func _delta(one: Image, two: Image) -> float:
    var value: float = 0.0
    for y in range(60, 600, 16):
        for x in range(60, 900, 16):
            var first: Color = one.get_pixel(x, y)
            var second: Color = two.get_pixel(x, y)
            value += absf(first.r - second.r)
            value += absf(first.g - second.g)
            value += absf(first.b - second.b)
    return value

func _capture() -> void:
    var scene = StudyScene.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.overlay.visible = false
    scene._clock = 9.0
    scene._update_scene(0.0)
    scene.ship.set_motion(9.0, false)
    scene.ship.set_landing_gear(false)
    var fixed_ship: Transform3D = scene.ship.global_transform
    var folder: String = ProjectSettings.globalize_path("res://evidence/ship-hero")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("SHIP_HERO_CAPTURE_DIR_FAILED")
        quit(1)
        return
    var failures: int = 0
    var frames: Dictionary = {}
    for shot in SHOTS:
        if scene.visuals == null:
            push_error("SHIP_HERO_WEATHER_VISUALS_MISSING")
            failures += 1
            break
        var label: String = str(shot[0])
        if label == "bow-halfway":
            # Use identical golden starting appearance, exact scene clock and
            # half a deterministic 2s blend into storm/night/magic.
            scene.visuals.set_environment_look(0, 0, false)
            scene.visuals.queue_environment_look(3, 3, true, 2.0)
            scene.visuals.advance_environment_transition(1.0, false)
            if not scene.visuals.transition_active:
                push_error("SHIP_HERO_MIDFADE_NOT_ACTIVE")
                failures += 1
        else:
            scene.visuals.set_environment_look(int(shot[3]), int(shot[4]), bool(shot[5]))
        scene.visuals.set_clock(9.0, false)
        scene.camera.position = scene.ship.position + shot[1]
        scene.camera.fov = float(shot[2])
        scene.camera.look_at(scene.ship.position + Vector3(0.0, 0.2, 0.0), Vector3.UP)
        scene.terrain.update_detail(scene.camera.position, 0.5)
        for warmup in range(8):
            await process_frame
            await RenderingServer.frame_post_draw
        var frame: Image = root.get_texture().get_image()
        var path: String = folder.path_join(label + ".png")
        if frame == null or frame.get_size() != Vector2i(960, 640):
            push_error("SHIP_HERO_CAPTURE_SIZE_FAILED: " + label)
            failures += 1
        elif frame.save_png(path) != OK:
            push_error("SHIP_HERO_CAPTURE_SAVE_FAILED: " + path)
            failures += 1
        else:
            print("NATIVE_SHIP_HERO_CAPTURE: ", path, " 960x640 NONCANON")
            frames[label] = frame.duplicate()
        if scene.ship.global_transform != fixed_ship:
            push_error("SHIP_HERO_PREVIEW_MUTATED_SHIP_TRANSFORM: " + label)
            failures += 1
    var compared: int = 0
    for comparison in [
        ["bow-quarter", "bow-bluehour-rain"],
        ["bow-quarter", "bow-storm-magic"],
        ["bow-quarter", "bow-halfway"],
        ["bow-halfway", "bow-storm-magic"]
    ]:
        if not frames.has(comparison[0]) or not frames.has(comparison[1]):
            failures += 1
            continue
        var delta: float = _delta(frames[comparison[0]], frames[comparison[1]])
        print("NATIVE_SHIP_HERO_MOOD_DELTA: ", comparison[0], " / ", comparison[1],
            " sum=", delta)
        if delta < 2.0:
            push_error("SHIP_HERO_WEATHER_VISUAL_DELTA_MISSING: " + str(comparison))
            failures += 1
        else:
            compared += 1
    scene.queue_free()
    await process_frame
    if failures == 0 and frames.size() == 6 and compared == 4:
        print("NATIVE_SHIP_WEATHER_INTEGRATION_PASS views=6 matched_mood_comparisons=4")
        quit(0)
    else:
        quit(1)
