extends SceneTree
## The 3D consumer accepts exactly the envelope produced by First Wake #491.
## This is independent of the 2D source branch, not a merged Chapter I build.
const StudyScene = preload("res://main.tscn")
const StoryCue = preload("res://first_wake_visual_cue_consumer.gd")
var errors: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_verify")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        errors.append(message)

func _packet(stage: String, ship: String, party: Array) -> Dictionary:
    var visuals := {
        "job_search": ["dock_job_notice", "find_harmonic_engine_work"],
        "engineering": ["aureate_wake_engineering", "inspect_engine_stations"],
        "preflight": ["engine_preflight", "await_short_test_launch"],
        "test_flight": ["first_lift", "monitor_phase_and_containment"],
        "waterborne": ["ship_ocean_afloat", "verify_ship_and_crew_afloat"],
        "postflight_diagnosis": ["shipboard_recovery_review", "inspect_reserve_and_recovery_readiness"],
        "family_reunion": ["family_reunion_review_only", "discuss_three_independent_observations"],
        "working_theory": ["shared_fuel_theory_review_only", "investigate_unconfirmed_fuel_role"],
    }
    var items: Array = visuals[stage]
    var qa_family: bool = stage in ["family_reunion", "working_theory"]
    return {
        "ok": true,
        "schema": "tstss.review.first_wake_pipeline.v1",
        "authority": "prototype_only",
        "chapter": "first_wake",
        "story_phase": stage,
        "story_party": party.duplicate(),
        "visual_cue": items[0],
        "quest_cue": items[1],
        "ship_state": ship,
        "recovery_checks": ["crew_accounting", "systems_isolation", "contact_plan"] if qa_family else [],
        "recovery_readiness_observed": qa_family,
        "reunion_fixture_only": qa_family,
        "observed_clues": ["phase_readings", "lyra_observation"] if stage == "working_theory" else [],
        "fuel_explanation": "working_hypothesis" if stage == "working_theory" else "unknown",
        "gameplay_combat_grants": [],
        "world_navigation_authorized": false,
        "production_ocean_verified": false,
        "real_family_meeting_verified": false,
        "production_save_write_authorized": false,
        "canon_promotion_authorized": false,
    }

