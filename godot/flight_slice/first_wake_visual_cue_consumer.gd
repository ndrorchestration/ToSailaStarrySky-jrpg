extends RefCounted
## Safe CONSUMER of the exact read-only First Wake cue envelope from
## review/first-wake-pipeline-projection-20261027 at 641a1ba0.
## Opt-in 3D presentation ONLY: never moves the ship, changes landing physics,
## writes saves, grants combat, selects a coastline or enables navigation.
const SCHEMA := "tstss.review.first_wake_pipeline.v1"

const VISUAL_CUES := {
    "job_search": "dock_job_notice",
    "engineering": "aureate_wake_engineering",
    "preflight": "engine_preflight",
    "test_flight": "first_lift",
    "waterborne": "ship_ocean_afloat",
    "postflight_diagnosis": "shipboard_recovery_review",
    "family_reunion": "family_reunion_review_only",
    "working_theory": "shared_fuel_theory_review_only",
}
const QUEST_CUES := {
    "job_search": "find_harmonic_engine_work",
    "engineering": "inspect_engine_stations",
    "preflight": "await_short_test_launch",
    "test_flight": "monitor_phase_and_containment",
    "waterborne": "verify_ship_and_crew_afloat",
    "postflight_diagnosis": "inspect_reserve_and_recovery_readiness",
    "family_reunion": "discuss_three_independent_observations",
    "working_theory": "investigate_unconfirmed_fuel_role",
}
const RECOVERY_CHECKS: Array[String] = [
    "crew_accounting", "systems_isolation", "contact_plan",
]
const OBSERVABLE_CLUES: Array[String] = [
    "phase_readings", "depleted_reserve", "lyra_observation",
]

