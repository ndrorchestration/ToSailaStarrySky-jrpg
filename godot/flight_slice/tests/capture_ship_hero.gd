extends SceneTree
## Three genuine Godot software-rendered ship close-ups for visual review.
## Scene assets remain a provisional planar flight-scale study, not creator art.
const StudyScene = preload("res://main.tscn")
const SHOTS = [
    ["bow-quarter", Vector3(6.5, 3.0, -7.0), 43.0],
    ["stern-quarter", Vector3(-7.0, 2.8, 7.0), 45.0],
    ["wing-planform", Vector3(2.5, 10.5, 2.0), 50.0],
    ["foredeck-open", Vector3(2.2, 1.8, -4.2), 37.0],
    ["foredeck-weather-cover", Vector3(2.2, 1.8, -4.2), 37.0]
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
    for shot in SHOTS:
        scene.ship.set_foredeck_weather_shelter(str(shot[0]) == "foredeck-weather-cover")
        scene.camera.position = scene.ship.position + shot[1]
        scene.camera.fov = float(shot[2])
        scene.camera.look_at(scene.ship.position + Vector3(0.0, 0.2, 0.0), Vector3.UP)
        scene.terrain.update_detail(scene.camera.position, 0.5)
        for warmup in range(6):
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
    scene.queue_free()
    await process_frame
    quit(1 if failures > 0 else 0)
