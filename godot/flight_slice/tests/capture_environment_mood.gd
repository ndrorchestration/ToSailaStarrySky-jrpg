extends SceneTree
## Exact-camera/time HUD-free GL frames for environmental art comparison.
## A changed framebuffer is not a claim of photographic or artistic quality.
const StudyScene = preload("res://main.tscn")
const CUTS = [
    ["golden-clear", 0, 0, false],
    ["midday-mist", 1, 1, false],
    ["blue-hour-rain", 2, 2, false],
    ["storm-night-magic", 3, 3, true]
]
var _failed: bool = false

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var scene = StudyScene.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.overlay.visible = false
    scene._clock = 23.0
    scene._update_scene(10.0)
    var folder: String = ProjectSettings.globalize_path(
        "res://evidence/environment-mood")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("ENVIRONMENT_MOOD_CAPTURE_DIR_FAIL")
        quit(1)
        return
    var reference: Image
    var compared: int = 0
    for cut in CUTS:
        scene.visuals.set_environment_look(int(cut[1]), int(cut[2]), bool(cut[3]))
        scene.visuals.set_clock(23.0, false)
        scene.visuals.set_camera_frame(scene.camera)
        for warmup in range(8):
            await process_frame
            await RenderingServer.frame_post_draw
        var frame: Image = root.get_texture().get_image()
        var file_path: String = folder.path_join(str(cut[0]) + ".png")
        if frame == null or frame.get_size() != Vector2i(960, 640):
            push_error("ENVIRONMENT_MOOD_CAPTURE_SIZE_FAIL: " + str(cut[0]))
            _failed = true
            continue
        if frame.save_png(file_path) != OK:
            push_error("ENVIRONMENT_MOOD_CAPTURE_SAVE_FAIL: " + file_path)
            _failed = true
            continue
        print("NATIVE_ENVIRONMENT_CAPTURE: ", file_path)
        if reference == null:
            reference = frame.duplicate()
        else:
            # Same timestamp and camera: a coarse delta proves modes reach
            # actual rendered pixels, not that either look is aesthetically better.
            var delta: float = 0.0
            for y in range(40, 600, 24):
                for x in range(40, 920, 24):
                    var before: Color = reference.get_pixel(x, y)
                    var after: Color = frame.get_pixel(x, y)
                    delta += absf(before.r - after.r)
                    delta += absf(before.g - after.g)
                    delta += absf(before.b - after.b)
            if delta < 2.0:
                push_error("ENVIRONMENT_MOOD_CAPTURE_NO_VISIBLE_DELTA: " + str(cut[0]))
                _failed = true
            compared += 1
    scene.queue_free()
    await process_frame
    if not _failed and compared == 3:
        print("NATIVE_ENVIRONMENT_CAPTURE_PASS comparisons=", compared)
        quit(0)
    else:
        quit(1)