func _verify() -> void:
    var stage = StudyScene.instantiate()
    root.add_child(stage)
    await process_frame
    stage.set_process(false)
    stage._clock = 9.0
    stage._update_scene(0.0)
    var original_transform: Transform3D = stage.ship.global_transform
    var original_manual: bool = stage._manual_active
    var original_landing: String = stage.landing.state
    var golden: Dictionary = stage.visuals.current_mood.duplicate(true)
    var preflight: Dictionary = _packet("preflight", "docked_engineering", ["ender", "ionia"])
    var launch: Dictionary = _packet("test_flight", "airborne_test", ["ender", "ionia"])
    var descent: Dictionary = _packet("test_flight", "controlled_descent", ["ender", "ionia"])
    var afloat: Dictionary = _packet("waterborne", "ocean_afloat", ["ender", "ionia"])
    var family: Dictionary = _packet("family_reunion", "ocean_afloat_engines_offline", ["ender", "ionia", "lyra"])
    var theory: Dictionary = _packet("working_theory", "ocean_afloat_engines_offline", ["ender", "ionia", "lyra"])
    var bad_legacy: Dictionary = _packet("job_search", "docked", ["ender", "lyra"])
    check(not bool(StoryCue.plan(bad_legacy).get("ok", false)), "old Lyra-first chronology rejected")
    check(not stage.preview_first_wake_visual_cue(bad_legacy), "legacy cannot change visual scene")
    check(stage.visuals.current_mood == golden and stage._story_visual_plan.is_empty(),
        "invalid producer cue leaves current grade and camera source alone")

    for malformed in [
        {"schema": "tstss.review.first_wake_pipeline.v1", "ok": true},
        _mutate(launch, "authority", "production"),
        _mutate(launch, "world_navigation_authorized", true),
        _mutate(afloat, "production_ocean_verified", true),
        _mutate(family, "real_family_meeting_verified", true),
        _mutate(theory, "gameplay_combat_grants", ["invented_spell"]),
        _mutate(theory, "observed_clues", ["phase_readings"]),
        _mutate(family, "reunion_fixture_only", false),
        _mutate(theory, "recovery_readiness_observed", false),
        _mutate(launch, "ship_state", "ocean_afloat"),
        _mutate(preflight, "visual_cue", "first_lift"),
    ]:
        check(not bool(StoryCue.plan(malformed).get("ok", false)),
            "invalid/promoted story envelope rejected")

    check(stage.preview_first_wake_visual_cue(preflight, 0.0), "preflight grade accepted")
    check(stage.story_cue_label.visible, "noncanonical scene HUD is visible")
    check(stage.visuals.current_mood["time_name"] == "MIDDAY",
        "preflight scene uses optional daylight grade")
    check(stage.ship.global_transform == original_transform,
        "preflight visual request does not move original 3D ship")
    check(stage.preview_first_wake_visual_cue(launch, 2.0), "first lift cue accepted")
    check(stage.visuals.transition_active, "first lift blends grade")
    stage.visuals.advance_environment_transition(1.0, false)
    check(stage.visuals.transition_active, "first lift grade passes through midpoint")
    check(stage.preview_first_wake_visual_cue(descent, 2.0),
        "emergency can interrupt transition")
    stage.visuals.advance_environment_transition(2.0, false)
    check(stage.visuals.current_mood["weather_name"] == "RAIN" and
        stage.visuals.current_mood["time_name"] == "BLUE_HOUR",
        "descent cues actual rain/light 3D shaders without simulating weather")
    var descent_shot: Dictionary = stage.first_wake_visual_snapshot()
    check(descent_shot["visual_cue"] == "first_lift" and
        descent_shot["story_phase"] == "test_flight", "visual provenance retained")
    stage._update_scene(0.0)
    check(stage.camera.global_position.distance_to(stage.ship.global_position) < 40.0,
        "actual 3D camera uses scene-relative cue framing")
    check(stage.ship.global_transform == original_transform,
        "3D camera/environment changes do not modify ship transform or physics")
    check(stage.preview_first_wake_visual_cue(afloat, 0.0), "waterborne visual cue accepted")
    check(stage.visuals.current_mood["weather_name"] == "MIST",
        "afloat visual cue mapped to distinct noncanonical mist grade")
    check(not bool(stage.first_wake_visual_snapshot()["production_ocean_verified"]),
        "3D ship look does not claim physics-certified ocean landing")
    check(stage.preview_first_wake_visual_cue(family, 0.0), "family visual preview accepted")
    check(stage.story_cue_label.text.find("QA FAMILY REHEARSAL") >= 0,
        "reunion cannot claim a real shoreline or child arrival")
    check(stage.preview_first_wake_visual_cue(theory, 0.0), "three-mind theory preview accepted")
    check(stage.ship.get_node("LongHull") is MeshInstance3D, "Aureate Wake hull preserved")
    for name in ["PortFore", "PortAft", "StarboardFore", "StarboardAft"]:
        check(stage.ship.has_node("WingRig_" + name), "four original wing rigs preserved: " + name)
    check(stage._manual_active == original_manual and stage.landing.state == original_landing,
        "story visual preview does not change flight / landing state")
    check(stage.ship.global_transform == original_transform, "ship unchanged through every cue")
    stage._reduced_motion = true
    stage.visuals.queue_environment_look(3, 3, false)
    stage.visuals.advance_environment_transition(0.0, true)
    check(not stage.visuals.transition_active, "reduced motion snaps optional grade")
    stage.set_manual_mode(true)
    var before_manual: Dictionary = stage.first_wake_visual_snapshot()
    check(not stage.preview_first_wake_visual_cue(launch), "manual piloting blocks cutscene preview")
    check(stage.first_wake_visual_snapshot() == before_manual,
        "manual-state rejection is side-effect free")
    stage.clear_first_wake_visual_cue()
    check(not stage.story_cue_label.visible and stage._story_visual_plan.is_empty(),
        "exiting opt-in preview hides cue UI")
    check(stage.visuals.current_mood == golden,
        "exiting story preview restores existing art-study environment")
    check(not stage.first_wake_visual_snapshot()["story_preview_active"],
        "preview closure does not persist in ship control")
    stage.queue_free()
    await process_frame
    if errors.is_empty():
        print("GODOT_FIRST_WAKE_3D_VISUAL_CUE_PASS checks=", checks)
        quit(0)
    else:
        for item in errors:
            push_error("GODOT_FIRST_WAKE_3D_VISUAL_CUE_FAIL: " + item)
        quit(1)

func _mutate(packet: Dictionary, key: String, value: Variant) -> Dictionary:
    var copy: Dictionary = packet.duplicate(true)
    copy[key] = value
    return copy
