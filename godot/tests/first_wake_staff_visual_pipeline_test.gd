extends SceneTree
## Integration probe: invokes the REAL native Chapter I scene's authoritative
## action entry point, then derives a read-only visual receipt from snapshots.
## It never patches or subclasses that scene and never changes a save.
const Observer = preload("res://scripts/first_wake_staff_visual_pipeline_observer.gd")
const Staff = preload("res://scripts/ender_staff_combat_keyframe_review.gd")
const Target = preload("res://scripts/ender_staff_target_alignment_review.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/first_wake_chapter1_review.tscn")
    if packed == null:
        _fail("actual First Wake migration review scene missing")
        return
    var world = packed.instantiate()
    get_root().add_child(world)
    await process_frame
    var observer = Observer.new()
    if not observer.validate() or world.chapter.stage_key() != "signal":
        _fail("native Chapter I scene/observer authority unavailable")
        return

    var chapter_before: Dictionary = world.chapter.snapshot()
    if not world.start_formula_review():
        _fail("real First Wake scene could not start noncanonical formula review")
        return
    var before: Dictionary = world.formula_encounter.snapshot()
    if world.take_formula_review_action("sharedDream"):
        _fail("blocked action was executed by actual First Wake scene")
        return
    var after_reject: Dictionary = world.formula_encounter.snapshot()
    if before != after_reject:
        _fail("rejected action changed formula encounter state")
        return
    if not observer.observe_accepted_transition(
        "ender","full_length_staff","sharedDream",true,before,after_reject,
        chapter_before,world.chapter.snapshot()).is_empty():
        _fail("unauthorized action emitted a visual receipt")
        return

    # This call, not the observer, is the one authentic authorized combat turn.
    if not world.take_formula_review_action("staffStrike"):
        _fail("real First Wake staffStrike rejected")
        return
    var after: Dictionary = world.formula_encounter.snapshot()
    var snapshot_before_probe: Dictionary = after.duplicate(true)
    var good: Dictionary = observer.observe_accepted_transition(
        "ender","full_length_staff","staffStrike",true,before,after,
        chapter_before,world.chapter.snapshot(),"east")
    if good.is_empty() or str(good["source"]) != Observer.SOURCE \
        or str(good["encounterKind"]) != "formula_review" \
        or not bool(good["visualPlaybackReady"]) \
        or bool(good["realHitVerified"]) \
        or bool(good["combatCommandIssuedByObserver"]) \
        or bool(good["savedStateWritten"]) \
        or bool(good["spriteAssetApproved"]):
        _fail("real staff action did not bind the guarded visual study")
        return
    if int(good["turnDeltaObserved"]) != 1 \
        or int(good["formulaDamageObserved"]) != \
            int(before["target"]["hp"])-int(after["target"]["hp"]) \
        or int(good["staffChargesBefore"]) != int(good["staffChargesAfter"])+1:
        _fail("observed host combat accounting inconsistent with visual receipt")
        return
    if int(world.formula_encounter.turns) != 1 or world.chapter.snapshot()!=chapter_before:
        _fail("formula sample changed Chapter I progression or repeated the turn")
        return

    var rig = Staff.new()
    get_root().add_child(rig)
    for face in Staff.FACINGS:
        var receipt: Dictionary = observer.observe_accepted_transition(
            "ender","full_length_staff","staffStrike",true,before,after,
            chapter_before,world.chapter.snapshot(),face)
        if receipt.is_empty() or not rig.set_facing(face) \
            or not rig.apply_battle_pose(receipt["visualPose"]):
            _fail("face-dependent combat pose failed on real scene receipt: "+face)
            return
        var frame: Dictionary = rig.visual_contract()
        var witness: Dictionary = receipt["contactStudy"]
        if Vector2(frame["shaftTipA"]).distance_to(Vector2(witness["targetAnchor"])) > 0.001 \
            or not bool(witness["aligned"]) or float(witness["reaction"]) < 0.95 \
            or bool(witness["collisionDetected"]) or bool(witness["hitAuthorized"]):
            _fail("staff visual contact failed or claimed a physical hit: "+face)
            return
    var reduced: Dictionary = observer.observe_accepted_transition(
        "ender","full_length_staff","staffStrike",true,before,after,
        chapter_before,world.chapter.snapshot(),"east",true)
    if reduced.is_empty() or float(reduced["contactStudy"]["reaction"]) != 0.0 \
        or float(reduced["cameraStudy"]["zoom"]) != 1.0 \
        or float(reduced["authoredFrame"]["trailStrength"]) != 0.0:
        _fail("reduced-motion receipt still animates visual contact")
        return
    if world.formula_encounter.snapshot() != snapshot_before_probe \
        or world.chapter.snapshot() != chapter_before:
        _fail("observer, pose sampler or training target mutated actual First Wake state")
        return

    for actor in ["lyra","ionia","reson","aepex","unknown"]:
        if not observer.observe_accepted_transition(
            actor,"full_length_staff","staffStrike",true,before,after,
            chapter_before,chapter_before).is_empty():
            _fail("unauthorized actor obtained a visual receipt: "+actor)
            return
    if not observer.observe_accepted_transition(
        "ender","practice_sword","staffStrike",true,before,after,
        chapter_before,chapter_before).is_empty():
        _fail("wrong equipment received a staff action presentation")
        return
    if not observer.observe_accepted_transition(
        "ender","full_length_staff","staffStrike",false,before,after,
        chapter_before,chapter_before).is_empty():
        _fail("rejected gameplay action emitted a visual cue")
        return
    var fake_after: Dictionary = after.duplicate(true)
    fake_after["turns"] = int(fake_after["turns"])+1
    if not observer.observe_accepted_transition(
        "ender","full_length_staff","staffStrike",true,before,fake_after,
        chapter_before,chapter_before).is_empty():
        _fail("invented extra turn admitted to pipeline")
        return
    var forged_chapter: Dictionary = chapter_before.duplicate(true)
    forged_chapter["stage"] = "done"
    if not observer.observe_accepted_transition(
        "ender","full_length_staff","staffStrike",true,before,after,
        chapter_before,forged_chapter).is_empty():
        _fail("chapter progression drift was ignored")
        return

    if not world.close_formula_review() or world.chapter.snapshot() != chapter_before:
        _fail("noncanonical formula review affected the Chapter I path")
        return
    for signal_id in ["harmonic_buoy","below_frequency","sky_lane_warning"]:
        if not world.complete_signal_contact(signal_id):
            _fail("real scene refused signal progression needed for Wind Shear")
            return
    if world.chapter.stage_key() != "crossing" \
        or not world.start_hazard_encounter("wind_shear"):
        _fail("current Chapter I Wind Shear encounter unavailable")
        return
    var crossing_before: Dictionary = world.chapter.snapshot()
    var hazard_before: Dictionary = world.formula_encounter.snapshot()
    if not world.take_formula_review_action("staffStrike"):
        _fail("real authorized Wind Shear staff action refused")
        return
    var hazard_after: Dictionary = world.formula_encounter.snapshot()
    var event: Dictionary = observer.observe_accepted_transition(
        "ender","full_length_staff","staffStrike",true,
        hazard_before,hazard_after,crossing_before,world.chapter.snapshot())
    if event.is_empty() or str(event["encounterKind"]) != "authored_hazard" \
        or str(event["targetId"]) != "windShear" \
        or int(event["turnDeltaObserved"]) != 1:
        _fail("actual Chapter I Wind Shear state failed visual receipt contract")
        return
    if world.chapter.snapshot() != crossing_before \
        or world.formula_encounter.snapshot() != hazard_after:
        _fail("combat observer moved Crossing or changed genuine encounter accounting")
        return
    rig.queue_free()
    world.queue_free()
    await process_frame
    print("FIRST_WAKE_STAFF_VISUAL_PIPELINE_PASS: authentic formula + Wind Shear turns observed, four visual directions, zero extra turns/saves/hits")
    quit(0)

func _fail(reason: String) -> void:
    push_error("FIRST_WAKE_STAFF_VISUAL_PIPELINE_FAIL: "+reason)
    quit(1)
