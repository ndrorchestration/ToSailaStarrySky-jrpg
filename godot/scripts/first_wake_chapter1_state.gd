extends RefCounted

const Content = preload("res://scripts/first_wake_chapter1_content.gd")
## Migration-only native state contract for the packaged First Wake Chapter I flow.
## Mirrors the verified player-facing progression without claiming canon admission,
## save compatibility, release readiness, or completed production migration.

enum Stage {
    SIGNAL,
    CROSSING,
    CONTACT,
    CHOICE,
    WAKE,
    DONE,
}

const SIGNAL_IDS: Array[String] = [
    "harmonic_buoy",
    "sky_lane_warning",
    "below_frequency",
]

const HAZARD_IDS: Array[String] = [
    "sky_predator",
    "wind_shear",
    "corporate_intercept",
]

const CONTACT_IDS: Array[String] = [
    "elder_farmer",
    "engine_spirit",
    "child_prophet",
    "corporate_salvager",
]

const CHOICE_IDS: Array[String] = [
    "path_a",
    "path_b",
    "path_c",
]

const VALID_VARIANTS: Array[String] = [
    "10+",
    "7-9",
]

var stage: Stage = Stage.SIGNAL
var completed_signals: Array[String] = []
var completed_hazards: Array[String] = []
var contacts_met: Array[String] = []
var ionia_joined_for_choice: bool = false
var choice_path: String = ""
var choice_variant: String = ""
var epilogue_id: String = ""
var chapter_one_complete: bool = false

func complete_signal(signal_id: String) -> bool:
    if stage != Stage.SIGNAL:
        return false
    if signal_id not in SIGNAL_IDS or signal_id in completed_signals:
        return false
    completed_signals.append(signal_id)
    if completed_signals.size() == SIGNAL_IDS.size():
        stage = Stage.CROSSING
    return true

func complete_hazard(hazard_id: String) -> bool:
    if stage != Stage.CROSSING:
        return false
    if hazard_id not in HAZARD_IDS or hazard_id in completed_hazards:
        return false
    completed_hazards.append(hazard_id)
    if completed_hazards.size() == HAZARD_IDS.size():
        stage = Stage.CONTACT
        _advance_contact_if_ready()
    return true

func meet_contact(contact_id: String) -> bool:
    if stage == Stage.CHOICE or stage == Stage.WAKE or stage == Stage.DONE:
        return false
    if contact_id not in CONTACT_IDS or contact_id in contacts_met:
        return false
    # Signal-phase conversations remain valid contact evidence later, matching
    # the currently packaged Chapter I behavior.
    contacts_met.append(contact_id)
    if stage == Stage.CONTACT:
        _advance_contact_if_ready()
    return true

func choose_path(path_id: String, outcome_variant: String) -> bool:
    if stage != Stage.CHOICE:
        return false
    if not choice_path.is_empty():
        return false
    if path_id not in CHOICE_IDS or outcome_variant not in VALID_VARIANTS:
        return false
    choice_path = path_id
    choice_variant = outcome_variant
    stage = Stage.WAKE
    return true

func complete_wake(resolved_epilogue_id: String) -> bool:
    if stage != Stage.WAKE or choice_path.is_empty():
        return false
    if not Content.has_epilogue(resolved_epilogue_id):
        return false
    epilogue_id = resolved_epilogue_id
    chapter_one_complete = true
    stage = Stage.DONE
    return true

func stage_key() -> String:
    match stage:
        Stage.SIGNAL:
            return "signal"
        Stage.CROSSING:
            return "crossing"
        Stage.CONTACT:
            return "contact"
        Stage.CHOICE:
            return "choice"
        Stage.WAKE:
            return "wake"
        Stage.DONE:
            return "done"
    return ""

func desired_active_party_ids() -> Array[String]:
    if ionia_joined_for_choice:
        return ["ender", "lyra", "ionia"]
    return ["ender", "lyra"]

func snapshot() -> Dictionary:
    return {
        "stage": stage_key(),
        "signals_completed": completed_signals.duplicate(),
        "hazards_completed": completed_hazards.duplicate(),
        "contacts_met": contacts_met.duplicate(),
        "ionia_joined_for_choice": ionia_joined_for_choice,
        "choice_path": choice_path,
        "choice_variant": choice_variant,
        "epilogue_id": epilogue_id,
        "chapter_one_complete": chapter_one_complete,
        "desired_active_party_ids": desired_active_party_ids(),
    }

func _advance_contact_if_ready() -> void:
    if stage != Stage.CONTACT:
        return
    if contacts_met.size() < CONTACT_IDS.size():
        return
    ionia_joined_for_choice = true
    stage = Stage.CHOICE
