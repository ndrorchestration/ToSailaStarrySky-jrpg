extends RefCounted
## Read-only presentation projection. Never owns combat state or grants actions.
const Turns = preload("res://scripts/combat/turn_queue.gd")

static func project(state: Dictionary) -> Dictionary:
    if not state.get("ok", false):
        return {"ok": false, "reason": "inactive_battle"}
    if typeof(state.get("roster")) != TYPE_DICTIONARY or typeof(state.get("order")) != TYPE_ARRAY:
        return {"ok": false, "reason": "invalid_battle"}
    if typeof(state.get("events")) != TYPE_ARRAY or typeof(state.get("round")) != TYPE_INT:
        return {"ok": false, "reason": "invalid_battle"}
    if typeof(state.get("cursor")) != TYPE_INT or state["round"] < 1:
        return {"ok": false, "reason": "invalid_turn_state"}
    var order: Array = state["order"]
    if order.is_empty() or state["cursor"] < 0 or state["cursor"] >= order.size():
        return {"ok": false, "reason": "invalid_turn_state"}
    var roster: Dictionary = state["roster"]
    var seen := {}
    var members: Array = []
    for id in state["order"]:
        if typeof(id) != TYPE_STRING or id.is_empty() or seen.has(id) or not roster.has(id) or typeof(roster[id]) != TYPE_DICTIONARY:
            return {"ok": false, "reason": "invalid_participant"}
        seen[id] = true
        var unit: Dictionary = roster[id]
        for field in ["hp", "max_hp", "mp", "max_mp", "stamina", "max_stamina"]:
            if typeof(unit.get(field)) != TYPE_INT:
                return {"ok": false, "reason": "invalid_stats"}
        if unit["max_hp"] <= 0 or unit["hp"] < 0 or unit["hp"] > unit["max_hp"]:
            return {"ok": false, "reason": "invalid_stats"}
        if unit["max_mp"] < 0 or unit["mp"] < 0 or unit["mp"] > unit["max_mp"]:
            return {"ok": false, "reason": "invalid_stats"}
        if unit["max_stamina"] < 0 or unit["stamina"] < 0 or unit["stamina"] > unit["max_stamina"]:
            return {"ok": false, "reason": "invalid_stats"}
        members.append({
            "id": id,
            "hp": unit["hp"], "max_hp": unit["max_hp"],
            "mp": unit["mp"], "max_mp": unit["max_mp"],
            "stamina": unit["stamina"], "max_stamina": unit["max_stamina"],
            "incapacitated": unit["hp"] == 0
        })
    return {
        "ok": true,
        "round": state["round"],
        "current_actor_id": Turns.current_actor(state),
        "members": members,
        "events": state["events"].duplicate(true)
    }
