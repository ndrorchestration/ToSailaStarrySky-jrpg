extends SceneTree
## Native Godot Compatibility captures; not a gameplay screenshot or final plan.
const StudyScene = preload("res://ship_interior_study.tscn")
const SHOTS = [
    ["deck-overview", Vector3(9.0, 13.0, 10.0), 54.0],
    ["living-and-engineering", Vector3(-8.0, 9.0, 6.0), 50.0]
]
var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene = StudyScene.instantiate()
    root.add_child(scene)
    await process_frame
    var directory: String = ProjectSettings.globalize_path("res://evidence/ship-interior")
    if DirAccess.make_dir_recursive_absolute(directory) != OK:
        push_error("SHIP_INTERIOR_CAPTURE_DIR_FAILED")
        quit(1)
        return
    var camera: Camera3D = scene.get_node("InteriorReviewCamera")
    for shot in SHOTS:
        camera.position = shot[1]
        camera.fov = float(shot[2])
        camera.look_at(Vector3(0.0, 0.30, 0.0), Vector3.UP)
        for warmup in range(7):
            await process_frame
            await RenderingServer.frame_post_draw
        var picture: Image = root.get_texture().get_image()
        var path: String = directory.path_join(str(shot[0]) + ".png")
        if picture == null or picture.get_size() != Vector2i(960, 640):
            push_error("SHIP_INTERIOR_CAPTURE_DIMENSIONS_FAILED")
            failures += 1
        elif picture.save_png(path) != OK:
            push_error("SHIP_INTERIOR_CAPTURE_SAVE_FAILED")
            failures += 1
        else:
            print("NATIVE_SHIP_INTERIOR_CAPTURE: ", path, " 960x640 NONCANON")
    scene.queue_free()
    await process_frame
    quit(1 if failures else 0)
