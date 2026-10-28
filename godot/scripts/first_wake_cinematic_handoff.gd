extends RefCounted
## Presentation-only seam between the creator-directed Chapter I review and
## the separately native-verified Aureate Wake 3D flight cinematography lab.
## No 3D source, screenshot, physics, story, save or canon is imported here.
## An admitted descriptor is a REVIEW INTENT, never art approval or execution.

const FROZEN_VISUAL_PR := 486
const FROZEN_VISUAL_HEAD := "36a13d6063235ed2114bb25d2a2cc61d1d4c9f22"
const FROZEN_VISUAL_RUN := 40609537235
const FALLBACK_SCENE := "res://scenes/first_wake_flight_water_review.tscn"
const VALID_SHOTS := ["bow-quarter", "wing-planform", "stern-quarter"]
const SHOT_BY_PHASE := {
    "awaiting_launch": "bow-quarter",
    "ascent": "wing-planform",
    "warning": "stern-quarter",
    "descent": "bow-quarter",
    "waterborne": "stern-quarter",
}
const STORY_STEP_BY_PHASE := {
    "awaiting_launch": "preflight",
    "ascent": "test_flight",
    "warning": "test_flight",
    "descent": "test_flight",
    "waterborne": "waterborne",
}

static func _reject(reason: String) -> Dictionary:
    return {
        "admitted_for_review": false,
        "reason": reason,
        "blocks_progression": false,
        "executes_visuals": false,
        "modifies_story_state": false,
    }

static func build(review: Dictionary, reduced_motion: bool = false,
        low_detail: bool = false, opt_in_storm_art_study: bool = false) -> Dictionary:
    # The only source of story authority is the existing native First Wake FSM.
    # A visual storyboard may not assert actual contact, progress, or a new party.
    if review.get("party", []) != ["ender", "ionia"]:
        return _reject("Ionia-first party contract not satisfied")
    var phase: String = str(review.get("phase", ""))
    if not SHOT_BY_PHASE.has(phase):
        return _reject("unknown or unauthorised first-flight phase")
    if str(review.get("story_step", "")) != STORY_STEP_BY_PHASE[phase]:
        return _reject("story step does not match physics review phase")
    if bool(review.get("production_ocean_verified", true)):
        return _reject("cannot elevate local 2D physics to production ocean")
    if str(review.get("fuel_formula", "invalid")) != "unknown":
        return _reject("first flight cannot supply a fuel formula")
    var physical_contact: bool = bool(review.get(
        "actual_2d_area_contact_observed", false))
    var float_stable: bool = bool(review.get(
        "stable_buoyant_hull_observed", false))
    if phase == "waterborne":
        if not physical_contact or not float_stable:
            return _reject("waterborne requires real contact and stable flotation")
    elif float_stable:
        return _reject("stable flotation cannot precede waterborne")
    if (phase == "awaiting_launch" or phase == "ascent" or phase == "warning") and physical_contact:
        return _reject("physics contact cannot precede descent")
    # A night/storm grade is a review switch, not a scripted Chapter I event.
    # Defaults remain golden-clear, even if the model can render storm-night.
    var look: String = "storm-night-study" if opt_in_storm_art_study else "golden-clear"
    return {
        "admitted_for_review": true,
        "review_only": true,
        "visual_source_pr": FROZEN_VISUAL_PR,
        "visual_source_sha": FROZEN_VISUAL_HEAD,
        "native_visual_ci_run": FROZEN_VISUAL_RUN,
        "camera_shot_id": SHOT_BY_PHASE[phase],
        "visual_grade_id": look,
        "storm_depth_study_strength": 1.0 if opt_in_storm_art_study else 0.0,
        "reduced_motion": reduced_motion,
        "low_detail": low_detail,
        "scene_phase": phase,
        "fallback_scene": FALLBACK_SCENE,
        "blocks_progression": false,
        "executes_visuals": false,
        "uses_external_binary_art": false,
        "modifies_story_state": false,
        "changes_saves": false,
        "grants_combat_magic": false,
        "production_ocean_verified": false,
        "local_water_contact_observed": physical_contact,
        "local_stable_float_observed": float_stable,
    }
