extends SceneTree
## Source-path anchored Lyra south boots: source geometry candidates only.
const Contact = preload("res://scripts/lyra_south_source_contact_proposal.gd")
const FACINGS: Array[String] = ["south", "west", "north", "east"]

func _initialize() -> void:
    call_deferred("_verify")

func _fail(message: String, code: int) -> void:
    push_error("LYRA_SOURCE_SOLE_FAIL: " + message)
    quit(code)

func _verify() -> void:
    var stage = load("res://scenes/three_character_physics_walk_review.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    var lyra = stage.get_actor("Lyra")
    var aepex = stage.get_actor("Aepex")
    var reson = stage.get_actor("Reson")
    if lyra == null or aepex == null or reson == null:
        _fail("three actors unavailable", 1)
        return
    if stage.lyra_source_contact_enabled or stage.lyra_source_contact_guide.visible:
        _fail("source contact overlay visible by default", 2)
        return
    if Contact.point(-1, Contact.FOOT_LEFT).get("valid", true) or Contact.point(6, Contact.FOOT_RIGHT).get("valid", true):
        _fail("invalid phase accepted", 3)
        return
    if Contact.point(0, "screen_left").get("valid", true):
        _fail("screen-side alpha was mistaken for anatomical path", 4)
        return
    if Contact.world_point(aepex, 0, Contact.FOOT_RIGHT).get("valid", true):
        _fail("foot-source annotation applies to a different character", 5)
        return
    if Contact.world_point(lyra, 0, "bogus").get("valid", true):
        _fail("unknown contact identity accepted", 6)
        return
    var source: Sprite2D = lyra.source_sprites["south"]
    if source.texture == null or source.texture.resource_path != Contact.SOURCE_ATLAS:
        _fail("Lyra native original source changed", 7)
        return
    var verified_points := 0
    var stance_points := 0
    var screen_half_max_distance := 0.0
    for phase in range(6):
        for foot in [Contact.FOOT_RIGHT, Contact.FOOT_LEFT]:
            var spec: Dictionary = Contact.point(phase, foot)
            var raster: Dictionary = Contact.sample_source_pixel(source.texture, phase, foot)
            if not spec.get("valid", false) or spec.get("anatomy_certified", true) or spec.get("approval", "") != "UNAPPROVED_SOURCE_GEOMETRY_PROPOSAL":
                _fail("unapproved source-geometry status altered", 8)
                return
            if not raster.get("valid", false):
                _fail("hand-picked SVG boot point not present as boot ink phase=%d foot=%s alpha=%.3f color=%.3f" % [
                    phase, foot, raster.get("alpha", -1.0), raster.get("boot_color_error", -1.0)], 9)
                return
            var support: Dictionary = lyra.get_source_boot_sample("south", phase)
            var side: Dictionary = support["left"] if foot == Contact.FOOT_RIGHT else support["right"]
            if not side.get("present", false):
                _fail("no boot-side source-alpha neighbor", 10)
                return
            var native: Vector2i = spec["source_pixel"]
            var centroid_delta := Vector2(float(native.x) - float(side["x"]), float(native.y) - float(side["y"])).length()
            if centroid_delta > 18.0:
                _fail("annotated boot not near the alpha-support region", 11)
                return
            screen_half_max_distance = maxf(screen_half_max_distance, centroid_delta)
            if spec["stance_candidate"]:
                stance_points += 1
            verified_points += 1
    if verified_points != 12 or stance_points != 4:
        _fail("six frames x two anatomical candidates or stance windows incomplete", 12)
        return
    for phase in [2, 5]:
        if Contact.REVIEW_STANCE[phase] != Contact.SWING:
            _fail("undefined transfer phase was promoted to a plant", 13)
            return
    var unchanged_positions := {
        "Lyra": lyra.global_position, "Aepex": aepex.global_position, "Reson": reson.global_position
    }
    stage.set_lyra_source_contact_enabled(true)
    if not stage.lyra_source_contact_enabled or not stage.lyra_source_contact_guide.visible or stage.source_guides_enabled or stage.stance_guides_enabled:
        _fail("opt-in sole path marker changed other debug modes", 14)
        return
    for character_id in unchanged_positions:
        if stage.get_actor(character_id).global_position != unchanged_positions[character_id]:
            _fail("visual overlay translated gameplay actor", 15)
            return
    var last_foot := ""
    var first_point := Vector2.ZERO
    var max_drift := {Contact.FOOT_RIGHT: 0.0, Contact.FOOT_LEFT: 0.0}
    var windows := {Contact.FOOT_RIGHT: 0, Contact.FOOT_LEFT: 0}
    var moving_ticks := 0
    stage.start_all()
    for tick in range(78):
        await physics_frame
        if lyra.completed:
            break
        if lyra.facing != "south":
            break
        moving_ticks += 1
        var phase: int = lyra.current_phase
        var active_foot: String = Contact.REVIEW_STANCE[phase]
        if active_foot == Contact.SWING:
            last_foot = ""
            continue
        var sample: Dictionary = Contact.world_point(lyra, phase, active_foot)
        if not sample.get("valid", false) or sample.get("anatomy_certified", true):
            _fail("review contact source not measurable", 16)
            return
        var point: Vector2 = sample["world_pixel"]
        if active_foot != last_foot:
            first_point = point
            last_foot = active_foot
            windows[active_foot] += 1
        else:
            max_drift[active_foot] = maxf(max_drift[active_foot], point.distance_to(first_point))
    if moving_ticks < 60:
        _fail("not enough real physical south movement", 17)
        return
    for foot in [Contact.FOOT_RIGHT, Contact.FOOT_LEFT]:
        var displacement: float = max_drift[foot]
        if windows[foot] < 1 or displacement <= 1.0 or displacement > 40.0:
            _fail("missing or invalid source-foot window displacement", 18)
            return
        print("LYRA_SOURCE_SOLE_WORLD_DRIFT:%s:windows=%d:max_drift=%.2f:UNAPPROVED" % [
            foot, windows[foot], displacement])
    stage.stop_all()
    stage.set_lyra_source_contact_enabled(false)
    if stage.lyra_source_contact_guide.visible or stage.lyra_source_contact_enabled:
        _fail("source proposal overlay not fully reversible", 19)
        return
    print("LYRA_SOURCE_SOLE_AUDIT_PASS: original six SVG poses x two hand-selected boot path points; actual physical south window drift; no sprite/world writes")
    print("LYRA_SOURCE_SOLE_APPROVAL=UNAPPROVED_ANATOMICAL_CANDIDATES")
    print("LYRA_SOURCE_SOLE_MAX_ALPHA_CENTROID_DIFFERENCE=%.2f" % screen_half_max_distance)
    quit(0)
