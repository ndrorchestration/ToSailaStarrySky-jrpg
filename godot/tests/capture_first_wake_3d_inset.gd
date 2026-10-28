extends SceneTree
## Real Godot Compatibility GL framebuffer proof of the live Chapter I
## inset. Built from original PR486 3D ship mesh, NOT a prerecorded mockup.
const Preview = preload("res://scenes/first_wake_job_preview.tscn")
var problems: Array[String] = []

func _initialize() -> void:
    call_deferred("_capture")

func _frame() -> Image:
    for i in range(14):
        await process_frame
        await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _private_review_jpeg(frame: Image, label: String) -> void:
    # Existing visual QA custody: native 960x640 originals remain runner-only.
    # Small low-quality JPEG is printed in bounded chunks for inspection.
    if not (label.begins_with("01-") or label.begins_with("02-") or label.begins_with("05-")):
        return
    var reduced: Image = frame.duplicate()
    reduced.resize(480, 320, Image.INTERPOLATE_LANCZOS)
    var bytes: PackedByteArray = reduced.save_jpg_to_buffer(0.68)
    if bytes.is_empty() or bytes.size() > 180000:
        problems.append("private 3D shot preview encoding failed or exceeded 180KB")
        return
    var encoded: String = Marshalls.raw_to_base64(bytes)
    print("TSTSS_3D_PRIVATE_JPEG_BEGIN:" + label + ":480x320")
    for i in range(0, encoded.length(), 3500):
        print("TSTSS_3D_PRIVATE_JPEG_DATA:" + encoded.substr(i, 3500))
    print("TSTSS_3D_PRIVATE_JPEG_END:" + label)

func _save(dir: String, label: String) -> Image:
    var image: Image = await _frame()
    if image == null or image.get_size() != Vector2i(960, 640):
        problems.append("invalid actual Godot viewport dimensions for " + label)
        return null
    var path: String = dir.path_join(label + ".png")
    if image.save_png(path) != OK:
        problems.append("could not write actual rendered " + path)
        return null
    print("NATIVE_FIRST_WAKE_3D_FRAME: ", path)
    _private_review_jpeg(image, label)
    return image.duplicate()

func _delta(a: Image, b: Image) -> float:
    # Only the actual 355x200 SubViewport panel is sampled, excluding the
    # timeline text and moving 2D physics body outside the visual region.
    var total: float = 0.0
    for y in range(164, 326, 8):
        for x in range(586, 924, 8):
            var lhs: Color = a.get_pixel(x, y)
            var rhs: Color = b.get_pixel(x, y)
            total += absf(lhs.r-rhs.r)+absf(lhs.g-rhs.g)+absf(lhs.b-rhs.b)
    return total

func _capture() -> void:
    var world = Preview.instantiate()
    root.add_child(world)
    await process_frame
    world.opening.accept_ionia_job()
    world._enter_engineering_room()
    for item in ["reference", "containment", "fuel"]:
        world.inspected_items.append(item)
    world.opening.complete_engineering_checks()
    if not world.launch_flight_review():
        push_error("TSTSS_FIRST_WAKE_3D_CAPTURE_FAIL: authentic job preflight rejected")
        quit(1)
        return
    var flight = world.flight_review
    if flight == null or flight.cinematic_inset == null:
        push_error("TSTSS_FIRST_WAKE_3D_CAPTURE_FAIL: native 3D viewport missing")
        quit(1)
        return
    var folder: String = ProjectSettings.globalize_path("res://review-evidence/first-wake-3d")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("TSTSS_FIRST_WAKE_3D_CAPTURE_FAIL: output folder unavailable")
        quit(1)
        return
    var preflight: Image = await _save(folder, "01-preflight-bow-real-3d")
    if not flight.begin_short_test_flight():
        problems.append("native launch rejected")
    var ascent: Image = await _save(folder, "02-ascent-planform-real-3d")
    var warned: bool = false
    for k in range(180):
        await process_frame
        if flight.phase == "warning":
            warned = true
            break
    if not warned:
        problems.append("real 2D flight warning never reached")
    var warning: Image = await _save(folder, "03-warning-stern-real-3d")
    if warned and not flight.stabilize_for_water_descent():
        problems.append("real 2D descent rejected")
    var descent: Image = await _save(folder, "04-descent-bow-real-3d")
    var waterborne: bool = false
    for k in range(540):
        await process_frame
        if flight.phase == "waterborne":
            waterborne = true
            break
    if not waterborne:
        problems.append("no real Area2D contact and flotation")
    var final: Image = await _save(folder, "05-waterborne-stern-real-3d")
    if preflight != null and ascent != null and warning != null and descent != null and final != null:
        var bow_wing: float = _delta(preflight, ascent)
        var wing_stern: float = _delta(ascent, warning)
        var stern_bow: float = _delta(warning, descent)
        var bow_stern: float = _delta(descent, final)
        print("NATIVE_FIRST_WAKE_3D_INSET_CAMERA_DELTAS bowwing=", bow_wing,
            " wingstern=", wing_stern, " sternbow=", stern_bow, " bowstern=", bow_stern)
        for delta in [bow_wing, wing_stern, stern_bow, bow_stern]:
            if delta < 4.0:
                problems.append("real 3D camera panel did not change with story phase")
    else:
        problems.append("incomplete five-frame render capture")
    if not flight.contact_observed or not flight.stable_float_verified:
        problems.append("cinematic image falsely claimed physical splashdown")
    if world.opening.active_party_ids != ["ender", "ionia"]:
        problems.append("visual handoff incorrectly recruited Lyra")
    if not flight.visual_review_snapshot().get("is_actual_native_3d_subviewport", false):
        problems.append("image did not originate from real native 3D viewport")
    world.queue_free()
    await process_frame
    if problems.is_empty():
        print("TSTSS_FIRST_WAKE_3D_CAPTURE_PASS frames=5 genuine-gl=true",
            " local-2d-physics=true original-3d-ship=true")
        quit(0)
    else:
        for msg in problems:
            push_error("TSTSS_FIRST_WAKE_3D_CAPTURE_FAIL: " + msg)
        quit(1)
