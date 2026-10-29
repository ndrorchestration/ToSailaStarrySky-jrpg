extends RefCounted
## Atomic roster-level adapter for the pure combat transaction.
## The roster remains unchanged on failure. No turn order or story authorization.
const Transaction = preload("res://scripts/combat/turn_transaction.gd")

static func apply_action(roster: Dictionary, actor_id: String, target_id: String, action: Dictionary) -> Dictionary:
    if actor_id.is_empty() or target_id.is_empty():
        return {"ok": false, "reason": "missing_identity"}
    if not roster.has(actor_id) or not roster.has(target_id):
        return {"ok": false, "reason": "unknown_unit"}
    if typeof(roster[actor_id]) != TYPE_DICTIONARY or typeof(roster[target_id]) != TYPE_DICTIONARY:
        return {"ok": false, "reason": "invalid_unit"}
    var outcome: Dictionary = Transaction.resolve_action(roster[actor_id], roster[target_id], action)
    if not outcome["ok"]:
        return outcome
    var next_roster: Dictionary = roster.duplicate(true)
    if actor_id == target_id:
        # The two projections of one actor are not two independent units.
        # Merge spent resources with restored/damaged HP, keeping other stats.
        var merged: Dictionary = outcome["actor"].duplicate(true)
        merged["hp"] = outcome["target"]["hp"]
        next_roster[actor_id] = merged
    else:
        next_roster[actor_id] = outcome["actor"]
        next_roster[target_id] = outcome["target"]
    return {
        "ok": true,
        "roster": next_roster,
        "event": outcome["event"].duplicate(true),
        "actor_id": actor_id,
        "target_id": target_id
    }
