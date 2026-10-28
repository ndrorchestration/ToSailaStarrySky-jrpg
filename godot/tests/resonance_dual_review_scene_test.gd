extends SceneTree
## Load actual opt-in Godot battle scene and exercise callable player controls.
const ReviewScene = preload("res://scenes/resonance_dual_review.tscn")
const Authority = preload("res://scripts/first_wake_party_combat_authority.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world = ReviewScene.instantiate()
    root.add_child(world)
    await process_frame
    if world == null or world.heading == null or world.battle_status == null or world.notice == null:
        _fail("native scene or accessible HUD missing")
        return
    if not world.reduced_motion or not world.battle.REVIEW_ONLY:
        _fail("opt-in scene defaults or review authority invalid")
        return
    var opening: Dictionary = world.battle.snapshot()
    if world.threat_status == null or not world.threat_status.text.contains("ENDER"):
        _fail("announced strike target missing from accessible HUD")
        return
    world._set_threat("lyra")
    if world.battle.snapshot()["threat"]["target"] != "lyra" or not world.threat_status.text.contains("Lyra"):
        _fail("new interactive target was not announced")
        return
    world._set_threat("ender")
    if world.battle.snapshot() != opening:
        _fail("retargeting to original state was not reversible")
        return
    world._strike()
    if world.battle.snapshot() != opening:
        _fail("illegal player input changed battle")
        return
    # Explicitly inspect the optional three-beat cut-in, without a timed input gate.
    world._toggle_motion()
    if world.reduced_motion:
        _fail("motion toggle could not enable optional three-beat cut-in")
        return
    world._cast()
    if world.visual_step != 0:
        _fail("Spirit beat not entered on successful art")
        return
    for _frame in range(19):
        world._process(0.06)
    if world.visual_step != 3:
        _fail("Spirit/Water/Confluence cut-in did not settle")
        return
    world._toggle_motion()
    if not world.reduced_motion or world.visual_step != 3:
        _fail("reduced-motion bypass did not restore static ward")
        return
    var after_cast: Dictionary = world.battle.snapshot()
    if after_cast["phase"] != "enemy" or int(after_cast["wardCapacity"]) != 4:
        _fail("cast button not connected to ward controller")
        return
    world._strike()
    var resolved: Dictionary = world.battle.snapshot()
    if resolved["phase"] != "complete" or resolved["lastOutcome"]["absorbed"] != 4:
        _fail("enemy strike button did not resolve protected damage")
        return
    if not world.detail.text.contains("RESULT"):
        _fail("result is not communicated in the text HUD")
        return
    world._restart()
    if world.battle.snapshot() != opening:
        _fail("restart did not restore fixture")
        return
    world._toggle_motion()
    if world.reduced_motion:
        _fail("reversible motion toggle missing")
        return
    world._toggle_motion()
    if not world.reduced_motion:
        _fail("reduced-motion restoration missing")
        return
    world._baseline()
    var locked_baseline: Dictionary = world.battle.snapshot()
    world._set_threat("lyra")
    if world.battle.snapshot() != locked_baseline:
        _fail("UI accepted changing announced enemy target after baseline choice")
        return
    world._strike()
    if int(world.battle.snapshot()["party"]["ender"]["hp"]) != 4:
        _fail("baseline branch inaccessible via buttons")
        return
    world._restart()
    world._set_threat("lyra")
    if not world.battle.configure_threat("lyra", 7).get("ok", false):
        _fail("review strike strength could not be configured")
        return
    world._refresh_hud()
    world._cast()
    var locked: Dictionary = world.battle.snapshot()
    world._set_threat("ender")
    if world.battle.snapshot() != locked or not world.threat_status.text.contains("LOCKED"):
        _fail("UI retargeted after shared Art action commitment")
        return
    world._strike()
    var lyra_hit: Dictionary = world.battle.snapshot()
    if int(lyra_hit["party"]["lyra"]["hp"]) != 10 or int(lyra_hit["party"]["ender"]["hp"]) != 11:
        _fail("Lyra-targeted enemy intent resolved incorrectly")
        return
    if not world.detail.text.contains("Ender took 1") or not world.detail.text.contains("Lyra took 2"):
        _fail("result HUD swapped target and partner damage")
        return
    var auth = Authority.new()
    if not auth.validate() or auth.can_take_formula_turn("lyra") or auth.can_use_formula_action("ender", "tidebound_promise"):
        _fail("first-wake production authority accidentally broadened")
        return
    world.queue_free()
    await process_frame
    print("GODOT_TIDEBOUND_PROMISE_SCENE_PASS: scene controls, declared target locking, dual-target results, reduced-motion and no native combat promotion")
    quit(0)

func _fail(reason: String) -> void:
    push_error("GODOT_TIDEBOUND_PROMISE_SCENE_FAIL: " + reason)
    quit(1)
