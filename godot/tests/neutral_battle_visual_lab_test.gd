extends SceneTree
## True isolated Godot battle lab. Executes ONE real FormulaEncounter
## staffStrike, then tests two read-only visual consumers from its snapshots.
## No legacy Chapter I scene, party roster or quest progression is instantiated.

const LAB_SCENE = preload("res://scenes/neutral_battle_visual_lab.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var lab = LAB_SCENE.instantiate()
    root.add_child(lab)
    await process_frame
    if lab.encounter != null or lab.enemy_view.visible:
        _fail("neutral lab must not create a gameplay turn on scene load")
        return
    if not lab.start_lab():
        _fail("authorized existing Wind Shear data was not admitted into isolated lab")
        return
    lab.enemy_view.set_process(false)
    var before: Dictionary = lab.encounter.snapshot()
    if str(before.get("encounterKind", "")) != "authored_hazard"         or str(before["target"]["id"]) != "windShear"         or int(before["target"]["hp"]) != 14 or int(before.get("turns",-1)) != 0:
        _fail("battle lab did not load the existing enemy contract")
        return
    if not lab.visual_gate.consume(
        "lyra","full_length_staff","staffStrike",true,before,before
    ).is_empty():
        _fail("visual cue admitted unauthorized actor")
        return
    if not lab.visual_gate.consume(
        "ender","practice_sword","staffStrike",true,before,before
    ).is_empty():
        _fail("visual cue admitted unsupported weapon")
        return
    if not lab.visual_gate.consume(
        "ender","full_length_staff","sharedDream",true,before,before
    ).is_empty():
        _fail("visual cue admitted forbidden magic")
        return
    if not lab.visual_gate.consume(
        "ender","full_length_staff","staffStrike",false,before,before
    ).is_empty():
        _fail("rejected action emitted a visual cue")
        return
    if before != lab.encounter.snapshot():
        _fail("the visual preflight changed combat state")
        return

    if not lab.resolve_one_staff_strike():
        _fail("one real staffStrike failed to drive both visual stages")
        return
    var after: Dictionary = lab.encounter.snapshot()
    var receipt: Dictionary = lab.last_visual_receipt
    if after["turns"] != 1 or after["enemyTurns"] != 1         or int(after["player"]["staffCharges"]) != int(before["player"]["staffCharges"]) - 1         or int(after["target"]["hp"]) >= int(before["target"]["hp"])         or int(after["player"]["vit"]) != int(before["player"]["vit"]) - 2:
        _fail("real authorized action did not produce one expected formula turn")
        return
    if lab.accepted_actions != 1 or lab.finished_visual_receipts != 1         or receipt.is_empty() or not bool(receipt.get("visualOnly", false))         or int(receipt.get("turnDelta", -1)) != 1         or int(receipt.get("damageObserved", 0)) <= 0         or bool(receipt.get("storyPlacementApproved", true))         or bool(receipt.get("spriteApproved", true)):
        _fail("read-only dual-stage receipt had wrong authority or cardinality")
        return
    if not lab.staff_view.visible or not lab.enemy_view.visible         or lab.staff_view.visual_contract().is_empty()         or lab.enemy_view.reaction_phase() != "hit"         or lab.enemy_view.queued_gale_seconds <= 0.0:
        _fail("one real strike did not render staff and enemy reaction truthfully")
        return
    # Optical contact uses the real 168-unit staff shaft and its ferrule.
    # These are measurable stage-space positions, NOT a physics hitbox.
    var contact_frame: Dictionary = lab.staff_view.visual_contract()
    var staff_tip: Vector2 = lab.staff_view.position + Vector2(contact_frame["shaftTipA"])
    var expected_surface: Vector2 = lab.enemy_view.position + lab.OPTICAL_CONTACT_LOCAL
    if not lab.optical_contact_verified or lab.optical_contact_distance > 2.0         or staff_tip.distance_to(expected_surface) > 2.0:
        _fail("authored staff tip is not aligned to the review-only optical surface")
        return
    if absf(float(contact_frame["weaponLength"]) - 168.0) > 0.001         or bool(contact_frame.get("combatCommandIssued", true))         or bool(contact_frame.get("canExecute", true)):
        _fail("optical staging shortened the staff or invented combat authority")
        return
    var planted_foot: Vector2 = lab.staff_view.position + Vector2(contact_frame["footA"])
    if planted_foot.y < 424.0 or planted_foot.y > 480.0         or lab.staff_view.position.x < 350.0 or lab.staff_view.position.x > 510.0:
        _fail("optical staging moved Ender off the plausible encounter deck")
        return
    if not lab.visual_gate.consume(
        "ender","full_length_staff","staffStrike",true,before,after
    ).is_empty():
        _fail("replayed resolution accepted twice")
        return
    var forged: Dictionary = after.duplicate(true)
    forged["turns"] = int(after["turns"]) + 1
    if not lab.visual_gate.consume(
        "ender","full_length_staff","staffStrike",true,before,forged
    ).is_empty():
        _fail("forged extra battle turn admitted as a visual event")
        return
    if lab.encounter.snapshot() != after or lab.finished_visual_receipts != 1:
        _fail("duplicate or forged visuals mutated the single real action")
        return

    for _tick in range(6):
        lab.enemy_view._process(0.05)
    if lab.enemy_view.reaction_phase() != "gale":
        _fail("already-resolved Gale was not shown after the post-hit phase")
        return
    for _tick in range(8):
        lab.enemy_view._process(0.05)
    if lab.enemy_view.reaction_phase() != "idle" or lab.encounter.snapshot() != after:
        _fail("visual clocks changed real battle state or retained stale VFX")
        return

    if not lab.close_lab() or lab.enemy_view.visible or lab.staff_view.visible:
        _fail("closing neutral visual rehearsal left combat art visible")
        return
    if not lab.start_lab(true):
        _fail("reduced-motion neutral lab failed to reset")
        return
    lab.enemy_view.set_process(false)
    if not lab.resolve_one_staff_strike():
        _fail("reduced-motion presentation blocked an authorized battle action")
        return
    if lab.enemy_view.reaction_phase() != "still"         or lab.enemy_view.authored_idle_frame() != 0         or not bool(lab.last_visual_receipt["visualPose"]["motionReduced"])         or not lab.staff_view.visible         or not lab.optical_contact_verified:
        _fail("reduced motion did not preserve static weapon and enemy poses")
        return
    if lab.accepted_actions != 1 or lab.finished_visual_receipts != 1         or lab.encounter.turns != 1:
        _fail("reduced-motion presentation repeated combat work")
        return

    lab.queue_free()
    await process_frame
    print("TSTSS_NEUTRAL_BATTLE_VISUAL_LAB_PASS: real single staffStrike -> weapon+enemy, 168-unit ferrule/surface optical alignment, no replay/hitbox/story/save, hit -> resolved Gale, reduced motion")
    quit(0)

func _fail(reason: String) -> void:
    push_error("TSTSS_NEUTRAL_BATTLE_VISUAL_LAB_FAIL: " + reason)
    quit(1)
