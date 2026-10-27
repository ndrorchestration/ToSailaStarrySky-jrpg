extends RefCounted
## Read-only cross-system JOIN-CHRONOLOGY GATE for proposed Resonance Arts.
## Uses the existing Ionia-first First Wake story model. No new story FSM.
## Roster eligibility is NOT Art unlock, combat action permission, or a spell.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const VERSION := "0.1.0"
const KNOWN_PROTAGONISTS := ["ender", "ionia", "lyra", "reson", "aepex"]
const PRE_LYRA_STEPS := [
    "engineering", "preflight", "test_flight",
    "waterborne", "postflight_diagnosis",
]
const POST_LYRA_STEPS := ["family_reunion", "working_theory"]

func evaluate(opening: Variant, participants: Variant) -> Dictionary:
    # Never accept an arbitrary save/dictionary as authority. This adapter is
    # bound specifically to the revised-opening candidate in its own branch.
    if not (opening is RefCounted) or opening.get_script() != Opening:
        return _deny("unrecognized_story_contract")
    if not (participants is Array):
        return _deny("invalid_participants")
    if not (participants.size() in [2, 3]):
        return _deny("invalid_participant_count")
    var seen: Dictionary = {}
    for actor_id in participants:
        if not (actor_id is String) or actor_id not in KNOWN_PROTAGONISTS:
            return _deny("unknown_protagonist")
        if seen.has(actor_id):
            return _deny("duplicate_protagonist")
        seen[actor_id] = true

    # Only read source-model state; never mark Lyra joined or advance the quest.
    var state: Dictionary = opening.snapshot()
    var stage: String = str(state.get("step", ""))
    var actual = state.get("active_party_ids", null)
    if not (actual is Array):
        return _deny("invalid_story_roster")
    var expected: Array = []
    if stage == "job_search":
        expected = ["ender"]
    elif stage in PRE_LYRA_STEPS:
        expected = ["ender", "ionia"]
    elif stage in POST_LYRA_STEPS:
        expected = ["ender", "ionia", "lyra"]
    else:
        return _deny("unrecognized_story_step")
    if actual != expected:
        return _deny("story_roster_mismatch")
    var safe = state.get("safe_reunion_confirmed", null)
    if not (safe is bool) or safe != (stage in POST_LYRA_STEPS):
        return _deny("reunion_evidence_mismatch")
    if "lyra" in participants and stage not in POST_LYRA_STEPS:
        return _deny("lyra_not_joined")
    for actor_id in participants:
        if actor_id not in actual:
            return _deny("participant_not_yet_joined:" + str(actor_id))
    return {
        "rosterEligible": true,
        "canExecute": false,
        "canUnlockArt": false,
        "reason": "story_presence_only",
        "storyStep": stage,
        "participants": participants.duplicate(),
        "storySource": "revised-opening-review",
        "version": VERSION,
    }

func _deny(reason: String) -> Dictionary:
    return {
        "rosterEligible": false,
        "canExecute": false,
        "canUnlockArt": false,
        "reason": reason,
        "version": VERSION,
    }
