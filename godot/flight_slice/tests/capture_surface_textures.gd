extends SceneTree
## Exact-pose native GL proof: authentic 128px PNG texels change the ground,
## forest and water render. No screen effect may counterfeit the comparison.
const FlightScene = preload("res://main.tscn")
var images: Array[Image] = []
var problems: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _shot(scene: Node3D, path: String) -> void:
    scene.visuals.set_clock(23.0, false)
    scene.visuals.set_camera_frame(scene.camera)
    for k in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    var im: Image = root.get_texture().get_image()
    if im == null or im.get_size() != Vector2i(960, 640):
        problems.append("missing expected real GL framebuffer at " + path)
        return
    if im.save_png(path) != OK:
        problems.append("could not save native GL frame " + path)
        return
    images.append(im.duplicate())
    print("NATIVE_SURFACE_TEXTURE_FRAME: ", path)

func _land_pixel_delta(first: Image, other: Image) -> float:
    # Exclude most sky/HUD pixels; constrain measurements to same world pose.
    var sum: float = 0.0
    for y in range(285, 612, 12):
        for x in range(45, 915, 12):
            var a: Color = first.get_pixel(x, y)
            var b: Color = other.get_pixel(x, y)
            sum += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
    return sum

func _run() -> void:
    var scene = FlightScene.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.overlay.visible = false
    scene._clock = 23.0
    scene._update_scene(10.0)
    var camera_pose: Transform3D = scene.camera.global_transform
    var dir: String = ProjectSettings.globalize_path("res://evidence/surface-textures")
    if DirAccess.make_dir_recursive_absolute(dir) != OK:
        push_error("NATIVE_SURFACE_TEXTURE_CAPTURE_FAIL: output folder unavailable")
        quit(1)
        return
    scene.visuals.set_environment_look(0, 0, false)
    scene.visuals.set_texture_detail_enabled(false)
    await _shot(scene, dir.path_join("01-golden-untextured.png"))
    scene.visuals.set_texture_detail_enabled(true)
    await _shot(scene, dir.path_join("02-golden-textured.png"))
    scene.visuals.set_environment_look(3, 3, true)
    scene.visuals.set_texture_detail_enabled(false)
    await _shot(scene, dir.path_join("03-night-untextured.png"))
    scene.visuals.set_texture_detail_enabled(true)
    await _shot(scene, dir.path_join("04-night-textured.png"))
    if images.size() == 4:
        var delta_golden: float = _land_pixel_delta(images[0],images[1])
        var delta_night: float = _land_pixel_delta(images[2],images[3])
        print("NATIVE_SURFACE_TEXTURE_DELTAS golden=",delta_golden,
            " night=",delta_night)
        if delta_golden < 1.0:
            problems.append("committed microtextures did not affect golden render")
        if delta_night < 0.30:
            problems.append("committed microtextures did not affect night render")
        if scene.camera.global_transform != camera_pose:
            problems.append("texture comparison moved camera")
    else:
        problems.append("incomplete 4-pair source capture")
    scene.queue_free()
    await process_frame
    if problems.is_empty():
        print("NATIVE_SURFACE_TEXTURE_CAPTURE_PASS frames=4")
        quit(0)
    else:
        for problem in problems:
            push_error("NATIVE_SURFACE_TEXTURE_CAPTURE_FAIL: " + problem)
        quit(1)
