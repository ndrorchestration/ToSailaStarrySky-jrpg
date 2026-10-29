extends SceneTree
const Guard = preload("res://scripts/combat/ability_learning_guard_20261029.gd")
const Turns = preload("res://scripts/combat/turn_queue.gd")

func _initialize() -> void:
    var roster := {
        "ender": {"hp": 45, "max_hp": 50, "mp": 8, "max_mp": 8, "stamina": 5, "max_stamina": 5},
        "foe": {"hp": 20, "max_hp": 20, "mp": 0, "max_mp": 0, "stamina": 0, "max_stamina": 0}
    }
    var ids: Array[String] = ["ender", "foe"]
    var state: Dictionary = Turns.begin(roster, ids)
    if not state["ok"]:
        _fail("initial battle invalid")
        return
    var catalog := {"strike": {"kind": "damage", "power": 7, "cost": 2, "resource": "mp", "target_rule": "enemy"}}
    var teams := {"ender": "crew", "foe": "opponents"}
    for learning in [{}, {"ender": []}, {"ender": [""]}, {"ender": [42]}]:
        var refused := Guard.use_learned_ability(state, "ender", "foe", "strike", catalog, teams, learning)
        if refused["ok"] or refused.has("state") or state["roster"] != roster:
            _fail("unlearned or invalid learning admitted")
            return
    var success := Guard.use_learned_ability(state, "ender", "foe", "strike", catalog, teams, {"ender": ["strike"]})
    if not success["ok"] or success["state"]["roster"]["foe"]["hp"] != 13:
        _fail("learned action failed")
        return
    if success["state"]["events"][0].get("ability_id") != "strike" or state["roster"] != roster:
        _fail("ability provenance or immutable state failed")
        return
    print("NATIVE_ABILITY_LEARNING_GUARD_PASS")
    quit(0)

func _fail(reason: String) -> void:
    push_error("NATIVE_ABILITY_LEARNING_GUARD_FAIL: " + reason)
    quit(1)
