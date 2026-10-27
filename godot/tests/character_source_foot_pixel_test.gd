extends SceneTree
## Godot-imported source boot-alpha measurements and reversible review-only offset.
## Not a claim about anatomically planted feet or physical terrain grounding.
const FootProbe = preload("res://scripts/character_foot_pixel_probe.gd")
const CHARACTERS: Array[String] = ["Lyra", "Aepex", "Reson"]
const FACINGS: Array[String] = ["south", "west", "north", "east"]

func _initialize() -> void:
    call_deferred("_verify")

func _fail(message: String, code: int) -> void:
    push_error("SOURCE_FOOT_PIXEL_FAIL: " + message)
    quit(code)

func _verify() -> void:
    var malformed: Image = Image.create(80, 128, false, Image.FORMAT_RGBA8)
    if FootProbe.inspect_image(malformed, 0).get("valid", true):
        _fail("malformed one-cell atlas accepted", 1)
        return
    var blank: Image = Image.create(480, 128, false, Image.FORMAT_RGBA8)
    blank.fill(Color.TRANSPARENT)
    if FootProbe.inspect_image(blank, 0).get("valid", true):
        _fail("transparent boot band accepted", 2)
        return
    if FootProbe.inspect_image(blank, -1).get("valid", true) or FootProbe.inspect_image(blank, 6).get("valid", true):
        _fail("out-of-range source frame accepted", 3)
        return

    var stage = load("res://scenes/three_character_physics_walk_review.tscn").instantiate()
    root.add_child(stage)
    await process_frame
    if stage.source_guides_enabled:
        _fail("diagnostic overlays visible before opt-in", 4)
        return

    var original_positions := {}
    for character_id in CHARACTERS:
        var actor = stage.get_actor(character_id)
        if actor == null or not actor.foot_pixel_align_enabled:
            _fail("default review pixel-baseline correction unavailable", 5)
            return
        original_positions[character_id] = actor.global_position
        var corrections_min := 1000.0
        var corrections_max := -1000.0
        var source_left_supports := 0
        var source_right_supports := 0
        for facing in FACINGS:
            var source: Sprite2D = actor.source_sprites[facing]
            if source.texture == null or source.texture.resource_path != "res://art-review/%s-%s-sixphase-v1-unapproved.svg" % [character_id.to_lower(), facing]:
                _fail("unknown source art or source path drift", 6)
                return
            for phase in range(6):
                var sample: Dictionary = actor.get_source_boot_sample(facing, phase)
                if not sample.get("valid", false):
                    _fail("no candidate boot baseline: %s %s phase %d (%s)" % [character_id, facing, phase, sample.get("reason", "unknown")], 7)
                    return
                var bottom: int = sample["bottom_y"]
                if bottom < 113 or bottom > 127:
                    _fail("impossible boot band y value", 8)
                    return
                corrections_min = minf(corrections_min, float(sample["baseline_correction_y"]))
                corrections_max = maxf(corrections_max, float(sample["baseline_correction_y"]))
                for side in ["left", "right"]:
                    var support: Dictionary = sample[side]
                    if support.get("present", false):
                        if float(support["x"]) < 0.0 or float(support["x"]) >= 80.0 or int(support["y"]) > bottom:
                            _fail("bad source alpha support coordinate", 9)
                            return
                        if side == "left":
                            source_left_supports += 1
                        else:
                            source_right_supports += 1
                if not sample["left"].get("present", false) and not sample["right"].get("present", false):
                    _fail("no left/right support in otherwise valid frame", 10)
                    return
                actor.current_phase = phase
                actor._apply_pixel_baselines()
                if absf(float(source.position.y) + float(bottom) - 64.0) > 0.001:
                    _fail("visible alpha boot y cannot be normalized to actor ground: %s %s %d" % [character_id, facing, phase], 11)
                    return
        if source_left_supports < 1 or source_right_supports < 1:
            _fail("one-sided source capture for all frames", 12)
            return
        actor.current_phase = 0
        actor.set_pixel_baseline_enabled(false)
        for facing in FACINGS:
            if not is_equal_approx((actor.source_sprites[facing] as Sprite2D).position.y, -60.0):
                _fail("reversible baseline-disable source anchor mismatch", 13)
                return
        actor.set_pixel_baseline_enabled(true)
        if actor.global_position != original_positions[character_id]:
            _fail("source visual correction changed collision/world position", 14)
            return
        print("SOURCE_FOOT_PIXEL_BASELINES:%s:24_frames:min_adjust=%.2f:max_adjust=%.2f:left_candidates=%d:right_candidates=%d" % [
            character_id, corrections_min, corrections_max, source_left_supports, source_right_supports])

    stage.set_source_guides_enabled(true)
    if not stage.source_guides_enabled:
        _fail("debug contact guides cannot be opted into", 15)
        return
    for character_id in CHARACTERS:
        if not stage.guides[character_id].visible:
            _fail("one character pixel-guide missing", 16)
            return
    stage.set_source_guides_enabled(false)
    for character_id in CHARACTERS:
        if stage.guides[character_id].visible or stage.get_actor(character_id).global_position != original_positions[character_id]:
            _fail("pixel guide opt-out changes world or keeps guide active", 17)
            return

    # Measure real support-marker world displacement while an *unchanged atlas
    # frame* is visible. These are lower boot-alpha markers, not certified stance
    # toes; this trace quantifies the unresolved sliding risk rather than
    # attempting to counterfeit contact animation approval.
    var prior_key := {}
    var held_start := {}
    var peak_held := {}
    for character_id in CHARACTERS:
        prior_key[character_id] = ""
        held_start[character_id] = Vector2.ZERO
        peak_held[character_id] = {"south": 0.0, "west": 0.0, "north": 0.0, "east": 0.0}
    stage.start_all()
    for tick in range(295):
        await physics_frame
        for character_id in CHARACTERS:
            var actor = stage.get_actor(character_id)
            if actor.completed:
                continue
            var facing: String = actor.facing
            var source: Sprite2D = actor.source_sprites[facing]
            var sample: Dictionary = actor.get_source_boot_sample(facing, actor.current_phase)
            if not sample.get("valid", false):
                _fail("missing active source sample while moving", 18)
                return
            var baseline_world: float = actor.global_position.y + source.position.y + float(sample["bottom_y"]) - 64.0
            if absf(baseline_world - actor.global_position.y) > 0.001:
                _fail("active phase boot alpha baseline jumped away from actor ground", 19)
                return
            var support: Dictionary = sample["left"] if sample["left"].get("present", false) else sample["right"]
            if not support.get("present", false):
                _fail("support pixel not measurable while moving", 20)
                return
            var source_key: String = facing + ":" + str(actor.current_phase)
            var pixel_world := actor.global_position + Vector2(
                float(support["x"]) - 40.0,
                float(support["y"]) - 64.0 + source.position.y)
            if prior_key[character_id] != source_key:
                prior_key[character_id] = source_key
                held_start[character_id] = pixel_world
            else:
                var held: float = (pixel_world - held_start[character_id]).length()
                peak_held[character_id][facing] = maxf(float(peak_held[character_id][facing]), held)
    stage.stop_all()
    for character_id in CHARACTERS:
        for facing in FACINGS:
            var measured: float = peak_held[character_id][facing]
            if measured < 6.0 or measured > 17.0:
                _fail("unrealistic or missing held-pixel slide trace %s/%s %.2f" % [character_id, facing, measured], 21)
                return
            print("SOURCE_FOOT_PIXEL_HELD_WORLD_SLIP:%s:%s:max_displacement=%.2f:STANCE_NOT_IDENTIFIED" % [character_id, facing, measured])
    print("SOURCE_FOOT_PIXEL_PASS: 72 native phase baselines, 3 four-direction physical routes, held-pixel displacement trace and reversible visual correction")
    print("SOURCE_FOOT_PIXEL_TRUE_PLANTED_FEET=NOT_CERTIFIED")
    quit(0)
