extends SceneTree
## Matched real Godot GL review of distance wet-shore, ground-cover color
## and fixed-batch rock dressing. Does not certify creator art acceptance.
const Study = preload("res://main.tscn")
var frames: Array[Image] = []
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _shot(scene: Node3D, path: String) -> void:
    scene.visuals.set_clock(scene._clock,false)
    scene.visuals.set_camera_frame(scene.camera)
    for i in range(8):
        await process_frame
        await RenderingServer.frame_post_draw
    var picture: Image = root.get_texture().get_image()
    if picture == null or picture.get_size() != Vector2i(960,640):
        failures.append("wrong native capture dimensions")
        return
    if picture.save_png(path) != OK:
        failures.append("cannot save native OpenGL image: "+path)
        return
    frames.append(picture.duplicate())
    print("NATIVE_COAST_ROCK_FRAME: ",path)

func _pixel_delta(a: Image,b: Image) -> float:
    var total: float = 0.0
    for y in range(220,620,12):
        for x in range(40,920,12):
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
        "res://evidence/coast-rock-dressing")
    if DirAccess.make_dir_recursive_absolute(directory) != OK:
        push_error("NATIVE_COAST_ROCK_CAPTURE_FAIL output directory")
        quit(1)
        return
    var photos: Array[String] = [
        "01-coast-original.png","02-coast-distance-material.png",
        "03-forest-original.png","04-forest-litter.png",
        "05-highland-no-rocks.png","06-highland-rock-outcrops.png"]
    var ix: int = 0
    for configuration in [
        {"clock":5.5,"biome":true,"rock_pair":false},
        {"clock":23.0,"biome":true,"rock_pair":false},
        {"clock":31.5,"biome":true,"rock_pair":true}
    ]:
        scene._clock = float(configuration["clock"])
        scene._update_scene(10.0)
        scene.visuals.set_environment_look(0,0,false)
        scene.visuals.set_texture_detail_enabled(true)
        var camera_before: Transform3D = scene.camera.global_transform
        if bool(configuration["rock_pair"]):
            scene.visuals.set_biome_layer_enabled(true)
            scene.visuals.rocks.visible = false
        else:
            scene.visuals.set_biome_layer_enabled(false)
        await _shot(scene,directory.path_join(photos[ix]))
        ix += 1
        if bool(configuration["rock_pair"]):
            scene.visuals.rocks.visible = true
        else:
            scene.visuals.set_biome_layer_enabled(true)
        await _shot(scene,directory.path_join(photos[ix]))
        ix += 1
        if camera_before != scene.camera.global_transform:
            failures.append("camera changed within A/B pair")
    if frames.size() == 6:
        var shore: float = _pixel_delta(frames[0],frames[1])
        var forest: float = _pixel_delta(frames[2],frames[3])
        var rocks: float = _pixel_delta(frames[4],frames[5])
        print("NATIVE_COAST_ROCK_DELTAS coast=",shore,
            " forest=",forest," rocks=",rocks)
        if shore < 0.8: failures.append("coastal material unchanged")
        if forest < 0.8: failures.append("forest material unchanged")
        if rocks < 0.25: failures.append("highland outcrops not visible")
    else:
        failures.append("native 6-frame screenshot sequence incomplete")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("NATIVE_COAST_ROCK_CAPTURE_PASS frames=6")
        quit(0)
    else:
        for failure in failures:
            push_error("NATIVE_COAST_ROCK_CAPTURE_FAIL: "+failure)
        quit(1)
