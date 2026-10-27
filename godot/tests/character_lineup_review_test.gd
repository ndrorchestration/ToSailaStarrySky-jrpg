extends SceneTree
## Native opt-in presentation contract; this does not declare sprite approval.

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var preview = world.get_node_or_null("CanvasLayer/FiveProtagonistVisualReviewUnapproved")
    if preview == null or preview.visible:
        push_error("CHARACTER_LINEUP_FAIL: missing board or visible without consent")
        quit(1)
        return
    if preview.get_character_id_order() != ["Ionia", "Ender", "Aepex", "Lyra", "Reson"]:
        push_error("CHARACTER_LINEUP_FAIL: creator reference order changed")
        quit(2)
        return
    if preview.get_innate_energy_names() != ["Earth", "Spirit", "Air", "Water", "Fire"]:
        push_error("CHARACTER_LINEUP_FAIL: innate resonance mapping changed")
        quit(3)
        return
    var ionia: Sprite2D = preview.get_node("IoniaCandidateFront")
    var ender: Sprite2D = preview.get_node("EnderCandidateFront")
    if ionia.texture == null or ender.texture == null or ionia.hframes != 6 or ender.hframes != 6:
        push_error("CHARACTER_LINEUP_FAIL: native candidate atlases missing")
        quit(4)
        return
    if ionia.texture.resource_path != "res://art-review/ionia-front-sixframe-candidate.svg" or ender.texture.resource_path != "res://art-review/ender-south-detailed-staff-v2-candidate.svg":
        push_error("CHARACTER_LINEUP_FAIL: atlas source path altered")
        quit(5)
        return
    if not preview.magnified or ender.scale.x <= 1.0 or ionia.scale.x <= 0.13:
        push_error("CHARACTER_LINEUP_FAIL: enlarged inspection mode missing")
        quit(11)
        return
    preview.set_magnified(false)
    if preview.magnified or not is_equal_approx(ender.scale.x, 1.0) or not is_equal_approx(ionia.scale.x, 0.13):
        push_error("CHARACTER_LINEUP_FAIL: cannot restore original gameplay sprite scale")
        quit(12)
        return
    preview.set_magnified(true)
    var original_ender: Vector2 = world.ender.global_position
    var original_ionia: Vector2 = world.ionia.global_position
    world.set_character_lineup_review_enabled(true)
    if not preview.visible or world.ender.is_physics_processing() or world.ionia.is_physics_processing():
        push_error("CHARACTER_LINEUP_FAIL: review stage does not suspend actors")
        quit(6)
        return
    preview.set_walk_phase(5)
    if ionia.frame != 5 or ender.frame != 5:
        push_error("CHARACTER_LINEUP_FAIL: six-frame scrub not synchronized")
        quit(7)
        return
    preview.set_walk_phase(6)
    if ionia.frame != 0 or ender.frame != 0:
        push_error("CHARACTER_LINEUP_FAIL: phase wrap failed")
        quit(8)
        return
    world.set_character_lineup_review_enabled(false)
    await process_frame
    if preview.visible or not world.ender.is_physics_processing() or not world.ionia.is_physics_processing():
        push_error("CHARACTER_LINEUP_FAIL: opt-out did not restore the original world")
        quit(9)
        return
    if world.ender.global_position != original_ender or world.ionia.global_position != original_ionia:
        push_error("CHARACTER_LINEUP_FAIL: presentation mutated gameplay positions")
        quit(10)
        return
    print("CHARACTER_LINEUP_REVIEW_PASS: provenance, five identities, non-magic plot resonance, six-frame opt-in preview")
    quit(0)
