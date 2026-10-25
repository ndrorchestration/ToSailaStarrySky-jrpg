extends SceneTree
## Engine-native SOFTWARE snapshot harness; not representative GPU performance.
const StudyScene = preload("res://main.tscn")
const CUTS: Array = [["coast", 9.0], ["forest", 23.0], ["highland", 34.0]]

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var scene = StudyScene.instantiate()
    get_root().add_child(scene)
    await process_frame
    var folder: String = ProjectSettings.globalize_path("res://evidence")
    DirAccess.make_dir_recursive_absolute(folder)
    for cut in CUTS:
        scene._clock = float(cut[1])
        scene.camera.position = scene.ship.position + Vector3(-25, 18, 25)
        scene._update_scene(10.0)
        scene.overlay.text = "TO SAIL THE STARRY SKY  /  VISUAL LAB\n" + str(cut[0]).to_upper() + "  •  NATIVE GODOT 4.7.2\nCOAST-TO-HIGHLAND ART STUDY  •  NON-CANON"
        await RenderingServer.frame_post_draw
        var screenshot: Image = get_root().get_texture().get_image()
        if screenshot == null or screenshot.get_width() != 960 or screenshot.get_height() != 640:
            push_error("CAPTURE_FAILED: invalid framebuffer for " + str(cut[0]))
            quit(1)
            return
        var output: String = folder.path_join(str(cut[0]) + ".png")
        var result: Error = screenshot.save_png(output)
        if result != OK:
            push_error("CAPTURE_FAILED: save PNG for " + str(cut[0]))
            quit(1)
            return
        print("NATIVE_ART_CAPTURE:", output, " ", screenshot.get_width(), "x", screenshot.get_height())
    scene.queue_free()
    quit(0)
