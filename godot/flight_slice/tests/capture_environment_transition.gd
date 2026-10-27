extends SceneTree
## Genuine 960x640 GL images proving a visible intermediate atmospheric grade.
## Matched camera, ship position and scene clock. Art acceptance remains separate.
const Study = preload("res://main.tscn")
var captured: Array[Image] = []
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _snapshot(scene: Node3D, file_path: String) -> void:
    scene.visuals.set_clock(23.0, false)
    scene.visuals.set_camera_frame(scene.camera)
    for pass_index in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    var frame: Image = root.get_texture().get_image()
    if frame == null or frame.get_size() != Vector2i(960, 640):
        errors.append("missing correct native GL framebuffer: " + file_path)
        return
    if frame.save_png(file_path) != OK:
        errors.append("cannot save GL image: " + file_path)
        return
    captured.append(frame.duplicate())
    print("NATIVE_ENVIRONMENT_BLEND_FRAME: ", file_path)

func _sampled_delta(one: Image, two: Image) -> float:
    var difference: float = 0.0
    for y in range(32, 608, 24):
        for x in range(32, 928, 24):
            var a: Color = one.get_pixel(x, y)
            var b: Color = two.get_pixel(x, y)
            difference += absf(a.r - b.r)
            difference += absf(a.g - b.g)
            difference += absf(a.b - b.b)
    return difference

func _run() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.overlay.visible = false
    scene._clock = 23.0
    scene._update_scene(10.0)
    var original_pose: Transform3D = scene.camera.global_transform
    var directory: String = ProjectSettings.globalize_path(
        "res://evidence/environment-transition")
    if DirAccess.make_dir_recursive_absolute(directory) != OK:
        push_error("GODOT_ENVIRONMENT_BLEND_CAPTURE_FAIL: output folder")
        quit(1)
        return
    scene.visuals.set_environment_look(0, 0, false)
    await _snapshot(scene, directory.path_join("01-golden-clear.png"))
    scene.visuals.queue_environment_look(3, 3, true, 2.0)
    scene.visuals.advance_environment_transition(1.0, false)
    await _snapshot(scene, directory.path_join("02-halfway.png"))
    scene.visuals.advance_environment_transition(1.0, false)
    await _snapshot(scene, directory.path_join("03-storm-night.png"))
    if captured.size() == 3:
        var first_to_middle: float = _sampled_delta(captured[0], captured[1])
        var middle_to_last: float = _sampled_delta(captured[1], captured[2])
        var first_to_last: float = _sampled_delta(captured[0], captured[2])
        print("NATIVE_ENVIRONMENT_BLEND_DELTAS first_half=", first_to_middle,
            " half_last=", middle_to_last, " full=", first_to_last)
        if first_to_middle < 2.0 or middle_to_last < 2.0:
            errors.append("transition intermediate did not alter rendered pixels")
        if scene.camera.global_transform != original_pose:
            errors.append("presentation changed camera transform")
    else:
        errors.append("native transition frames incomplete")
    scene.queue_free()
    await process_frame
    if errors.is_empty():
        print("NATIVE_ENVIRONMENT_BLEND_CAPTURE_PASS frames=3")
        quit(0)
    else:
        for err in errors:
            push_error("GODOT_ENVIRONMENT_BLEND_CAPTURE_FAIL: " + err)
        quit(1)
