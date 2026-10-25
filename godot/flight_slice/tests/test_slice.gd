extends SceneTree
## Native engine regression for standalone art-only biome slice.
const TerrainStudy = preload("res://terrain.gd")
const ShipStudy = preload("res://ship.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    _check(TerrainStudy.classify(-60.0, 0.0) == "submerged", "water classification")
    _check(TerrainStudy.classify(-2.0, 0.0) == "coast", "shore classification")
    _check(TerrainStudy.classify(30.0, 0.0) == "forest", "forest classification")
    _check(TerrainStudy.sample_height(76.0, 0.0) > TerrainStudy.sample_height(20.0, 0.0), "highland elevation")
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
    terrain.update_detail(Vector3(0.0, 13.0, 0.0), 0.5)
    _check(terrain.visible_tiles > 0 and terrain.visible_tiles <= 64, "bounded visibility")
    _check(terrain.detailed_tiles > 0, "high-detail promotion")
    var ship = ShipStudy.new()
    get_root().add_child(ship)
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
