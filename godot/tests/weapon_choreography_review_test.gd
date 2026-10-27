extends SceneTree
## Exercise real Godot 4.7.2 choreography node lifecycle, not mock frames.
const Timeline = preload("res://scripts/weapon_action_timeline.gd")
const Catalog = preload("res://scripts/weapon_skill_catalog.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var timeline = Timeline.new()
    if not timeline.validate():
        _fail("timeline metadata contract failed")
        return
    if not timeline.sample("unknown","attack",0.1).is_empty():
        _fail("unknown weapon admitted")
        return
    if not timeline.sample("full_length_staff","unknown",0.1).is_empty():
        _fail("unknown action admitted")
        return
    if not timeline.sample("full_length_staff","attack",NAN).is_empty():
        _fail("nonfinite time accepted")
        return

    for id in Catalog.WEAPONS:
        for action in Timeline.ACTIONS:
            var total := timeline.duration(id,action)
            var a := timeline.sample(id,action,total*0.70)
            var b := timeline.sample(id,action,total*0.70)
            if a != b or str(a.get("phase","")) != "impact":
                _fail("phase nondeterminism: "+id+"/"+action)
                return
            if bool(a.get("canExecute",true)) or int(a.get("damage",-1)) != 0:
                _fail("preview acquired combat effects")
                return
            var quiet := timeline.sample(id,action,total*0.70,true)
            if float(quiet["effect"]) != 0.0 or float(quiet["recoil"]) != 0.0 \
                or float(quiet["advance"]) != 0.0 or float(quiet["weaponAngle"]) != 0.0:
                _fail("reduced-motion effect escaped")
                return
            var end := timeline.sample(id,action,total+5.0)
            if float(end["progress"]) != 1.0 or str(end["phase"]) != "aftermath":
                _fail("duration clamp failed")
                return

    var packed = load("res://scenes/weapon_choreography_review.tscn")
    if packed == null:
        _fail("scene failed to import")
        return
    var review = packed.instantiate()
    get_root().add_child(review)
    if not review.has_node("BattlePose"):
        _fail("mannequin rig not instantiated")
        return
    if review.weapon_id() != "full_length_staff" or review.action_id() != "idle":
        _fail("opening preview identity changed")
        return
    review._cycle_weapon()
    if review.weapon_id() != "practice_sword" or str(review.current_contract()["family"]) != "sword":
        _fail("equipment swap failed to update visual rig")
        return
    review._cycle_action()
    review._scrub(70.0)
    var hit := review.get_node("BattlePose").pose
    if str(hit["phase"]) != "impact" or float(hit["effect"]) <= 0.0:
        _fail("attack animation scrub missed contact cue")
        return
    review._set_motion(true)
    var muted := review.get_node("BattlePose").pose
    if not bool(review.current_contract()["motionReduced"]) \
        or float(muted["effect"]) != 0.0 or float(muted["weaponAngle"]) != 0.0:
        _fail("UI motion setting did not suppress visual effects")
        return
    if bool(review.current_contract()["canExecute"]):
        _fail("visual actor given battle authority")
        return
    review._step()
    if bool(review.playing):
        _fail("frame stepping started playback")
        return
    review._play()
    if not bool(review.playing):
        _fail("play did not start")
        return
    review.queue_free()
    print("STARRY_SKY_WEAPON_CHOREOGRAPHY_PASS: 16 action studies, native rig, deterministic phases, no combat grants")
    quit(0)

func _fail(reason: String) -> void:
    push_error("STARRY_SKY_WEAPON_CHOREOGRAPHY_FAIL: "+reason)
    quit(1)
