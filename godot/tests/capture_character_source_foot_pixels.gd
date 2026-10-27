extends SceneTree
## Two authentic 960x640 native Godot framebuffer comparisons.
## Pixel support guides are diagnostic marks, not proof of planted anatomy.
const OUTPUT := "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var stage = load("res://scenes/three_character_physics_walk_review.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    stage.start_all()
    for tick in range(48):
        await physics_frame
    # Freeze just this isolated renderer scene to ensure A/B has identical
    # actor coordinates and source frames. No in-game motion state changes.
    for name in ["Lyra", "Aepex", "Reson"]:
        stage.get_actor(name).set_physics_process(false)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("SOURCE_FOOT_CAPTURE_FAIL: review directory")
        quit(1)
        return
    for mode in ["without-guides", "with-guides"]:
        stage.set_source_guides_enabled(mode == "with-guides")
        await process_frame
        await RenderingServer.frame_post_draw
        var frame: Image = root.get_texture().get_image()
        if frame.is_empty() or frame.get_size() != Vector2i(960, 640):
            push_error("SOURCE_FOOT_CAPTURE_FAIL: actual Godot frame missing")
            quit(2)
            return
        var file: String = OUTPUT + "source-foot-" + mode + "-native-960x640.png"
        if frame.save_png(file) != OK:
            push_error("SOURCE_FOOT_CAPTURE_FAIL: PNG write " + mode)
            quit(3)
            return
        print("SOURCE_FOOT_NATIVE_PNG:" + mode + ":sha256=" + FileAccess.get_sha256(file))
        var preview: Image = frame.get_region(Rect2i(145, 200, 680, 298))
        preview.resize(680, 298, Image.INTERPOLATE_NEAREST)
        var jpg: PackedByteArray = preview.save_jpg_to_buffer(0.62)
        if jpg.is_empty() or jpg.size() > 95000:
            push_error("SOURCE_FOOT_CAPTURE_FAIL: private crop out of bounds")
            quit(4)
            return
        print("SOURCE_FOOT_NATIVE_CROP_JPEG_BASE64:" + mode + ":" + Marshalls.raw_to_base64(jpg))
    var off_hash := FileAccess.get_sha256(OUTPUT + "source-foot-without-guides-native-960x640.png")
    var on_hash := FileAccess.get_sha256(OUTPUT + "source-foot-with-guides-native-960x640.png")
    if off_hash == on_hash:
        push_error("SOURCE_FOOT_CAPTURE_FAIL: opt-in guide had no optical effect")
        quit(5)
        return
    print("SOURCE_FOOT_NATIVE_CAPTURE_PASS: real unchanged-actor A/B, only debug guides changed; source boots are NOT certified contact points")
    quit(0)
