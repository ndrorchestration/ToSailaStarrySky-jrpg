extends SceneTree
## Original symbolic music puzzle, not a song composition or DSP measurement.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Core = preload("res://scripts/first_wake_core_alignment_review.gd")
const Panel = preload("res://scripts/first_wake_melody_analysis_review.gd")
const Melody = preload("res://scripts/first_wake_melody_math_fixture.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _make_ready_core():
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
    var core = Core.new()
    if not core.begin(s):
        return null
    core.take_world_item("recovered_supply", "world_pickup")
    core.take_world_item("recovered_part", "world_pickup")
    core.install_part("recovered_supply", true)
    core.install_part("recovered_part", true)
    core.retest_with_supplies(true, true, true)
    core.ionia_hums_unprompted(true)
    core.ionia_repeats_denith_song(true, true)
    return core

func _verify() -> void:
    var panel = Panel.new()
    var core = Core.new()
    if panel.show_for(core) or panel.show_for({}):
        _fail("chart opened without valid post-repair story stage")
        return
    if panel.choose(1) or panel.submit(core).get("ok", true) or panel.dismiss():
        _fail("closed chart accepted a selection/submit/cancel")
        return
    core = _make_ready_core()
    if core == null or core.snapshot()["phase"] != "analyze":
        _fail("fixture did not reach legitimate musical analysis")
        return
    var before: Dictionary = core.snapshot()
    if not panel.show_for(core) or panel.show_for(core):
        _fail("legitimate chart was refused or duplicate opening succeeded")
        return
    if panel.choose(-1) or panel.choose(3):
        _fail("outside-option selection accepted")
        return
    if panel.submit(core).get("ok", true) or panel.attempts != 0:
        _fail("no-selection automatically solved puzzle")
        return
    if not panel.choose(0) or panel.submit(core).get("ok", true):
        _fail("short-held interval should be rejected")
        return
    if not panel.feedback.contains("two beats"):
        _fail("incorrect held-note option lacks accessible explanatory feedback")
        return
    if not panel.choose(2) or panel.submit(core).get("ok", true):
        _fail("wrong interval should be rejected")
        return
    if panel.attempts != 2 or core.snapshot() != before or not panel.open:
        _fail("wrong guesses caused stage mutation, lockout, or lost attempt count")
        return
    if not panel.dismiss() or core.snapshot() != before:
        _fail("cancel mutated core evidence or refused close")
        return
    if panel.choose(1) or panel.submit(core).get("ok", true):
        _fail("dismissed chart still accepted inputs")
        return
    if not panel.show_for(core) or panel.attempts != 0 or panel.selected != -1:
        _fail("reopened investigation retained stale selections or attempts")
        return
    if not panel.choose(1):
        _fail("correct phrase could not be selected")
        return
    var result: Dictionary = panel.submit(core)
    if not bool(result.get("ok", false)) or panel.open or core.snapshot()["phase"] != "observe":
        _fail("correct player choice did not advance to Lyra")
        return
    if panel.show_for(core) or panel.submit(core).get("ok", true):
        _fail("solved chart could be replayed")
        return
    if panel.snapshot()["can_launch"] or panel.snapshot()["can_execute_art"] or panel.snapshot()["audio_verified"]:
        _fail("review choice became physical flight, spell, or recorded-audio authority")
        return

    # The symbolic comparison must not depend on the singer's absolute key:
    # interval contours and timed holds produce equivalent chart evidence.
    if not Melody.verify(Melody.sample_phrase(5), Melody.sample_sensor_vector()).get("ok", false):
        _fail("transposed relative melody failed despite identical interval/dwell shape")
        return

    print("TSTSS_FIRST_WAKE_MELODY_CHOICES_PASS: no auto-solve, three visible hypotheses, invalid/retry/cancel/keyboard-compatible selection, noncanonical math and no launch rights")
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_FIRST_WAKE_MELODY_CHOICES_FAIL: " + reason)
    quit(1)
