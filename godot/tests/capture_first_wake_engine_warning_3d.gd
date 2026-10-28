extends SceneTree
## Real GL pixels from one 3D inset AND physically authoritative 2D flight scene.
const Scene = preload("res://scenes/first_wake_engine_warning_3d_review.tscn")
const OUT = "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _shot(file: String) -> Image:
    for i in range(3):
        await RenderingServer.frame_post_draw
    var img: Image = root.get_texture().get_image()
    if img.is_empty() or img.get_size() != Vector2i(960, 640):
        push_error("TSTSS_PW02_3D_CAPTURE_FAIL: invalid framebuffer")
        return null
    if img.save_png(OUT + file) != OK:
        push_error("TSTSS_PW02_3D_CAPTURE_FAIL: cannot save evidence")
        return null
    print("TSTSS_PW02_FRAME:" + file + ":960x640:" + FileAccess.get_sha256(OUT + file))
    return img

func _capture() -> void:
    root.size = Vector2i(960, 640)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
        push_error("TSTSS_PW02_3D_CAPTURE_FAIL: dir unavailable")
        quit(1)
        return
    var s = Scene.instantiate()
    root.add_child(s)
    await process_frame
    var idle: Image = await _shot("pw02-real3d-engine-before-launch-native-960x640.png")
    if idle == null or not s.flight.begin_short_test_flight():
        push_error("TSTSS_PW02_3D_CAPTURE_FAIL: preflight")
        quit(2)
        return
    var warning := false
    for i in range(180):
        await process_frame
        if s.flight.phase == "warning":
            warning = true
            break
    if not warning:
        push_error("TSTSS_PW02_3D_CAPTURE_FAIL: no genuine phase warning")
        quit(3)
        return
    s.synchronize_visual()
    s.synchronize_3d_alarm()
    var lit: Image = await _shot("pw02-real3d-engine-warning-on-native-960x640.png")
    s.set_visual_enabled(false)
    s.synchronize_3d_alarm()
    var unlit: Image = await _shot("pw02-real3d-engine-warning-off-native-960x640.png")
    if lit == null or unlit == null:
        quit(4)
        return
    var roi := Rect2i(int(s.INSET_POSITION.x), int(s.INSET_POSITION.y), s.INSET_SIZE.x, s.INSET_SIZE.y)
    if lit.get_region(roi).get_data() == unlit.get_region(roi).get_data():
        push_error("TSTSS_PW02_3D_CAPTURE_FAIL: actual 3D inset has no native lighting/emissive pixel delta")
        quit(5)
        return
    for hud in [Rect2i(0, 0, 960, 95), Rect2i(0, 550, 960, 90)]:
        if lit.get_region(hud).get_data() != unlit.get_region(hud).get_data():
            push_error("TSTSS_PW02_3D_CAPTURE_FAIL: engine cue altered main story UI")
            quit(6)
            return
    s.set_visual_enabled(true)
    s.synchronize_3d_alarm()
    if not s.interrupt_visual():
        push_error("TSTSS_PW02_3D_CAPTURE_FAIL: interrupt denied")
        quit(7)
        return
    s.synchronize_3d_alarm()
    var interrupted: Image = await _shot("pw02-real3d-engine-interrupted-native-960x640.png")
    if interrupted == null or interrupted.get_region(roi).get_data() != unlit.get_region(roi).get_data():
        push_error("TSTSS_PW02_3D_CAPTURE_FAIL: 3D alarm persisted after interrupt")
        quit(8)
        return
    if not s.flight.stabilize_for_water_descent():
        push_error("TSTSS_PW02_3D_CAPTURE_FAIL: real descent denied")
        quit(9)
        return
    var afloat := false
    for i in range(540):
        await process_frame
        if s.flight.phase == "waterborne":
            afloat = true
            break
    if not afloat or not s.flight.contact_observed or not s.flight.stable_float_verified:
        push_error("TSTSS_PW02_3D_CAPTURE_FAIL: real native water contact not observed")
        quit(10)
        return
    var water: Image = await _shot("pw02-real3d-engine-physical-waterborne-native-960x640.png")
    if water == null:
        quit(11)
        return
    s.queue_free()
    await process_frame
    print("TSTSS_PW02_3D_CAPTURE_PASS: real candidate hull/wing Camera3D SubViewport GL, on/off/interrupt pixels, live original 2D splashdown")
    print("TSTSS_PW02_3D_GPU_FRAME_TIME=NOT_PROFILED")
    print("TSTSS_PW02_3D_ART_APPROVAL=PENDING")
    quit(0)
