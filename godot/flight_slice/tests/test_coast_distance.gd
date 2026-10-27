extends SceneTree
## Verify signed distance from the identical world-height field sampled by
## the water/terrain shaders. Proximity art cannot create a second coastline.
const Study = preload("res://main.tscn")
const Coasts = preload("res://coast_distance.gd")
const Terrain = preload("res://terrain.gd")
var failures: Array[String] = []
var checks: int = 0

func assert_true(value: bool, name: String) -> void:
    checks += 1
    if not value: failures.append(name)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var sample := Image.create(9,9,false,Image.FORMAT_RF)
    # Tiny analytic case: an exactly vertical coast between x=3 and x=4.
    for y in range(9):
        for x in range(9):
            sample.set_pixel(x,y,Color(-2.0 if x < 4 else 3.0,0.0,0.0))
    var analytic: Image = Coasts.bake(sample,0.0,9.0)
    assert_true(analytic != null, "signed field bakes finite square RF images")
    if analytic != null:
        assert_true(is_zero_approx(analytic.get_pixel(3,4).r),
            "water-side exact boundary is zero")
        assert_true(is_zero_approx(analytic.get_pixel(4,4).r),
            "land-side exact boundary is zero")
        assert_true(analytic.get_pixel(2,4).r < -0.5,
            "water interior remains negative")
        assert_true(analytic.get_pixel(5,4).r > 0.5,
            "land interior remains positive")
        assert_true(analytic.get_pixel(8,4).r > analytic.get_pixel(5,4).r,
            "far inland remains farther than shoreline")
        assert_true(analytic.get_pixel(2,0).r == analytic.get_pixel(2,8).r,
            "straight coast invariant to latitude")
        assert_true(is_equal_approx(analytic.get_pixel(5,4).r,1.0),
            "distance units reflect authoritative meter span")
    assert_true(Coasts.bake(null,0.0,260.0) == null,
        "missing terrain height data fails closed")
    assert_true(Coasts.bake(sample,0.0,NAN) == null,
        "nonfinite span cannot create false shoreline")
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var visuals = scene.visuals
    assert_true(visuals.coastal_distance != null, "scene bakes real coastal field")
    assert_true(visuals.land.get_shader_parameter(
        "coast_distance_field") == visuals.coastal_distance,
        "ground uses single source shoreline")
    assert_true(visuals.water.get_shader_parameter(
        "coast_distance_field") == visuals.coastal_distance,
        "ocean shares exact same signed shoreline source")
    if visuals.coastal_distance != null:
        var field: Image = visuals.coastal_distance.get_image()
        assert_true(field.get_size() == Vector2i(256,256),
            "visual shoreline resolution bounded at 256x256")
        # Derive reference samples from authoritative x/z conversion.
        for x in [-36.0,-24.0,-12.0,0.0,10.0,38.0,55.0]:
            for z in [-20.0,0.0,20.0]:
                var px: int = clampi(floori((x+130.0)/260.0*256.0),0,255)
                var py: int = clampi(floori((z+130.0)/260.0*256.0),0,255)
                var signed: float = field.get_pixel(px,py).r
                var source_dry: bool = Terrain.sample_height(x,z) >= Terrain.SEA_LEVEL
                if source_dry:
                    assert_true(signed >= -0.001, "inland cannot be underwater in mask")
                else:
                    assert_true(signed <= 0.001, "water cannot be inland in mask")
                assert_true(absf(signed) <= Coasts.MAX_DISTANCE_METERS+0.001,
                    "bounded signed coastal distance")
    assert_true(is_equal_approx(float(visuals.land.get_shader_parameter(
        "sea_surface_elevation")), Terrain.SEA_LEVEL),
        "terrain sea height identity")
    assert_true(is_equal_approx(float(visuals.water.get_shader_parameter(
        "sea_surface_elevation")), Terrain.SEA_LEVEL),
        "ocean sea height identity")
    var ship_location: Vector3 = scene.ship.position
    var clock: float = scene._clock
    var geometry: float = Terrain.sample_height(ship_location.x,ship_location.z)
    visuals.set_biome_layer_enabled(false)
    visuals.set_biome_layer_enabled(true)
    assert_true(ship_location == scene.ship.position,
        "shoreline presentation never changes flight position")
    assert_true(clock == scene._clock,
        "shoreline presentation never advances world time")
    assert_true(is_equal_approx(geometry,Terrain.sample_height(
        ship_location.x,ship_location.z)),
        "shoreline presentation never changes terrain")
    assert_true(scene.terrain.chunk_count() == 64,
        "terrain LOD/chunks untouched")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_COAST_DISTANCE_PASS checks=", checks)
        quit(0)
    else:
        for fail in failures: push_error("GODOT_COAST_DISTANCE_FAIL: "+fail)
        quit(1)
