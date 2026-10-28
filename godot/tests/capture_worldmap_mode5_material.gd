extends SceneTree
## Mode-5 ACTUAL in-scene geodesic flight camera; HUD hidden only for
## material-isolation captures, not a custom or synthetic studio camera.
const Scene = preload("res://scenes/planetary_worldmap.tscn")
const Study = preload("res://scripts/planetary/worldmap_surface_patch_review.gd")
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")
const OUT := "res://review-evidence/"
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _frame() -> Image:
    await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _warmup(count: int) -> void:
    for n in range(count):
        await process_frame

func _different(a: Image, b: Image) -> int:
    var count := 0
    for y in range(110,545,2):
        for x in range(20,940,2):
            var aa: Color = a.get_pixel(x,y)
            var bb: Color = b.get_pixel(x,y)
            if maxf(maxf(absf(aa.r-bb.r),absf(aa.g-bb.g)),
                    absf(aa.b-bb.b)) > 2.0/255.0:
                count += 1
    return count

func _save(kind: String, variant: String, img: Image) -> void:
    var target: String = OUT+"worldmap-mode5-"+kind+"-"+variant+"-960x640.png"
    if img.get_size() != Vector2i(960,640) or img.save_png(target) != OK:
        failures.append("native image invalid or failed to write: "+target)

func _run() -> void:
    root.size = Vector2i(960,640)
    var world := Scene.instantiate()
    root.add_child(world)
    await _warmup(3)
    world.set_process(false)
    var overlay := world.get_node("WorldMapUI") as CanvasLayer
    overlay.visible = false
    var stream := world.get_node("NativeCubedSphereTerrain") as Node3D
    if DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(OUT)) != OK:
        push_error("GODOT_MODE5_MATERIAL_CAPTURE_FAIL mkdir")
        quit(1)
        return
    for kind in ["wet_ground","snow"]:
        var pair: Array[Dictionary] = Study.find_pair(kind)
        if pair.size() != 2:
            failures.append("unable to locate native biome fixture "+kind)
            continue
        var center: Vector2 = Tiles.tile_center(pair[0])
        var state: Dictionary = world.call("snapshot")
        state["flight"]["latDeg"] = center.x
        state["flight"]["lonDeg"] = center.y
        state["flight"]["headingDeg"] = 90.0
        state["flight"]["altitudeKm"] = 2.0
        state["mode"] = "tiles"
        world.call("_apply_state",state)
        world.call("_refresh_chart")
        world.call("_update_view")
        await _warmup(23)
        var baseline: Image = await _frame()
        var accepted: bool = world.call("set_surface_review",kind)
        var status: Dictionary = stream.call("stats")
        if not accepted or str(status["review_key"]) == "":
            failures.append("no eligible active mode-5 tile for "+kind)
            continue
        await _warmup(12)
        var enhanced: Image = await _frame()
        var delta: int = _different(baseline,enhanced)
        print("GODOT_MODE5_MATERIAL_PIXEL_DELTA kind=",kind,
            " changed_sample_pixels=",delta,
            " tile=",str(status["review_key"]),
            " real_flight_camera=true")
        _save(kind,"default",baseline)
        _save(kind,"review",enhanced)
        if delta < 100:
            failures.append("candidate not visibly contributing in flight camera: "+kind)
        # The two captures differ only by actual one-tile shader and never
        # HUD text, a new camera, a second WorldEnvironment or terrain shape.
        if baseline.get_pixel(0,0) != enhanced.get_pixel(0,0):
            failures.append("background unexpectedly altered: "+kind)
        world.call("set_surface_review","")
        await _warmup(8)
        var restored: Image = await _frame()
        if _different(baseline,restored) > 35:
            failures.append("original tile image did not restore: "+kind)
    world.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_MODE5_MATERIAL_NATIVE_PASS cases=2 frames=4 original_fallback=true NONCANON")
        quit(0)
    else:
        for failure in failures:
            push_error("GODOT_MODE5_MATERIAL_CAPTURE_FAIL: "+failure)
        quit(1)
