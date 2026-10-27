extends SceneTree
## Native engine regression for standalone art-only biome slice.
const TerrainStudy = preload("res://terrain.gd")
const ShipStudy = preload("res://ship.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    # SceneTree._initialize occurs before child ready callbacks; defer the test.
    call_deferred("_run_tests")

func _run_tests() -> void:
    _check(TerrainStudy.classify(-60.0, 0.0) == "submerged", "water classification")
    _check(TerrainStudy.classify(-2.0, 0.0) == "coast", "shore classification")
    _check(TerrainStudy.classify(30.0, 0.0) == "forest", "forest classification")
    _check(TerrainStudy.sample_height(76.0, 0.0) > TerrainStudy.sample_height(20.0, 0.0), "highland elevation")
    # The mountain study must add actual relief while retaining the original
    # coastal and landing-field samples. Reference values are from parent
    # 7502ab5 before the candidate landform change.
    _check(TerrainStudy.sample_height(72.0, -12.0) > 18.5, "central summit gains visible relief")
    _check(TerrainStudy.sample_height(70.0, 18.0) > 15.0, "second summit gains visible relief")
    for reference in [
        Vector3(-2.0, -0.0931680654853998, 0.0),
        Vector3(6.0, 2.0010412668318267, -18.0),
        Vector3(15.0, 2.8800466896456447, -7.0),
        Vector3(30.0, 4.299302457100411, 0.0),
        Vector3(50.0, 7.276565629040649, 0.0)
    ]:
        _check(absf(TerrainStudy.sample_height(reference.x, reference.z) - reference.y) < 0.0001,
            "coast and landing-region elevation preserved")
    for x in range(50, 88, 2):
        for z in range(-44, 34, 3):
            var h: float = TerrainStudy.sample_height(float(x), float(z))
            var next_x: float = TerrainStudy.sample_height(float(x) + 0.5, float(z))
            var next_z: float = TerrainStudy.sample_height(float(x), float(z) + 0.5)
            _check(is_finite(h) and absf(next_x - h) < 1.5 and absf(next_z - h) < 1.5,
                "bounded, continuous sampled highland relief")

    # Fractal study is compared with fixed parent heights, not an invented
    # second terrain sampler. Variation must remain bounded and repeatable.
    var parent_heights := [
        Vector3(64.0, 16.727040717244066, -10.0),
        Vector3(68.0, 15.346824621341234, -18.0),
        Vector3(76.0, 13.669936163110084, 5.0),
        Vector3(78.0, 17.759769892416806, -30.0),
        Vector3(70.0, 18.471818713437827, 18.0)
    ]
    var strongest_change: float = 0.0
    for reference in parent_heights:
        var value: float = TerrainStudy.sample_height(reference.x, reference.z)
        var delta_from_parent: float = absf(value - reference.y)
        strongest_change = maxf(strongest_change, delta_from_parent)
        _check(is_finite(value) and delta_from_parent <= 1.81,
            "fractal elevation remains bounded against parent")
        _check(is_equal_approx(value, TerrainStudy.sample_height(reference.x, reference.z)),
            "fractal elevation repeats at identical coordinates")
    _check(strongest_change > 0.12, "fractal detail changes highland elevations")

    for ix in [-4, -1, 0, 2]:
        for iz in [-3, 0, 2]:
            for i in range(7):
                # Every low-detail tile edge must meet its high-detail endpoint.
                var a: Vector3 = TerrainStudy.grid_point(ix, iz, 6, i, 0)
                var b: Vector3 = TerrainStudy.grid_point(ix, iz, 12, i * 2, 0)
                _check(a.distance_to(b) < 0.00001, "shared edge at %s/%s/%s" % [ix, iz, i])
    var terrain = TerrainStudy.new()
    get_root().add_child(terrain)
    _check(terrain.chunk_count() == 64, "bounded 64-chunk scene")
    # Engine is clockwise-front: a top-facing triangle has negative winding
    # cross.y here. This regression catches missing terrain seen in real frames.
    var probe_mesh: ArrayMesh = terrain._tile_mesh(0, 0, 6)
    var geometry: Array = probe_mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = geometry[Mesh.ARRAY_VERTEX]
    var oriented: Vector3 = (vertices[1] - vertices[0]).cross(vertices[2] - vertices[0])
    _check(oriented.y < 0.0, "terrain CW front-face is visible from above")
    terrain.update_detail(Vector3(0.0, 13.0, 0.0), 0.5)
    _check(terrain.visible_tiles > 0 and terrain.visible_tiles <= 64, "bounded visibility")
    _check(terrain.detailed_tiles > 0, "high-detail promotion")
    var ship = ShipStudy.new()
    get_root().add_child(ship)
    await process_frame
    _check(ship.get_child_count() >= 10, "ship silhouette has authored parts")
    ship.set_motion(5.0, true)
    _check(ship.rotation == Vector3.ZERO, "reduced-motion stillness")
    terrain.queue_free()
    ship.queue_free()
    call_deferred("_finish")

func _check(ok: bool, label_name: String) -> void:
    checks += 1
    if not ok:
        failures.append(label_name)

func _finish() -> void:
    if failures.is_empty():
        print("GODOT_FLIGHT_SLICE_NATIVE_PASS checks=", checks)
        quit(0)
    else:
        for message in failures:
            push_error("GODOT_FLIGHT_SLICE_FAIL: " + message)
        quit(1)
