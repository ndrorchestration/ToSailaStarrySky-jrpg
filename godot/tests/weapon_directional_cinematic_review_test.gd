extends SceneTree
## Native Godot 4.7.2 read-only art provenance, authority and stage-framing gate.
const Layer = preload("res://scripts/weapon_directional_character_review.gd")
const Framing = preload("res://scripts/weapon_cinematic_contact_review.gd")
const Adapter = preload("res://scripts/weapon_battle_visual_adapter.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var adapter = Adapter.new()
    var timing = Framing.new()
    if not adapter.validate() or not timing.validate():
        _fail("cinematography or authority contracts invalid")
        return
    var valid := adapter.actor_action_pose(
        "ender","full_length_staff","staffStrike",0.7645)
    if valid.is_empty():
        _fail("authorized visual no longer available")
        return
    for face in Layer.FACINGS:
        var shot := timing.sample(valid,face)
        if shot.is_empty() or bool(shot["hitAuthorized"]) \
            or bool(shot["combatCommandIssued"]) or int(shot["damage"]) != 0:
            _fail("camera framed executable hit: "+face)
            return
    for wrong in [
        {"actorId":"lyra"},
        {"actorId":"ender","weaponId":"practice_sword"},
        {"actorId":"ender","weaponId":"full_length_staff","formulaActionId":"hold"}
    ]:
        var fake := valid.duplicate(true)
        fake.merge(wrong,true)
        if not timing.sample(fake,"east").is_empty():
            _fail("invalid actor/equipment/action mapped to combat shot")
            return

    var packed = load("res://scenes/weapon_directional_cinematic_review.tscn")
    if packed == null:
        _fail("directional cinematic scene not imported")
        return
    var review = packed.instantiate()
    get_root().add_child(review)
    if not review.has_node("CinematicReviewStage/DirectionalCandidateLayer") \
        or not review.has_node("CinematicReviewStage/VisualOnlyContactMarker"):
        _fail("live directional layers missing")
        return
    var rig: Node2D = review.get_node("CinematicReviewStage")
    var layer: Node2D = rig.get_node("DirectionalCandidateLayer")
    if rig.weapon.visible or rig.show_mannequin:
        _fail("Ender sprite received duplicate geometric staff or mannequin body")
        return
    if int(review.active_contract()["spriteFrame"]) != 0:
        _fail("walking pose repurposed as unauthorized combat art")
        return

    var textures := {}
    for face in Layer.FACINGS:
        var accepted := layer.set_facing(face)
        if not accepted:
            _fail("facing rejected: "+face)
            return
        var entry: Dictionary = layer.visual_contract()
        if str(entry["candidateStatus"]) != Layer.ART_STATUS \
            or bool(entry["combatActionExecuted"]) \
            or not bool(entry["staffAlreadyInSprite"]):
            _fail("art authority or baked staff invalid: "+face)
            return
        if layer.display_sprite.flip_h or layer.display_sprite.hframes != 6 \
            or layer.display_sprite.frame != 0:
            _fail("candidate mirrored, sliced or misrepresented: "+face)
            return
        var path: String = str(entry["texturePath"])
        if path.is_empty() or textures.has(path):
            _fail("directional sprite reused texture or lost provenance: "+face)
            return
        textures[path] = true
    if layer.set_facing("unknown"):
        _fail("unrecognized facing admitted")
        return

    review._scrub(63.0)
    var forming: Dictionary = review.active_contract()
    review._scrub(69.5)
    var impact: Dictionary = review.active_contract()
    if float(impact["contactStrength"]) <= float(forming["contactStrength"]) \
        or float(impact["cinematicZoom"]) <= float(forming["cinematicZoom"]):
        _fail("contact timing has no visible peak")
        return
    if bool(impact["combatCommandIssued"]) or bool(impact["canExecute"]) \
        or int(impact["damage"]) != 0:
        _fail("camera study executed formula")
        return
    review._set_motion(true)
    var muted: Dictionary = review.active_contract()
    if float(muted["cinematicZoom"]) != 1.0 \
        or float(muted["contactStrength"]) != 0.0:
        _fail("reduced-motion stage still flashes or zooms")
        return
    review._toggle_candidate()
    if not rig.show_mannequin or not rig.weapon.visible or layer.visible:
        _fail("mannequin comparison mode failed")
        return
    review._toggle_candidate()
    if rig.show_mannequin or rig.weapon.visible or not layer.visible:
        _fail("Ender candidate restored with duplicated weapon")
        return
    review.queue_free()
    print("WEAPON_DIRECTIONAL_CINEMATIC_PASS: 4 existing candidates, exact authority, 0 execution, no duplicate staff")
    quit(0)

func _fail(reason: String) -> void:
    push_error("WEAPON_DIRECTIONAL_CINEMATIC_FAIL: "+reason)
    quit(1)
