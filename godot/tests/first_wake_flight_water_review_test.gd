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
    for item in ["reference", "containment", "fuel"]:
        world.inspected_items.append(item)
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
    if flight.record_afloat_recovery_brief():
        _fail("recovery brief accessible before water contact")
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
    if review.get("reserve_inspection_observed", true) or review.get("real_inventory_scan_verified", true):
        _fail("water-contact receipt prematurely claimed material inventory evidence")
        return
    if flight.inspect_empty_reserve_after_splashdown():
        _fail("could inspect reserve without boarding the onboard review")
        return
    if not flight.interact() or flight.phase != "afloat_inspection":
        _fail("stable float did not open the gated onboard reserve deck")
        return
    if not flight.review_snapshot().get("afloat_station_entered", false):
        _fail("afloat station did not enter the actual flight scene")
        return
    if flight.open_afloat_reserve_review() or flight.interact():
        _fail("duplicate entry or distant inspection was incorrectly permitted")
        return
    var deck = flight.afloat_review
    if deck == null or deck.opening != flight.opening:
        _fail("afloat review lost the shared story contract")
        return
    if deck.review_snapshot().get("real_inventory_scan_verified", true):
        _fail("afloat station incorrectly claimed inventory verification")
        return
    var before_walk: float = deck.ender.position.x
    if not deck.ender.player_controlled or not deck.ender.is_physics_processing():
        _fail("afloat Ender actor was not configured for live movement")
        return
    Input.action_press("ui_right")
    for i in range(50):
        await physics_frame
    Input.action_release("ui_right")
    print("TSTSS_AFLOAT_MOVE_DIAGNOSTIC: start=", before_walk, " end=", deck.ender.position.x, " global=", deck.ender.global_position.x, " velocity=", deck.ender.velocity, " active=", deck.ender.player_controlled)
    if deck.ender.position.x <= before_walk:
        _fail("Ender could not physically move in the reserve station scene")
        return
    if flight.interact() or deck.inspection_observed:
        _fail("remote inspection was possible before arriving at the station")
        return
    deck.ender.position = deck.RESERVE_POSITION
    if not flight.interact() or flight.phase != "postflight_diagnosis":
        _fail("nearby reserve-station inspection failed to advance the story")
        return
    if not flight.review_snapshot().get("physical_reserve_interaction_verified", false):
        _fail("actual onboard reserve interaction receipt missing")
        return
    if deck.review_snapshot().get("salvage_verified", true):
        _fail("onboard inspection improperly granted physical salvage")
        return
    if flight.opening.step_key() != "postflight_diagnosis":
        _fail("inspected empty reserve did not enter postflight story state")
        return
    if not flight.review_snapshot().get("reserve_inspection_observed", false):
        _fail("inspection receipt missing after authored reserve confirmation")
        return
    if flight.review_snapshot().get("real_inventory_scan_verified", true):
        _fail("authored review incorrectly claimed actual inventory implementation")
        return
    if flight.interact() or "lyra" in flight.opening.active_party_ids:
        _fail("duplicate inspection or premature Lyra reunion admitted")
        return

    if flight.record_afloat_recovery_brief() or deck.record_recovery_brief():
        _fail("distant recovery log was recorded without actual approach")
        return
    if deck.review_snapshot().get("recovery_brief_recorded", true):
        _fail("recovery log began already completed")
        return
    var before_log_walk: float = deck.ender.position.x
    Input.action_press("ui_left")
    for i in range(90):
        await physics_frame
    Input.action_release("ui_left")
    if deck.ender.position.x >= before_log_walk - 60.0:
        _fail("Ender could not walk across the afloat deck toward recovery log")
        return
    if deck.ender.position.distance_to(deck.BRIEF_POSITION) > deck.INTERACT_RADIUS:
        _fail("physical walking could not reach the recovery board")
        return
    if not flight.interact() or flight.phase != "recovery_brief_recorded":
        _fail("physical recovery observation log did not complete")
        return
    var brief: Dictionary = deck.review_snapshot()
    if not brief.get("recovery_brief_recorded", false) or brief.get("known_observation_ids", []) != ["local_contact", "local_float", "empty_reserve"]:
        _fail("recovery log failed to record exactly the known observations")
        return
    if brief.get("fuel_formula_known", true) or brief.get("recovery_deployment_authorized", true) or brief.get("family_reunion_authorized", true):
        _fail("recovery board granted unverified knowledge, deployment or reunion")
        return
    var flight_report: Dictionary = flight.review_snapshot()
    if not flight_report.get("recovery_brief_recorded", false) or flight_report.get("recovery_route_verified", true) or flight_report.get("rescue_or_salvage_authorized", true):
        _fail("flight report elevated staged recovery log to approved recovery")
        return
    if flight.opening.step_key() != "postflight_diagnosis" or flight.opening.active_party_ids != ["ender", "ionia"]:
        _fail("staged observation log advanced restricted story or crew state")
        return
    if flight.interact() or deck.record_recovery_brief():
        _fail("duplicate recovery brief recording was admitted")
        return

    world.queue_free()
    await process_frame
    print("TSTSS_FIRST_WAKE_PHYSICS_SPLASHDOWN_PASS: Ionia-first preflight, actual RigidBody2D/Area2D water contact, settled flotation, navigable afloat reserve-station proximity gate and post-diagnosis recovery log, no Lyra or fuel revelation")
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_PHYSICS_SPLASHDOWN_FAIL: " + reason)
    quit(1)
