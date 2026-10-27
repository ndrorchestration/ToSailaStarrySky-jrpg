extends SceneTree
## Proves authored 4-direction, 5-beat strike geometry and non-execution.
const Staff = preload("res://scripts/ender_staff_combat_keyframe_review.gd")
const Adapter = preload("res://scripts/weapon_battle_visual_adapter.gd")
const EXPECTED_PHASES: Array[String] = [
    "anticipation","formation","release","impact","aftermath"
]
const SAMPLE_PCTS: Array[float] = [0.10,0.30,0.51,0.695,0.90]

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var bridge = Adapter.new()
    var rig = Staff.new()
    get_root().add_child(rig)
    for facing in Staff.FACINGS:
        var seen: Dictionary = {}
        if not rig.set_facing(facing):
            _fail("legitimate direction rejected: "+facing)
            return
        for beat in range(SAMPLE_PCTS.size()):
            var pct: float = SAMPLE_PCTS[beat]
            var pose: Dictionary = bridge.actor_action_pose(
                "ender","full_length_staff","staffStrike",pct*1.10)
            if str(pose.get("phase","")) != EXPECTED_PHASES[beat] \
                or not rig.apply_battle_pose(pose):
                _fail("phase or combat rig rejected at "+facing+"/"+str(beat))
                return
            var output: Dictionary = rig.visual_contract()
            if str(output["source"]) != Staff.ART_AUTHORITY \
                or not bool(output["handContact"]) \
                or not bool(output["footGrounding"]) \
                or bool(output["spriteAssetApproved"]) \
                or bool(output["canExecute"]) \
                or bool(output["combatCommandIssued"]) \
                or int(output["damage"]) != 0:
                _fail("combat/art authority boundary leaked at "+facing)
                return
            if not bool(output["oneStaffOnly"]) or not bool(output["animationAuthoredForCombatReview"]):
                _fail("staff asset count or combat pose source invalid")
                return
            if absf(float(output["weaponLength"])-168.0) > 0.01:
                _fail("staff full-length visual invariant changed")
                return
            if Vector2(output["leftHand"]).distance_to(Vector2(output["leftGripPoint"])) > 0.001 \
                or Vector2(output["rightHand"]).distance_to(Vector2(output["rightGripPoint"])) > 0.001 \
                or float(output["gripError"]) > 0.001:
                _fail("hand-to-staff contact lost: "+facing+"/"+str(beat))
                return
            var grip_center: Vector2 = output["shaftMidpoint"]
            if grip_center.distance_to(Vector2(output["leftHand"])) > Staff.WRAP_HALF \
                or grip_center.distance_to(Vector2(output["rightHand"])) > Staff.WRAP_HALF:
                _fail("hands leave midpoint wrap")
                return
            if absf(Vector2(output["footA"]).y-112.0)>0.001 \
                or absf(Vector2(output["footB"]).y-112.0)>0.001:
                _fail("boot floor grounding drifted")
                return
            var footprint: String = "%0.1f/%0.1f/%0.1f" % [
                float(output["angle"]),Vector2(output["shaftMidpoint"]).x,
                Vector2(output["hip"]).x
            ]
            if seen.has(footprint):
                _fail("successive physical beats have identical equipment/body pose")
                return
            seen[footprint]=true
        if seen.size()!=5:
            _fail("fewer than five authored physical pose beats")
            return
        var reduced: Dictionary = bridge.actor_action_pose(
            "ender","full_length_staff","staffStrike",0.695*1.10,true)
        var quiet: Dictionary = rig.sample_frame(facing,reduced)
        var baseline: Dictionary = bridge.actor_action_pose(
            "ender","full_length_staff","staffStrike",0.0,true)
        var base_frame: Dictionary = rig.sample_frame(facing,baseline)
        if float(quiet["angle"]) != float(base_frame["angle"]) \
            or Vector2(quiet["shaftMidpoint"]) != Vector2(base_frame["shaftMidpoint"]) \
            or Vector2(quiet["hip"]) != Vector2(base_frame["hip"]):
            _fail("reduced motion failed to freeze combat pose")
            return
    if rig.set_facing("invalid"):
        _fail("unknown view accepted")
        return
    var valid: Dictionary = bridge.actor_action_pose("ender","full_length_staff","staffStrike",0.70)
    for change in [
        {"actorId":"lyra"},
        {"weaponId":"practice_sword"},
        {"formulaActionId":"sharedDream"},
        {"combatCommandIssued":true},
        {"canExecute":true}
    ]:
        var forged: Dictionary = valid.duplicate(true)
        forged.merge(change,true)
        if rig.apply_battle_pose(forged):
            _fail("forged actor/weapon/skill/execution state accepted")
            return

    var packed = load("res://scenes/weapon_directional_cinematic_review.tscn")
    if packed == null:
        _fail("new battle-pose review scene not found")
        return
    var screen = packed.instantiate()
    get_root().add_child(screen)
    screen._toggle_combat_pose()
    var state: Dictionary = screen.active_contract()
    if not bool(state["authoredCombatPoseShown"]) \
        or bool(state["candidateShown"]) \
        or bool(state["duplicateStaffOverlay"]) \
        or str(state["combatArtAuthority"]) != Staff.ART_AUTHORITY \
        or float(state["combatGripError"]) > 0.001 \
        or not bool(state["combatBootsGrounded"]):
        _fail("combat pose scene displayed duplicate staff or unbound art")
        return
    var stage: Node2D = screen.get_node("CinematicReviewStage")
    if stage.show_mannequin or stage.weapon.visible or stage.show_review_effects:
        _fail("old mannequin actor/weapon/effect overlays remained visible")
        return
    var child: Node2D = stage.get_node("AuthoredStaffCombatPoseLayer")
    if not child.visible:
        _fail("combat layer is hidden")
        return
    for f in Staff.FACINGS:
        var slot: int = Staff.FACINGS.find(f)
        screen.facing_index = slot
        screen._scrub(69.5)
        if str(child.visual_contract()["facing"]) != f:
            _fail("selected view did not update authored combat geometry")
            return
    screen._set_motion(true)
    if not bool(child.visual_contract()["motionReduced"]):
        _fail("scene motion preference not propagated to combat rig")
        return
    screen._toggle_combat_pose()
    if child.visible or not screen.get_node("CinematicReviewStage/DirectionalCandidateLayer").visible:
        _fail("original walking candidate A/B could not be restored")
        return
    screen.queue_free()
    rig.queue_free()
    print("ENDER_STAFF_COMBAT_KEYFRAMES_PASS: 4 directions x 5 physical beats, two grips, planted feet, no execution")
    quit(0)

func _fail(reason: String) -> void:
    push_error("ENDER_STAFF_COMBAT_KEYFRAMES_FAIL: "+reason)
    quit(1)
