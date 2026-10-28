extends SceneTree
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Comparison = preload("res://scripts/first_wake_evidence_comparison_review.gd")
var faults: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func assert_check(condition: bool, message: String) -> void:
    if not condition:
        faults.append(message)

func _run() -> void:
    var story = Opening.new()
    var compare = Comparison.new()
    var original: Dictionary = story.snapshot()
    assert_check(not compare.compare(story, ["phase_readings", "depleted_reserve"]).get("validComparison", true), "cannot compare before hiring")
    assert_check(not compare.compare(null, ["phase_readings", "depleted_reserve"]).get("validComparison", true), "no synthetic story")
    assert_check(story.snapshot() == original, "invalid comparisons do not modify story")
    assert_check(story.accept_ionia_job(), "hire Ionia first")
    assert_check(story.complete_engineering_checks(), "engineering before flight")
    assert_check(story.begin_test_flight(), "start short test flight")
    assert_check(story.record_engine_failure(true, true, true), "record actual phase and reserve failure")
    assert_check(story.complete_ocean_splashdown(true, true), "real sea contact established by source contract")
    assert_check(story.inspect_postflight_reserve(true), "confirm depleted reserve")
    assert_check(not compare.compare(story, ["phase_readings", "depleted_reserve"]).get("validComparison", true), "no Lyra observations before family")
    assert_check(story.introduce_lyra_and_talen(true), "introduce Lyra after splashdown")
    assert_check(story.record_clue("phase_readings"), "first authorized clue")
    assert_check(story.record_clue("depleted_reserve"), "second authorized clue")
    var baseline: Dictionary = story.snapshot()
    assert_check(not compare.compare(story, ["phase_readings", "phase_readings"]).get("validComparison", true), "duplicate evidence forbidden")
    assert_check(not compare.compare(story, ["phase_readings", "lyra_observation"]).get("validComparison", true), "unobserved clue forbidden")
    var result: Dictionary = compare.compare(story, ["phase_readings", "depleted_reserve"])
    assert_check(result.get("validComparison", false), "two observed clues can be compared")
    assert_check(not result.get("canExecute", true) and not result.get("canAdvanceStory", true) and not result.get("fuelKnown", true), "visual clue UI never grants magic or story")
    assert_check(story.snapshot() == baseline, "comparison is strictly read only")
    assert_check(story.form_working_fuel_theory(), "existing story FSM owns working theory")
    assert_check(story.snapshot().get("fuel_explanation_status") == "hypothesis_only", "no formula certainty")
    if faults.is_empty():
        print("TSTSS_CH1_EVIDENCE_HOOK_PASS source_authority=true no_magic=true no_save=true")
        quit(0)
    else:
        for fault in faults:
            push_error("TSTSS_CH1_EVIDENCE_HOOK_FAIL: " + fault)
        quit(1)
