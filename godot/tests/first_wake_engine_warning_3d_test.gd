extends SceneTree
## PW-02: real 3D ship in actual SubViewport; flight authority is 2D-only.
const Review = preload("res://scenes/first_wake_engine_warning_3d_review.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(why: String) -> void:
    push_error("TSTSS_PW02_3D_FAIL: " + why)
    quit(1)

func _verify() -> void:
    var s = Review.instantiate()
    root.add_child(s)
    await process_frame
    if s.viewport3d == null or not s.viewport3d.own_world_3d or s.viewport3d.size != s.INSET_SIZE:
        _fail("independent real 3D viewport absent")
        return
    if s.camera3d == null or not s.camera3d.current or s.camera3d.fov != 54.0:
        _fail("real 3D camera/frame contract broken")
        return
    if not (s.ship3d.get_node_or_null("LongHull") is MeshInstance3D):
        _fail("actual provenance-copied procedural 3D hull missing")
        return
    for component in ["WingRig_PortFore", "WingRig_PortAft", "WingRig_StarboardFore", "WingRig_StarboardAft", "HelmGlass", "AftTurbine", "ExhaustThroat"]:
        if s.ship3d.get_node_or_null(component) == null:
            _fail("missing original 3D ship geometry: " + component)
            return
    if s.active_camera_shot != "bow-quarter" or s.camera3d.position != s.SHOT_CAMERAS["bow-quarter"]:
        _fail("real preflight phase not mapped to bow-quarter 3D camera")
        return
    if s.halo3d.visible or s.light3d.visible or s.applied_visual_state or s.flight.phase != "awaiting_launch":
        _fail("3D energy activated without the original flight warning")
        return
    var original_party: Array = s.opening.active_party_ids.duplicate()
    if original_party != ["ender", "ionia"] or not s.reduced_motion or s.detail_level != 0:
        _fail("Ionia-first party / reduced-motion safety contract drift")
        return
    if not s.flight.begin_short_test_flight():
        _fail("actual Ionia-first flight refused")
        return
    await process_frame
    s.synchronize_3d_alarm()
    if s.active_camera_shot != "wing-planform" or s.camera3d.position != s.SHOT_CAMERAS["wing-planform"]:
        _fail("real ascent did not select 3D wing-planform shot")
        return
    var warning := false
    for i in range(180):
        await process_frame
        if s.flight.phase == "warning":
            warning = true
            break
    s.synchronize_visual()
    s.synchronize_3d_alarm()
    if not warning or not s.halo3d.visible or not s.light3d.visible or not s.applied_visual_state:
        _fail("3D engine did not follow real warning-only admission")
        return
    if s.active_camera_shot != "stern-quarter" or s.camera3d.position != s.SHOT_CAMERAS["stern-quarter"]:
        _fail("real phase warning not mapped to 3D stern-quarter shot")
        return
    s.set_light_only_review(true)
    if s.halo3d.visible or not s.light3d.visible:
        _fail("light-only native material witness unavailable")
        return
    s.set_light_only_review(false)
    if not s.halo3d.visible or not s.light3d.visible:
        _fail("3D alarm could not restore complete rendering")
        return
    var snapshot: Dictionary = s.opening.snapshot()
    var position2d: Vector2 = s.flight.ship_body.position
    var position3d: Vector3 = s.ship3d.position
    s.set_visual_enabled(false)
    s.synchronize_3d_alarm()
    if s.halo3d.visible or s.light3d.visible:
        _fail("3D cue remained on when 2D presentation disabled")
        return
    s.set_visual_enabled(true)
    s.synchronize_3d_alarm()
    if not s.applied_visual_state or not s.interrupt_visual():
        _fail("interrupt not supported")
        return
    s.synchronize_3d_alarm()
    if s.halo3d.visible or s.light3d.visible:
        _fail("3D cue did not respect interrupted presentation")
        return
    if s.opening.snapshot() != snapshot or s.flight.ship_body.position != position2d or s.ship3d.position != position3d:
        _fail("visual operation changed story, 2D physics or 3D ship transform")
        return
    if not s.flight.stabilize_for_water_descent():
        _fail("real 2D controlled descent refused")
        return
    await process_frame
    s.synchronize_3d_alarm()
    if s.active_camera_shot != "bow-quarter" or s.camera3d.position != s.SHOT_CAMERAS["bow-quarter"]:
        _fail("legitimate controlled descent did not restore 3D bow-quarter shot")
        return
    var waterborne := false
    for i in range(540):
        await process_frame
        if s.flight.phase == "waterborne":
            waterborne = true
            break
    if not waterborne or not s.flight.contact_observed or not s.flight.stable_float_verified:
        _fail("actual physics splashdown blocked by independent 3D inset")
        return
    s.synchronize_3d_alarm()
    if s.active_camera_shot != "stern-quarter":
        _fail("real waterborne physical phase did not select stern-quarter")
        return
    if s.applied_visual_state or s.halo3d.visible or s.light3d.visible:
        _fail("3D warning persisted after real 2D splashdown")
        return
    if s.opening.active_party_ids != original_party or s.flight.review_snapshot()["fuel_formula"] != "unknown":
        _fail("visual passed through a narrative authority boundary")
        return
    s.queue_free()
    await process_frame
    print("TSTSS_PW02_3D_PASS: authentic hull+four wings Camera3D/SubViewport, 3 phase-derived 3D camera shots, 3D light-only witness, warning disabled/interrupt, 2D splashdown unchanged")
    print("TSTSS_PW02_3D_ART_ACCEPTANCE=PENDING")
    quit(0)
