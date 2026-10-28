extends SceneTree
## Reproducible native GL A/B and grazing view of the detached dune geometry.
## Other flight_slice screenshot marker counts remain exactly unchanged.
const DuneStudy = preload("res://dune_study.gd")
var failed: bool = false

func _initialize() -> void:
    call_deferred("_capture")

func _frame() -> Image:
    for step in range(7):
        await process_frame
        await RenderingServer.frame_post_draw
    return root.get_texture().get_image()

func _difference(a: Image, b: Image) -> int:
    var changes: int = 0
    for y in range(110, 640, 2):
        for x in range(0, 960, 2):
            if a.get_pixel(x, y) != b.get_pixel(x, y):
                changes += 1
    return changes

func _save(frame: Image, filename: String) -> void:
    var file: String = ProjectSettings.globalize_path(
        "res://evidence/dune-review/" + filename)
    if frame == null or frame.get_size() != Vector2i(960,640) \
            or frame.save_png(file) != OK:
        failed = true
        push_error("NATIVE_DUNE_CAPTURE_FAIL: " + filename)
    else:
        print("NATIVE_DUNE_CAPTURE: ", filename, " 960x640 NONCANON")

func _capture() -> void:
    var folder: String = ProjectSettings.globalize_path("res://evidence/dune-review")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("NATIVE_DUNE_FOLDER_FAIL")
        quit(1)
        return
    var world := Node3D.new()
    world.name = "DuneOpticsReview"
    root.add_child(world)
    var dune := DuneStudy.new()
    world.add_child(dune)
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.36, 0.49, 0.57)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.65, 0.73, 0.82)
    environment.ambient_light_energy = 0.63
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    var atmosphere := WorldEnvironment.new()
    atmosphere.environment = environment
    world.add_child(atmosphere)
    var key := DirectionalLight3D.new()
    key.light_color = Color(1.0, 0.83, 0.64)
    key.light_energy = 1.18
    world.add_child(key)
    key.look_at(-DuneStudy.SUN_DIRECTION.normalized(), Vector3.UP)
    var camera := Camera3D.new()
    world.add_child(camera)
    camera.current = true
    camera.fov = 58.0
    camera.far = 140.0
    camera.position = Vector3(-6.0, 11.0, 25.0)
    camera.look_at(Vector3(0.0, 2.1, -1.0), Vector3.UP)
    dune.set_optics_strength(0.0)
    var plain: Image = await _frame()
    dune.set_optics_strength(1.0)
    var optical: Image = await _frame()
    _save(plain, "dune-plain.png")
    _save(optical, "dune-optics.png")
    var difference: int = _difference(plain,optical)
    # A full-screen dune can occupy far more area than the coastal-sand A/B.
    # Measure *visible sand coverage* rather than guessing an upper pixel
    # bound. Original dunescape is warm R>B; clear-sky pixels have B>R.
    var sand_pixels: int = 0
    var sky_drift: int = 0
    var total_sand_abs: float = 0.0
    for y in range(110, 640, 2):
        for x in range(0, 960, 2):
            var a: Color = plain.get_pixel(x,y)
            var sample_b: Color = optical.get_pixel(x,y)
            if a.r > a.b:
                sand_pixels += 1
                total_sand_abs += absf(a.r-sample_b.r)+absf(a.g-sample_b.g)+absf(a.b-sample_b.b)
            elif a != sample_b:
                sky_drift += 1
    var changed_fraction: float = float(difference) / float(maxi(sand_pixels, 1))
    var mean_sand_delta: float = total_sand_abs / float(maxi(sand_pixels * 3, 1))
    print("NATIVE_DUNE_OPTICS_PAIR_DELTA pixels=", difference)
    print("NATIVE_DUNE_SAND_COVERAGE pixels=", sand_pixels,
        " changed_fraction=", changed_fraction,
        " mean_abs_channel=", mean_sand_delta,
        " sky_drift=", sky_drift)
    if sand_pixels < 1500 or changed_fraction < 0.10 \
            or changed_fraction > 1.0 or sky_drift != 0 \
            or mean_sand_delta > 0.12:
        failed = true
        push_error("NATIVE_DUNE_OPTICS_PAIR_UNBOUNDED")
    dune.set_low_quality(true)
    dune.set_optics_strength(0.0)
    var low_old: Image = await _frame()
    dune.set_optics_strength(1.0)
    var low_new: Image = await _frame()
    var low_difference: int = _difference(low_old,low_new)
    print("NATIVE_DUNE_OPTICS_LOW_DELTA pixels=", low_difference)
    if low_difference != 0:
        failed = true
        push_error("NATIVE_DUNE_OPTICS_LOW_QUALITY_NOT_IDENTICAL")
    dune.set_low_quality(false)
    camera.position = Vector3(13.0, 5.8, 27.0)
    camera.look_at(Vector3(0.0,2.0,-1.0), Vector3.UP)
    var grazing: Image = await _frame()
    _save(grazing,"dune-grazing.png")
    print("NATIVE_DUNE_REVIEW_PASS geometry=standalone collision=none")
    world.queue_free()
    await process_frame
    quit(1 if failed else 0)
