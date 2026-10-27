extends RefCounted
## Read-only COMPOSITE candidate: creator-directed Chapter I roster presence
## + explicit laboratory Art grant + shared metadata + pure turn reservation.
## It never produces combat authorization, advances story, commits costs, or casts.
const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Roster = preload("res://scripts/first_wake_resonance_roster_gate.gd")
const Battle = preload("res://scripts/tidebound_promise_review.gd")
const Ability = preload("res://scripts/combat_ability_contract.gd")
const Reservation = preload("res://scripts/party_action_reservation.gd")
const Authority = preload("res://scripts/first_wake_party_combat_authority.gd")
const VERSION := "0.1.0"
const ART_ID := "tidebound_promise"
const PARTICIPANTS := ["ender", "lyra"]

var roster = Roster.new()
var abilities = Ability.new()
var reservations = Reservation.new()
var live_authority = Authority.new()

func inspect(opening: Variant, trial: Variant) -> Dictionary:
    # Only the exact reviewed source scripts may be inspected. JSON or old
    # Crossing party snapshots cannot impersonate the new story FSM.
    if not (opening is RefCounted) or opening.get_script() != Opening:
        return _deny("unrecognized_story_contract")
    if not (trial is RefCounted) or trial.get_script() != Battle:
        return _deny("unrecognized_training_fixture")
    if not live_authority.validate():
        return _deny("native_party_authority_invalid")
    if live_authority.can_take_formula_turn("lyra") or live_authority.can_use_formula_action("ender", ART_ID):
        return _deny("production_authority_drift")

    var story: Dictionary = roster.evaluate(opening, PARTICIPANTS)
    if not bool(story.get("rosterEligible", false)):
        return _deny("story:" + str(story.get("reason", "roster_denied")))

    # Important: story roster presence can only be a prerequisite; never an
    # entitlement. The laboratory access path remains separate and revocable.
    var ability: Dictionary = abilities.for_resonance(ART_ID)
    if not abilities.validate_definition(ability) or ability.get("runtimeStatus", "") != Ability.REVIEW_STATUS:
        return _deny("shared_ability_invalid")
    if ability.get("participants", []) != PARTICIPANTS or bool(ability.get("canExecute", true)):
        return _deny("shared_ability_not_review_only")

    var training_state: Dictionary = trial.snapshot()
    if training_state.get("reviewOnly", null) != true:
        return _deny("training_scope_required")
    var training: Dictionary = trial.admission()
    if not bool(training.get("ok", false)):
        return _deny("training:" + str(training.get("reason", "training_denied")))
    var plan: Dictionary = reservations.plan(training_state, ability, "focus", Battle.FOCUS_COST)
    if not bool(plan.get("ok", false)):
        return _deny("joint_reservation:" + str(plan.get("reason", "reservation_denied")))
    var receipts = plan.get("reservations", null)
    if not (receipts is Array) or receipts.size() != PARTICIPANTS.size():
        return _deny("reservation_receipt_invalid")
    for i in range(PARTICIPANTS.size()):
        if not (receipts[i] is Dictionary) or receipts[i].get("actorId", "") != PARTICIPANTS[i]:
            return _deny("reservation_receipt_invalid")
    return {
        "canPreview": true, "canExecute": false, "canUnlockArt": false,
        "reviewOnly": true, "reason": "composite_review_preflight_only",
        "artId": ART_ID, "storyStep": story["storyStep"],
        "participants": PARTICIPANTS.duplicate(),
        "reservationPreview": Array(receipts).duplicate(true),
        "version": VERSION,
    }

func try_execute(_opening: Variant, _trial: Variant) -> Dictionary:
    # Explicit invariant: this adapter can NEVER dispatch to Battle.activate.
    # Story unlock, costs/turn economy, live action authority, etc. remain open.
    return _deny("production_art_authority_not_implemented")

func _deny(reason: String) -> Dictionary:
    return {
        "canPreview": false, "canExecute": false,
        "canUnlockArt": false, "reviewOnly": true,
        "reason": reason, "version": VERSION,
    }
