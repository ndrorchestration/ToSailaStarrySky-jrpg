extends SceneTree
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const EvidencePanel = preload("res://scripts/first_wake_evidence_comparison_panel.gd")
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, message: String) -> void:
    if not ok:
        errors.append(message)

func _run() -> void:
    var story = Opening.new()
    var ui = EvidencePanel.new()
    check(ui.configure_story(story), "panel accepts authentic story")
    root.add_child(ui)
    await process_frame
    check(ui.compare_button.disabled, "cannot select before story eligibility")
    check(story.accept_ionia_job(), "Ionia first")
    check(story.complete_engineering_checks(), "checks")
    check(story.begin_test_flight(), "flight")
    check(story.record_engine_failure(true, true, true), "failure")
    check(story.complete_ocean_splashdown(true, true), "contact")
    check(story.inspect_postflight_reserve(true), "reserve")
    check(story.introduce_lyra_and_talen(true), "family")
    check(story.record_clue("phase_readings"), "clue one")
    check(story.record_clue("depleted_reserve"), "clue two")
    ui.refresh()
    check(not ui.buttons["phase_readings"].disabled, "observed clue active")
    check(ui.buttons["lyra_observation"].disabled, "unobserved clue locked")
    ui.buttons["phase_readings"].button_pressed = true
    ui.buttons["depleted_reserve"].button_pressed = true
    check(not ui.compare_button.disabled, "two observed clues enable compare")
    var before: Dictionary = story.snapshot()
    var result: Dictionary = ui.compare_selected()
    check(result.get("validComparison", false), "comparison rendered")
    check(ui.status.text.contains("unknown"), "no fuel formula invented")
    check(before == story.snapshot(), "UI read-only story invariant")
    check(not result.get("canExecute", true), "no combat/magic execution")
    ui.queue_free()
    await process_frame
    if errors.is_empty():
        print("TSTSS_CH1_EVIDENCE_PANEL_PASS native_ui=true story_unchanged=true")
        quit(0)
        return
    for issue in errors:
        push_error("TSTSS_CH1_EVIDENCE_PANEL_FAIL: " + issue)
    quit(1)
