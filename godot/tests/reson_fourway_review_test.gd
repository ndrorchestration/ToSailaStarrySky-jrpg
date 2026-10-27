extends SceneTree
## Native Reson source-art test. No canon or final animation acceptance.

const FACINGS: Array[String] = ["south", "west", "north", "east"]
const NAME_BY_FACING := {
    "south": "ResonSouthV1Unapproved",
    "west": "ResonWestV1Unapproved",
    "north": "ResonNorthV1Unapproved",
    "east": "ResonEastV1Unapproved"
}

func _initialize() -> void:
    call_deferred("_verify")

func _fail(message: String, code: int) -> void:
    push_error("RESON_FOURWAY_FAIL: " + message)
    quit(code)

func _verify() -> void:
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var view = world.get_node_or_null("CanvasLayer/FiveProtagonistVisualReviewUnapproved")
    if view == null or view.visible or view.get_reson_direction() != "south":
        _fail("opt-in preview missing or direction default changed", 1)
        return
    var observed_sources := {}
    var initial_frame_pixels := {}
    for facing in FACINGS:
        var sprite: Sprite2D = view.get_node_or_null(NAME_BY_FACING[facing]) as Sprite2D
        var expected_path := "res://art-review/reson-%s-sixphase-v1-unapproved.svg" % facing
        if sprite == null or sprite.texture == null or sprite.texture.resource_path != expected_path or sprite.hframes != 6:
            _fail("wrong source or missing six-frame atlas: " + facing, 2)
            return
        if observed_sources.has(sprite.texture.resource_path) or sprite.flip_h:
            _fail("shared atlas or mirrored sprite: " + facing, 3)
            return
        observed_sources[sprite.texture.resource_path] = true
        var source := FileAccess.get_file_as_string(expected_path)
        if source.count('id="reson-%s-pose-' % facing) != 6:
            if facing == "south" and source.count('id="reson-pose-') == 6:
                pass # Existing source identifier is immutable provenance.
            else:
                _fail("missing six authored source groups: " + facing, 4)
                return
        var raster: Image = sprite.texture.get_image()
        if raster.is_empty() or raster.get_width() != 480 or raster.get_height() != 128:
            _fail("Godot SVG import is not 480x128: " + facing, 5)
            return
        var prior_frames: Array[PackedByteArray] = []
        for phase in range(6):
            var bytes: PackedByteArray = raster.get_region(Rect2i(80 * phase, 0, 80, 128)).get_data()
            if bytes.is_empty():
                _fail("missing raster pixels: " + facing, 6)
                return
            for prior in prior_frames:
                if prior == bytes:
                    _fail("duplicate imported art phases in " + facing, 7)
                    return
            prior_frames.append(bytes)
        initial_frame_pixels[facing] = prior_frames[0]
    for facing in FACINGS:
        for other in FACINGS:
            if facing != other and initial_frame_pixels[facing] == initial_frame_pixels[other]:
                _fail("one view duplicates another: " + facing + " vs " + other, 8)
                return

    world.set_character_lineup_review_enabled(true)
    if not view.visible or world.ender.is_physics_processing() or world.ionia.is_physics_processing():
        _fail("review opt-in changes gameplay movement contract", 9)
        return
    for facing in FACINGS:
        view.set_reson_direction(facing)
        if view.get_reson_direction() != facing:
            _fail("direction not retained: " + facing, 10)
            return
        view.set_walk_phase(4)
        for expected in FACINGS:
            var sprite: Sprite2D = view.get_node(NAME_BY_FACING[expected])
            if sprite.visible != (expected == facing) or sprite.frame != 4 or sprite.flip_h:
                _fail("wrong visibility/frame/mirroring: " + facing, 11)
                return
    view.set_reson_direction("west")
    view.cycle_reson_direction()
    if view.get_reson_direction() != "north":
        _fail("direction cycle differs from authored order", 12)
        return
    view.set_reson_direction("invalid")
    if view.get_reson_direction() != "north":
        _fail("invalid direction changed review state", 13)
        return
    view.set_magnified(false)
    for facing in FACINGS:
        var sprite: Sprite2D = view.get_node(NAME_BY_FACING[facing])
        if not is_equal_approx(sprite.scale.x, 1.0):
            _fail("non-native scale retained after toggle: " + facing, 14)
            return
    view.set_magnified(true)
    for facing in FACINGS:
        var sprite: Sprite2D = view.get_node(NAME_BY_FACING[facing])
        if not is_equal_approx(sprite.scale.x, 1.55):
            _fail("zoom not propagated: " + facing, 15)
            return
    world.set_character_lineup_review_enabled(false)
    if view.visible or not world.ender.is_physics_processing() or not world.ionia.is_physics_processing():
        _fail("review did not safely restore world physics", 16)
        return
    print("RESON_FOURWAY_PASS: independent Godot-imported six-phase front/sides/rear, no sprite mirroring, reversible inspection")
    quit(0)
