extends RefCounted
## Native battle transaction primitive. Pure, deterministic and fail-closed.
## Does not authorize encounters, change story state, or define canon balance.
## Combat UI/AI must use the same preflight result before committing an action.

const MAX_RESOURCE := 999999
const MAX_POWER := 99999

static func resolve_action(actor: Dictionary, target: Dictionary, action: Dictionary) -> Dictionary:
    var checked := preflight(actor, target, action)
    if not checked["ok"]:
        return checked
    var actor_next: Dictionary = actor.duplicate(true)
    var target_next: Dictionary = target.duplicate(true)
    var resource: String = action.get("resource", "mp")
    var cost: int = action.get("cost", 0)
    var power: int = action["power"]
    var kind: String = action["kind"]
    actor_next[resource] = actor_next[resource] - cost
    var before: int = target_next["hp"]
    if kind == "damage":
        target_next["hp"] = maxi(0, before - power)
    else:
        target_next["hp"] = mini(target_next["max_hp"], before + power)
    return {
        "ok": true,
        "actor": actor_next,
        "target": target_next,
        "event": {
            "kind": kind,
            "resource": resource,
            "resource_spent": cost,
            "amount_applied": absi(target_next["hp"] - before),
            "target_hp_after": target_next["hp"]
        }
    }

static func preflight(actor: Dictionary, target: Dictionary, action: Dictionary) -> Dictionary:
    if not _valid_unit(actor) or not _valid_unit(target):
        return _reject("invalid_unit")
    if not action.has("kind") or typeof(action["kind"]) != TYPE_STRING:
        return _reject("invalid_kind")
    var kind: String = action["kind"]
    if kind != "damage" and kind != "heal":
        return _reject("unsupported_kind")
    if not _bounded_int(action.get("power"), MAX_POWER):
        return _reject("invalid_power")
    if not _bounded_int(action.get("cost", 0), MAX_RESOURCE):
        return _reject("invalid_cost")
    if not action.has("resource") or typeof(action["resource"]) != TYPE_STRING:
        return _reject("invalid_resource")
    var resource: String = action["resource"]
    if resource != "mp" and resource != "stamina":
        return _reject("unsupported_resource")
    if actor[resource] < action.get("cost", 0):
        return _reject("insufficient_resource")
    if actor["hp"] <= 0:
        return _reject("actor_incapacitated")
    if target["hp"] <= 0:
        return _reject("target_incapacitated")
    if kind == "heal" and target["hp"] >= target["max_hp"]:
        return _reject("target_full_health")
    return {"ok": true}

static func _valid_unit(unit: Dictionary) -> bool:
    for field in ["hp", "max_hp", "mp", "max_mp", "stamina", "max_stamina"]:
        if not _bounded_int(unit.get(field), MAX_RESOURCE):
            return false
    return unit["max_hp"] > 0 and unit["hp"] <= unit["max_hp"] and unit["mp"] <= unit["max_mp"] and unit["stamina"] <= unit["max_stamina"]

static func _bounded_int(value: Variant, upper: int) -> bool:
    return typeof(value) == TYPE_INT and value >= 0 and value <= upper

static func _reject(reason: String) -> Dictionary:
    return {"ok": false, "reason": reason}
