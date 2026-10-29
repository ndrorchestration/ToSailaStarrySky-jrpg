extends SceneTree
const Turns = preload("res://scripts/combat/turn_queue.gd")
const View = preload("res://scripts/combat/battle_ui_projection.gd")

func _initialize() -> void:
    var roster := {
        "ender": {"hp": 30, "max_hp": 50, "mp": 6, "max_mp": 10, "stamina": 4, "max_stamina": 5},
        "ionia": {"hp": 40, "max_hp": 40, "mp": 3, "max_mp": 8, "stamina": 2, "max_stamina": 6}
    }
    var order: Array[String] = ["ender", "ionia"]
    var state: Dictionary = Turns.begin(roster, order)
    var before: Dictionary = state.duplicate(true)
    var view := View.project(state)
    if not view["ok"] or view["current_actor_id"] != "ender" or view["members"].size() != 2:
        _fail("initial projection")
        return
    if view["members"][0]["hp"] != 30 or view["members"][1]["mp"] != 3:
        _fail("stat projection")
        return
    view["members"][0]["hp"] = 0
    view["events"].append({"fabricated": true})
    if state != before:
        _fail("UI modified authoritative state")
        return
    var next := Turns.take_action(state, "ender", "ionia",
        {"kind": "damage", "power": 40, "resource": "mp", "cost": 2})
    if not next["ok"]:
        _fail("combat resolution")
        return
    var updated := View.project(next["state"])
    if not updated["ok"] or updated["members"][1]["hp"] != 0 or not updated["members"][1]["incapacitated"]:
        _fail("damage projection")
        return
    if updated["events"].size() != 1 or updated["current_actor_id"] != "ender":
        _fail("active actor after incapacitation")
        return
    # Malformed queue metadata must not be presented as authoritative UI.
    for bad_cursor in [-1, 2, "0"]:
        var malformed: Dictionary = state.duplicate(true)
        malformed["cursor"] = bad_cursor
        if View.project(malformed).get("ok", true):
            _fail("invalid cursor accepted")
            return
    var repeated: Dictionary = state.duplicate(true)
    repeated["order"] = ["ender", "ender"]
    if View.project(repeated).get("ok", true):
        _fail("duplicate participant accepted")
        return
    var empty_order: Dictionary = state.duplicate(true)
    empty_order["order"] = []
    if View.project(empty_order).get("ok", true):
        _fail("empty order accepted")
        return
    if state != before:
        _fail("invalid projection mutated input")
        return
    print("NATIVE_BATTLE_UI_PROJECTION_PASS")
    quit(0)

func _fail(reason: String) -> void:
    push_error("NATIVE_BATTLE_UI_PROJECTION_FAIL: " + reason)
    quit(1)
