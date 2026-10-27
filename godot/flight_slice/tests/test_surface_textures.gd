extends SceneTree
## Native contract for original committed PNG assets and material bindings.
## Textures may alter pixels but must not alter mesh, physics or Five Lights.
const Scene = preload("res://main.tscn")
const Mood = preload("res://environment_mood.gd")
var failed: Array[String] = []
var checks: int = 0

func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failed.append(message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene = Scene.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var visuals = scene.visuals
    var textures: Dictionary = visuals.texture_resources
    check(textures.size() == 3, "exactly three independent PNG microtextures")
    var sampler_bindings: Array = [
        ["terrain", visuals.land, "terrain_microdetail"],
        ["foliage", visuals.foliage, "foliage_microdetail"],
        ["foliage", visuals.broadleaf, "foliage_microdetail"],
        ["foliage", visuals.understory, "foliage_microdetail"],
        ["water", visuals.water, "water_ripple_detail"]
    ]
    for record in sampler_bindings:
        check(record[1].get_shader_parameter(record[2]) == textures[record[0]],
            "material sampler correctly bound: " + record[2])
    for key in ["terrain", "foliage", "water"]:
        var tex: Texture2D = textures[key]
        check(tex != null, "native imported PNG exists: " + key)
        if tex == null:
            continue
        check(tex.get_size() == Vector2(128, 128),
            "texture is bounded 128px repeatable PNG: " + key)
        var image: Image = tex.get_image()
        check(image != null, "native Godot decoded PNG: " + key)
        if image != null:
            var first: Color = image.get_pixel(13, 19)
            var other: Color = image.get_pixel(79, 83)
            check(first != other, "texture contains nonflat authentic pixel data: " + key)
            check(first.a > 0.99 and other.a > 0.99,
                "no unexpected translucent depth sorting: " + key)
    check(visuals.texture_detail_enabled, "K texture mode defaults ON")
    for material in [visuals.land, visuals.foliage, visuals.broadleaf,
            visuals.understory, visuals.water]:
        check(is_equal_approx(float(material.get_shader_parameter(
            "texture_detail_strength")), 0.68), "default bounded grain strength")
    visuals.set_texture_detail_enabled(false)
    for material in [visuals.land, visuals.foliage, visuals.broadleaf,
            visuals.understory, visuals.water]:
        check(is_zero_approx(float(material.get_shader_parameter(
            "texture_detail_strength"))), "K off enables baseline A/B comparison")
    visuals.set_low_quality(true)
    visuals.set_texture_detail_enabled(true)
    for material in [visuals.land, visuals.foliage, visuals.broadleaf,
            visuals.understory, visuals.water]:
        check(is_zero_approx(float(material.get_shader_parameter(
            "texture_detail_strength"))), "V always suppresses fine texel sampling")
    visuals.set_low_quality(false)
    check(is_equal_approx(float(visuals.land.get_shader_parameter(
        "texture_detail_strength")), 0.68), "high-quality grain restored")
    var night: Dictionary = Mood.sample(3, 3, true)
    check(float(night["sun_visibility"]) == 0.0,
        "increased moonlike visibility does not re-enable solar disk")
    check(float(night["key_energy"]) >= 0.19,
        "night main silhouette light retained through storm")
    check(float(night["fill_energy"]) >= 0.30,
        "night rim fill survives storm")
    check(float(night["fog_density"]) <= 0.013,
        "storm-night fog remains bounded")
    var preset_clock: float = scene._clock
    var ship_position: Vector3 = scene.ship.position
    var clearance: float = scene.terrain.sample_height(
        ship_position.x, ship_position.z)
    visuals.set_environment_look(3, 3, true)
    visuals.set_texture_detail_enabled(false)
    visuals.set_texture_detail_enabled(true)
    check(scene._clock == preset_clock, "material art cannot advance world time")
    check(scene.ship.position == ship_position, "material art cannot move ship")
    check(is_equal_approx(scene.terrain.sample_height(
        ship_position.x, ship_position.z), clearance),
        "material art cannot alter terrain elevation")
    check(scene.terrain.chunk_count() == 64,
        "texture art cannot add or subtract terrain chunks")
    check(visuals.rain.instances.multimesh.instance_count == 112,
        "same weather instance budget despite textured environment")
    scene.queue_free()
    await process_frame
    if failed.is_empty():
        print("GODOT_SURFACE_TEXTURE_PASS checks=", checks)
        quit(0)
    else:
        for problem in failed:
            push_error("GODOT_SURFACE_TEXTURE_FAIL: " + problem)
        quit(1)
