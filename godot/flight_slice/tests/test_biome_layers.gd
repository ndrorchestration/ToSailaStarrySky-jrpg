extends SceneTree
## Native macro-biome and shared-level shoreline art contract.
## Visual-only: no landscape erosion, collision reauthoring or world progression.
const Study = preload("res://main.tscn")
var faults: Array[String] = []
var count: int = 0

func verify(ok: bool, label: String) -> void:
    count += 1
    if not ok: faults.append(label)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var visuals = scene.visuals
    var land = visuals.land
    var water = visuals.water
    var macro: Texture2D = visuals.texture_resources["biome"]
    verify(macro != null, "region mask PNG imported")
    if macro != null:
        verify(macro.get_size() == Vector2(128, 128), "fixed 128px macro texture")
        var data: Image = macro.get_image()
        verify(data != null, "native image decode")
        if data != null:
            verify(data.get_pixel(22, 31) != data.get_pixel(72, 90),
                "actual nonflat biome channel pixels")
    verify(land.get_shader_parameter("biome_macrodetail") == macro,
        "ground uses original biome regional PNG")
    verify(water.get_shader_parameter("biome_macrodetail") == macro,
        "water shares identical regional source image")
    verify(visuals.biome_layer_enabled, "J defaults on")
    verify(is_equal_approx(float(land.get_shader_parameter(
        "biome_layer_strength")), 0.78), "macro default strength bounded")
    verify(is_equal_approx(float(water.get_shader_parameter(
        "biome_layer_strength")), 0.78), "water regional strength synchronized")
    verify(is_equal_approx(float(land.get_shader_parameter(
        "shoreline_wet_strength")), 0.78), "wet sand grade synchronized")
    verify(is_equal_approx(float(land.get_shader_parameter(
        "sea_surface_elevation")), float(water.get_shader_parameter(
        "sea_surface_elevation"))), "land/water refer to one authoritative sea height")
    var baseline_ship: Vector3 = scene.ship.position
    var baseline_clock: float = scene._clock
    var terrain_sample: float = scene.terrain.sample_height(
        baseline_ship.x,baseline_ship.z)
    for enabled in [false,true,false,true]:
        visuals.set_biome_layer_enabled(enabled)
        var expected: float = 0.78 if enabled else 0.0
        verify(is_equal_approx(float(land.get_shader_parameter(
            "biome_layer_strength")), expected), "J ground toggles from exact state")
        verify(is_equal_approx(float(water.get_shader_parameter(
            "biome_layer_strength")), expected), "J water toggles from exact state")
        verify(is_equal_approx(float(land.get_shader_parameter(
            "shoreline_wet_strength")), expected), "J wet sand toggles from exact state")
    visuals.set_low_quality(true)
    for enabled in [true,false,true]:
        visuals.set_biome_layer_enabled(enabled)
        verify(is_zero_approx(float(land.get_shader_parameter(
            "biome_layer_strength"))), "V always hides regional cost")
        verify(is_zero_approx(float(water.get_shader_parameter(
            "biome_layer_strength"))), "V hides regional ocean")
        verify(is_zero_approx(float(land.get_shader_parameter(
            "shoreline_wet_strength"))), "V hides wet sand")
    visuals.set_low_quality(false)
    verify(is_equal_approx(float(land.get_shader_parameter(
        "biome_layer_strength")),0.78), "V restore resumes J state")
    visuals.set_texture_detail_enabled(false)
    verify(is_equal_approx(float(land.get_shader_parameter(
        "biome_layer_strength")),0.78), "K fine textures independent of J regional art")
    verify(is_zero_approx(float(land.get_shader_parameter(
        "texture_detail_strength"))), "K still suppresses grain")
    visuals.set_biome_layer_enabled(false)
    verify(is_zero_approx(float(land.get_shader_parameter(
        "biome_layer_strength"))), "J independent of K grain")
    visuals.set_texture_detail_enabled(true)
    verify(is_equal_approx(float(land.get_shader_parameter(
        "texture_detail_strength")),0.68), "K restores independent micro grain")
    verify(scene.ship.position == baseline_ship, "biome visuals cannot move ship")
    verify(scene._clock == baseline_clock, "biome visuals cannot advance clock")
    verify(is_equal_approx(scene.terrain.sample_height(
        baseline_ship.x,baseline_ship.z),terrain_sample),
        "regional colors cannot change collision height")
    verify(scene.terrain.chunk_count() == 64, "no generated terrain chunks")
    verify(visuals.rain.instances.multimesh.instance_count == 112,
        "no additional atmospheric geometry budget")
    scene.queue_free()
    await process_frame
    if faults.is_empty():
        print("GODOT_BIOME_MACRO_PASS checks=",count)
        quit(0)
    else:
        for fault in faults: push_error("GODOT_BIOME_MACRO_FAIL: "+fault)
        quit(1)