static func plan(packet: Dictionary) -> Dictionary:
    if packet.get("ok", false) != true:
        return _no("invalid producer receipt")
    if packet.get("schema", "") != SCHEMA or packet.get("authority", "") != "prototype_only":
        return _no("unrecognized schema or source authority")
    if packet.get("chapter", "") != "first_wake":
        return _no("not a First Wake cue")
    var step: String = str(packet.get("story_phase", ""))
    if not VISUAL_CUES.has(step):
        return _no("unknown story stage")
    if packet.get("visual_cue", "") != VISUAL_CUES[step]:
        return _no("stage/visual cue conflict")
    if packet.get("quest_cue", "") != QUEST_CUES[step]:
        return _no("stage/quest cue conflict")

    var expected_party: Array = ["ender"]
    if step in ["engineering", "preflight", "test_flight", "waterborne", "postflight_diagnosis"]:
        expected_party = ["ender", "ionia"]
    elif step in ["family_reunion", "working_theory"]:
        expected_party = ["ender", "ionia", "lyra"]
    if packet.get("story_party", []) != expected_party:
        return _no("unexpected recruitment chronology")

    var expected_ship: String = "docked"
    if step in ["engineering", "preflight"]:
        expected_ship = "docked_engineering"
    elif step == "test_flight":
        if packet.get("ship_state", "") not in ["airborne_test", "controlled_descent"]:
            return _no("unrecognized bounded flight state")
        expected_ship = str(packet["ship_state"])
    elif step == "waterborne":
        expected_ship = "ocean_afloat"
    elif step in ["postflight_diagnosis", "family_reunion", "working_theory"]:
        expected_ship = "ocean_afloat_engines_offline"
    if packet.get("ship_state", "") != expected_ship:
        return _no("ship state and story phase disagree")

    for field in [
        "world_navigation_authorized", "production_ocean_verified",
        "real_family_meeting_verified", "production_save_write_authorized",
        "canon_promotion_authorized"
    ]:
        if typeof(packet.get(field, null)) != TYPE_BOOL or packet[field]:
            return _no("unapproved production authority: " + field)
    if packet.get("gameplay_combat_grants", ["invalid"]) != []:
        return _no("story party is not battle-ability authorization")
    if typeof(packet.get("reunion_fixture_only", null)) != TYPE_BOOL:
        return _no("rehearsal provenance missing")
    var qa_family: bool = step in ["family_reunion", "working_theory"]
    if bool(packet["reunion_fixture_only"]) != qa_family:
        return _no("QA family meeting state disagrees with chronology")

    var checks: Array = packet.get("recovery_checks", [])
    if typeof(packet.get("recovery_readiness_observed", null)) != TYPE_BOOL:
        return _no("readiness authority missing")
    if checks.size() > RECOVERY_CHECKS.size():
        return _no("too many shipboard checks")
    var observed: Array = []
    for check in checks:
        if check not in RECOVERY_CHECKS or check in observed:
            return _no("invalid or duplicated recovery observation")
        observed.append(check)
    var ready: bool = bool(packet["recovery_readiness_observed"])
    if ready != (checks.size() == RECOVERY_CHECKS.size()):
        return _no("invalid readiness evidence")
    if checks.size() > 0 and step not in ["postflight_diagnosis", "family_reunion", "working_theory"]:
        return _no("crew checks recorded before postflight")
    if qa_family and not ready:
        return _no("family rehearsal bypassed shipboard readiness")

    var clues: Array = packet.get("observed_clues", [])
    var unique_clues: Array = []
    for clue in clues:
        if clue not in OBSERVABLE_CLUES or clue in unique_clues:
            return _no("invalid or duplicated theory clue")
        unique_clues.append(clue)
    if not clues.is_empty() and step not in ["family_reunion", "working_theory"]:
        return _no("clues recorded before family introduction")
    if step == "working_theory":
        if packet.get("fuel_explanation", "") != "working_hypothesis" or clues.size() < 2:
            return _no("unearned working hypothesis")
    elif packet.get("fuel_explanation", "") != "unknown":
        return _no("fuel mechanism must remain unknown before theory")

    # These are noncanonical CINEMATOGRAPHY LOOKS, not weather or travel facts.
    # Palette selection is opt-in and never asserts that a story event causes rain.
    var light_index: int = 0
    var weather_index: int = 0
    var camera_offset := Vector3(8.0, 5.0, -10.0)
    var camera_fov: float = 47.0
    var label: String = "SHIP VISUAL PREVIEW"
    match step:
        "job_search":
            label = "JOB NOTICE / DOCK REVIEW"
            camera_offset = Vector3(8.2, 5.1, -11.4)
        "engineering":
            label = "ENGINEERING / INTERIOR NOT IMPLEMENTED"
            light_index = 1
            camera_offset = Vector3(-8.0, 4.0, -9.0)
        "preflight":
            label = "PRE-FLIGHT / AUREATE WAKE"
            light_index = 1
            camera_fov = 51.0
        "test_flight":
            if expected_ship == "controlled_descent":
                label = "CONTROLLED DESCENT / PRESENTATION STUDY"
                light_index = 2
                weather_index = 2
                camera_offset = Vector3(9.0, 6.0, 8.5)
            else:
                label = "FIRST LIFT / AUREATE WAKE"
                camera_offset = Vector3(9.0, 5.8, -13.0)
                camera_fov = 52.0
        "waterborne":
            label = "AFLOAT / 2D PHYSICS PROOF IS SEPARATE"
            light_index = 2
            weather_index = 1
            camera_offset = Vector3(7.0, 3.5, 10.0)
        "postflight_diagnosis":
            label = "SHIPBOARD CHECKS / SAFE ROUTE UNKNOWN"
            light_index = 2
            weather_index = 1
            camera_offset = Vector3(7.0, 4.0, -8.0)
        "family_reunion":
            label = "LYRA / QA FAMILY REHEARSAL ONLY"
            light_index = 0
            camera_offset = Vector3(6.0, 3.5, -8.0)
        "working_theory":
            label = "THREE MINDS / PROVISIONAL FUEL THEORY"
            light_index = 1
            camera_offset = Vector3(-7.0, 4.0, -7.0)
    return {
        "ok": true, "source_schema": SCHEMA,
        "source_visual_cue": str(packet["visual_cue"]),
        "source_story_phase": step,
        "noncanonical_cinematography": true,
        "time_index": light_index,
        "weather_index": weather_index,
        "magic_enabled": false,
        "camera_offset": camera_offset,
        "camera_fov": camera_fov,
        "display_label": label,
        "may_move_ship": false,
        "may_modify_landing_physics": false,
        "may_grant_gameplay": false,
        "may_write_save": false,
    }

static func _no(reason: String) -> Dictionary:
    return {"ok": false, "reason": reason}
