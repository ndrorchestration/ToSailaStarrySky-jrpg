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
    # Front-facing atlases must be separate original source files with actual
    # baked per-phase visual differences, not repeated labels or mirrored placeholders.
    var authored_heights: Dictionary = {}
    for item in [
        ["Aepex", "aepex", "AepexSouthV1Unapproved"],
        ["Lyra", "lyra", "LyraSouthV1Unapproved"],
        ["Reson", "reson", "ResonSouthV1Unapproved"]
    ]:
        var actor_name: String = item[0]
        var source_id: String = item[1]
        var sprite: Sprite2D = preview.get_node_or_null(item[2]) as Sprite2D
        var source_path: String = "res://art-review/%s-south-sixphase-v1-unapproved.svg" % source_id
        if sprite == null or sprite.texture == null or sprite.texture.resource_path != source_path or sprite.hframes != 6:
            push_error("CHARACTER_LINEUP_FAIL: missing original front atlas: " + actor_name)
            quit(13)
            return
        var source: String = FileAccess.get_file_as_string(source_path)
        if source.count('id="%s-pose-' % source_id) != 6:
            push_error("CHARACTER_LINEUP_FAIL: missing six authored frame groups: " + actor_name)
            quit(14)
            return
        var raster: Image = sprite.texture.get_image()
        if raster.is_empty() or raster.get_width() != 480 or raster.get_height() != 128:
            push_error("CHARACTER_LINEUP_FAIL: Godot did not import 480x128 atlas: " + actor_name)
            quit(15)
            return
        var alpha_bounds: Rect2i = raster.get_region(Rect2i(0, 0, 80, 128)).get_used_rect()
        if alpha_bounds.size.y < 50 or alpha_bounds.size.y > 128:
            push_error("CHARACTER_LINEUP_FAIL: source frame has implausible visible anatomy")
            quit(21)
            return
        authored_heights[source_id] = alpha_bounds.size.y
        var prior_frames: Array = []
        for phase in range(6):
            var source_pixels: Image = raster.get_region(Rect2i(80 * phase, 0, 80, 128))
            var bytes: PackedByteArray = source_pixels.get_data()
            if bytes.is_empty():
                push_error("CHARACTER_LINEUP_FAIL: no frame pixels: " + actor_name)
                quit(16)
                return
            for prior in prior_frames:
                if prior == bytes:
                    push_error("CHARACTER_LINEUP_FAIL: duplicate imported phase: " + actor_name)
                    quit(17)
                    return
            prior_frames.append(bytes)
        if not preview.magnified or sprite.scale.x <= 1.0:
            push_error("CHARACTER_LINEUP_FAIL: review-scale third-party candidate missing: " + actor_name)
            quit(18)
            return
        preview.set_magnified(false)
        if not is_equal_approx(sprite.scale.x, 1.0):
            push_error("CHARACTER_LINEUP_FAIL: true authored source size cannot be restored")
            quit(19)
            return
        preview.set_magnified(true)
    if not (authored_heights["reson"] > authored_heights["aepex"] and authored_heights["aepex"] > authored_heights["lyra"]):
        push_error("CHARACTER_LINEUP_FAIL: authored tall/broad protagonist visual hierarchy regressed")
        quit(22)
        return
    print("CHARACTER_LINEUP_AUTHORED_HEIGHTS:" + str(authored_heights))
    var original_ender: Vector2 = world.ender.global_position
    var original_ionia: Vector2 = world.ionia.global_position
    world.set_character_lineup_review_enabled(true)
    if not preview.visible or world.ender.is_physics_processing() or world.ionia.is_physics_processing():
        push_error("CHARACTER_LINEUP_FAIL: review stage does not suspend actors")
        quit(6)
        return
    preview.set_walk_phase(5)
    if preview.get_node("AepexSouthV1Unapproved").frame != 5 or preview.get_node("LyraSouthV1Unapproved").frame != 5 or preview.get_node("ResonSouthV1Unapproved").frame != 5:
        push_error("CHARACTER_LINEUP_FAIL: new front studies not phase synchronized")
        quit(20)
        return
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
    print("CHARACTER_LINEUP_REVIEW_PASS: provenance, five identities, non-magic plot resonance, five source-bound, six-frame opt-in preview")
    quit(0)
