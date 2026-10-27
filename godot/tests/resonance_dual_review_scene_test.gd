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
    world._strike()
    if world.battle.snapshot() != opening:
        _fail("illegal player input changed battle")
        return
    world._cast()
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
    world._strike()
    if int(world.battle.snapshot()["party"]["ender"]["hp"]) != 4:
        _fail("baseline branch inaccessible via buttons")
        return
    var auth = Authority.new()
    if not auth.validate() or auth.can_take_formula_turn("lyra") or auth.can_use_formula_action("ender", "tidebound_promise"):
        _fail("first-wake production authority accidentally broadened")
        return
    world.queue_free()
    await process_frame
    print("GODOT_TIDEBOUND_PROMISE_SCENE_PASS: loaded scene, controls, result HUD, reduced-motion default and no native combat promotion")
    quit(0)

func _fail(reason: String) -> void:
    push_error("GODOT_TIDEBOUND_PROMISE_SCENE_FAIL: " + reason)
    quit(1)
