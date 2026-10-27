extends SceneTree
## Native proof: equipped visuals are strictly a reader of formula authority.
const Adapter = preload("res://scripts/weapon_battle_visual_adapter.gd")
const FormulaEncounter = preload("res://scripts/first_wake_formula_encounter.gd")
const Catalog = preload("res://scripts/weapon_skill_catalog.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var bridge = Adapter.new()
    if not bridge.validate():
        _fail("authority-to-visual adapter invalid")
        return
    var encounter = FormulaEncounter.new()
    var before_player: Dictionary = encounter.player.duplicate(true)
    var before_target: Dictionary = encounter.target.duplicate(true)
    var authorized: Dictionary = bridge.actor_action_pose("ender","full_length_staff","staffStrike",0.74)
    if authorized.is_empty() or str(authorized["action"]) != "attack":
        _fail("Ender staff formula action not mapped to visual cue")
        return
    if str(authorized["mode"]) != Adapter.MODE_AUTHORIZED_INTENT \
        or not bool(authorized["actorPermissionObserved"]):
        _fail("authorized observation mislabeled")
        return
    if bool(authorized["combatCommandIssued"]) or bool(authorized["canExecute"]) \
        or int(authorized["damage"]) != 0:
        _fail("visual observation mutated combat authority")
        return

    for actor in ["lyra","ionia","reson","aepex","unknown"]:
        if not bridge.actor_action_pose(actor,"full_length_staff","staffStrike",0.74).is_empty():
            _fail("unauthorized actor visual granted: "+actor)
            return
    for action in ["staff.measured_footwork","sharedDream","windWard","mycelialLedger",
            "aetherSeal","uncoverTruth","hold","rest","fake"]:
        if not bridge.actor_action_pose("ender","full_length_staff",action,0.5).is_empty():
            _fail("missing animation route accepted or gated action leaked: "+action)
            return
    if not bridge.actor_action_pose("ender","practice_sword","staffStrike",0.74).is_empty():
        _fail("equipping sword implicitly granted Ender an action visual")
        return
    if not bridge.actor_action_pose("ender","full_length_staff","staffStrike",NAN).is_empty():
        _fail("nonfinite timeline position was accepted")
        return
    for id in Catalog.WEAPONS:
        var training: Dictionary = bridge.equipment_sandbox_pose(id,"attack",0.7)
        if training.is_empty() or str(training["actorId"]) != "" \
            or bool(training["actorPermissionObserved"]) or bool(training["canExecute"]):
            _fail("equipment sandbox imputed actor authority: "+id)
            return
    var known: Array[String] = ["staff.measured_footwork"]
    var preview: Array[Dictionary] = bridge.learned_tree_preview("full_length_staff",known)
    if preview.size() != 1 or bool(preview[0]["executionAuthorized"]) \
        or bool(preview[0]["combatCommandIssued"]):
        _fail("mastery preview acquired execution permissions")
        return
    if encounter.player != before_player or encounter.target != before_target or encounter.turns != 0:
        _fail("model inspection mutated combat snapshot")
        return

    var packed = load("res://scenes/weapon_battle_equipment_review.tscn")
    if packed == null:
        _fail("battle equipment scene failed to load")
        return
    var screen = packed.instantiate()
    get_root().add_child(screen)
    if not screen.has_node("ReadOnlyEquippedBattleRig"):
        _fail("actual visual node not present")
        return
    var hp_before: int = int(screen.frozen_encounter.target["hp"])
    var charges_before: int = int(screen.frozen_encounter.player["staffCharges"])
    var initial: Dictionary = screen.review_contract()
    if str(initial["actorId"]) != "ender" or str(initial["weaponId"]) != "full_length_staff" \
        or bool(initial["combatCommandIssued"]):
        _fail("opening actor/weapon authority drift")
        return
    screen._cycle_weapon()
    if screen.current_weapon_id() != "full_length_staff":
        _fail("locked actor-equipped weapon was changed")
        return
    screen._toggle_mode()
    if screen.authorized_intent_mode:
        _fail("unable to enter anonymous training mode")
        return
    screen._cycle_weapon()
    screen._scrub(70.0)
    var sandbox: Dictionary = screen.review_contract()
    if str(sandbox["weaponId"]) != "practice_sword" \
        or str(sandbox["rigWeaponId"]) != "practice_sword" \
        or str(sandbox["actorId"]) != "" or bool(sandbox["canExecute"]):
        _fail("sandbox weapon selection leaked or failed visual swap")
        return
    screen._set_reduced_motion(true)
    if not bool(screen.review_contract()["motionReduced"]):
        _fail("battle review failed reduced-motion switch")
        return
    screen._toggle_mode()
    var returned: Dictionary = screen.review_contract()
    if str(returned["actorId"]) != "ender" \
        or str(returned["rigWeaponId"]) != "full_length_staff":
        _fail("returning from sandbox failed to restore restricted equip")
        return
    if int(screen.frozen_encounter.target["hp"]) != hp_before \
        or int(screen.frozen_encounter.player["staffCharges"]) != charges_before \
        or screen.frozen_encounter.turns != 0 or screen.frozen_encounter.active:
        _fail("visual stage changed combat fixture resources")
        return
    screen.queue_free()
    print("WEAPON_BATTLE_VISUAL_ADAPTER_PASS: permission-bound staff cue, sandbox swaps, no combat mutation")
    quit(0)

func _fail(reason: String) -> void:
    push_error("WEAPON_BATTLE_VISUAL_ADAPTER_FAIL: "+reason)
    quit(1)
