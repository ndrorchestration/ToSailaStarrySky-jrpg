extends SceneTree
const Turns = preload("res://scripts/combat/turn_queue.gd")

func _initialize() -> void:
    var roster := {
        "ender": {"hp": 50, "max_hp": 50, "mp": 6, "max_mp": 6, "stamina": 4, "max_stamina": 4},
        "ionia": {"hp": 40, "max_hp": 40, "mp": 4, "max_mp": 4, "stamina": 4, "max_stamina": 4}
    }
    var order: Array[String] = ["ender", "ionia"]
    var initial := Turns.begin(roster, order)
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
    var duplicate_order: Array[String] = ["ender", "ender"]
    var invalid := Turns.begin(roster, duplicate_order)
    if invalid["ok"]:
        _fail("duplicate participants")
        return
    # Skipping a defeated last participant must still close the round.
    var triple_roster: Dictionary = roster.duplicate(true)
    triple_roster["talen"] = {"hp": 3, "max_hp": 3, "mp": 4, "max_mp": 4, "stamina": 4, "max_stamina": 4}
    var triple_order: Array[String] = ["ender", "ionia", "talen"]
    var triple := Turns.begin(triple_roster, triple_order)
    if not triple["ok"]:
        _fail("three participant begin")
        return
    var knockout := Turns.take_action(triple, "ender", "talen", {"kind": "damage", "power": 3, "resource": "mp", "cost": 0})
    if not knockout["ok"] or knockout["state"]["roster"]["talen"]["hp"] != 0:
        _fail("last participant knockout")
        return
    var after_knockout := Turns.take_action(knockout["state"], "ionia", "ender", action)
    if not after_knockout["ok"] or after_knockout["state"]["round"] != 2 or Turns.current_actor(after_knockout["state"]) != "ender":
        _fail("skipped last participant round rollover")
        return
    if after_knockout["state"]["roster"]["talen"]["hp"] != 0 or triple["roster"] != triple_roster:
        _fail("knockout state preservation")
        return
    # Only one living participant remains: each legal action begins a new round.
    var solo_state: Dictionary = Turns.begin(roster, order)
    if not solo_state["ok"]:
        _fail("solo setup")
        return
    solo_state["roster"]["ionia"]["hp"] = 0
    var solo_action := {"kind": "heal", "power": 1, "resource": "mp", "cost": 0}
    solo_state["roster"]["ender"]["hp"] = 49
    var solo_original: Dictionary = solo_state.duplicate(true)
    var solo_result := Turns.take_action(solo_state, "ender", "ender", solo_action)
    if not solo_result["ok"] or solo_result["state"]["round"] != 2 or Turns.current_actor(solo_result["state"]) != "ender":
        _fail("sole survivor round rollover")
        return
    if solo_state != solo_original or solo_result["state"]["roster"]["ender"]["hp"] != 50:
        _fail("sole survivor immutable input")
        return
    print("NATIVE_COMBAT_TURN_QUEUE_PASS")
    quit(0)

func _fail(reason: String) -> void:
    push_error("NATIVE_COMBAT_TURN_QUEUE_FAIL: " + reason)
    quit(1)
