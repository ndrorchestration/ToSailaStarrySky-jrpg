extends RefCounted
## Single authority for the creator-directed First Wake game entry path.
## Owns Ionia-first story sequence and local checkpoint provenance, never the
## actual RigidBody2D/Area2D sensor, 3D camera, VFX or deprecated chapter FSM.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Checkpoint = preload("res://scripts/first_wake_game_checkpoint.gd")

var opening = Opening.new()
var physical_landing_observed: bool = false
var reserve_inspected: bool = false
var restored_from_local_checkpoint: bool = false

func bind_job_scene(candidate) -> bool:
    if candidate == null or candidate.step_key() != "job_search":
        return false
    if candidate.active_party_ids != ["ender"]:
        return false
    opening = candidate
    physical_landing_observed = false
    reserve_inspected = false
    restored_from_local_checkpoint = false
    return true

func record_physical_landing(physical_review: Dictionary) -> bool:
    if physical_landing_observed or opening.step_key() != "waterborne":
        return false
    if physical_review.get("phase", "") != "waterborne":
        return false
    if physical_review.get("story_step", "") != "waterborne":
        return false
    if physical_review.get("party", []) != ["ender", "ionia"]:
        return false
    if physical_review.get("actual_2d_area_contact_observed") != true:
        return false
    if physical_review.get("stable_buoyant_hull_observed") != true:
        return false
    if physical_review.get("production_ocean_verified") != false:
        return false
    if physical_review.get("fuel_formula") != "unknown":
        return false
    physical_landing_observed = true
    return true

func inspect_depleted_reserve() -> bool:
    if not physical_landing_observed or reserve_inspected:
        return false
    if opening.step_key() != "waterborne":
        return false
    if not opening.inspect_postflight_reserve(true):
        return false
    reserve_inspected = true
    return true

func can_checkpoint() -> bool:
    return physical_landing_observed and reserve_inspected         and opening.step_key() == "postflight_diagnosis"         and opening.active_party_ids == ["ender", "ionia"]

func save_checkpoint(path: String = Checkpoint.DEFAULT_PATH) -> bool:
    if not can_checkpoint():
        return false
    return Checkpoint.save(Checkpoint.snapshot(), path)

func load_checkpoint(path: String = Checkpoint.DEFAULT_PATH) -> bool:
    var payload: Dictionary = Checkpoint.load(path)
    if not Checkpoint.validate(payload):
        return false
    # Never reinterpret the old save contract or rewrite arbitrary stage keys.
    # Rebuild only the exact supported safe postflight entry checkpoint.
    var recovered = Opening.new()
    if not recovered.accept_ionia_job()         or not recovered.complete_engineering_checks()         or not recovered.begin_test_flight()         or not recovered.record_engine_failure(true, true, true)         or not recovered.complete_ocean_splashdown(true, true)         or not recovered.inspect_postflight_reserve(true):
        return false
    if recovered.step_key() != "postflight_diagnosis":
        return false
    opening = recovered
    physical_landing_observed = true
    reserve_inspected = true
    restored_from_local_checkpoint = true
    return true

func progress_snapshot() -> Dictionary:
    return {
        "story_step": opening.step_key(),
        "story_party": opening.active_party_ids.duplicate(),
        "physical_contact_recorded": physical_landing_observed,
        "reserve_inspected": reserve_inspected,
        "checkpoint_available": can_checkpoint(),
        "restored_historical_landing": restored_from_local_checkpoint,
        "fuel_formula": "unknown",
        "lyra_joined": "lyra" in opening.active_party_ids,
        "uses_legacy_chapter_save": false,
    }
