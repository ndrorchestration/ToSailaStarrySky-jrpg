extends RefCounted
## PURE atomic review reservation planner. Accepts no production state.
## It returns a proposed deep copy, NEVER mutates the input or dispatches effects.
## This is a future-integration seam, not an alternate live combat resolver.
const Contract = preload("res://scripts/combat_ability_contract.gd")
const VERSION := "0.1.0"
const REVIEW_RESOURCE := "focus"
const REVIEW_MAX_COST := 2

var contract = Contract.new()

func plan(state: Variant, definition: Variant, resource_id: String, unit_cost: int) -> Dictionary:
    if not (state is Dictionary):
        return _deny("invalid_state")
    var battle: Dictionary = state
    if battle.get("reviewOnly", null) != true:
        return _deny("review_scope_required")
    if not contract.validate_definition(definition):
        return _deny("invalid_ability_definition")
    var d: Dictionary = definition
    if d.get("runtimeStatus", "") != Contract.REVIEW_STATUS or d.get("sourceKind", "") not in ["dual", "triple"]:
        return _deny("production_authority_required")
    if battle.get("phase", "") != "player":
        return _deny("wrong_phase")
    if resource_id != REVIEW_RESOURCE or unit_cost < 1 or unit_cost > REVIEW_MAX_COST:
        return _deny("unsupported_review_resource")
    var party_value = battle.get("party", null)
    if not (party_value is Dictionary):
        return _deny("invalid_party")
    var party: Dictionary = party_value
    var ids: Array = d["participants"]
    var next: Dictionary = party.duplicate(true)
    var receipts: Array[Dictionary] = []
    for actor_id in ids:
        if not next.has(actor_id) or not (next[actor_id] is Dictionary):
            return _deny("participant_missing:" + str(actor_id))
        var actor: Dictionary = next[actor_id]
        if not _valid_actor(actor):
            return _deny("invalid_actor_state:" + str(actor_id))
        if not bool(actor["alive"]) or not bool(actor["canAct"]):
            return _deny("participant_unavailable")
        if int(actor["focus"]) < unit_cost:
            return _deny("insufficient_review_focus:" + str(actor_id))
        actor["focus"] = int(actor["focus"]) - unit_cost
        actor["canAct"] = false
        receipts.append({"actorId": actor_id, "resource": resource_id, "amount": unit_cost, "actionReserved": true})
    return {
        "ok": true,
        "reason": "review_plan_ready",
        "reviewOnly": true,
        "party": next,
        "reservations": receipts,
        "abilityId": d["id"],
    }

func _valid_actor(actor: Dictionary) -> bool:
    for key in ["hp", "maxHp", "focus"]:
        if not actor.has(key) or not (actor[key] is int):
            return false
    if not (actor.get("alive", null) is bool) or not (actor.get("canAct", null) is bool):
        return false
    var health: int = int(actor["hp"])
    var max_health: int = int(actor["maxHp"])
    var focus: int = int(actor["focus"])
    return max_health > 0 and health >= 0 and health <= max_health \
        and focus >= 0 and focus <= 2 and bool(actor["alive"]) == (health > 0)

func _deny(reason: String) -> Dictionary:
    return {"ok": false, "reason": reason, "reviewOnly": true}
