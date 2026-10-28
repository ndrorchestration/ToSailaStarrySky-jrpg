extends SceneTree
## Four true native OpenGL A/B screenshots. Exact pose, clock, light and mood.
const Study = preload("res://main.tscn")
var images: Array[Image] = []
var problems: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _shot(scene: Node3D, path: String) -> void:
    scene.visuals.set_clock(scene._clock,false)
    scene.visuals.set_camera_frame(scene.camera)
    for i in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    var im: Image = root.get_texture().get_image()
    if im == null or im.get_size() != Vector2i(960,640):
        problems.append("wrong 960x640 real GL framebuffer")
        return
    if im.save_png(path) != OK:
        problems.append("cannot save native framebuffer "+path)
        return
    images.append(im.duplicate())
    print("NATIVE_FOLIAGE_SURF_FRAME: ",path)

func _land_delta(a: Image,b: Image) -> float:
    var total: float = 0.0
    for y in range(240,620,12):
        for x in range(42,915,12):
            var p: Color = a.get_pixel(x,y)
            var q: Color = b.get_pixel(x,y)
            total += absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)
    return total

func _run() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.overlay.visible = false
    var directory: String = ProjectSettings.globalize_path(
        "res://evidence/foliage-surf")
    if DirAccess.make_dir_recursive_absolute(directory) != OK:
        push_error("NATIVE_FOLIAGE_SURF_CAPTURE_FAIL cannot create folder")
        quit(1)
        return
    scene._clock = 5.5
    scene._update_scene(10.0)
    scene.visuals.set_environment_look(0,0,false)
    var coast_pose: Transform3D = scene.camera.global_transform
    scene.visuals.set_coastal_surf_enabled(false)
    await _shot(scene,directory.path_join("01-coast-base-foam.png"))
    scene.visuals.set_coastal_surf_enabled(true)
    await _shot(scene,directory.path_join("02-coast-swash.png"))
    if coast_pose != scene.camera.global_transform:
        problems.append("coast A/B moved camera")
    scene._clock = 23.0
    scene._update_scene(10.0)
    var forest_pose: Transform3D = scene.camera.global_transform
    scene.visuals.set_foliage_shape_enabled(false)
    await _shot(scene,directory.path_join("03-forest-base-canopy.png"))
    scene.visuals.set_foliage_shape_enabled(true)
    await _shot(scene,directory.path_join("04-forest-organic-canopy.png"))
    if forest_pose != scene.camera.global_transform:
        problems.append("forest A/B moved camera")
    if images.size() == 4:
        var surf_delta: float = _land_delta(images[0],images[1])
        var forest_delta: float = _land_delta(images[2],images[3])
        print("NATIVE_FOLIAGE_SURF_DELTAS surf=",surf_delta,
            " forest=",forest_delta)
        if surf_delta < 0.08:
            problems.append("signed-coast swash not visibly different")
        if forest_delta < 0.15:
            problems.append("canopy silhouette not visibly different")
    else:
        problems.append("incomplete 4-frame study")
    scene.queue_free()
    await process_frame
    if problems.is_empty():
        print("NATIVE_FOLIAGE_SURF_CAPTURE_PASS frames=4")
        quit(0)
    else:
        for err in problems:
            push_error("NATIVE_FOLIAGE_SURF_CAPTURE_FAIL: "+err)
        quit(1)
