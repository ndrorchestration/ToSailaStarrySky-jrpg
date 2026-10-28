extends RefCounted
## Read-only native Chapter I integration seam for the FORWARD (Ionia-first)
## prototype. Gives future quest UI, camera and ship systems a stable *cue*
## without promoting simulated ocean/meeting, combat grants or legacy saves.
## Never call methods that advance a scene, move a ship or authorize gameplay.

const SCHEMA := "tstss.review.first_wake_pipeline.v1"
const VALID_STEPS: Array[String] = [
    "job_search", "engineering", "preflight", "test_flight",
    "waterborne", "postflight_diagnosis", "family_reunion", "working_theory",
]
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

static func project(opening, flight: Node = null, recovery: Node = null, reunion: Node = null) -> Dictionary:
    if opening == null or not opening.has_method("snapshot") or not opening.has_method("step_key"):
        return _reject("forward opening contract required; legacy chapter is not compatible")
    var progress: Dictionary = opening.snapshot()
    if progress.get("implemented_in_live_chapter_one", true) != false:
        return _reject("prototype authority must not be promoted to live chapter")
    var step: String = str(progress.get("step", ""))
    if step not in VALID_STEPS or opening.step_key() != step:
        return _reject("unknown or inconsistent forward stage")
    var party: Array = progress.get("active_party_ids", [])
    var expected_party: Array = ["ender"] if step == "job_search" else (["ender", "ionia", "lyra"] if step in ["family_reunion", "working_theory"] else ["ender", "ionia"])
    if party != expected_party:
        return _reject("recruitment chronology mismatch")
    if "talen" in party or "reson" in party or "aepex" in party:
        return _reject("out-of-order character or noncombat child admitted")

    var ship_state: String = "docked"
    var flight_receipt: Dictionary = {}
    if flight != null:
        if not flight.has_method("review_snapshot") or flight.opening != opening:
            return _reject("flight source does not match opening instance")
        flight_receipt = flight.review_snapshot()
        if flight_receipt.get("party", []) != party and step not in ["family_reunion", "working_theory"]:
            return _reject("flight party snapshot mismatch")
        if bool(flight_receipt.get("production_ocean_verified", true)):
            return _reject("synthetic water proof falsely claimed production ocean")
    if step in ["test_flight", "waterborne", "postflight_diagnosis", "family_reunion", "working_theory"] and flight == null:
        return _reject("physical flight/postflight source required")
    if step in ["job_search", "engineering", "preflight"] and flight != null and flight.phase not in ["awaiting_launch"]:
        return _reject("unexpected progressed flight source")
    match step:
        "engineering", "preflight":
            ship_state = "docked_engineering"
        "test_flight":
            if flight.phase not in ["ascent", "warning", "descent"]:
                return _reject("test flight phase mismatch")
            ship_state = "controlled_descent" if flight.phase == "descent" else "airborne_test"
        "waterborne":
            if flight.phase != "waterborne" or not bool(flight_receipt.get("actual_2d_area_contact_observed", false)) or not bool(flight_receipt.get("stable_buoyant_hull_observed", false)):
                return _reject("waterborne status requires physical local contact and stable float")
            ship_state = "ocean_afloat"
        "postflight_diagnosis", "family_reunion", "working_theory":
            if not bool(flight_receipt.get("actual_2d_area_contact_observed", false)) or not bool(flight_receipt.get("stable_buoyant_hull_observed", false)) or not bool(flight_receipt.get("postflight_reserve_observed", false)):
                return _reject("postflight scene lacks physical and reserve observations")
            if flight.phase != "postflight_diagnosis":
                return _reject("flight source is not in stable postflight diagnosis")
            ship_state = "ocean_afloat_engines_offline"

    var checks: Array = []
    var readiness_complete: bool = false
    if recovery != null:
        if step not in ["postflight_diagnosis", "family_reunion", "working_theory"]:
            return _reject("recovery check appears before postflight diagnosis")
        if not recovery.has_method("review_snapshot") or recovery.opening != opening or recovery.source_flight != flight:
            return _reject("shipboard recovery is not bound to original voyage")
        var receipt: Dictionary = recovery.review_snapshot()
        if receipt.get("review_source", "") != "isolated_first_wake_recovery_checklist":
            return _reject("unknown shipboard readiness source")
        if receipt.get("story_step", "") not in ["postflight_diagnosis", "family_reunion", "working_theory"]:
            return _reject("recovery contract stage mismatch")
        if bool(receipt.get("actual_sailing_route_verified", true)) or bool(receipt.get("safe_family_meeting_verified", true)) or bool(receipt.get("message_delivered", true)) or bool(receipt.get("recovery_success_certified", true)):
            return _reject("local readiness cannot certify voyage, transmission or reunion")
        checks = receipt.get("observations", []).duplicate()
        readiness_complete = bool(receipt.get("readiness_review_complete", false))
        if readiness_complete and checks.size() != 3:
            return _reject("ready flag without all three shipboard checks")

    var clue_ids: Array = progress.get("clues", []).duplicate()
    var meeting_rehearsal: bool = false
    if reunion != null:
        if step not in ["postflight_diagnosis", "family_reunion", "working_theory"]:
            return _reject("reunion review appears before waterborne recovery")
        if not reunion.has_method("review_snapshot") or reunion.opening != opening or reunion.source_flight != flight:
            return _reject("reunion review is not bound to original voyage")
        var meeting: Dictionary = reunion.review_snapshot()
        if bool(meeting.get("real_recovery_route_verified", true)) or bool(meeting.get("geography_authorized", true)) or bool(meeting.get("fuel_formula_verified", true)) or bool(meeting.get("talen_combat_authorized", true)):
            return _reject("rehearsal claimed production geography, fuel or child's combat")
        if not readiness_complete and bool(meeting.get("recovery_fixture_only", false)):
            return _reject("QA reunion cannot bypass shipboard readiness")
        meeting_rehearsal = bool(meeting.get("recovery_fixture_only", false))
    if step in ["family_reunion", "working_theory"]:
        if reunion == null or not meeting_rehearsal or not readiness_complete:
            return _reject("family/theory phase requires complete isolated QA rehearsal chain")
        if step == "working_theory" and clue_ids.size() < 2:
            return _reject("unearned fuel hypothesis")

    return {
        "ok": true,
        "schema": SCHEMA,
        "authority": "prototype_only",
        "chapter": "first_wake",
        "story_phase": step,
        "story_party": party.duplicate(),
        "visual_cue": str(VISUAL_CUES[step]),
        "quest_cue": str(QUEST_CUES[step]),
        "ship_state": ship_state,
        "recovery_checks": checks.duplicate(),
        "recovery_readiness_observed": readiness_complete,
        "reunion_fixture_only": meeting_rehearsal,
        "observed_clues": clue_ids.duplicate(),
        "fuel_explanation": "working_hypothesis" if step == "working_theory" else "unknown",
        "gameplay_combat_grants": [],
        "world_navigation_authorized": false,
        "production_ocean_verified": false,
        "real_family_meeting_verified": false,
        "production_save_write_authorized": false,
        "canon_promotion_authorized": false,
    }

static func _reject(reason: String) -> Dictionary:
    return {"ok": false, "error": reason}
