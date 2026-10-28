extends SceneTree
## Deterministic dual-art fixture: turn reservation, focus cost, ward and rollback.
## No production action authority or actual save/Chapter I state involved.
const Battle = preload("res://scripts/tidebound_promise_review.gd")

func _initialize() -> void:
    var b = Battle.new()
    var before: Dictionary = b.snapshot()
    if not bool(b.admission().get("ok", false)):
        _fail("initial sandbox fixture did not admit")
        return
    if bool(b.resolve_enemy_strike("ender", 8).get("ok", false)) or b.snapshot() != before:
        _fail("attack accepted outside enemy phase or mutated state")
        return
    if bool(b.resolve_enemy_strike("unknown", 8).get("ok", false)) or b.snapshot() != before:
        _fail("illegal target accepted")
        return
    if not bool(b.activate().get("ok", false)):
        _fail("dual art did not activate in isolated fixture")
        return
    var armed: Dictionary = b.snapshot()
    if armed["phase"] != "enemy" or int(armed["wardCapacity"]) != 4 or int(armed["turns"]) != 1:
        _fail("ward and two-action reservation invalid")
        return
    for actor_id in ["ender", "lyra"]:
        var actor: Dictionary = armed["party"][actor_id]
        if int(actor["focus"]) != 1 or bool(actor["canAct"]):
            _fail("both combatants did not reserve focus and actions: " + actor_id)
            return
    if bool(b.activate().get("ok", false)) or b.snapshot() != armed:
        _fail("second activation spent resources or advanced turn")
        return
    if bool(b.resolve_enemy_strike("ender", -1).get("ok", false)) or b.snapshot() != armed:
        _fail("invalid negative strike mutated state")
        return
    if bool(b.resolve_enemy_strike("unknown", 8).get("ok", false)) or b.snapshot() != armed:
        _fail("unknown strike target mutated state")
        return
    var result: Dictionary = b.resolve_enemy_strike("ender", 8)
    if not bool(result.get("ok", false)):
        _fail("enemy retaliation could not resolve")
        return
    var outcome: Dictionary = result["outcome"]
    if int(outcome["incoming"]) != 8 or int(outcome["absorbed"]) != 4:
        _fail("bounded ward interception invalid")
        return
    if int(outcome["targetDamage"]) != 2 or int(outcome["partnerDamage"]) != 2:
        _fail("residual damage was not shared")
        return
    var protected: Dictionary = b.snapshot()
    if int(protected["party"]["ender"]["hp"]) != 10 or int(protected["party"]["lyra"]["hp"]) != 10:
        _fail("post-strike HP invalid")
        return
    if protected["phase"] != "complete" or int(protected["wardCapacity"]) != 0 or int(protected["enemyTurns"]) != 1:
        _fail("ward duration/turn count invalid")
        return
    if bool(b.resolve_enemy_strike("ender", 8).get("ok", false)) or b.snapshot() != protected:
        _fail("second enemy retaliation accepted")
        return
    b.reset()
    if not bool(b.pass_without_art().get("ok", false)):
        _fail("no-ward baseline cannot advance")
        return
    if not bool(b.resolve_enemy_strike("ender", 8).get("ok", false)):
        _fail("no-ward baseline attack rejected")
        return
    var baseline := b.snapshot()
    if int(baseline["party"]["ender"]["hp"]) != 4 or int(baseline["party"]["lyra"]["hp"]) != 12:
        _fail("no-ward baseline incorrectly mitigated damage")
        return
    if int(baseline["party"]["ender"]["focus"]) != 2 or int(baseline["party"]["lyra"]["focus"]) != 2:
        _fail("baseline incorrectly consumed resource")
        return
    b.reset()
    if not b.configure_fixture("lyra", {"focus": 0}):
        _fail("could not create low-focus fixture")
        return
    var low_focus: Dictionary = b.snapshot()
    if str(b.activate().get("reason", "")) != "insufficient_review_focus:lyra" or b.snapshot() != low_focus:
        _fail("insufficient focus failed to rollback")
        return
    b.reset()
    if not b.configure_fixture("lyra", {"canAct": false}):
        _fail("could not create unavailable fixture")
        return
    var unavailable: Dictionary = b.snapshot()
    if str(b.activate().get("reason", "")) != "participant_unavailable" or b.snapshot() != unavailable:
        _fail("unavailable actor failed to rollback")
        return
    b.reset()
    if not b.configure_fixture("lyra", {"hp": 0}):
        _fail("could not create incapacitated fixture")
        return
    if bool(b.admission().get("ok", false)):
        _fail("incapacitated actor became eligible")
        return
    b.reset()
    var clean: Dictionary = b.snapshot()
    if b.configure_fixture("lyra", {"focus": -1}) or b.configure_fixture("lyra", {"hp": 15}) or b.configure_fixture("x", {"focus": 1}):
        _fail("malformed fixture update accepted")
        return
    if b.configure_fixture("lyra", {"unknown": 0}) or b.snapshot() != clean:
        _fail("invalid fixture update mutated state")
        return
    print("GODOT_TIDEBOUND_PROMISE_CONTRACT_PASS: reservation, both costs, one-hit ward, shared residual, negative cases, rollback")
    quit(0)

func _fail(reason: String) -> void:
    push_error("GODOT_TIDEBOUND_PROMISE_CONTRACT_FAIL: " + reason)
    quit(1)
