extends RefCounted
## Explicit, deterministic round-robin turn authority for isolated native combat.
## Receives ordered participant identities; no recruitment or encounter authorization.
const RosterBattle = preload("res://scripts/combat/roster_battle.gd")

static func begin(roster: Dictionary, participant_ids: Array[String]) -> Dictionary:
    if participant_ids.is_empty():
        return _reject("empty_participants")
    var unique := {}
    for id in participant_ids:
        if id.is_empty() or unique.has(id) or not roster.has(id):
            return _reject("invalid_participants")
        if typeof(roster[id]) != TYPE_DICTIONARY or not _healthy(roster[id]):
            return _reject("invalid_participants")
        unique[id] = true
    return {"ok": true, "roster": roster.duplicate(true), "order": participant_ids.duplicate(), "cursor": 0, "round": 1, "events": []}

static func current_actor(state: Dictionary) -> String:
    if not _valid_state(state):
        return ""
    var order: Array = state["order"]
    var cursor: int = state["cursor"]
    for offset in range(order.size()):
        var id: String = order[(cursor + offset) % order.size()]
        if _healthy(state["roster"][id]):
            return id
    return ""

static func take_action(state: Dictionary, actor_id: String, target_id: String, action: Dictionary) -> Dictionary:
    if not _valid_state(state):
        return _reject("invalid_turn_state")
    var active: String = current_actor(state)
    if active.is_empty():
        return _reject("battle_inactive")
    if actor_id != active:
        return _reject("not_actor_turn")
    if target_id not in state["order"]:
        return _reject("target_not_participant")
    var resolution: Dictionary = RosterBattle.apply_action(state["roster"], actor_id, target_id, action)
    if not resolution["ok"]:
        return resolution
    var next: Dictionary = state.duplicate(true)
    next["roster"] = resolution["roster"]
    var event: Dictionary = resolution["event"].duplicate(true)
    event["actor_id"] = actor_id
    event["target_id"] = target_id
    next["events"].append(event)
    var order: Array = next["order"]
    var idx: int = order.find(actor_id)
    next["cursor"] = (idx + 1) % order.size()
    if idx + 1 >= order.size():
        next["round"] += 1
    return {"ok": true, "state": next, "event": event}

static func _valid_state(state: Dictionary) -> bool:
    if not state.has_all(["roster", "order", "cursor", "round", "events"]):
        return false
    if typeof(state["roster"]) != TYPE_DICTIONARY or typeof(state["order"]) != TYPE_ARRAY or typeof(state["events"]) != TYPE_ARRAY:
        return false
    if typeof(state["cursor"]) != TYPE_INT or typeof(state["round"]) != TYPE_INT:
        return false
    var order: Array = state["order"]
    if order.is_empty() or state["cursor"] < 0 or state["cursor"] >= order.size() or state["round"] < 1:
        return false
    var seen := {}
    for id in order:
        if typeof(id) != TYPE_STRING or id.is_empty() or seen.has(id) or not state["roster"].has(id):
            return false
        seen[id] = true
        var unit: Variant = state["roster"][id]
        if typeof(unit) != TYPE_DICTIONARY or not unit.has("hp") or typeof(unit["hp"]) != TYPE_INT:
            return false
    return true

static func _healthy(unit: Dictionary) -> bool:
    return unit.has("hp") and typeof(unit["hp"]) == TYPE_INT and unit["hp"] > 0

static func _reject(reason: String) -> Dictionary:
    return {"ok": false, "reason": reason}
