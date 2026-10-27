extends SceneTree
## Bounded ordering and fail-closed checks, not proof of integrated Chapter I.

const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var state = Opening.new()
    if state.snapshot()["active_party_ids"] != ["ender"]:
        _fail("Ender must begin alone")
        return
    if state.begin_test_flight() or state.introduce_lyra_and_talen(true):
        _fail("premature flight or Lyra join accepted")
        return
    if state.form_working_fuel_theory() or state.record_clue("phase_readings"):
        _fail("theory or clue accepted before safe reunion")
        return

    if not state.accept_ionia_job():
        _fail("Ionia job join rejected")
        return
    if state.snapshot()["active_party_ids"] != ["ender", "ionia"]:
        _fail("Ionia must be first recruit")
        return
    if state.accept_ionia_job() or state.begin_test_flight():
        _fail("duplicate Ionia join or unchecked flight permitted")
        return
    if not state.complete_engineering_checks() or not state.begin_test_flight():
        _fail("checked test flight rejected")
        return
    if state.complete_ocean_splashdown(true, true):
        _fail("splashdown allowed before failure")
        return
    if state.record_engine_failure(true, false, true):
        _fail("incomplete engine diagnosis accepted")
        return
    if not state.record_engine_failure(true, true, true):
        _fail("three observed failure conditions rejected")
        return
    if state.record_engine_failure(true, true, true):
        _fail("duplicate failure event accepted")
        return
    if state.complete_ocean_splashdown(false, true) or state.complete_ocean_splashdown(true, false):
        _fail("unsafe water landing accepted")
        return
    if not state.complete_ocean_splashdown(true, true):
        _fail("safe ocean splashdown rejected")
        return
    if state.introduce_lyra_and_talen(true):
        _fail("Lyra joined before fuel reserve diagnosis")
        return
    if state.inspect_postflight_reserve(false) or not state.inspect_postflight_reserve(true):
        _fail("fuel-exhaustion evidence gate failed")
        return
    if state.introduce_lyra_and_talen(false) or not state.introduce_lyra_and_talen(true):
        _fail("safe Lyra/Talen reunion gate failed")
        return
    if state.introduce_lyra_and_talen(true):
        _fail("duplicate Lyra join accepted")
        return
    var joined: Dictionary = state.snapshot()
    if joined["active_party_ids"] != ["ender", "ionia", "lyra"]:
        _fail("post-splashdown party order drifted")
        return
    if "talen" in joined["active_party_ids"]:
        _fail("Talen erroneously made playable")
        return
    if state.form_working_fuel_theory():
        _fail("hypothesis admitted with no evidence")
        return
    if state.record_clue("invented_fuel_formula"):
        _fail("invented fuel formula accepted")
        return
    if not state.record_clue("phase_readings"):
        _fail("valid Ender clue rejected")
        return
    if state.record_clue("phase_readings") or state.form_working_fuel_theory():
        _fail("duplicate clue or single-clue theory accepted")
        return
    if not state.record_clue("lyra_observation"):
        _fail("valid Lyra clue rejected")
        return
    if not state.form_working_fuel_theory():
        _fail("two-clue working hypothesis rejected")
        return
    var finished: Dictionary = state.snapshot()
    if finished["fuel_explanation_status"] != "hypothesis_only":
        _fail("theory claimed a confirmed fuel formula")
        return
    if finished["actual_water_physics_verified"] or finished["implemented_in_live_chapter_one"]:
        _fail("review-only source claimed production evidence")
        return

    # Two-of-three clues should work in different encounter orders;
    # Ionia's Denith recollections are still required by the story dialogue.
    for ordered_clues in [
        ["depleted_reserve", "phase_readings"],
        ["lyra_observation", "depleted_reserve"],
    ]:
        var alternate = Opening.new()
        alternate.accept_ionia_job()
        alternate.complete_engineering_checks()
        alternate.begin_test_flight()
        alternate.record_engine_failure(true, true, true)
        alternate.complete_ocean_splashdown(true, true)
        alternate.inspect_postflight_reserve(true)
        alternate.introduce_lyra_and_talen(true)
        for clue_id in ordered_clues:
            if not alternate.record_clue(clue_id):
                _fail("alternate clue ordering rejected")
                return
        if not alternate.form_working_fuel_theory():
            _fail("alternate two-clue hypothesis rejected")
            return
    print("TSTSS_FIRST_WAKE_REVISED_OPENING_CONTRACT_PASS: recruitment, flight, water, family and hypothesis gates")
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_REVISED_OPENING_CONTRACT_FAIL: " + reason)
    quit(1)
