extends SceneTree
const Turns = preload("res://scripts/combat/turn_queue.gd")

func _initialize() -> void:
    var roster := {
        "ender": {"hp": 50, "max_hp": 50, "mp": 6, "max_mp": 6, "stamina": 4, "max_stamina": 4},
        "ionia": {"hp": 40, "max_hp": 40, "mp": 4, "max_mp": 4, "stamina": 4, "max_stamina": 4}
    }
    var initial := Turns.begin(roster, ["ender", "ionia"] as Array[String])
    if not initial["ok"]:
        _fail("begin")
        return
    var state: Dictionary = initial
    if Turns.current_actor(state) != "ender":
        _fail("first turn")
        return
    var action := {"kind": "damage", "power": 5, "resource": "mp", "cost": 2}
    var rejected := Turns.take_action(state, "ionia", "ender", action)
    if rejected["ok"] or state["cursor"] != 0:
        _fail("out-of-turn mutation")
        return
    rejected = Turns.take_action(state, "ender", "ionia", {"kind": "damage", "power": 5, "resource": "mp", "cost": 7})
    if rejected["ok"] or state["roster"] != roster:
        _fail("unaffordable mutation")
        return
    var first := Turns.take_action(state, "ender", "ionia", action)
    if not first["ok"] or first["state"]["roster"]["ionia"]["hp"] != 35 or first["state"]["cursor"] != 1:
        _fail("first commit")
        return
    if state["roster"] != roster:
        _fail("immutable prior state")
        return
    var second := Turns.take_action(first["state"], "ionia", "ender", action)
    if not second["ok"] or second["state"]["round"] != 2 or second["state"]["cursor"] != 0:
        _fail("round transition")
        return
    if second["state"]["events"].size() != 2:
        _fail("event log")
        return
    var invalid := Turns.begin(roster, ["ender", "ender"] as Array[String])
    if invalid["ok"]:
        _fail("duplicate participants")
        return
    print("NATIVE_COMBAT_TURN_QUEUE_PASS")
    quit(0)

func _fail(reason: String) -> void:
    push_error("NATIVE_COMBAT_TURN_QUEUE_FAIL: " + reason)
    quit(1)
