extends SceneTree
## Real native Godot ship close-ups at fixed camera for environmental comparison.
## This noncanonical Aureate Wake study is NOT the separate Dragonfly Frigate.
const StudyScene = preload("res://main.tscn")
const SHOTS = [
    ["bow-quarter", Vector3(6.5, 3.0, -7.0), 43.0, 0, 0, false],
    ["stern-quarter", Vector3(-7.0, 2.8, 7.0), 45.0, 0, 0, false],
    ["wing-planform", Vector3(2.5, 10.5, 2.0), 50.0, 0, 0, false],
    ["bow-bluehour-rain", Vector3(6.5, 3.0, -7.0), 43.0, 2, 2, false],
    ["bow-storm-magic", Vector3(6.5, 3.0, -7.0), 43.0, 3, 3, true]
]

func _initialize() -> void:
    call_deferred("_capture")

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
    var folder: String = ProjectSettings.globalize_path("res://evidence/ship-hero")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("SHIP_HERO_CAPTURE_DIR_FAILED")
        quit(1)
        return
    var failures: int = 0
    var golden_bow: Image
    var compared: int = 0
    for shot in SHOTS:
        if scene.visuals == null:
            push_error("SHIP_HERO_WEATHER_VISUALS_MISSING")
            failures += 1
            break
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
        var path: String = folder.path_join(str(shot[0]) + ".png")
        if frame == null or frame.get_size() != Vector2i(960, 640):
            push_error("SHIP_HERO_CAPTURE_SIZE_FAILED: " + str(shot[0]))
            failures += 1
        elif frame.save_png(path) != OK:
            push_error("SHIP_HERO_CAPTURE_SAVE_FAILED: " + path)
            failures += 1
        else:
            print("NATIVE_SHIP_HERO_CAPTURE: ", path, " 960x640 NONCANON")
            if str(shot[0]) == "bow-quarter":
                golden_bow = frame.duplicate()
            elif str(shot[0]) in ["bow-bluehour-rain", "bow-storm-magic"] and golden_bow != null:
                # Fixed camera/clock/object transform. A visible difference only
                # proves that the environmental grade reached native pixels.
                var delta: float = 0.0
                for y in range(60, 600, 16):
                    for x in range(60, 900, 16):
                        var before: Color = golden_bow.get_pixel(x, y)
                        var after: Color = frame.get_pixel(x, y)
                        delta += absf(before.r - after.r)
                        delta += absf(before.g - after.g)
                        delta += absf(before.b - after.b)
                if delta < 2.0:
                    push_error("SHIP_HERO_WEATHER_VISUAL_DELTA_MISSING: " + str(shot[0]))
                    failures += 1
                else:
                    compared += 1
                print("NATIVE_SHIP_HERO_MOOD_DELTA: ", shot[0], " sum=", delta)
    scene.queue_free()
    await process_frame
    if failures == 0 and compared == 2:
        print("NATIVE_SHIP_WEATHER_INTEGRATION_PASS views=5 matched_mood_comparisons=", compared)
        quit(0)
    else:
        quit(1)
