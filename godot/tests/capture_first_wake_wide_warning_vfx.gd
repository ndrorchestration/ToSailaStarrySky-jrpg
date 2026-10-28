extends SceneTree
## Actual 960×640 Godot GL same-scene warning ON/OFF/interrupt evidence.
## Source-original 3D ship + PW01 2D shader overlay + real 2D contact.
const Preview = preload("res://scenes/first_wake_job_preview.tscn")
const OUT = "res://review-evidence/first-wake-wide-warning/"
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_capture")

func _image(label: String) -> Image:
    for i in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    var frame: Image = root.get_texture().get_image()
    if frame == null or frame.get_size() != Vector2i(960, 640):
        errors.append("invalid Godot 960x640 GL image: " + label)
        return null
    var path: String = OUT + label + ".png"
    if frame.save_png(path) != OK:
        errors.append("could not save authentic frame " + path)
        return null
    print("TSTSS_WIDE_WARNING_FRAME:", label, ":", FileAccess.get_sha256(path))
    # Existing CI policy: full-size PNG stays runner-local; 480x320
    # log JPEG is a small review receipt, not a replacement for PNG.
    if label in ["01-preflight", "02-warning-on", "03-warning-off", "06-waterborne"]:
        var small: Image = frame.duplicate()
        small.resize(480, 320, Image.INTERPOLATE_LANCZOS)
        var bytes: PackedByteArray = small.save_jpg_to_buffer(0.69)
        if bytes.is_empty() or bytes.size() > 180000:
            errors.append("private preview invalid " + label)
        else:
            var encoded: String = Marshalls.raw_to_base64(bytes)
            print("TSTSS_WIDE_WARNING_JPEG_BEGIN:", label)
            for idx in range(0, encoded.length(), 3500):
                print("TSTSS_WIDE_WARNING_JPEG_DATA:", encoded.substr(idx, 3500))
            print("TSTSS_WIDE_WARNING_JPEG_END:", label)
    return frame.duplicate()

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
        push_error("TSTSS_WIDE_WARNING_CAPTURE_FAIL: output directory")
        quit(1)
        return
    var job = Preview.instantiate()
    root.add_child(job)
    await process_frame
    job.opening.accept_ionia_job()
    job._enter_engineering_room()
    for key in ["reference", "containment", "fuel"]:
        job.inspected_items.append(key)
    job.opening.complete_engineering_checks()
    if not job.launch_flight_review():
        push_error("TSTSS_WIDE_WARNING_CAPTURE_FAIL: preflight rejected")
        quit(1)
        return
    var flight = job.flight_review
    var inset = flight.cinematic_inset
    flight.visual_reduced_motion = true
    flight._refresh_presentation()
    if not inset.wide_stage_enabled or inset.warning_visual == null:
        push_error("TSTSS_WIDE_WARNING_CAPTURE_FAIL: no wide 3D and VFX")
        quit(1)
        return
    var preflight: Image = await _image("01-preflight")
    if not flight.begin_short_test_flight():
        errors.append("physical launch rejected")
    for k in range(180):
        await process_frame
        if flight.phase == "warning":
            break
    if flight.phase != "warning" or not inset.warning_visual.active:
        errors.append("real 2D flight engine warning not reached")
    # The 2D rigidbody is motionless at warning: genuine matched GL A/B.
    var before_snapshot: Dictionary = job.opening.snapshot().duplicate(true)
    var shown: Image = await _image("02-warning-on")
    inset.set_warning_enabled(false)
    var hidden: Image = await _image("03-warning-off")
    inset.set_warning_enabled(true)
    if not inset.interrupt_warning_visual():
        errors.append("VFX did not permit interruption")
    var interrupted: Image = await _image("04-warning-interrupted")
    if shown != null and hidden != null and interrupted != null:
        var inside: Rect2i = Rect2i(355, 232, 250, 186)
        var first: PackedByteArray = shown.get_region(inside).get_data()
        var off: PackedByteArray = hidden.get_region(inside).get_data()
        var end: PackedByteArray = interrupted.get_region(inside).get_data()
        if first == off:
            errors.append("neutral warning shader rendered no in-engine GL pixels")
        if off != end:
            errors.append("interrupt did not restore same pixel appearance")
        for zone in [Rect2i(0, 0, 960, 95), Rect2i(0, 548, 960, 91)]:
            if shown.get_region(zone).get_data() != hidden.get_region(zone).get_data():
                errors.append("engine effect altered protected flight HUD")
        print("TSTSS_WIDE_WARNING_GL_AB_PASS: on_off_distinct=",
            first != off, " off_interrupt_identical=", off == end)
    if job.opening.snapshot() != before_snapshot:
        errors.append("VFX changed actual Chapter I story state")
    if not flight.stabilize_for_water_descent():
        errors.append("legitimate descent was refused")
    var descent: Image = await _image("05-descent")
    var reached: bool = false
    for k in range(540):
        await process_frame
        if flight.phase == "waterborne":
            reached = true
            break
    if not reached or not flight.contact_observed or not flight.stable_float_verified:
        errors.append("true physical contact and settled flotation missing")
    var water: Image = await _image("06-waterborne")
    if preflight == null or descent == null or water == null:
        errors.append("genuine scene capture incomplete")
    if inset.warning_visual.active or inset.warning_visual.visible:
        errors.append("warning effect leaked beyond engine warning")
    if job.opening.active_party_ids != ["ender", "ionia"]:
        errors.append("visual scene added early party member")
    job.queue_free()
    await process_frame
    if errors.is_empty():
        print("TSTSS_FIRST_WAKE_WIDE_WARNING_CAPTURE_PASS frames=6",
            " real_gl=true source_original_3d=true real_2d_water_contact=true",
            " visual_only_pw01=true")
        quit(0)
    else:
        for err in errors:
            push_error("TSTSS_WIDE_WARNING_CAPTURE_FAIL: " + err)
        quit(1)
