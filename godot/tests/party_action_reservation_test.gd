extends SceneTree
## Reservation planning must be atomic, typed, and nonmutating across actors.
const Ability = preload("res://scripts/combat_ability_contract.gd")
const Planner = preload("res://scripts/party_action_reservation.gd")

func _initialize() -> void:
    var adapter = Ability.new()
    var planner = Planner.new()
    var d: Dictionary = adapter.for_resonance("tidebound_promise")
    var initial := {
        "reviewOnly": true, "phase": "player",
        "party": {
            "ender": {"hp": 12, "maxHp": 12, "focus": 2, "alive": true, "canAct": true},
            "lyra": {"hp": 12, "maxHp": 12, "focus": 2, "alive": true, "canAct": true},
        }
    }
    var original: Dictionary = initial.duplicate(true)
    var plan: Dictionary = planner.plan(initial, d, "focus", 1)
    if not bool(plan.get("ok", false)) or not bool(plan.get("reviewOnly", false)):
        _fail("valid two-party plan rejected")
        return
    if initial != original:
        _fail("successful plan mutated caller input")
        return
    if plan["reservations"].size() != 2 or plan["reservations"][0]["actorId"] != "ender" or plan["reservations"][1]["actorId"] != "lyra":
        _fail("missing or misordered reservations")
        return
    for actor_id in ["ender", "lyra"]:
        if int(plan["party"][actor_id]["focus"]) != 1 or bool(plan["party"][actor_id]["canAct"]):
            _fail("shared plan did not reserve focus and action: " + actor_id)
            return
    plan["party"]["lyra"]["focus"] = 0
    if initial != original:
        _fail("returned proposal aliases original party")
        return
    var invalids := [
        {"state": {"party": original["party"], "phase": "player"}, "ability": d, "resource": "focus", "cost": 1, "reason": "review_scope_required"},
        {"state": initial, "ability": adapter.for_formula("staffStrike"), "resource": "focus", "cost": 1, "reason": "production_authority_required"},
        {"state": initial, "ability": d, "resource": "echoes", "cost": 1, "reason": "unsupported_review_resource"},
        {"state": initial, "ability": d, "resource": "focus", "cost": 0, "reason": "unsupported_review_resource"},
        {"state": initial, "ability": d, "resource": "focus", "cost": 3, "reason": "unsupported_review_resource"},
    ]
    for case in invalids:
        var before: Dictionary = initial.duplicate(true)
        var result: Dictionary = planner.plan(case["state"], case["ability"], case["resource"], case["cost"])
        if bool(result.get("ok", false)) or result.get("reason", "") != case["reason"]:
            _fail("fail-closed condition did not reject: " + str(case["reason"]))
            return
        if initial != before:
            _fail("failure mutated fixture")
            return
    var low: Dictionary = initial.duplicate(true)
    low["party"]["lyra"]["focus"] = 0
    var result_low: Dictionary = planner.plan(low, d, "focus", 1)
    if result_low.get("reason", "") != "insufficient_review_focus:lyra" or low["party"]["ender"]["focus"] != 2:
        _fail("late participant insufficient focus leaked earlier reservation")
        return
    var down: Dictionary = initial.duplicate(true)
    down["party"]["lyra"]["hp"] = 0
    down["party"]["lyra"]["alive"] = false
    var result_down: Dictionary = planner.plan(down, d, "focus", 1)
    if result_down.get("reason", "") != "participant_unavailable" or down["party"]["ender"]["focus"] != 2:
        _fail("incapacitated partner leaked resource")
        return
    var missing: Dictionary = initial.duplicate(true)
    missing["party"].erase("lyra")
    if planner.plan(missing, d, "focus", 1).get("reason", "") != "participant_missing:lyra":
        _fail("missing participant gate")
        return
    var malformed: Dictionary = initial.duplicate(true)
    malformed["party"]["lyra"]["canAct"] = "yes"
    if planner.plan(malformed, d, "focus", 1).get("reason", "") != "invalid_actor_state:lyra":
        _fail("malformed action state accepted")
        return
    var enemy: Dictionary = initial.duplicate(true)
    enemy["phase"] = "enemy"
    if planner.plan(enemy, d, "focus", 1).get("reason", "") != "wrong_phase":
        _fail("enemy phase gate")
        return
    var forged: Dictionary = d.duplicate(true)
    forged["runtimeStatus"] = Ability.FORMULA_STATUS
    if planner.plan(initial, forged, "focus", 1).get("reason", "") != "invalid_ability_definition":
        _fail("altered art runtime status passed schema")
        return
    if planner.plan("no state", d, "focus", 1).get("reason", "") != "invalid_state":
        _fail("non-dictionary state accepted")
        return
    # The same planner handles three-party Arts with no special-case resolver.
    var triple: Dictionary = adapter.for_resonance("horizon_relay")
    var party3: Dictionary = {
        "reviewOnly": true, "phase": "player",
        "party": {
            "ender": {"hp": 12, "maxHp": 12, "focus": 2, "alive": true, "canAct": true},
            "ionia": {"hp": 12, "maxHp": 12, "focus": 2, "alive": true, "canAct": true},
            "aepex": {"hp": 12, "maxHp": 12, "focus": 2, "alive": true, "canAct": true},
        },
    }
    var triple_before: Dictionary = party3.duplicate(true)
    var triple_plan: Dictionary = planner.plan(party3, triple, "focus", 1)
    if not bool(triple_plan.get("ok", false)) or triple_plan["reservations"].size() != 3:
        _fail("shared planner failed to stage triple art")
        return
    for actor_id in ["ender", "ionia", "aepex"]:
        if int(triple_plan["party"][actor_id]["focus"]) != 1 or bool(triple_plan["party"][actor_id]["canAct"]):
            _fail("triple reservation left actor uncommitted: " + actor_id)
            return
    if party3 != triple_before:
        _fail("triple reservation mutated input")
        return
    var triple_low: Dictionary = party3.duplicate(true)
    triple_low["party"]["aepex"]["focus"] = 0
    var triple_low_before: Dictionary = triple_low.duplicate(true)
    if planner.plan(triple_low, triple, "focus", 1).get("reason", "") != "insufficient_review_focus:aepex":
        _fail("third participant resource check missed")
        return
    if triple_low != triple_low_before:
        _fail("late third-person failure partially committed earlier costs")
        return
    var triple_missing: Dictionary = party3.duplicate(true)
    triple_missing["party"].erase("ionia")
    if planner.plan(triple_missing, triple, "focus", 1).get("reason", "") != "participant_missing:ionia":
        _fail("triple membership gate missed")
        return
    print("GODOT_PARTY_RESERVATION_PASS: two/three actors atomic, typed costs, no aliasing or partial deductions")
    quit(0)

func _fail(reason: String) -> void:
    push_error("GODOT_PARTY_RESERVATION_FAIL: " + reason)
    quit(1)
