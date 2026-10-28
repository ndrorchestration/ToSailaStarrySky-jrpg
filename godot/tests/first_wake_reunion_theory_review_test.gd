extends SceneTree
## Godot native contract: physically landed/safe Ionia-first review -> gated
## family meeting fixture -> Lyra joins second -> 2/3 independent clues.
## No production recovery route, definitive fuel formula or Talen combat role.

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var source: PackedScene = load("res://scenes/first_wake_job_preview.tscn")
    var reunion_scene: PackedScene = load("res://scenes/first_wake_reunion_theory_review.tscn")
    if source == null or reunion_scene == null:
        _fail("native review scene import failed")
        return
    var world = source.instantiate()
    root.add_child(world)
    await process_frame
    var reunion = reunion_scene.instantiate()
    if reunion.configure_from_postflight(world):
        _fail("reunion admitted job-search scene as postflight")
        return
    if not world.opening.accept_ionia_job():
        _fail("Ionia was not recruited first")
        return
    world._enter_engineering_room()
    for item in ["reference", "containment", "fuel"]:
        world.inspected_items.append(item)
    if not world.opening.complete_engineering_checks() or not world.launch_flight_review():
        _fail("could not reach flight stage with approved preflight")
        return
    var flight = world.flight_review
    if reunion.configure_from_postflight(flight):
        _fail("unlanded flight admitted as recovery")
        return
    if not flight.begin_short_test_flight():
        _fail("native test-flight launch failed")
        return
    var warning := false
    for i in range(240):
        await process_frame
        if flight.phase == "warning":
            warning = true
            break
    if not warning or not flight.stabilize_for_water_descent():
        _fail("test-flight emergency could not begin controlled descent")
        return
    var waterborne := false
    for i in range(660):
        await process_frame
        if flight.phase == "waterborne":
            waterborne = true
            break
    if not waterborne or not flight.contact_observed or not flight.stable_float_verified:
        _fail("actual native water contact and settled flotation missing")
        return
    if reunion.configure_from_postflight(flight):
        _fail("postflight proof admitted before reserve diagnosis")
        return
    if flight.begin_recovery_readiness():
        _fail("recovery readiness entered before postflight diagnosis")
        return
    if not flight.start_postflight_inspection():
        _fail("native postflight diagnosis cannot start")
        return
    for i in range(flight.POSTFLIGHT_INSPECTION_LINES.size()):
        if not flight.advance_postflight_inspection():
            _fail("postflight diagnosis failed to acknowledge observations")
            return
    if flight.opening.step_key() != "postflight_diagnosis":
        _fail("postflight state absent after reserve examination")
        return
    if not reunion.configure_from_postflight(flight):
        _fail("valid local postflight evidence rejected")
        return
    root.add_child(reunion)
    await process_frame

    if reunion.interact() or reunion.inspect_clue("phase_readings"):
        _fail("reunion progressed before recovery receipt")
        return
    if reunion.attach_recovery_readiness(world):
        _fail("unrelated scene accepted as recovery receipt")
        return
    var fixture: Dictionary = {
        "source": "isolated_qa_fixture",
        "fixture_only": true,
        "crew_safe": true,
        "family_contact_safe": true,
    }
    if reunion.authorize_qa_reunion_fixture(fixture):
        _fail("meeting fixture bypassed shipboard readiness checks")
        return
    if not flight.begin_recovery_readiness() or flight.recovery_review == null:
        _fail("postflight readiness did not open a native shipboard review")
        return
    if flight.flight_overlay.visible:
        _fail("original flight UI overlapped the recovery review")
        return
    if flight.begin_recovery_readiness():
        _fail("duplicate recovery review scene admitted")
        return
    var plan = flight.recovery_review
    if plan.phase != "inspect" or plan.opening != flight.opening:
        _fail("recovery scene not bound to original Ender-Ionia story state")
        return
    if reunion.attach_recovery_readiness(plan):
        _fail("unfinished recovery checklist attached to family fixture")
        return
    for station_id in ["contact_plan", "crew_accounting", "systems_isolation"]:
        if not plan.inspect_station(station_id):
            _fail("shipboard station was unavailable: " + station_id)
            return
        if station_id in plan.completed_stations:
            _fail("shipboard observation awarded before dialogue: " + station_id)
            return
        var lines: Array[String] = plan._station_lines(station_id)
        for i in range(lines.size() - 1):
            if not plan.interact() or station_id in plan.completed_stations:
                _fail("station evidence awarded without complete observation: " + station_id)
                return
        if not plan.interact() or station_id not in plan.completed_stations:
            _fail("station dialogue did not finish: " + station_id)
            return
        if plan.inspect_station(station_id):
            _fail("repeated station inspection admitted")
            return
    var readiness: Dictionary = plan.review_snapshot()
    if not readiness["readiness_review_complete"] or plan.phase != "ready_for_route_review":
        _fail("three shipboard observations did not finish the checklist")
        return
    if readiness["actual_sailing_route_verified"] or readiness["message_delivered"] or readiness["safe_family_meeting_verified"] or readiness["recovery_success_certified"]:
        _fail("shipboard readiness was mislabeled as successful travel, contact or recovery")
        return
    if readiness["route_status"] != "awaiting_creator_geography":
        _fail("safe travel destination improperly assigned")
        return
    if plan.interact() or plan.inspect_station("crew_accounting"):
        _fail("finished readiness checklist mutated after completion")
        return
    if not reunion.attach_recovery_readiness(plan):
        _fail("valid shipboard readiness not admitted for later QA-only rehearsal")
        return
    if reunion.attach_recovery_readiness(plan):
        _fail("duplicate shipboard readiness admission accepted")
        return
    for bad in [
        {},
        {"source": "production", "fixture_only": true, "crew_safe": true, "family_contact_safe": true},
        {"source": "isolated_qa_fixture", "fixture_only": true, "crew_safe": true, "family_contact_safe": false},
        {"source": "isolated_qa_fixture", "fixture_only": true, "crew_safe": true, "family_contact_safe": true, "geography": "invented"},
    ]:
        if reunion.authorize_qa_reunion_fixture(bad):
            _fail("invalid or fake production recovery proof admitted")
            return
    if not reunion.authorize_qa_reunion_fixture(fixture):
        _fail("isolated QA rehearsal fixture was rejected")
        return
    if reunion.authorize_qa_reunion_fixture(fixture):
        _fail("duplicate recovery fixture was accepted")
        return
    if not reunion.interact() or reunion.phase != "reunion_dialogue":
        _fail("safe-meeting dialogue not started")
        return
    if reunion.opening.active_party_ids != ["ender", "ionia"]:
        _fail("Lyra joined before meeting completed")
        return
    if reunion.inspect_clue("lyra_observation"):
        _fail("clue unlocked before Lyra introduction")
        return
    for i in range(reunion.INTRO_LINES.size() - 1):
        if not reunion.interact():
            _fail("family dialogue failed to advance")
            return
        if "lyra" in reunion.opening.active_party_ids:
            _fail("Lyra recruited before last introduction line")
            return
    if not reunion.interact():
        _fail("finished family dialogue rejected")
        return
    if reunion.phase != "investigation" or reunion.opening.active_party_ids != ["ender", "ionia", "lyra"]:
        _fail("Lyra not recruited second after reviewed safe meeting")
        return
    if "talen" in reunion.opening.active_party_ids:
        _fail("nonplayable child was added to party")
        return

    if reunion.interact():
        _fail("working theory accepted before two observations")
        return
    if not reunion.inspect_clue("lyra_observation"):
        _fail("Lyra clue not inspectable")
        return
    if reunion.opening.clues.size() != 0 or reunion.interact() == false:
        _fail("clue evidence was awarded early or not completed")
        return
    if reunion.opening.clues != ["lyra_observation"]:
        _fail("Lyra's independent observation not recorded")
        return
    if reunion.inspect_clue("lyra_observation") or reunion.interact():
        _fail("duplicate clue or single-observation theory admitted")
        return
    if not reunion.inspect_clue("phase_readings"):
        _fail("second distinct observation not inspectable")
        return
    if not reunion.interact():
        _fail("second clue record failed")
        return
    if reunion.opening.clues != ["lyra_observation", "phase_readings"]:
        _fail("independent clues reordered or duplicated")
        return
    if not reunion.interact() or reunion.phase != "theory_dialogue":
        _fail("two independent observations did not unlock shared theory")
        return
    for i in range(reunion.THEORY_LINES.size() - 1):
        if not reunion.interact():
            _fail("three-character theory dialogue failed")
            return
        if reunion.opening.step_key() != "family_reunion":
            _fail("theory marked final before all conversation lines")
            return
    if not reunion.interact():
        _fail("closing working-hypothesis dialogue failed")
        return
    var final: Dictionary = reunion.review_snapshot()
    if reunion.phase != "working_theory" or final["stage"] != "working_theory":
        _fail("working theory state missing")
        return
    if final["fuel_explanation"] != "working_hypothesis" or final["fuel_formula_verified"]:
        _fail("fuel was misrepresented as a verified formula")
        return
    if final["geography_authorized"] or final["real_recovery_route_verified"] or not final["readiness_review_complete"]:
        _fail("readiness was lost or QA fixture promoted to real-world rescue authorization")
        return
    if final["talen_combat_authorized"] or "talen" in final["party"]:
        _fail("Talen gained battle-party access")
        return
    if reunion.interact() or reunion.inspect_clue("depleted_reserve"):
        _fail("finished theory could be rewritten without review")
        return
    reunion.queue_free()
    world.queue_free()
    await process_frame
    print("TSTSS_FIRST_WAKE_REUNION_THEORY_PASS: local postflight, 3/3 crew/engine/contact readiness, no invented rescue route, QA-only meeting, Lyra-second, Talen nonparty, two-clue hypothesis")
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_REUNION_THEORY_FAIL: " + reason)
    quit(1)
