extends SceneTree
## Run: godot --headless --path godot --script res://tests/native_combat_transaction_test.gd
const Transaction = preload("res://scripts/combat/turn_transaction.gd")

func _initialize() -> void:
    var actor := {"hp": 80, "max_hp": 100, "mp": 10, "max_mp": 20, "stamina": 5, "max_stamina": 10}
    var enemy := {"hp": 30, "max_hp": 30, "mp": 0, "max_mp": 0, "stamina": 0, "max_stamina": 0}
    var a := actor.duplicate(true)
    var b := enemy.duplicate(true)
    var hit := Transaction.resolve_action(a, b, {"kind": "damage", "power": 40, "resource": "mp", "cost": 3})
    if not hit["ok"] or hit["actor"]["mp"] != 7 or hit["target"]["hp"] != 0 or hit["event"]["amount_applied"] != 30:
        _fail("damage / spending / overkill")
        return
    if a != actor or b != enemy:
        _fail("input mutated")
        return
    var heal := Transaction.resolve_action(actor, actor, {"kind": "heal", "power": 50, "resource": "stamina", "cost": 2})
    if not heal["ok"] or heal["target"]["hp"] != 100 or heal["actor"]["stamina"] != 3 or heal["event"]["amount_applied"] != 20:
        _fail("healing / cap / spending")
        return
    for bad in [
        {"kind": "damage", "power": 1, "resource": "mp", "cost": 11},
        {"kind": "damage", "power": -1, "resource": "mp", "cost": 0},
        {"kind": "damage", "power": 1.5, "resource": "mp", "cost": 0},
        {"kind": "damage", "power": 1, "resource": "unknown", "cost": 0},
        {"kind": "execute", "power": 1, "resource": "mp", "cost": 0}
    ]:
        var result := Transaction.resolve_action(actor, enemy, bad)
        if result["ok"] or result.has("actor") or result.has("target"):
            _fail("invalid action admitted")
            return
    var dead := actor.duplicate()
    dead["hp"] = 0
    if Transaction.resolve_action(dead, enemy, {"kind": "damage", "power": 1, "resource": "mp", "cost": 0})["ok"]:
        _fail("incapacitated actor admitted")
        return
    if Transaction.resolve_action(actor, dead, {"kind": "damage", "power": 1, "resource": "mp", "cost": 0})["ok"]:
        _fail("incapacitated target admitted")
        return
    if Transaction.resolve_action(actor, enemy, {"kind": "heal", "power": 1, "resource": "mp", "cost": 0})["ok"]:
        _fail("full HP healing admitted")
        return
    print("NATIVE_COMBAT_TRANSACTION_PASS")
    quit(0)

func _fail(reason: String) -> void:
    push_error("NATIVE_COMBAT_TRANSACTION_FAIL: " + reason)
    quit(1)
