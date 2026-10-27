extends SceneTree
## Deterministic QA matrix for the isolated one-hit ward. Tests arithmetic
## conservation and both attack targets, not production balance approval.
const Battle = preload("res://scripts/tidebound_promise_review.gd")

func _initialize() -> void:
    var checks: int = 0
    for target_id in ["ender", "lyra"]:
        var partner_id: String = "lyra" if target_id == "ender" else "ender"
        for incoming in range(1, Battle.MAX_FIXTURE_STRIKE + 1):
            var protected = Battle.new()
            if not bool(protected.grant_training_access(Battle.ART_ID).get("ok", false)):
                _fail("explicit test grant missing")
                return
            if not bool(protected.activate().get("ok", false)):
                _fail("ward setup failed")
                return
            var p: Dictionary = protected.resolve_enemy_strike(target_id, incoming)
            if not bool(p.get("ok", false)):
                _fail("warded fixture rejected " + target_id + ":" + str(incoming))
                return
            var o: Dictionary = p["outcome"]
            var absorbed: int = mini(Battle.WARD_CAPACITY, incoming)
            var residual: int = incoming - absorbed
            var target_damage: int = (residual + 1) / 2
            var partner_damage: int = residual / 2
            if o["absorbed"] != absorbed or o["targetDamage"] != target_damage or o["partnerDamage"] != partner_damage:
                _fail("ward split coefficient mismatch")
                return
            if int(o["absorbed"]) + int(o["targetDamage"]) + int(o["partnerDamage"]) != incoming:
                _fail("ward damage accounting did not conserve incoming strike")
                return
            var state: Dictionary = protected.snapshot()
            if int(state["party"][target_id]["hp"]) != 12 - target_damage or int(state["party"][partner_id]["hp"]) != 12 - partner_damage:
                _fail("warded HP delta diverged from declared result")
                return
            if int(state["enemyTurns"]) != 1 or state["phase"] != "complete" or int(state["wardCapacity"]) != 0:
                _fail("ward was not consumed on first strike")
                return
            var final_state: Dictionary = state.duplicate(true)
            if bool(protected.resolve_enemy_strike(target_id, incoming).get("ok", false)) or protected.snapshot() != final_state:
                _fail("completed round accepted another strike")
                return
            var baseline = Battle.new()
            if not bool(baseline.pass_without_art().get("ok", false)):
                _fail("baseline failed to advance")
                return
            var raw: Dictionary = baseline.resolve_enemy_strike(target_id, incoming)
            if not bool(raw.get("ok", false)):
                _fail("no-ward strike failed")
                return
            var unprotected: Dictionary = baseline.snapshot()
            if int(unprotected["party"][target_id]["hp"]) != 12 - incoming or int(unprotected["party"][partner_id]["hp"]) != 12:
                _fail("baseline damage split drifted")
                return
            if int(unprotected["party"][target_id]["focus"]) != 2 or int(unprotected["party"][partner_id]["focus"]) != 2:
                _fail("baseline spent art-only Focus")
                return
            checks += 1
    print("GODOT_TIDEBOUND_DAMAGE_SWEEP_PASS: 24 target/strike checks, one-hit conservation and baseline parity")
    quit(0)

func _fail(reason: String) -> void:
    push_error("GODOT_TIDEBOUND_DAMAGE_SWEEP_FAIL: " + reason)
    quit(1)
