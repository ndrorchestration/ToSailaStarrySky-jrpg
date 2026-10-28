extends SceneTree
## Native OpenGL comparison: same clock, ship, weather and camera.
## Only the four existing wing hinges change their review pose.
const Study = preload("res://main.tscn")
const SHOTS = [["neutral", 0.0], ["gentle-sweep", 1.0]]
var images: Array[Image] = []
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_capture")

func _sampled_delta(a: Image, b: Image) -> float:
    var delta: float = 0.0
    for y in range(60, 600, 16):
        for x in range(60, 900, 16):
            var ca: Color = a.get_pixel(x, y)
            var cb: Color = b.get_pixel(x, y)
            delta += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
    return delta

func _capture() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.overlay.visible = false
    scene._clock = 9.0
    scene._update_scene(0.0)
    scene.ship.set_motion(9.0, true)
    scene.visuals.set_environment_look(0, 0, false)
    scene.camera.position = scene.ship.position + Vector3(6.5, 3.0, -7.0)
    scene.camera.fov = 43.0
    scene.camera.look_at(scene.ship.position + Vector3(0.0, 0.2, 0.0), Vector3.UP)
    scene.terrain.update_detail(scene.camera.position, 0.5)
    var ship_pose: Transform3D = scene.ship.global_transform
    var camera_pose: Transform3D = scene.camera.global_transform
    var directory: String = ProjectSettings.globalize_path("res://evidence/wing-hinge-review")
    if DirAccess.make_dir_recursive_absolute(directory) != OK:
        push_error("NATIVE_WING_HINGE_CAPTURE_FAIL: output directory")
        quit(1)
        return
    for shot in SHOTS:
        if not scene.ship.set_wing_review_sweep(float(shot[1])):
            errors.append("wing preview pose refused " + str(shot[0]))
            break
        for warmup in range(8):
            await process_frame
            await RenderingServer.frame_post_draw
        var frame: Image = root.get_texture().get_image()
        if frame == null or frame.get_size() != Vector2i(960, 640):
            errors.append("invalid native image " + str(shot[0]))
            continue
        var path: String = directory.path_join(str(shot[0]) + ".png")
        if frame.save_png(path) != OK:
            errors.append("image write failed " + str(shot[0]))
            continue
        images.append(frame.duplicate())
        print("NATIVE_WING_HINGE_CAPTURE: ", path, " 960x640 NONCANON")
        if scene.ship.global_transform != ship_pose:
            errors.append("wing art mutated ship pose")
        if scene.camera.global_transform != camera_pose:
            errors.append("wing art mutated camera pose")
    if images.size() == 2:
        var delta: float = _sampled_delta(images[0], images[1])
        print("NATIVE_WING_HINGE_DELTA: ", delta)
        if delta < 2.0:
            errors.append("small wing sweep not detectable in rendered pixels")
    if not scene.ship.set_wing_review_sweep(0.0):
        errors.append("could not restore neutral pose")
    scene.queue_free()
    await process_frame
    if errors.is_empty() and images.size() == 2:
        print("NATIVE_WING_HINGE_REVIEW_PASS frames=2")
        quit(0)
    else:
        for error in errors:
            push_error("NATIVE_WING_HINGE_CAPTURE_FAIL: " + error)
        quit(1)
