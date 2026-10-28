extends SceneTree
## Native Godot test of visual-only reach alignment; never models a hit.
const Adapter = preload("res://scripts/weapon_battle_visual_adapter.gd")
const Staff = preload("res://scripts/ender_staff_combat_keyframe_review.gd")
const Camera = preload("res://scripts/weapon_cinematic_contact_review.gd")
const Target = preload("res://scripts/ender_staff_target_alignment_review.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var bridge = Adapter.new()
    var staff = Staff.new()
    var camera = Camera.new()
    var target = Target.new()
    get_root().add_child(target)
    for face in Staff.FACINGS:
        var key: Dictionary = bridge.actor_action_pose(
            "ender","full_length_staff","staffStrike",0.695*1.10)
        var keyed: Dictionary = staff.sample_frame(face,key)
        if not target.bind_contact_anchor(face,keyed):
            _fail("cannot bind visual staff-tip anchor: "+face)
            return
        var anchor: Vector2 = Vector2(target.center)
        var hip: Vector2 = keyed["hip"]
        if anchor.x < -217.0 or anchor.x > 217.0 \
            or anchor.y < -185.0 or anchor.y > 112.0 \
            or (face in ["east","south"] and anchor.x <= hip.x) \
            or (face in ["west","north"] and anchor.x >= hip.x):
            _fail("practice prop outside usable training stage or wrong attack side")
            return
        for pct in [0.10,0.51,0.695,0.90]:
            var pose: Dictionary = bridge.actor_action_pose(
                "ender","full_length_staff","staffStrike",pct*1.10)
            var frame: Dictionary = staff.sample_frame(face,pose)
            var cue: Dictionary = camera.sample(pose,face)
            if not target.apply_visual_contact(frame,cue):
                _fail("visual practice target rejected valid cue: "+face)
                return
            var result: Dictionary = target.visual_contract()
            if str(result["source"]) != Target.SOURCE \
                or str(result["tipId"]) != "shaftTipA" \
                or bool(result["collisionDetected"]) \
                or bool(result["hitAuthorized"]) or bool(result["sfxFired"]) \
                or bool(result["combatCommandIssued"]) or int(result["damage"]) != 0 \
                or absf(float(result["pivotDegrees"])) > 4.01:
                _fail("visual target promoted to gameplay or exceeded reaction bound")
                return
            if absf(pct-0.695) < 0.001:
                if float(result["proximity"]) > 0.001 \
                    or float(result["reaction"]) < 0.95 \
                    or not bool(result["aligned"]):
                    _fail("contact pose ferrule not spatially aligned with practice target")
                    return
            elif float(result["reaction"]) > 0.001:
                _fail("optical reaction outside visual-only contact window")
                return
        var quiet_pose: Dictionary = bridge.actor_action_pose(
            "ender","full_length_staff","staffStrike",0.695*1.10,true)
        var quiet_frame: Dictionary = staff.sample_frame(face,quiet_pose)
        var quiet_cue: Dictionary = camera.sample(quiet_pose,face)
        if not target.apply_visual_contact(quiet_frame,quiet_cue) \
            or float(target.visual_contract()["reaction"]) != 0.0 \
            or float(target.visual_contract()["pivotDegrees"]) != 0.0:
            _fail("reduced motion visual compression remains")
            return
        var forged := keyed.duplicate(true)
        forged["actorId"]="lyra"
        if target.apply_visual_contact(forged,camera.sample(key,face)) \
            or not target.visual_contract().is_empty():
            _fail("forged actor retained a visual reaction")
            return

    var packed = load("res://scenes/weapon_directional_cinematic_review.tscn")
    if packed == null:
        _fail("scene import failed")
        return
    var review = packed.instantiate()
    get_root().add_child(review)
    review._toggle_combat_pose()
    var stage: Node2D = review.get_node("CinematicReviewStage")
    var registered: Node2D = stage.get_node("ContactAlignedTrainingTarget")
    var old_marker: Node2D = stage.get_node("VisualOnlyContactMarker")
    if stage.show_static_target or old_marker.visible or not registered.visible:
        _fail("legacy distant marker duplicated combat training disk")
        return
    for face in Staff.FACINGS:
        review.facing_index = Staff.FACINGS.find(face)
        review._scrub(69.5)
        var contract: Dictionary = review.active_contract()
        if float(contract["targetReaction"]) < 0.95 \
            or float(contract["targetProximity"]) > 0.001 \
            or bool(contract["targetHitAuthorized"]) \
            or bool(contract["combatCommandIssued"]) or bool(contract["canExecute"]):
            _fail("scene contact registration or authority failed for "+face)
            return
    review._set_motion(true)
    if float(review.active_contract()["targetReaction"]) != 0.0:
        _fail("live UI reduced-motion setting did not suppress target reaction")
        return
    review._toggle_combat_pose()
    if registered.visible or not stage.show_static_target or not old_marker.visible:
        _fail("legacy comparison view did not restore own training target")
        return
    review.queue_free()
    target.queue_free()
    print("ENDER_STAFF_TARGET_ALIGNMENT_PASS: four reachable directions, optical-only cue, bounded reaction, reduced motion, no combat dispatch")
    quit(0)

func _fail(reason: String) -> void:
    push_error("ENDER_STAFF_TARGET_ALIGNMENT_FAIL: "+reason)
    quit(1)
