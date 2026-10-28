extends SceneTree
## Real 960x640 Godot Compatibility frames of the SAME Chapter I scene.
## One off/on toggle is the sole intended change; not a flight-lab render.
const Chapter = preload("res://scenes/first_wake_chapter1_review.tscn")
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_capture")

func _shot(output: String) -> Image:
    for i in range(5):
        await process_frame
        await RenderingServer.frame_post_draw
    var image: Image = root.get_texture().get_image()
    if image == null or image.get_size() != Vector2i(960,640):
        errors.append("real 960x640 native framebuffer unavailable")
        return null
    if image.save_png(output) != OK:
        errors.append("Godot could not save screenshot: "+output)
        return null
    print("GODOT_CH1_ENVIRONMENT_FRAME: ",output)
    return image.duplicate()

func _pixel_delta(a: Image,b: Image,area: Rect2i) -> float:
    var delta: float = 0.0
    for y in range(area.position.y,area.end.y,5):
        for x in range(area.position.x,area.end.x,5):
            var left: Color = a.get_pixel(x,y)
            var right: Color = b.get_pixel(x,y)
            delta += absf(left.r-right.r)+absf(left.g-right.g)+absf(left.b-right.b)
    return delta

func _capture() -> void:
    var scene = Chapter.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var folder: String = ProjectSettings.globalize_path("res://review-evidence/environment-intake")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("GODOT_CH1_ENVIRONMENT_CAPTURE_FAIL: folder not writable")
        quit(1)
        return
    var pose: Vector2 = scene.ender.position
    var stage: Dictionary = scene.chapter.snapshot().duplicate(true)
    scene.set_environment_asset_intake_review_enabled(false)
    var before: Image = await _shot(folder.path_join("01-original-chapter1-dock.png"))
    scene.set_environment_asset_intake_review_enabled(true)
    var after: Image = await _shot(folder.path_join("02-with-original-flightlab-textures.png"))
    if before != null and after != null:
        var left_delta: float = _pixel_delta(before,after,Rect2i(0,410,88,110))
        var right_delta: float = _pixel_delta(before,after,Rect2i(890,410,68,110))
        var leaf_delta: float = _pixel_delta(before,after,Rect2i(104,379,29,36))
        print("GODOT_CH1_ENVIRONMENT_INTAKE_DELTAS water_left=",left_delta,
            " water_right=",right_delta," foliage=",leaf_delta)
        if left_delta < 0.4 or right_delta < 0.25:
            errors.append("actual staged water PNG not visible in both open channels")
        if leaf_delta < 0.1:
            errors.append("actual staged foliage PNG not visible at existing planter")
        if before.get_region(Rect2i(200,400,540,123)).get_data() != after.get_region(
                Rect2i(200,400,540,123)).get_data():
            errors.append("unrelated playable dock area was painted by prototype")
        if before.get_region(Rect2i(25,20,510,75)).get_data() != after.get_region(
                Rect2i(25,20,510,75)).get_data():
            errors.append("Chapter I UI/headline was obscured by art prototype")
    else:
        errors.append("missing one of two actual native screenshots")
    if scene.ender.position != pose or scene.chapter.snapshot() != stage:
        errors.append("scene gameplay state changed during art-only A/B")
    scene.set_environment_asset_intake_review_enabled(false)
    if scene.is_environment_asset_intake_review_enabled():
        errors.append("review did not restore original default")
    scene.queue_free()
    await process_frame
    if errors.is_empty():
        print("GODOT_CH1_ENVIRONMENT_CAPTURE_PASS frames=2")
        quit(0)
    else:
        for problem in errors:
            push_error("GODOT_CH1_ENVIRONMENT_CAPTURE_FAIL: "+problem)
        quit(1)
