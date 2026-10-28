extends SceneTree
## Native integration contract for the real 3D wide stage driven only by
## the original Ionia-first 2D physics source of truth. Noncanonical visual QA.
const Preview = preload("res://scenes/first_wake_job_preview.tscn")
var errors: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, description: String) -> void:
    checks += 1
    if not ok:
        errors.append(description)

func _run() -> void:
    var world = Preview.instantiate()
    root.add_child(world)
    await process_frame
    check(not world.launch_flight_review(), "cannot board before creator-directed Ionia hiring")
    check(world.opening.accept_ionia_job(), "Ionia aboard before first flight")
    world._enter_engineering_room()
    for key in ["reference", "containment", "fuel"]:
        world.inspected_items.append(key)
    check(world.opening.complete_engineering_checks(), "preflight gate authentic")
    check(world.launch_flight_review(), "real job scene opens local flight preview")
    var flight = world.flight_review
    if flight == null or flight.cinematic_inset == null:
        _fail("missing actual full-width Godot 3D render adapter")
        return
    var inset = flight.cinematic_inset
    var view: Dictionary = flight.visual_review_snapshot()
    check(view.get("is_actual_native_3d_subviewport", false), "actual native World3D present")
    check(view.get("wide_stage_enabled", false), "wide scene active by default in optional job preview")
    check(view.get("inset_dimensions", Vector2i.ZERO) == Vector2i(960, 442),
        "full-width stage exactly 960x442 below the HUD")
    check(inset.position == Vector2(0, 103), "wide composition stays below upper HUD")
    check(inset.shot_camera is Camera3D and inset.ship_model.has_node("LongHull"),
        "source-original 3D hull and native camera present")
    check(inset.ship_model.has_node("WingRig_PortFore")
        and inset.ship_model.has_node("WingRig_PortAft")
        and inset.ship_model.has_node("WingRig_StarboardFore")
        and inset.ship_model.has_node("WingRig_StarboardAft"),
        "all four original visual wings preserved")
    var physics_body = flight.ship_body
    var physics_y: float = physics_body.position.y
    var story: Dictionary = world.opening.snapshot().duplicate(true)
    var shape = physics_body.get_child(0)
    check(shape is CollisionShape2D and shape.shape != null,
        "real 2D physical collision shape still exists in wide mode")
    var polygons: Array = []
    for child in physics_body.get_children():
        if child is Polygon2D:
            polygons.append(child)
    check(polygons.size() == 2, "exact same 2D hull and wings are fallback-only")
    for polygon in polygons:
        check(not polygon.visible, "wide cinematic hides duplicated 2D hull art only")
    check(is_equal_approx(float(view.get("physical_body_y", -1)), physics_y),
        "wide visual reads actual physical body coordinate")
    var expected: float = (flight.SURFACE_Y - 14.0 - physics_y) * inset.BODY_SCALE_Y
    check(is_equal_approx(float(view.get("visual_altitude_above_waterline", -99)), expected),
        "3D altitude is deterministic shared-waterline projection of 2D physics")
    check(is_equal_approx(inset.ship_model.position.y, expected),
        "real 3D source ship actually moves to projected physical altitude")
    check(view.get("visual_ship_has_no_colliders", false),
        "3D hull remains a visual prototype, not physical authority")

    check(not inset.sync_physical_waterline(NAN, flight.SURFACE_Y, false),
        "nonfinite forged body position rejected")
    check(is_equal_approx(inset.ship_model.position.y, expected),
        "rejected position does not alter visual ship")
    check(flight.set_cinematic_wide_mode(false),
        "reversible fallback returns to original small 3D inset")
    check(inset.viewport.size == Vector2i(355, 200),
        "original independently tested 3D monitor dimensions restored")
    check(inset.position == Vector2(578, 144), "original inset location restored")
    for polygon in polygons:
        check(polygon.visible, "real 2D ship is visible again in fallback")
    check(flight.ship_body == physics_body and is_equal_approx(physics_body.position.y, physics_y),
        "changing presentation leaves physics body untouched")
    check(world.opening.snapshot() == story, "switching presentation does not progress plot")
    check(flight.set_cinematic_wide_mode(true), "wide 3D stage is reversible on demand")
    check(inset.viewport.size == Vector2i(960, 442), "wide framebuffer restored")
    for polygon in polygons:
        check(not polygon.visible, "duplicate 2D sprites hidden on return")
    check(is_equal_approx(inset.ship_model.position.y, expected),
        "reentering wide mode reprojects real body without resets")

    check(flight.begin_short_test_flight(), "real 2D lift launches from preflight")
    var ascending_y: float = physics_body.position.y
    for k in range(28):
        await process_frame
    check(physics_body.position.y < ascending_y, "physical body truly lifts")
    check(inset.ship_model.position.y > expected, "3D original hull visibly rises with physical body")
    check(flight.phase == "ascent" or flight.phase == "warning",
        "3D view has no influence on launch sequencing")
    var warned := false
    for k in range(180):
        await process_frame
        if flight.phase == "warning":
            warned = true
            break
    check(warned, "real flight warns of engine phase instability")
    if warned:
        check(flight.stabilize_for_water_descent(), "real original pilot initiates controlled descent")
        check(not flight.contact_observed, "descent cutscene cannot forge Area2D sensor entry")
        var landed := false
        for k in range(540):
            await process_frame
            if flight.phase == "waterborne":
                landed = true
                break
        check(landed, "actual 2D Area2D physical water contact and stable float")
        if landed:
            view = flight.visual_review_snapshot()
            check(flight.contact_observed and flight.stable_float_verified,
                "waterborne stays contingent on physical contact and buoyancy")
            check(is_equal_approx(float(view["physical_body_y"]), physics_body.position.y),
                "3D reads latest exact physical buoyancy equilibrium")
            check(absf(inset.ship_model.position.y) <= 0.7,
                "ship floats near visually projected sea plane at actual stable position")
            check(view["physical_stable_for_review"], "render receives observed physical stability")
            check(not flight.review_snapshot()["production_ocean_verified"],
                "never treat simple 3D plane as physical planetary ocean")
            check(world.opening.active_party_ids == ["ender", "ionia"],
                "Lyra/Talen not erroneously recruited during first descent")

    world.queue_free()
    await process_frame
    if errors.is_empty():
        print("TSTSS_FIRST_WAKE_WIDE_3D_PASS checks=", checks,
            " source-original-3d=true physical-2d-source=true reversible=true")
        quit(0)
    else:
        for msg in errors:
            push_error("TSTSS_FIRST_WAKE_WIDE_3D_FAIL: " + msg)
        quit(1)

func _fail(msg: String) -> void:
    push_error("TSTSS_FIRST_WAKE_WIDE_3D_FAIL: " + msg)
    quit(1)
