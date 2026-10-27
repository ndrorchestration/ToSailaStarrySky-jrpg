extends RefCounted
## Review-only First Wake opening order and evidence contract.
## Creator-directed story: Ender -> Ionia (before test flight) -> Lyra (after splashdown).
## Does NOT replace the legacy Chapter I quest FSM, grant combat permissions,
## implement real water physics, change saves, or establish fuel composition.

enum Step {
    JOB_SEARCH,
    ENGINEERING,
    PREFLIGHT,
    TEST_FLIGHT,
    WATERBORNE,
    POSTFLIGHT_DIAGNOSIS,
    FAMILY_REUNION,
    WORKING_THEORY,
}

const CLUE_IDS: Array[String] = [
    "phase_readings",
    "depleted_reserve",
    "lyra_observation",
]

var step: Step = Step.JOB_SEARCH
var active_party_ids: Array[String] = ["ender"]
var failure_logged: bool = false
var clues: Array[String] = []
var safe_reunion_confirmed: bool = false

func accept_ionia_job() -> bool:
    if step != Step.JOB_SEARCH:
        return false
    active_party_ids.append("ionia")
    step = Step.ENGINEERING
    return true

func complete_engineering_checks() -> bool:
    if step != Step.ENGINEERING:
        return false
    step = Step.PREFLIGHT
    return true

func begin_test_flight() -> bool:
    if step != Step.PREFLIGHT:
        return false
    step = Step.TEST_FLIGHT
    return true

func record_engine_failure(phase_drift: bool, containment_strain: bool, fuel_exhausted: bool) -> bool:
    if step != Step.TEST_FLIGHT or failure_logged:
        return false
    if not phase_drift or not containment_strain or not fuel_exhausted:
        return false
    failure_logged = true
    return true

func complete_ocean_splashdown(water_contact: bool, hull_seaworthy: bool) -> bool:
    if step != Step.TEST_FLIGHT or not failure_logged:
        return false
    if not water_contact or not hull_seaworthy:
        return false
    step = Step.WATERBORNE
    return true

func inspect_postflight_reserve(confirmed_empty: bool) -> bool:
    if step != Step.WATERBORNE or not confirmed_empty:
        return false
    step = Step.POSTFLIGHT_DIAGNOSIS
    return true

func introduce_lyra_and_talen(safe_reunion: bool) -> bool:
    if step != Step.POSTFLIGHT_DIAGNOSIS or not safe_reunion:
        return false
    safe_reunion_confirmed = true
    active_party_ids.append("lyra")
    step = Step.FAMILY_REUNION
    return true

func record_clue(clue_id: String) -> bool:
    if step != Step.FAMILY_REUNION:
        return false
    if clue_id not in CLUE_IDS or clue_id in clues:
        return false
    clues.append(clue_id)
    return true

func form_working_fuel_theory() -> bool:
    if step != Step.FAMILY_REUNION or not safe_reunion_confirmed:
        return false
    # At least two separate observable clues; Ionia's incomplete recollection
    # of Denith belongs in mandatory shared dialogue, not a confirmed formula.
    if clues.size() < 2:
        return false
    step = Step.WORKING_THEORY
    return true

func step_key() -> String:
    match step:
        Step.JOB_SEARCH: return "job_search"
        Step.ENGINEERING: return "engineering"
        Step.PREFLIGHT: return "preflight"
        Step.TEST_FLIGHT: return "test_flight"
        Step.WATERBORNE: return "waterborne"
        Step.POSTFLIGHT_DIAGNOSIS: return "postflight_diagnosis"
        Step.FAMILY_REUNION: return "family_reunion"
        Step.WORKING_THEORY: return "working_theory"
    return ""

func snapshot() -> Dictionary:
    return {
        "step": step_key(),
        "active_party_ids": active_party_ids.duplicate(),
        "failure_logged": failure_logged,
        "safe_reunion_confirmed": safe_reunion_confirmed,
        "clues": clues.duplicate(),
        "evidence_count": clues.size(),
        "fuel_explanation_status": "hypothesis_only" if step == Step.WORKING_THEORY else "unknown",
        "actual_water_physics_verified": false,
        "implemented_in_live_chapter_one": false,
    }
