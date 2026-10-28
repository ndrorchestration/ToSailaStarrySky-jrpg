extends SceneTree
## Genuine GL framebuffer capture. PNG stays runner-local; JPEG is a lossy review derivative.
const Studio = preload("res://scenes/five_lights_motion_studio.tscn")

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var stage = Studio.instantiate()
    root.add_child(stage)
    stage.keyboard_enabled = false
    await process_frame
    await RenderingServer.frame_post_draw
    var frame: Image = root.get_viewport().get_texture().get_image()
    if frame == null or frame.get_width() != 960 or frame.get_height() != 640:
        push_error("TSTSS_FIVE_LIGHTS_NATIVE_CAPTURE_FAIL: incorrect framebuffer dimensions")
        quit(1)
        return
    var full_path := "/tmp/tstss_five_lights_native_960x640.png"
    var err: Error = frame.save_png(full_path)
    if err != OK:
        push_error("TSTSS_FIVE_LIGHTS_NATIVE_CAPTURE_FAIL: could not save native framebuffer")
        quit(1)
        return
    var preview: Image = frame.duplicate()
    preview.resize(480, 320, Image.INTERPOLATE_LANCZOS)
    var jpg: PackedByteArray = preview.save_jpg_to_buffer(0.7)
    if jpg.is_empty() or jpg.size() > 90000:
        push_error("TSTSS_FIVE_LIGHTS_NATIVE_CAPTURE_FAIL: review preview bounds")
        quit(1)
        return
    print("TSTSS_FIVE_LIGHTS_NATIVE_CAPTURE_PASS:960x640 sha256=" + FileAccess.get_sha256(full_path))
    print("TSTSS_FIVE_LIGHTS_REVIEW_JPEG_480x320_BEGIN")
    print(Marshalls.raw_to_base64(jpg))
    print("TSTSS_FIVE_LIGHTS_REVIEW_JPEG_480x320_END")
    stage.queue_free()
    quit(0)
