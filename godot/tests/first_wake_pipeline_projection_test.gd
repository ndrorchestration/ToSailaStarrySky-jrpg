extends SceneTree
## Native end-to-end adapter seam: forward story, physical local flight, Ionia-first
## party, shipboard readiness and QA-only Lyra investigation -> read-only cues.
## This does NOT integrate the historical default Lyra-first runtime or save v1.

const Bridge = preload("res://scripts/first_wake_pipeline_projection.gd")
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const LegacyChapter = preload("res://scripts/first_wake_chapter1_state.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _assert_projection(opening, step: String, party: Array, visual: String, flight: Node = null, recovery: Node = null, reunion: Node = null) -> bool:
    var before: Dictionary = opening.snapshot()
    var envelope: Dictionary = Bridge.project(opening, flight, recovery, reunion)
    if not bool(envelope.get("ok", false)):
        return _fail("projection failed: " + str(envelope.get("error", "")))
    if envelope.get("schema", "") != "tstss.review.first_wake_pipeline.v1" or envelope.get("story_phase", "") != step:
        return _fail("projection schema or stage drift: " + step)
    if envelope.get("story_party", []) != party or envelope.get("visual_cue", "") != visual:
        return _fail("pipeline character/visual cues drift: " + step)
    if envelope.get("gameplay_combat_grants", ["bad"]) != []:
        return _fail("plot energy and party presence illegally enabled combat")
    for control in ["world_navigation_authorized", "production_ocean_verified", "real_family_meeting_verified", "production_save_write_authorized", "canon_promotion_authorized"]:
        if envelope.get(control, true) != false:
            return _fail("prototype silently acquired production authority: " + control)
    if opening.snapshot() != before:
        return _fail("read-only projection mutated actual story contract")
    return true

func _verify() -> void:
    var job_scene: PackedScene = load("res://scenes/first_wake_job_preview.tscn")
    var reunion_scene: PackedScene = load("res://scenes/first_wake_reunion_theory_review.tscn")
    if job_scene == null or reunion_scene == null:
        _fail("Godot could not import actual forward playable scenes")
        return
    var world = job_scene.instantiate()
    root.add_child(world)
    await process_frame
    if Bridge.project(LegacyChapter.new()).get("ok", true) != false:
        _fail("superseded Lyra-first native chapter silently mapped to new contract")
        return
    if not _assert_projection(world.opening, "job_search", ["ender"], "dock_job_notice"):
        return
    if not world.opening.accept_ionia_job():
        _fail("Ionia-first hiring contract rejected")
        return
    if not _assert_projection(world.opening, "engineering", ["ender", "ionia"], "aureate_wake_engineering"):
        return
    world._enter_engineering_room()
    for station_id in ["reference", "containment", "fuel"]:
        world.inspected_items.append(station_id)
    if not world.opening.complete_engineering_checks():
        _fail("engineering checks did not establish preflight")
        return
    if not _assert_projection(world.opening, "preflight", ["ender", "ionia"], "engine_preflight"):
        return
    if not world.launch_flight_review():
        _fail("native scene handoff to flight failed")
        return
    var flight = world.flight_review
    if not _assert_projection(world.opening, "preflight", ["ender", "ionia"], "engine_preflight", flight):
        return
    var stranger = Opening.new()
    if Bridge.project(stranger, flight).get("ok", true) != false:
        _fail("foreign story contract borrowed flight receipt")
        return
    if not flight.begin_short_test_flight():
        _fail("flight launch did not begin")
        return
    if not _assert_projection(world.opening, "test_flight", ["ender", "ionia"], "first_lift", flight):
        return
    var warning := false
    for i in range(240):
        await process_frame
        if flight.phase == "warning":
            warning = true
            break
    if not warning or not flight.stabilize_for_water_descent():
        _fail("native first-flight emergency unavailable")
        return
    var descending: Dictionary = Bridge.project(world.opening, flight)
    if not descending.get("ok", false) or descending.get("ship_state", "") != "controlled_descent":
        _fail("emergency descent cue not exposed to future camera/ship UI")
        return
    var waterborne := false
    for i in range(660):
        await process_frame
        if flight.phase == "waterborne":
            waterborne = true
            break
    if not waterborne or not _assert_projection(world.opening, "waterborne", ["ender", "ionia"], "ship_ocean_afloat", flight):
        _fail("native ocean contact/stable float did not produce waterborne cue")
        return
    if Bridge.project(world.opening).get("ok", true) != false:
        _fail("missing real flight receipt accepted at waterborne phase")
        return
    if not flight.start_postflight_inspection():
        _fail("reserve diagnosis did not begin")
        return
    for i in range(flight.POSTFLIGHT_INSPECTION_LINES.size()):
        if not flight.advance_postflight_inspection():
            _fail("postflight diagnosis line failed")
            return
    if not _assert_projection(world.opening, "postflight_diagnosis", ["ender", "ionia"], "shipboard_recovery_review", flight):
        return
    if not flight.begin_recovery_readiness():
        _fail("actual shipboard readiness UI handoff failed")
        return
    var plan = flight.recovery_review
    if not _assert_projection(world.opening, "postflight_diagnosis", ["ender", "ionia"], "shipboard_recovery_review", flight, plan):
        return
    var first: Dictionary = Bridge.project(world.opening, flight, plan)
    if first.get("recovery_readiness_observed", true):
        _fail("uncompleted recovery checklist exposed as approved")
        return
    for station_id in ["systems_isolation", "contact_plan", "crew_accounting"]:
        if not plan.inspect_station(station_id):
            _fail("recovery station absent: " + station_id)
            return
        for i in range(plan._station_lines(station_id).size()):
            if not plan.interact():
                _fail("shipboard observation interaction incomplete: " + station_id)
                return
    var after: Dictionary = Bridge.project(world.opening, flight, plan)
    if not after.get("ok", false) or not after.get("recovery_readiness_observed", false) or after.get("recovery_checks", []).size() != 3:
        _fail("readiness projection missing 3/3 witnessed shipboard observations")
        return
    after["recovery_checks"].clear()
    if plan.completed_stations.size() != 3:
        _fail("consumer mutated real prototype through copied envelope")
        return

    var reunion = reunion_scene.instantiate()
    if not reunion.configure_from_postflight(flight):
        _fail("reunion review refused correct postflight source")
        return
    root.add_child(reunion)
    await process_frame
    if not reunion.attach_recovery_readiness(plan):
        _fail("QA reunion did not attach same-source shipboard receipt")
        return
    var fixture: Dictionary = {
        "source": "isolated_qa_fixture",
        "fixture_only": true,
        "crew_safe": true,
        "family_contact_safe": true,
    }
    if not reunion.authorize_qa_reunion_fixture(fixture):
        _fail("explicit synthetic safe-meeting fixture did not start rehearsal")
        return
    if not reunion.interact():
        _fail("family introduction did not start")
        return
    for i in range(reunion.INTRO_LINES.size()):
        if not reunion.interact():
            _fail("family dialogue failed to finish")
            return
    if not _assert_projection(world.opening, "family_reunion", ["ender", "ionia", "lyra"], "family_reunion_review_only", flight, plan, reunion):
        return
    var family: Dictionary = Bridge.project(world.opening, flight, plan, reunion)
    if not family.get("reunion_fixture_only", false) or family.get("real_family_meeting_verified", true):
        _fail("QA family rehearsal was promoted to actual confirmed safe reunion")
        return
    for clue_id in ["depleted_reserve", "lyra_observation"]:
        if not reunion.inspect_clue(clue_id) or not reunion.interact():
            _fail("independent clue did not register: " + clue_id)
            return
    if not reunion.interact():
        _fail("2-of-3 clue threshold failed to open hypothesis discussion")
        return
    for i in range(reunion.THEORY_LINES.size()):
        if not reunion.interact():
            _fail("three-party theory dialogue failed to close")
            return
    if not _assert_projection(world.opening, "working_theory", ["ender", "ionia", "lyra"], "shared_fuel_theory_review_only", flight, plan, reunion):
        return
    var theory: Dictionary = Bridge.project(world.opening, flight, plan, reunion)
    if theory.get("fuel_explanation", "") != "working_hypothesis":
        _fail("shared provisional fuel theory was lost")
        return
    if Bridge.project(world.opening, flight, null, reunion).get("ok", true) != false:
        _fail("reunion permitted without original shipboard readiness receipt")
        return
    reunion.queue_free()
    world.queue_free()
    await process_frame
    print("TSTSS_FIRST_WAKE_PIPELINE_PROJECTION_PASS: playable native dock, Ionia-first recruitment, 2D flight/water contact, recovery checks, QA-only Lyra reunion, 2-of-3 fuel hypothesis, read-only UI/ship cues, no legacy/save/combat/geography authority")
    quit(0)

func _fail(reason: String) -> bool:
    push_error("TSTSS_FIRST_WAKE_PIPELINE_PROJECTION_FAIL: " + reason)
    quit(1)
    return false
