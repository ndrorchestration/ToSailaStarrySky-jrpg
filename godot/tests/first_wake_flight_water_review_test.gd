extends SceneTree
## Real native Godot 2D physics landing proof for revised First Wake.
## Only the opt-in local review scene; not global ocean physics or player approval.

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var source: PackedScene = load("res://scenes/first_wake_job_preview.tscn")
    if source == null:
        _fail("employment scene not importable")
        return
    var world = source.instantiate()
    root.add_child(world)
    await process_frame

    if world.launch_flight_review():
        _fail("test flight entered before Ionia hired Ender and safety checks completed")
        return
    if not world.opening.accept_ionia_job():
        _fail("Ionia-first baseline missing")
        return
    world._enter_engineering_room()
    world.inspected_items = ["reference", "containment", "fuel"]
    if world.launch_flight_review():
        _fail("test flight entered before state contract accepted preflight")
        return
    if not world.opening.complete_engineering_checks():
        _fail("authorized preflight progression rejected")
        return
    if not world.launch_flight_review():
        _fail("preflight did not hand off into physical flight scene")
        return
    if world.room != "flight_review" or world.ui_layer.visible or world.ender.visible:
        _fail("job scene not visually isolated from flight stage")
        return
    var flight = world.flight_review
    if flight == null or flight.opening != world.opening:
        _fail("Ionia-first contract state was not preserved in the handoff")
        return
    if flight.phase != "awaiting_launch" or flight.opening.active_party_ids != ["ender", "ionia"]:
        _fail("flight stage starts with incorrect story party or initial state")
        return
    if flight.stabilize_for_water_descent():
        _fail("predeparture stabilization wrongly accepted")
        return
    if world.interact():
        _fail("underlying employment scene consumed flight controls")
        return
    if not flight.interact() or flight.opening.step_key() != "test_flight":
        _fail("first-flight launch rejected")
        return
    if flight.contact_observed or flight.stable_float_verified:
        _fail("water contact was claimed while still flying")
        return
    if flight.begin_short_test_flight():
        _fail("duplicate launch accepted")
        return

    # Native script SceneTree reliably emits process_frame in headless CI;
    # the dynamic RigidBody2D must still be advanced by the physics server.
    var became_warning := false
    for i in range(180):
        await process_frame
        if flight.phase == "warning":
            became_warning = true
            break
    if not became_warning:
        _fail("flight never revealed phase drift and descent warning")
        return
    if not flight.interact() or flight.phase != "descent" or not flight.opening.failure_logged:
        _fail("deliberate stabilization did not create controlled descent")
        return
    if flight.interact():
        _fail("second emergency stabilization action was accepted")
        return

    var waterborne := false
    for i in range(540):
        await process_frame
        if flight.phase == "waterborne":
            waterborne = true
            break
    if not waterborne:
        _fail("actual 2D water-contact and buoyancy stabilization did not complete")
        return
    var review: Dictionary = flight.review_snapshot()
    if not review["actual_2d_area_contact_observed"] or not review["stable_buoyant_hull_observed"]:
        _fail("physics sensor or sustained buoyant stability was bypassed")
        return
    if review["story_step"] != "waterborne" or review["party"] != ["ender", "ionia"]:
        _fail("ocean completion lost revised scene chronology")
        return
    if review["production_ocean_verified"] or review["fuel_formula"] != "unknown":
        _fail("review elevated local physics or guessed specialized fuel")
        return
    if absf(float(review["hull_y"]) - (flight.SURFACE_Y - 14.0)) > 19.0:
        _fail("ship was reported afloat outside the observed waterline")
        return
    if "lyra" in flight.opening.active_party_ids:
        _fail("Lyra joined before the safe post-splashdown reunion")
        return
    if flight.opening.inspect_postflight_reserve(false):
        _fail("postflight diagnosis accepted without reserve evidence")
        return

    world.queue_free()
    await process_frame
    print("TSTSS_FIRST_WAKE_PHYSICS_SPLASHDOWN_PASS: Ionia-first preflight, actual RigidBody2D/Area2D water contact, settled flotation, safe story gate, no premature Lyra or fuel revelation")
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_PHYSICS_SPLASHDOWN_FAIL: " + reason)
    quit(1)
