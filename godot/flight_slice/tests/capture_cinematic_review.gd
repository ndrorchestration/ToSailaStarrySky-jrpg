extends SceneTree
## P0 cinematic review frames: HUD-free native capture, never claimed gameplay.
## Run with Godot 4.7.2 Compatibility + software OpenGL/Xvfb or a real GPU.
const StudyScene = preload("res://main.tscn")
const CUTS = [["coast-dusk", 9.0], ["forest-gold", 23.0], ["highland-horizon", 34.0]]
var _failed: bool = false

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var scene = StudyScene.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.overlay.visible = false
    var folder: String = ProjectSettings.globalize_path("res://evidence/cinematic-review")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("CINEMATIC_CAPTURE_DIR_FAILED")
        quit(1)
        return
    for cut in CUTS:
        scene._clock = float(cut[1])
        scene._update_scene(8.0)
        scene.visuals.set_clock(float(cut[1]), false)
        for warmup in range(8):
            await process_frame
            await RenderingServer.frame_post_draw
        var frame: Image = root.get_texture().get_image()
        var file_path: String = folder.path_join(str(cut[0]) + ".png")
        if frame == null or frame.get_size() != Vector2i(960, 640):
            push_error("CINEMATIC_CAPTURE_DIMENSIONS_FAILED: " + str(cut[0]))
            _failed = true
        elif frame.save_png(file_path) != OK:
            push_error("CINEMATIC_CAPTURE_SAVE_FAILED: " + file_path)
            _failed = true
        else:
            print("NATIVE_CINEMATIC_CAPTURE: ", file_path, " 960x640 HUD-free NONCANON")
    scene.queue_free()
    await process_frame
    quit(1 if _failed else 0)
