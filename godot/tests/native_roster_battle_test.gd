extends SceneTree
const Battle = preload("res://scripts/combat/roster_battle.gd")

func _initialize() -> void:
    var roster := {
        "ender": {"hp": 45, "max_hp": 100, "mp": 15, "max_mp": 20, "stamina": 8, "max_stamina": 10},
        "ionia": {"hp": 80, "max_hp": 80, "mp": 5, "max_mp": 10, "stamina": 4, "max_stamina": 10}
    }
    var original: Dictionary = roster.duplicate(true)
    var heal := Battle.apply_action(roster, "ender", "ender", {"kind": "heal", "power": 35, "resource": "mp", "cost": 5})
    if not heal["ok"] or heal["roster"]["ender"]["hp"] != 80 or heal["roster"]["ender"]["mp"] != 10:
        _fail("self-heal must atomically merge resource cost and restored HP")
        return
    if heal["roster"]["ionia"] != roster["ionia"] or roster != original:
        _fail("input roster changed")
        return
    var hit := Battle.apply_action(roster, "ender", "ionia", {"kind": "damage", "power": 21, "resource": "stamina", "cost": 3})
    if not hit["ok"] or hit["roster"]["ionia"]["hp"] != 59 or hit["roster"]["ender"]["stamina"] != 5:
        _fail("two-unit commit")
        return
    for invalid_target in ["", "lyra"]:
        var rejected := Battle.apply_action(roster, "ender", invalid_target, {"kind": "damage", "power": 2, "resource": "mp", "cost": 1})
        if rejected["ok"] or rejected.has("roster") or roster != original:
            _fail("unknown identity committed")
            return
    var unaffordable := Battle.apply_action(roster, "ender", "ionia", {"kind": "damage", "power": 2, "resource": "mp", "cost": 16})
    if unaffordable["ok"] or unaffordable.has("roster"):
        _fail("unaffordable action committed")
        return
    print("NATIVE_ROSTER_BATTLE_PASS")
    quit(0)

func _fail(reason: String) -> void:
    push_error("NATIVE_ROSTER_BATTLE_FAIL: " + reason)
    quit(1)
