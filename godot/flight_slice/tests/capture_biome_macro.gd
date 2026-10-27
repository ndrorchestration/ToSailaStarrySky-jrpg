extends SceneTree
## Same-pose real-OpenGL A/B regional biome + same-height shoreline captures.
const Study = preload("res://main.tscn")
var frames: Array[Image] = []
var issues: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _shot(scene: Node3D, path: String) -> void:
    scene.visuals.set_clock(scene._clock, false)
    scene.visuals.set_camera_frame(scene.camera)
    for index in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    var im: Image = root.get_texture().get_image()
    if im == null or im.get_size() != Vector2i(960,640):
        issues.append("wrong native framebuffer size")
        return
    if im.save_png(path) != OK:
        issues.append("cannot write native rendered PNG: "+path)
        return
    frames.append(im.duplicate())
    print("NATIVE_BIOME_MACRO_FRAME: ",path)

func _difference(left: Image, right: Image) -> float:
    var total: float = 0.0
    for y in range(240,620,12):
        for x in range(40,920,12):
            var a: Color = left.get_pixel(x,y)
            var b: Color = right.get_pixel(x,y)
            total += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
    return total

func _run() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.overlay.visible = false
    var dir: String = ProjectSettings.globalize_path(
        "res://evidence/biome-macro")
    if DirAccess.make_dir_recursive_absolute(dir) != OK:
        push_error("NATIVE_BIOME_MACRO_CAPTURE_FAIL folder")
        quit(1)
        return
    var frame_names: Array[String] = [
        "01-coast-original.png","02-coast-macro.png",
        "03-forest-original.png","04-forest-macro.png",
        "05-storm-original.png","06-storm-macro.png"]
    var ix: int = 0
    for setup in [{"clock":5.5,"t":0,"w":0,"m":false},
        {"clock":23.0,"t":0,"w":0,"m":false},
        {"clock":23.0,"t":3,"w":3,"m":true}]:
        scene._clock = float(setup["clock"])
        scene._update_scene(10.0)
        var pose: Transform3D = scene.camera.global_transform
        scene.visuals.set_environment_look(
            int(setup["t"]),int(setup["w"]),bool(setup["m"]))
        # Both arms retain the three fine-grain PNGs. Only the regional
        # biome PNG and matched wet-shore treatment are compared.
        scene.visuals.set_texture_detail_enabled(true)
        scene.visuals.set_biome_layer_enabled(false)
        await _shot(scene,dir.path_join(frame_names[ix]))
        ix += 1
        scene.visuals.set_biome_layer_enabled(true)
        await _shot(scene,dir.path_join(frame_names[ix]))
        ix += 1
        if pose != scene.camera.global_transform:
            issues.append("A/B macro capture shifted the camera")
    if frames.size() == 6:
        var coast: float = _difference(frames[0],frames[1])
        var forest: float = _difference(frames[2],frames[3])
        var night: float = _difference(frames[4],frames[5])
        print("NATIVE_BIOME_MACRO_DELTAS coast=",coast,
            " forest=",forest," night=",night)
        if coast < 0.9: issues.append("coast material region unchanged")
        if forest < 0.9: issues.append("forest material region unchanged")
        if night < 0.25: issues.append("storm-night material unchanged")
    else:
        issues.append("incomplete native six-frame macro evidence")
    scene.queue_free()
    await process_frame
    if issues.is_empty():
        print("NATIVE_BIOME_MACRO_CAPTURE_PASS frames=6")
        quit(0)
    else:
        for problem in issues:
            push_error("NATIVE_BIOME_MACRO_CAPTURE_FAIL: "+problem)
        quit(1)
