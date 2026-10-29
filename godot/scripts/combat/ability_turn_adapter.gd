extends RefCounted
## Review-only bridge from an explicit ability catalog to turn authority.
## No canonical ability, equipment, encounter or visual claim is made.
const Turns = preload("res://scripts/combat/turn_queue.gd")

static func use_ability(state: Dictionary, actor_id: String, target_id: String,
        ability_id: String, catalog: Dictionary, factions: Dictionary) -> Dictionary:
    if ability_id.is_empty() or not catalog.has(ability_id):
        return {"ok": false, "reason": "unknown_ability"}
    var raw: Variant = catalog[ability_id]
    if typeof(raw) != TYPE_DICTIONARY:
        return {"ok": false, "reason": "invalid_ability"}
    var ability: Dictionary = raw
    if not ability.has_all(["kind", "power", "resource", "cost", "target_rule"]):
        return {"ok": false, "reason": "invalid_ability"}
    if typeof(ability["target_rule"]) != TYPE_STRING:
        return {"ok": false, "reason": "invalid_target_rule"}
    var rule: String = ability["target_rule"]
    if rule not in ["self", "ally", "enemy"]:
        return {"ok": false, "reason": "invalid_target_rule"}
    if not factions.has(actor_id) or not factions.has(target_id):
        return {"ok": false, "reason": "unknown_faction"}
    if typeof(factions[actor_id]) != TYPE_STRING or typeof(factions[target_id]) != TYPE_STRING:
        return {"ok": false, "reason": "invalid_faction"}
    if str(factions[actor_id]).is_empty() or str(factions[target_id]).is_empty():
        return {"ok": false, "reason": "invalid_faction"}
    var same_team: bool = factions[actor_id] == factions[target_id]
    if rule == "self" and actor_id != target_id:
        return {"ok": false, "reason": "self_target_required"}
    if rule == "ally" and not same_team:
        return {"ok": false, "reason": "ally_target_required"}
    if rule == "enemy" and same_team:
        return {"ok": false, "reason": "enemy_target_required"}
    var action := {
        "kind": ability["kind"], "power": ability["power"],
        "resource": ability["resource"], "cost": ability["cost"]
    }
    var outcome: Dictionary = Turns.take_action(state, actor_id, target_id, action)
    if not outcome.get("ok", false):
        return outcome
    # Event metadata only; catalog never provides arbitrary mutable stats.
    outcome["state"]["events"][-1]["ability_id"] = ability_id
    outcome["event"]["ability_id"] = ability_id
    return outcome
