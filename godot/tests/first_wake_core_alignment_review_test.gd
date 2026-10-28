extends SceneTree
## Real Godot 4.7.2 test of ordering; not a real-world physics or music proof.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Core = preload("res://scripts/first_wake_core_alignment_review.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _story():
    var s = Opening.new()
    s.accept_ionia_job()
    s.complete_engineering_checks()
    s.begin_test_flight()
    s.record_engine_failure(true, true, true)
    s.complete_ocean_splashdown(true, true)
    s.inspect_postflight_reserve(true)
    s.introduce_lyra_and_talen(true)
    s.record_clue("phase_readings")
    s.record_clue("lyra_observation")
    s.form_working_fuel_theory()
    return s

func _verify() -> void:
    var pilot = Core.new()
    if pilot.begin(Opening.new()):
        _fail("started repair quest before splashdown/family/theory")
        return
    if pilot.begin({"step": "working_theory", "active_party_ids": ["ender", "ionia", "lyra"]}):
        _fail("accepted forged story snapshot")
        return
    var story = _story()
    if not pilot.begin(story) or pilot.begin(story):
        _fail("real theory start rejected or repeat start allowed")
        return
    var unchanged: Dictionary = pilot.snapshot()
    if pilot.ionia_hums_unprompted(true) or pilot.ender_matches_sequence(true, true, true):
        _fail("song-only shortcut bypassed material recovery")
        return
    if pilot.take_world_item("invented_fuel", "world_pickup") or pilot.take_world_item("recovered_supply", "scripted_gift"):
        _fail("unapproved physical item/source admitted")
        return
    if pilot.snapshot() != unchanged:
        _fail("invalid item shortcut mutated contract")
        return
    if not pilot.take_world_item("recovered_part", "world_pickup"):
        _fail("valid physical part receipt rejected")
        return
    if pilot.take_world_item("recovered_part", "world_pickup") or pilot.install_part("recovered_part", true):
        _fail("duplicate pickup or early installation admitted")
        return
    if not pilot.take_world_item("recovered_supply", "world_pickup"):
        _fail("second physical recovery rejected")
        return
    if pilot.install_part("recovered_part", false) or pilot.install_part("invented_fuel", true):
        _fail("installation without real checked evidence admitted")
        return
    if not pilot.install_part("recovered_supply", true):
        _fail("first checked installation rejected")
        return
    if pilot.install_part("recovered_supply", true) or not pilot.install_part("recovered_part", true):
        _fail("duplicate installation or second checked installation failure")
        return
    if pilot.snapshot()["phase"] != "retest":
        _fail("physical recovery did not reach retest")
        return
    if pilot.verify_stable_core(true, true):
        _fail("material-only shortcut incorrectly phase-locked")
        return
    for args in [[false, true, true], [true, false, true], [true, true, false]]:
        if pilot.retest_with_supplies(args[0], args[1], args[2]):
            _fail("unsafe or falsely successful failed-retest admitted")
            return
    if not pilot.retest_with_supplies(true, true, true):
        _fail("proper witnessed material-only failure rejected")
        return
    if pilot.ionia_hums_unprompted(false) or not pilot.ionia_hums_unprompted(true):
        _fail("unprompted anxious humming trigger failed")
        return
    if pilot.ionia_repeats_denith_song(true, false) or pilot.ionia_repeats_denith_song(false, true):
        _fail("song admitted without both memory and consent")
        return
    if not pilot.ionia_repeats_denith_song(true, true):
        _fail("Ionia repeating Denith's melody rejected")
        return
    if pilot.ender_matches_sequence(true, false, true) or pilot.ender_matches_sequence(false, true, true):
        _fail("incomplete musical-theory evidence accepted")
        return
    if not pilot.ender_matches_sequence(true, true, true):
        _fail("Ender's interval, timing and sensor insight rejected")
        return
    if pilot.lyra_confirms_response(false) or not pilot.lyra_confirms_response(true):
        _fail("Lyra independent corroboration gate failed")
        return
    if pilot.ionia_approves_bench_test(true, false) or pilot.ionia_approves_bench_test(false, true):
        _fail("bench test permitted without captain and safety")
        return
    if not pilot.ionia_approves_bench_test(true, true):
        _fail("Ionia captain's checked approval refused")
        return
    if pilot.verify_stable_core(true, false) or pilot.verify_stable_core(false, true):
        _fail("unsafe measured alignment accepted")
        return
    if not pilot.verify_stable_core(true, true):
        _fail("contained phase-lock candidate refused")
        return
    var result: Dictionary = pilot.snapshot()
    if not result["alignment_candidate"] or result["can_launch"] or result["can_execute_art"]:
        _fail("candidate conflated with flight or combat permissions")
        return
    if result["native_audio_verified"] or result["native_physics_verified"] or result["save_migrated"]:
        _fail("fictional evidence misreported as integrated implementation")
        return
    if pilot.verify_stable_core(true, true) or pilot.take_world_item("recovered_supply", "world_pickup"):
        _fail("final proof replay not idempotent")
        return
    if result["recovered"].size() != 2 or result["installed"].size() != 2:
        _fail("physical requirements not preserved")
        return
    print("TSTSS_FIRST_WAKE_CORE_ALIGNMENT_PASS: post-reunion physical pickups and install, mandatory failed retest, Ionia/Denith melody, Ender/Lyra/captain evidence; no flight or combat authority")
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_CORE_ALIGNMENT_FAIL: " + reason)
    quit(1)
