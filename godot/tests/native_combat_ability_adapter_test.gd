extends SceneTree
const AbilityGate = preload("res://scripts/combat/ability_turn_adapter.gd")
const Turns = preload("res://scripts/combat/turn_queue.gd")

func _initialize() -> void:
    var roster := {
        "ender": {"hp": 40, "max_hp": 60, "mp": 10, "max_mp": 10, "stamina": 5, "max_stamina": 5},
        "ionia": {"hp": 55, "max_hp": 55, "mp": 5, "max_mp": 5, "stamina": 5, "max_stamina": 5},
        "foe": {"hp": 30, "max_hp": 30, "mp": 4, "max_mp": 4, "stamina": 4, "max_stamina": 4}
    }
    var factions := {"ender": "crew", "ionia": "crew", "foe": "opponent"}
    var catalog := {
        "test_heal": {"kind": "heal", "power": 10, "resource": "mp", "cost": 3, "target_rule": "self"},
        "test_strike": {"kind": "damage", "power": 7, "resource": "stamina", "cost": 2, "target_rule": "enemy"}
    }
    var state := Turns.begin(roster, ["ender", "ionia", "foe"])
    if not state["ok"]:
        _fail("begin")
        return
    var original := state.duplicate(true)
    for id in ["unknown", ""]:
        var rejected := AbilityGate.use_ability(state, "ender", "foe", id, catalog, factions)
        if rejected.get("ok", true) or state != original:
            _fail("unknown ability rejection")
            return
    var friendly := AbilityGate.use_ability(state, "ender", "ionia", "test_strike", catalog, factions)
    if friendly.get("ok", true) or state != original:
        _fail("friendly fire blocked")
        return
    var invalid_self := AbilityGate.use_ability(state, "ender", "ionia", "test_heal", catalog, factions)
    if invalid_self.get("ok", true) or state != original:
        _fail("self-target blocked")
        return
    var healed := AbilityGate.use_ability(state, "ender", "ender", "test_heal", catalog, factions)
    if not healed["ok"] or healed["state"]["roster"]["ender"]["hp"] != 50 or healed["state"]["roster"]["ender"]["mp"] != 7:
        _fail("self-heal resolved")
        return
    if healed["state"]["events"][0]["ability_id"] != "test_heal" or state != original:
        _fail("event provenance or immutable input")
        return
    var wrong_turn := AbilityGate.use_ability(healed["state"], "foe", "ender", "test_strike", catalog, factions)
    if wrong_turn.get("ok", true):
        _fail("turn gate bypass")
        return
    print("NATIVE_COMBAT_ABILITY_ADAPTER_PASS")
    quit(0)

func _fail(reason: String) -> void:
    push_error("NATIVE_COMBAT_ABILITY_ADAPTER_FAIL: " + reason)
    quit(1)
