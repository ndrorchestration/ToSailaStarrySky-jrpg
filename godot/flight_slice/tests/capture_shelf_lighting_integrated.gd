extends SceneTree
## Real native Compatibility GL A/B for the same textured coastline in daylight
## and storm-night grade. This is a bounded art review, not aesthetic approval.
const Study = preload("res://main.tscn")
var problems: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _frame() -> Image:
    for i in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _capture(folder: String, label: String) -> Image:
    var im: Image = await _frame()
    if im == null or im.get_size() != Vector2i(960, 640):
        problems.append("missing genuine 960x640 GL frame " + label)
        return null
    var path: String = folder.path_join(label + ".png")
    if im.save_png(path) != OK:
        problems.append("cannot save real GL frame " + path)
        return null
    print("NATIVE_SHELF_LIGHTING_FRAME: ", path)
    return im.duplicate()

func _pixel_delta(first: Image, second: Image) -> int:
    var changed: int = 0
    for y in range(110, 640, 2):
        for x in range(0, 960, 2):
            if first.get_pixel(x, y) != second.get_pixel(x, y):
                changed += 1
    return changed

func _run() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.overlay.visible = false
    scene.ship.visible = false
    scene._clock = 5.5
    scene._update_scene(10.0)
    scene.visuals.set_clock(5.5, true)
    scene.visuals.set_texture_detail_enabled(true)
    scene.visuals.water.set_shader_parameter("foam_breakup_strength", 1.0)
    var original_camera: Transform3D = scene.camera.global_transform
    var original_ship: Transform3D = scene.ship.global_transform
    var path: String = ProjectSettings.globalize_path("res://evidence/shelf-lighting")
    if DirAccess.make_dir_recursive_absolute(path) != OK:
        push_error("NATIVE_SHELF_LIGHTING_FAIL: cannot create folder")
        quit(1)
        return
    scene.visuals.set_environment_look(0, 0, false)
    scene.visuals.water.set_shader_parameter("shelf_transition_strength", 0.0)
    var day_old: Image = await _capture(path, "01-day-original-shelf")
    scene.visuals.water.set_shader_parameter("shelf_transition_strength", 1.0)
    var day_new: Image = await _capture(path, "02-day-toned-shelf")
    scene.visuals.set_environment_look(3, 3, true)
    scene.visuals.water.set_shader_parameter("shelf_transition_strength", 0.0)
    var night_old: Image = await _capture(path, "03-night-original-shelf")
    scene.visuals.water.set_shader_parameter("shelf_transition_strength", 1.0)
    var night_new: Image = await _capture(path, "04-night-toned-shelf")
    # Low-detail V mode must be pixel-identical for both shelf parameters.
    scene.visuals.set_low_quality(true)
    scene.visuals.water.set_shader_parameter("shelf_transition_strength", 0.0)
    var low_old: Image = await _capture(path, "05-low-original-shelf")
    scene.visuals.water.set_shader_parameter("shelf_transition_strength", 1.0)
    var low_new: Image = await _capture(path, "06-low-toned-shelf")
    if day_old != null and day_new != null and night_old != null and night_new != null and low_old != null and low_new != null:
        var day_delta: int = _pixel_delta(day_old, day_new)
        var night_delta: int = _pixel_delta(night_old, night_new)
        var low_delta: int = _pixel_delta(low_old, low_new)
        print("NATIVE_SHELF_LIGHTING_DAY_DELTA pixels=", day_delta)
        print("NATIVE_SHELF_LIGHTING_NIGHT_DELTA pixels=", night_delta)
        print("NATIVE_SHELF_LIGHTING_LOW_DELTA pixels=", low_delta)
        if day_delta < 100 or day_delta > 65000:
            problems.append("day shelf difference missing or unbounded")
        if night_delta < 100 or night_delta > 65000:
            problems.append("night shelf difference missing or unbounded")
        if low_delta != 0:
            problems.append("V fallback changed pixels with shelf selection")
    else:
        problems.append("incomplete six-frame proof")
    if scene.camera.global_transform != original_camera:
        problems.append("shelf color changed camera transform")
    if scene.ship.global_transform != original_ship:
        problems.append("shelf color changed airship transform")
    if scene.visuals.transition_active:
        problems.append("comparison accidentally entered atmosphere fade")
    if scene.terrain.chunk_count() != 64:
        problems.append("shelf shader altered terrain topology")
    scene.queue_free()
    await process_frame
    if problems.is_empty():
        print("NATIVE_SHELF_LIGHTING_PASS frames=6 comparisons=3")
        quit(0)
    else:
        for msg in problems:
            push_error("NATIVE_SHELF_LIGHTING_FAIL: " + msg)
        quit(1)
