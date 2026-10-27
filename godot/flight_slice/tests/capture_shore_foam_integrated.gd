extends SceneTree
## Exact Godot GL review of reversible signed-depth coast foam on the same
## original textured ocean in a ship/weather scene. Not an art signoff.
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
    var frame: Image = await _frame()
    if frame == null or frame.get_size() != Vector2i(960, 640):
        problems.append("invalid 960x640 native GL frame " + label)
        return null
    var path: String = folder.path_join(label + ".png")
    if frame.save_png(path) != OK:
        problems.append("PNG write failed " + path)
        return null
    print("NATIVE_INTEGRATED_COAST_FOAM_FRAME: ", path)
    return frame.duplicate()

func _different(a: Image, b: Image) -> int:
    var changed: int = 0
    for y in range(110, 640, 2):
        for x in range(0, 960, 2):
            if a.get_pixel(x, y) != b.get_pixel(x, y):
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
    scene.visuals.set_environment_look(0, 0, false)
    scene.visuals.set_texture_detail_enabled(true)
    scene.visuals.set_clock(5.5, true)
    var original_camera: Transform3D = scene.camera.global_transform
    var original_ship: Transform3D = scene.ship.global_transform
    var folder: String = ProjectSettings.globalize_path("res://evidence/coast-foam")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("NATIVE_INTEGRATED_COAST_FOAM_FAIL: folder")
        quit(1)
        return
    scene.visuals.water.set_shader_parameter("foam_breakup_strength", 0.0)
    var baseline: Image = await _capture(folder, "01-original-contour")
    scene.visuals.water.set_shader_parameter("foam_breakup_strength", 1.0)
    var candidate: Image = await _capture(folder, "02-broken-surf-textured-water")
    scene.visuals.set_low_quality(true)
    scene.visuals.water.set_shader_parameter("foam_breakup_strength", 0.0)
    var low_reference: Image = await _capture(folder, "03-low-foam-reference")
    scene.visuals.water.set_shader_parameter("foam_breakup_strength", 1.0)
    var low_candidate: Image = await _capture(folder, "04-low-foam-candidate")
    if baseline != null and candidate != null and low_reference != null and low_candidate != null:
        var delta: int = _different(baseline, candidate)
        var low_delta: int = _different(low_reference, low_candidate)
        print("NATIVE_INTEGRATED_COAST_FOAM_DELTA pixels=", delta)
        print("NATIVE_INTEGRATED_COAST_FOAM_LOW_DELTA pixels=", low_delta)
        if delta < 100 or delta > 65000:
            problems.append("surfoam modulation invisible or unbounded")
        if low_delta != 0:
            problems.append("low quality must ignore added foam modulation")
    if scene.camera.global_transform != original_camera:
        problems.append("foam review changed the camera")
    if scene.ship.global_transform != original_ship:
        problems.append("foam review changed the airship")
    if scene.visuals.transition_active:
        problems.append("foam comparison accidentally entered environment fade")
    scene.queue_free()
    await process_frame
    if problems.is_empty():
        print("NATIVE_INTEGRATED_COAST_FOAM_PASS frames=4")
        quit(0)
    else:
        for problem in problems:
            push_error("NATIVE_INTEGRATED_COAST_FOAM_FAIL: " + problem)
        quit(1)
