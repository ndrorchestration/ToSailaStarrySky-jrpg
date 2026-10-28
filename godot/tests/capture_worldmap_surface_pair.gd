extends SceneTree
## Genuine Godot GL framebuffer A/B of two actual adjacent spherical tiles.
## Off/on are the same camera, lights, terrain geometry, render engine and clock.
const Study = preload("res://scripts/planetary/worldmap_surface_patch_review.gd")
const OUT := "res://review-evidence/"
var failed: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _capture() -> Image:
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _count_differences(a: Image, b: Image) -> int:
    var changed := 0
    for y in range(60,585,2):
        for x in range(40,920,2):
            var ca := a.get_pixel(x,y)
            var cb := b.get_pixel(x,y)
            if maxf(maxf(absf(ca.r-cb.r),absf(ca.g-cb.g)),
                    absf(ca.b-cb.b)) > 2.0/255.0:
                changed += 1
    return changed

func _warmup() -> void:
    for frame in range(5):
        await process_frame

func _run() -> void:
    root.size = Vector2i(960,640)
    var lighting_root := Node3D.new()
    lighting_root.name = "SphericalMaterialReadOnlyReview"
    root.add_child(lighting_root)
    var environment := WorldEnvironment.new()
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color(0.09,0.14,0.21)
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color(0.7,0.75,0.82)
    environment.environment.ambient_light_energy = 0.8
    lighting_root.add_child(environment)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-43,-27,0)
    sun.light_energy = 1.5
    lighting_root.add_child(sun)
    if DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(OUT)) != OK:
        push_error("GODOT_PLANETARY_MATERIAL_CAPTURE_FAIL directory")
        quit(1)
        return
    for kind in ["snow","wet_ground"]:
        var stage: Node3D = Study.new()
        lighting_root.add_child(stage)
        if not stage.make_pair(kind):
            failed.append("missing actual spherical terrain sample for "+kind)
            stage.queue_free()
            continue
        stage.make_camera()
        await _warmup()
        var original: Image = await _capture()
        stage.effect(true)
        await _warmup()
        var improved: Image = await _capture()
        var changed := _count_differences(original,improved)
        if changed < 180:
            failed.append("%s visual difference too small: %d" % [kind,changed])
        if original.get_pixel(0,0) != improved.get_pixel(0,0):
            failed.append("%s background changed, not isolated to terrain" % kind)
        for pass_info in [
            {"name":"off","img":original},
            {"name":"on","img":improved}
        ]:
            var target: String = OUT + "planetary-surface-" + kind + "-" + \
                pass_info["name"] + "-native-960x640.png"
            if pass_info["img"].get_size() != Vector2i(960,640) or \
                    pass_info["img"].save_png(target) != OK:
                failed.append("invalid native framebuffer: "+target)
        print("GODOT_PLANETARY_MATERIAL_AB_FRAME kind=",kind,
            " changed_sample_pixels=",changed,
            " high_quality=true real_spherical_tiles=2")
        stage.queue_free()
        await process_frame
    if failed.is_empty():
        print("GODOT_PLANETARY_MATERIAL_AB_PASS actual_Godot_GL=true cases=2 frames=4 NO_CANON")
        quit(0)
    else:
        for issue in failed:
            push_error("GODOT_PLANETARY_MATERIAL_CAPTURE_FAIL: "+issue)
        quit(1)
