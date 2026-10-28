extends SceneTree
## GL output capture. PNGs are authoritative runner-local evidence;
## small lossy JPEGs are explicitly marked human-inspection derivatives.
const Studio = preload("res://scenes/five_lights_motion_studio.tscn")

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var stage = Studio.instantiate()
    root.add_child(stage)
    stage.keyboard_enabled = false
    await process_frame
    await RenderingServer.frame_post_draw
    var original_sha: String = _save("IDLE")
    if original_sha.is_empty():
        quit(1)
        return

    var ender = stage.cast_actors["Ender"]
    var initial: Vector2 = ender.global_position
    ender.set_motion(Vector2.RIGHT)
    for tick in range(30):
        await physics_frame
    if ender.global_position.x <= initial.x + 20.0 or ender.facing != "east" or ender.phase == 0:
        push_error("TSTSS_FIVE_LIGHTS_NATIVE_CAPTURE_FAIL: no optical sprite motion on native physics root")
        quit(1)
        return
    # Capture the actor during a genuine travel-distance-driven pose,
    # rather than freezing a post-motion idle frame.
    stage._update_hud()
    await RenderingServer.frame_post_draw
    var moving_sha: String = _save("MOVING")
    if moving_sha.is_empty() or moving_sha == original_sha:
        push_error("TSTSS_FIVE_LIGHTS_NATIVE_CAPTURE_FAIL: unchanged moving frame")
        quit(1)
        return

    ender.set_motion(Vector2.ZERO)
    await physics_frame
    stage.reduced_motion = true
    stage.ambience.set_shader_parameter("reduced_motion", true)
    stage._update_hud()
    await process_frame
    await RenderingServer.frame_post_draw
    var still_sha: String = _save("REDUCED_MOTION")
    if still_sha.is_empty():
        quit(1)
        return
    print("TSTSS_FIVE_LIGHTS_NATIVE_CAPTURE_PASS:frames=3 native_960x640=true ender_physics_moved=true atmos_still=true")
    stage.queue_free()
    quit(0)

func _save(label: String) -> String:
    var frame: Image = root.get_viewport().get_texture().get_image()
    if frame == null or frame.get_width() != 960 or frame.get_height() != 640:
        push_error("TSTSS_FIVE_LIGHTS_NATIVE_CAPTURE_FAIL: framebuffer dimensions")
        return ""
    var png_path: String = "/tmp/tstss_five_lights_%s_native_960x640.png" % label.to_lower()
    if frame.save_png(png_path) != OK:
        push_error("TSTSS_FIVE_LIGHTS_NATIVE_CAPTURE_FAIL: could not save original PNG " + label)
        return ""
    var digest: String = FileAccess.get_sha256(png_path)
    var review: Image = frame.duplicate()
    review.resize(480, 320, Image.INTERPOLATE_LANCZOS)
    var jpeg: PackedByteArray = review.save_jpg_to_buffer(0.74)
    if jpeg.size() <= 0 or jpeg.size() > 90000:
        push_error("TSTSS_FIVE_LIGHTS_NATIVE_CAPTURE_FAIL: invalid 480x320 JPEG")
        return ""
    print("TSTSS_FIVE_LIGHTS_NATIVE_FRAME:" + label + ":sha256=" + digest)
    print("TSTSS_FIVE_LIGHTS_REVIEW_JPEG_" + label + "_BEGIN")
    print(Marshalls.raw_to_base64(jpeg))
    print("TSTSS_FIVE_LIGHTS_REVIEW_JPEG_" + label + "_END")
    return digest
