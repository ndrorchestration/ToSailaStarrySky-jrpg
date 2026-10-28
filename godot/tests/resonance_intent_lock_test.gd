extends SceneTree
## Enemy intent is a precommitted review-fixture fact, not a post-action roll.
const Battle = preload("res://scripts/tidebound_promise_review.gd")

func _initialize() -> void:
    var b = Battle.new()
    var start: Dictionary = b.snapshot()
    if start["threat"] != {"target": "ender", "damage": 8, "locked": false}:
        _fail("default attack intent not exposed in snapshot")
        return
    for target in ["unknown", "", "reson"]:
        if b.configure_threat(target, 8).get("reason", "") != "invalid_threat":
            _fail("unknown attack target accepted")
            return
        if b.snapshot() != start:
            _fail("malformed target changed threat state")
            return
    for strike in [0, -1, Battle.MAX_FIXTURE_STRIKE + 1]:
        if b.configure_threat("lyra", strike).get("reason", "") != "invalid_threat" or b.snapshot() != start:
            _fail("out-of-bounds intent mutated state")
            return
    if not bool(b.configure_threat("lyra", 7).get("ok", false)):
        _fail("valid Lyra intent refused")
        return
    if b.snapshot()["threat"] != {"target": "lyra", "damage": 7, "locked": false}:
        _fail("configured threat not announced")
        return
    if not bool(b.activate().get("ok", false)):
        _fail("ward action failed after declaration")
        return
    var committed: Dictionary = b.snapshot()
    if committed["threat"] != {"target": "lyra", "damage": 7, "locked": true}:
        _fail("declared threat not locked at action commit")
        return
    if b.configure_threat("ender", 8).get("reason", "") != "threat_locked" or b.snapshot() != committed:
        _fail("post-commit target edit changed immutable intent")
        return
    if b.resolve_enemy_strike("ender", 7).get("reason", "") != "undeclared_strike" or b.snapshot() != committed:
        _fail("unannounced target accepted")
        return
    if b.resolve_enemy_strike("lyra", 8).get("reason", "") != "undeclared_strike" or b.snapshot() != committed:
        _fail("unannounced damage strength accepted")
        return
    var hit: Dictionary = b.resolve_enemy_strike("lyra", 7)
    if not bool(hit.get("ok", false)) or not bool(hit["outcome"].get("declaredIntentHonored", false)):
        _fail("declared enemy strike was rejected")
        return
    var done: Dictionary = b.snapshot()
    if int(done["party"]["lyra"]["hp"]) != 10 or int(done["party"]["ender"]["hp"]) != 11:
        _fail("Lyra-targeted post-ward result incorrect")
        return
    if done["threat"]["locked"] != true or b.configure_threat("ender", 7).get("reason", "") != "threat_locked":
        _fail("post-encounter threat became writable")
        return
    b.reset()
    if b.snapshot() != start:
        _fail("reset did not restore original intent")
        return
    if not bool(b.configure_threat("ender", 11).get("ok", false)):
        _fail("11-damage baseline intent refused")
        return
    if not bool(b.pass_without_art().get("ok", false)):
        _fail("baseline choice not admitted")
        return
    var pending: Dictionary = b.snapshot()
    if not bool(pending["threat"]["locked"]) or b.configure_threat("lyra", 11).get("reason", "") != "threat_locked":
        _fail("baseline did not lock the previously announced intent")
        return
    if b.resolve_enemy_strike("ender", 10).get("reason", "") != "undeclared_strike" or b.snapshot() != pending:
        _fail("baseline accepted altered incoming amount")
        return
    if not bool(b.resolve_enemy_strike("ender", 11).get("ok", false)) or int(b.snapshot()["party"]["ender"]["hp"]) != 1:
        _fail("announced baseline strike did not resolve correctly")
        return
    b.reset()
    if not b.configure_fixture("lyra", {"hp": 0}):
        _fail("cannot create incapacitated target fixture")
        return
    var down: Dictionary = b.snapshot()
    if b.configure_threat("lyra", 8).get("reason", "") != "invalid_target" or b.snapshot() != down:
        _fail("downed actor became a valid new target")
        return
    print("GODOT_RESONANCE_INTENT_LOCK_PASS: both targets, numeric bound, denied retarget/damage edits, reset and live-scene parity")
    quit(0)

func _fail(reason: String) -> void:
    push_error("GODOT_RESONANCE_INTENT_LOCK_FAIL: " + reason)
    quit(1)
