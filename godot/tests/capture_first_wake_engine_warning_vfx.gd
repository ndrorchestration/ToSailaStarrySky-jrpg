extends SceneTree
## GL Compatibility visual compare, real first-flight state, not fabricated scene art.
const Scene = preload("res://scenes/first_wake_engine_warning_review.tscn")
const OUT = "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _frame(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var frame: Image = root.get_texture().get_image()
    if frame.is_empty() or frame.get_size() != Vector2i(960, 640):
        push_error("PW01_FRAME_FAIL: native frame dimensions wrong")
        return null
    if frame.save_png(OUT + name) != OK:
        push_error("PW01_FRAME_FAIL: evidence PNG inaccessible")
        return null
    print("TSTSS_PW01_FRAME:" + name + ":960x640:" + FileAccess.get_sha256(OUT + name))
    return frame

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
        push_error("PW01_FRAME_FAIL: evidence directory not writable")
        quit(1)
        return
    var study = Scene.instantiate()
    root.add_child(study)
    await process_frame
    var standby: Image = await _frame("pw01-aureate-wake-before-launch-native-960x640.png")
    if standby == null:
        quit(2)
        return
    if not study.flight.begin_short_test_flight():
        push_error("PW01_FRAME_FAIL: real flight launch refused")
        quit(3)
        return
    var reached: bool = false
    for i in range(180):
        await process_frame
        if study.flight.phase == "warning":
            reached = true
            break
    if not reached or not study.synchronize_visual() or not study.warning_visual.visible:
        push_error("PW01_FRAME_FAIL: genuine warning never activated the VFX")
        quit(4)
        return
    await process_frame
    var active: Image = await _frame("pw01-aureate-wake-warning-on-native-960x640.png")
    study.set_visual_enabled(false)
    await process_frame
    var disabled: Image = await _frame("pw01-aureate-wake-warning-off-native-960x640.png")
    if active == null or disabled == null:
        quit(5)
        return
    # Same ship phase/geometry. Real shader/CanvasItem must alter local pixels.
    var witness := Rect2i(366, 155, 228, 151)
    if active.get_region(witness).get_data() == disabled.get_region(witness).get_data():
        push_error("PW01_FRAME_FAIL: engine phase-warning effect generated no real pixels")
        quit(6)
        return
    # High/low UI witness must be identical: a VFX effect may not overdraw labels.
    for zone in [Rect2i(0, 0, 960, 96), Rect2i(0, 547, 960, 90)]:
        if active.get_region(zone).get_data() != disabled.get_region(zone).get_data():
            push_error("PW01_FRAME_FAIL: magic presentation leaked into the flight HUD")
            quit(7)
            return
    study.set_visual_enabled(true)
    await process_frame
    if not study.interrupt_visual():
        push_error("PW01_FRAME_FAIL: visual interruption refused")
        quit(8)
        return
    await process_frame
    var interrupted: Image = await _frame("pw01-aureate-wake-warning-interrupted-native-960x640.png")
    if interrupted == null:
        quit(9)
        return
    if interrupted.get_region(witness).get_data() != disabled.get_region(witness).get_data():
        push_error("PW01_FRAME_FAIL: interrupted cue did not restore the same clean scene")
        quit(10)
        return
    if not study.flight.stabilize_for_water_descent():
        push_error("PW01_FRAME_FAIL: native controlled descent refused")
        quit(11)
        return
    await process_frame
    var descent: Image = await _frame("pw01-aureate-wake-real-descent-native-960x640.png")
    if descent == null:
        quit(12)
        return
    var floated: bool = false
    for i in range(540):
        await process_frame
        if study.flight.phase == "waterborne":
            floated = true
            break
    if not floated or not study.flight.contact_observed or not study.flight.stable_float_verified:
        push_error("PW01_FRAME_FAIL: native physical waterborne state not achieved")
        quit(13)
        return
    await process_frame
    var water: Image = await _frame("pw01-aureate-wake-physics-waterborne-native-960x640.png")
    if water == null:
        quit(14)
        return
    study.queue_free()
    await process_frame
    print("TSTSS_PW01_NATIVE_CAPTURE_PASS: genuine local VFX-on/off/interrupt 960x640 framebuffer and verified physical splashdown")
    print("TSTSS_PW01_ART_ACCEPTANCE=PENDING")
    quit(0)
