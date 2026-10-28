extends SceneTree
## Native Godot 960x640 matching storm and clear viewpoints (no HUD, no actor
## physics change) to evaluate optional darkness separation, not visual approval.
const Study = preload("res://main.tscn")
var issues: Array[String] = []
var frames: Dictionary = {}

func _initialize() -> void:
    call_deferred("_run")

func _shot(scene: Node3D, folder: String, label: String) -> void:
    scene.visuals.set_clock(23.0, true)
    for i in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    var pic: Image = root.get_texture().get_image()
    if pic == null or pic.get_size() != Vector2i(960,640):
        issues.append("native frame invalid: "+label)
        return
    var filename: String = folder.path_join(label+".png")
    if pic.save_png(filename) != OK:
        issues.append("cannot save native GL image "+filename)
        return
    frames[label] = pic.duplicate()
    print("NATIVE_STORM_DEPTH_FRAME: ",filename)

func _delta(one: Image, two: Image) -> float:
    var score: float = 0.0
    for y in range(52,604,16):
        for x in range(48,916,16):
            var a: Color = one.get_pixel(x,y)
            var b: Color = two.get_pixel(x,y)
            score += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
    return score

func _run() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.overlay.visible = false
    scene._clock = 23.0
    scene._update_scene(10.0)
    var fixed_camera: Transform3D = scene.camera.global_transform
    var fixed_ship: Transform3D = scene.ship.global_transform
    var dir: String = ProjectSettings.globalize_path("res://evidence/storm-depth")
    if DirAccess.make_dir_recursive_absolute(dir) != OK:
        push_error("NATIVE_STORM_DEPTH_CAPTURE_FAIL: folder")
        quit(1)
        return
    scene.visuals.set_environment_look(0,0,false)
    scene.visuals.set_storm_depth_study_strength(0.0)
    await _shot(scene,dir,"01-day-original")
    scene.visuals.set_storm_depth_study_strength(1.0)
    await _shot(scene,dir,"02-day-study-enabled")
    scene.visuals.set_environment_look(3,3,false)
    scene.visuals.set_storm_depth_study_strength(0.0)
    await _shot(scene,dir,"03-storm-original")
    scene.visuals.set_storm_depth_study_strength(0.5)
    await _shot(scene,dir,"04-storm-half")
    scene.visuals.set_storm_depth_study_strength(1.0)
    await _shot(scene,dir,"05-storm-contrast")
    scene.visuals.set_low_quality(true)
    await _shot(scene,dir,"06-storm-contrast-low")
    if frames.size() == 6:
        var golden: float = _delta(frames["01-day-original"],frames["02-day-study-enabled"])
        var first_half: float = _delta(frames["03-storm-original"],frames["04-storm-half"])
        var half_full: float = _delta(frames["04-storm-half"],frames["05-storm-contrast"])
        print("NATIVE_STORM_DEPTH_DAY_DELTA sum=",golden)
        print("NATIVE_STORM_DEPTH_FIRST_HALF sum=",first_half)
        print("NATIVE_STORM_DEPTH_HALF_FULL sum=",half_full)
        if golden > 0.1:
            issues.append("day grade unexpectedly changed with storm-only study")
        if first_half < 2.0 or half_full < 2.0:
            issues.append("storm contrast does not reach visible intermediate pixels")
    else:
        issues.append("six native review pictures missing")
    if scene.camera.global_transform != fixed_camera:
        issues.append("opt-in grade changed camera")
    if scene.ship.global_transform != fixed_ship:
        issues.append("opt-in grade changed ship")
    if scene.visuals.transition_active:
        issues.append("review introduced an active cinematic crossfade")
    scene.queue_free()
    await process_frame
    if issues.is_empty():
        print("NATIVE_STORM_DEPTH_CAPTURE_PASS frames=6")
        quit(0)
    else:
        for issue in issues:
            push_error("NATIVE_STORM_DEPTH_CAPTURE_FAIL: "+issue)
        quit(1)
