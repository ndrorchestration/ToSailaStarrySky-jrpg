extends SceneTree
## Genuine 960x640 native GL A/B/C: original dock / rectangular legacy /
## newly feathered material. The camera, chapter and player state stay fixed.
const Chapter = preload("res://scenes/first_wake_chapter1_review.tscn")
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_capture")

func _shot(path: String) -> Image:
    for n in range(6):
        await process_frame
        await RenderingServer.frame_post_draw
    var source: Image = root.get_texture().get_image()
    if source == null or source.get_size() != Vector2i(960,640):
        failures.append("no genuine native 960x640 framebuffer")
        return null
    if source.save_png(path) != OK:
        failures.append("image write failed "+path)
        return null
    print("GODOT_CH1_MATERIAL_BLEND_FRAME ",path)
    return source.duplicate()

func _delta(a: Image, b: Image, region: Rect2i, stride: int = 3) -> float:
    var total: float = 0.0
    for y in range(region.position.y,region.end.y,stride):
        for x in range(region.position.x,region.end.x,stride):
            var c0: Color = a.get_pixel(x,y)
            var c1: Color = b.get_pixel(x,y)
            total += absf(c0.r-c1.r)+absf(c0.g-c1.g)+absf(c0.b-c1.b)
    return total

func _capture() -> void:
    var world = Chapter.instantiate()
    root.add_child(world)
    await process_frame
    world.set_process(false)
    var dir: String = ProjectSettings.globalize_path(
        "res://review-evidence/environment-material")
    if DirAccess.make_dir_recursive_absolute(dir) != OK:
        push_error("GODOT_CH1_MATERIAL_BLEND_FAIL: cannot create output")
        quit(1)
        return
    var chapter_snapshot: Dictionary = world.chapter.snapshot().duplicate(true)
    var ender_pos: Vector2 = world.ender.position
    var input_bounds: Rect2 = world.ender.walking_bounds
    var adapter = world.environment_asset_intake
    world.set_environment_asset_intake_review_enabled(false)
    var original: Image = await _shot(dir.path_join("01-original-chapter-one.png"))
    adapter.set_preview_variant("legacy")
    world.set_environment_asset_intake_review_enabled(true)
    var legacy: Image = await _shot(dir.path_join("02-rectangular-prototype.png"))
    adapter.set_preview_variant("blended")
    var blended: Image = await _shot(dir.path_join("03-feathered-material-adapter.png"))
    if original != null and legacy != null and blended != null:
        var left_water: float = _delta(original,blended,Rect2i(25,420,46,70))
        var right_water: float = _delta(original,blended,Rect2i(894,420,46,70))
        var foliage: float = _delta(original,blended,Rect2i(101,372,34,45))
        var difference: float = _delta(legacy,blended,Rect2i(0,379,960,150),7)
        var left_edge: float = _delta(original,blended,Rect2i(0,412,3,85))
        var right_edge: float = _delta(original,blended,Rect2i(957,412,3,85))
        print("GODOT_CH1_MATERIAL_BLEND_DELTAS left=",left_water,
            " right=",right_water," foliage=",foliage,
            " legacy_to_new=",difference,
            " left_outer_edge=",left_edge," right_outer_edge=",right_edge)
        if left_water < 0.18 or right_water < 0.18 or foliage < 0.05:
            failures.append("original PNGs did not reach visible material areas")
        if difference < 2.0:
            failures.append("new material is indistinguishable from rectangular prototype")
        if left_edge > 0.25 or right_edge > 0.25:
            failures.append("outer material rectangle is still visible at canvas border")
        for frame in [legacy,blended]:
            if original.get_region(Rect2i(225,408,515,105)).get_data() != frame.get_region(
                    Rect2i(225,408,515,105)).get_data():
                failures.append("material modified active playable dock")
            if original.get_region(Rect2i(25,19,540,75)).get_data() != frame.get_region(
                    Rect2i(25,19,540,75)).get_data():
                failures.append("material obscured Chapter I UI")
    else:
        failures.append("one or more real native frame captures missing")
    world.set_environment_asset_intake_review_enabled(false)
    if world.chapter.snapshot() != chapter_snapshot or world.ender.position != ender_pos:
        failures.append("material comparison changed story or actor position")
    if world.ender.walking_bounds != input_bounds:
        failures.append("material changed navigable deck region")
    world.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_CH1_MATERIAL_BLEND_CAPTURE_PASS frames=3")
        quit(0)
    else:
        for issue in failures:
            push_error("GODOT_CH1_MATERIAL_BLEND_FAIL: "+issue)
        quit(1)
