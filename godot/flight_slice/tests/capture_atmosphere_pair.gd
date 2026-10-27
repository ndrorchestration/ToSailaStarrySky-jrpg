extends SceneTree
## Rendered A/B cloud-depth proof using the same Godot 4.7.2 framebuffer.
## No external artwork and no claims of physical volumetric cloud simulation.
const StudyScene = preload("res://main.tscn")
const CUTS = [["coast-dusk", 9.0], ["highland-horizon", 34.0]]
var failed: bool = false

func _initialize() -> void:
    call_deferred("_run")

func _frame() -> Image:
    for i in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _save(frame: Image, file_path: String) -> void:
    if frame == null or frame.get_size() != Vector2i(960,640):
        push_error("ATMOSPHERE_FRAME_DIMENSIONS_INVALID " + file_path)
        failed = true
    elif frame.save_png(file_path) != OK:
        push_error("ATMOSPHERE_FRAME_WRITE_FAILED " + file_path)
        failed = true

func _difference_pixels(a: Image, b: Image) -> int:
    var changes: int = 0
    # Subsample only to bound CPU readback cost; same fixed camera and clock.
    for y in range(0, 640, 3):
        for x in range(0, 960, 3):
            var first: Color = a.get_pixel(x, y)
            var second: Color = b.get_pixel(x, y)
            var contrast: float = absf(first.r-second.r) + absf(
                first.g-second.g) + absf(first.b-second.b)
            if contrast > 0.05:
                changes += 1
    return changes

func _run() -> void:
    var scene = StudyScene.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.overlay.visible = false
    var path: String = ProjectSettings.globalize_path("res://evidence/atmosphere-review")
    if DirAccess.make_dir_recursive_absolute(path) != OK:
        push_error("ATMOSPHERE_REVIEW_DIRECTORY_FAILED")
        quit(1)
        return

    var max_changed: int = 0
    for cut in CUTS:
        scene._clock = float(cut[1])
        scene._update_scene(10.0)
        scene.visuals.set_low_quality(false)
        scene.visuals.sky_material.set_shader_parameter("cloud_depth_strength", 0.0)
        var reference: Image = await _frame()
        _save(reference, path.path_join(str(cut[0]) + "-reference.png"))
        scene.visuals.sky_material.set_shader_parameter("cloud_depth_strength", 1.0)
        var layered: Image = await _frame()
        _save(layered, path.path_join(str(cut[0]) + "-layered.png"))
        var delta: int = _difference_pixels(reference, layered)
        max_changed = maxi(max_changed, delta)
        print("NATIVE_ATMOSPHERE_PAIR: ", cut[0], " changed_sampled_pixels=", delta)

    # At least one scene must visibly respond on a real frame buffer.
    # This is an existence check, NOT a claim that the new sky looks good.
    if max_changed < 80:
        push_error("NATIVE_ATMOSPHERE_PAIR_NO_VISIBLE_CHANGE")
        failed = true
    scene.queue_free()
    await process_frame
    if failed:
        quit(1)
    else:
        print("NATIVE_ATMOSPHERE_PAIR_PASS delta=", max_changed)
        quit(0)
