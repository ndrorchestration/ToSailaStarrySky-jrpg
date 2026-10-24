extends RefCounted
## Fail-closed native combat-party authority for the current First Wake migration.
##
## This is intentionally narrower than roster/playability state:
## - Chapter I Crossing currently exposes Ender + Lyra as the active party.
## - Only Ender's production-formula subset has executable native combat authority.
## - Lyra's and Ionia's affinities / combat actions remain OPEN in current SSOT.
## - Ionia joins after Crossing at the storm/shield choice boundary, so she is not
##   part of the authored Wind Shear combat party.
##
## Do not infer spells, weapons, support actions, or turn rights from character
## theme, stat profile, party membership, or narrative importance.

const VERSION := "0.1.0"

const CURRENT_CROSSING_PARTY: Array[String] = [
    "ender",
    "lyra",
]

const AUTHORIZED_ACTIONS_BY_ACTOR := {
    "ender": [
        "staffStrike",
        "uncoverTruth",
        "hold",
        "rest",
    ],
    "lyra": [],
    "ionia": [],
}

const SEPARATE_CONTRACT_ACTIONS_BY_ACTOR := {
    "ender": [
        "mycelialLedger",
        "aetherSeal",
    ],
    "lyra": [],
    "ionia": [],
}

const BLOCKED_OR_UNRESOLVED_ACTIONS := {
    "sharedDream": "blocked-by-current-ssot",
    "windWard": "blocked-pending-owner-and-domain",
}

const ACTOR_STATUS := {
    "ender": "active-formula-authority",
    "lyra": "party-present-actions-not-authorized",
    "ionia": "joins-after-crossing-actions-not-authorized",
}

func authorized_actions(actor_id: String) -> Array[String]:
    var raw: Array = AUTHORIZED_ACTIONS_BY_ACTOR.get(actor_id, [])
    var result: Array[String] = []
    for action_id in raw:
        result.append(str(action_id))
    return result

func separate_contract_actions(actor_id: String) -> Array[String]:
    var raw: Array = SEPARATE_CONTRACT_ACTIONS_BY_ACTOR.get(actor_id, [])
    var result: Array[String] = []
    for action_id in raw:
        result.append(str(action_id))
    return result

func can_take_formula_turn(actor_id: String) -> bool:
    return not authorized_actions(actor_id).is_empty()

func can_use_formula_action(actor_id: String, action_id: String) -> bool:
    return action_id in authorized_actions(actor_id)

func status_for(actor_id: String) -> String:
    return str(ACTOR_STATUS.get(actor_id, "unknown-actor"))

func surface_for_party(party_ids: Array[String]) -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for actor_id in party_ids:
        rows.append({
            "actorId": actor_id,
            "status": status_for(actor_id),
            "canTakeFormulaTurn": can_take_formula_turn(actor_id),
            "authorizedActions": authorized_actions(actor_id),
            "separateContractActions": separate_contract_actions(actor_id),
        })
    return rows

func validate() -> bool:
    if VERSION != "0.1.0":
        return false
    if CURRENT_CROSSING_PARTY != ["ender", "lyra"]:
        return false
    if authorized_actions("ender") != ["staffStrike", "uncoverTruth", "hold", "rest"]:
        return false
    if not authorized_actions("lyra").is_empty():
        return false
    if not authorized_actions("ionia").is_empty():
        return false
    if separate_contract_actions("ender") != ["mycelialLedger", "aetherSeal"]:
        return false
    for separate_action_id in separate_contract_actions("ender"):
        if can_use_formula_action("ender", separate_action_id):
            return false
    if str(BLOCKED_OR_UNRESOLVED_ACTIONS.get("sharedDream", "")) != "blocked-by-current-ssot":
        return false
    if str(BLOCKED_OR_UNRESOLVED_ACTIONS.get("windWard", "")) != "blocked-pending-owner-and-domain":
        return false
    if can_take_formula_turn("lyra") or can_take_formula_turn("ionia"):
        return false
    if can_take_formula_turn("unknown") or can_use_formula_action("unknown", "staffStrike"):
        return false
    if status_for("unknown") != "unknown-actor":
        return false
    return true
