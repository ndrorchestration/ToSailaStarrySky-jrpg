extends RefCounted
## Read-only player-facing clue comparison for the revised Ionia-first opening.
## This is a legibility/prototype contract, NOT a new fuel answer, unlock,
## combat ability, story authorizer, or alternative quest FSM.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const CLUE_LABELS := {
    "phase_readings": "Engine phase readings",
    "depleted_reserve": "Depleted reserve",
    "lyra_observation": "Lyra's observation",
}

func compare(opening: Variant, selected_ids: Array[String]) -> Dictionary:
    if not (opening is RefCounted) or opening.get_script() != Opening:
        return _deny("invalid_story_authority")
    var state: Dictionary = opening.snapshot()
    if state.get("step", "") not in ["family_reunion", "working_theory"]:
        return _deny("await_safe_family_reunion")
    if state.get("active_party_ids", []) != ["ender", "ionia", "lyra"]             or state.get("safe_reunion_confirmed", false) != true:
        return _deny("party_or_reunion_unverified")
    if selected_ids.size() != 2:
        return _deny("select_exactly_two_clues")
    if selected_ids[0] == selected_ids[1]:
        return _deny("duplicate_clue")
    var recorded: Array = state.get("clues", [])
    var labels: Array[String] = []
    for clue_id in selected_ids:
        if clue_id not in Opening.CLUE_IDS or clue_id not in recorded:
            return _deny("clue_not_observed")
        labels.append(str(CLUE_LABELS[clue_id]))
    return {
        "validComparison": true,
        "canExecute": false,
        "canUnlockArt": false,
        "canAdvanceStory": false,
        "changesSave": false,
        "fuelKnown": false,
        "selected": selected_ids.duplicate(),
        "labels": labels,
        "observation": "Two independent observations are consistent with a missing or altered harmonic reserve; composition remains unknown.",
        "nextAction": "Discuss the observations with Ionia and Lyra.",
        "sourceStep": str(state["step"]),
    }

func _deny(reason: String) -> Dictionary:
    return {
        "validComparison": false,
        "canExecute": false,
        "canUnlockArt": false,
        "canAdvanceStory": false,
        "changesSave": false,
        "fuelKnown": false,
        "reason": reason,
    }
