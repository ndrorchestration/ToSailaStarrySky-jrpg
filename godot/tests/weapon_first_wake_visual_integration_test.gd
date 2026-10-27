extends SceneTree
## Full real-scene check of read-only equipment drawing in Chapter I battle.
const Scene = preload("res://scenes/first_wake_chapter1_review.tscn")
const Encounter = preload("res://scripts/first_wake_formula_encounter.gd")
const Projection = preload("res://scripts/weapon_battle_visual_projection.gd")

class FixedRng:
    extends RefCounted
    func next() -> float:
        return 0.5

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var bridge = Projection.new()
    if not bridge.validate():
        _fail("staff visual bridge did not validate")
        return
    for actor in ["lyra", "ionia", "reson", "aepex", "unknown"]:
        if not bridge.initial(actor,Projection.ENDER_STAFF_ID).is_empty():
            _fail("non-authorized actor acquired staff art: "+actor)
            return
    if not bridge.initial("ender","practice_sword").is_empty():
        _fail("proposed sword incorrectly equipped in current Crossing battle")
        return
    if not bridge.accepted_action("ender",Projection.ENDER_STAFF_ID,
        "staff.centerline_drive",0.3).is_empty():
        _fail("proposed skill gained formula visual authorization")
        return

    var world = Scene.instantiate()
    root.add_child(world)
    await process_frame
    var visual = world.weapon_visual
    if visual == null or visual.name != "EnderBattleEquippedStaffReview":
        _fail("battle screen missing equipped staff visual")
        return
    if visual.visible or not visual.visual_contract().is_empty():
        _fail("weapon panel appeared in exploration before encounter")
        return

    var rng = FixedRng.new()
    world.formula_encounter = Encounter.new(rng.next)
    var unchanged: Dictionary = world.chapter.snapshot()
    if not world.start_formula_review():
        _fail("formula review could not start")
        return
    var initial: Dictionary = visual.visual_contract()
    if not visual.visible or str(initial.get("weaponId","")) != Projection.ENDER_STAFF_ID \
        or str(initial.get("action","")) != "idle":
        _fail("initial battle slot was not Ender's staff")
        return
    if not visual.has_node("EquippedWeaponVisual") \
        or str(visual.get_node("EquippedWeaponVisual").visual_contract().get("family","")) != "staff":
        _fail("real drawn equipment node did not identify staff family")
        return
    if world.take_formula_review_action("staff.centerline_drive") \
        or world.take_formula_review_action("sharedDream"):
        _fail("unauthorized skill passed scene authority gate")
        return
    if visual.visual_contract() != initial:
        _fail("rejected action mutated weapon animation")
        return
    if not world.take_formula_review_action("uncoverTruth"):
        _fail("existing authorized analysis stopped working")
        return
    if visual.visual_contract() != initial:
        _fail("non-physical analysis invented a physical weapon action")
        return
    if not world.take_formula_review_action("staffStrike"):
        _fail("existing staff strike failed")
        return
    if str(visual.visual_contract().get("action","")) != "attack":
        _fail("accepted staff strike did not update equipped visual")
        return
    world._process(0.77)
    if str(visual.visual_contract().get("phase","")) != "impact":
        _fail("staff impact phase not projected into actual battle")
        return
    if bool(visual.visual_contract().get("canAuthorizeActions",true)):
        _fail("visual projection acquired combat turn authority")
        return
    if world.chapter.snapshot() != unchanged:
        _fail("visual integration modified Chapter I progression")
        return

    world.set_weapon_visual_reduced_motion(true)
    if not bool(visual.visual_contract().get("motionReduced",false)):
        _fail("motion preference not reflected in visible battle preview")
        return
    if absf(visual.equipment.rotation_degrees) > 0.001:
        _fail("weapon rotation persisted in reduced-motion presentation")
        return

    # Rejected zero-charge attempts cannot restart attack choreography.
    world.formula_encounter.player["staffCharges"] = 0
    var progress_before: float = world.weapon_visual_elapsed
    if world.take_formula_review_action("staffStrike"):
        _fail("depleted staff was allowed to strike")
        return
    if world.weapon_visual_elapsed != progress_before:
        _fail("rejected no-charge strike restarted visual timeline")
        return
    world._process(4.0)
    if str(visual.visual_contract().get("action","")) != "idle":
        _fail("strike animation failed to return to safe idle")
        return

    var snapshot: Dictionary = world.export_save_snapshot()
    if snapshot.has("weapon_visual") or snapshot.has("combat"):
        _fail("read-only weapon preview leaked into save")
        return
    if not world.restore_save_snapshot(snapshot):
        _fail("restore after visual preview failed")
        return
    if world.formula_encounter.active or visual.visible \
        or not visual.visual_contract().is_empty():
        _fail("transient battle weapon art remained visible on restored save")
        return
    if world.chapter.snapshot() != unchanged:
        _fail("restore changed persistent story state")
        return

    if not world.start_formula_review() or not visual.visible:
        _fail("visual failed to reappear on a new formula encounter")
        return
    if not world.close_formula_review() or visual.visible:
        _fail("equipped panel persisted outside a closed combat scene")
        return

    for signal_id in ["harmonic_buoy","below_frequency","sky_lane_warning"]:
        if not world.complete_signal_contact(signal_id):
            _fail("could not advance to authorized Crossing hazard")
            return
    if world.chapter.stage_key() != "crossing":
        _fail("native Crossing not reached")
        return
    var before_hazard: Dictionary = world.chapter.snapshot()
    if not world.start_hazard_encounter("wind_shear"):
        _fail("authored hazard scene failed to open")
        return
    if not world.take_formula_review_action("staffStrike"):
        _fail("current-story hazard rejected authorized staff strike")
        return
    if str(visual.visual_contract().get("action","")) != "attack":
        _fail("authored encounter did not show equipped weapon motion")
        return
    if not world.close_formula_review():
        _fail("uncleared hazard could not be canceled")
        return
    if visual.visible or world.chapter.snapshot() != before_hazard:
        _fail("canceling encounter leaked visual/progression state")
        return

    world.queue_free()
    await process_frame
    print("STARRY_SKY_FIRST_WAKE_WEAPON_VISUAL_PASS: actual battle overlay, accepted strike, denied skills, reduced motion, no-charge/restore/cancel isolation")
    quit(0)

func _fail(reason: String) -> void:
    push_error("STARRY_SKY_FIRST_WAKE_WEAPON_VISUAL_FAIL: "+reason)
    quit(1)
