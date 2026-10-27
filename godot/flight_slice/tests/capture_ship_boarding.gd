extends SceneTree
## Two actual HUD-free native Godot 4.7.2 cabin threshold images.
const Study = preload("res://ship_boarding_interface.tscn")
const SHOTS = [
    ["crew-hatch-open", Vector3(5.2, 4.7, -7.0), 51.0, true],
    ["crew-hatch-closed", Vector3(-4.9, 4.5, -6.8), 51.0, false]
]
var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    var output: String = ProjectSettings.globalize_path(
        "res://evidence/ship-boarding")
    if DirAccess.make_dir_recursive_absolute(output) != OK:
        push_error("SHIP_BOARDING_CAPTURE_DIR_FAILURE")
        quit(1)
        return
    var camera: Camera3D = scene.get_node("CrewThresholdCamera")
    for shot in SHOTS:
        scene.set_door_open(bool(shot[3]))
        camera.position = shot[1]
        camera.fov = float(shot[2])
        camera.look_at(Vector3(0.0, 0.90, -3.28), Vector3.UP)
        for frame in range(7):
            await process_frame
            await RenderingServer.frame_post_draw
        var image: Image = root.get_texture().get_image()
        var filename: String = output.path_join(str(shot[0]) + ".png")
        if image == null or image.get_size() != Vector2i(960, 640):
            push_error("SHIP_BOARDING_CAPTURE_SIZE_FAILURE")
            failures += 1
        elif image.save_png(filename) != OK:
            push_error("SHIP_BOARDING_CAPTURE_SAVE_FAILURE")
            failures += 1
        else:
            print("NATIVE_SHIP_BOARDING_CAPTURE: ", filename,
                " 960x640 NONCANON")
    scene.queue_free()
    await process_frame
    quit(1 if failures else 0)
