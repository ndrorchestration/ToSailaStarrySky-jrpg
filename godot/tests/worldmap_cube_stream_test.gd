extends SceneTree
## Real native mesh-stream regression: six-face topology, UV seams, horizon
## budget, cache reuse, and 3D world-frame movement. No runtime/art admission.
const Geo = preload("res://scripts/planetary/planetary_geometry.gd")
const Tiles = preload("res://scripts/planetary/planetary_tiles.gd")
const Meshes = preload("res://scripts/planetary/worldmap_cube_tile_mesh.gd")
const Stream = preload("res://scripts/planetary/worldmap_cube_stream.gd")
var failed: Array[String] = []

func check(ok: bool, label: String) -> void:
    if not ok:
        failed.append(label)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var center_tile := Tiles.tile_at(20.0,12.0,5)
    var right := Tiles.neighbor(center_tile,1,0)
    check(str(center_tile["face"]) == str(right["face"]),"same-face adjacent address")
    for i in range(13):
        var seam1 := Meshes.sample_border(center_tile,12,i)
        var seam2 := Meshes.sample_border(right,0,i)
        check(seam1.distance_to(seam2) < 0.0000001,"no face-local cracks at shared edge")
    for lat in [-89.8,5.0,70.0]:
        for lon in [-179.99,-45.0,130.0,179.99]:
            var tile := Tiles.tile_at(lat,lon,5)
            var mesh: Dictionary = Meshes.build(tile,8)
            check(mesh["terrain"] is ArrayMesh,"real native ArrayMesh exists")
            check(int(mesh["vertex_count"]) == 81,"fixed mesh vertex budget")
            check(int(mesh["land_cells"]) + int(mesh["water_cells"]) == 64,
                    "each cube tile covers every grid cell")
            var points: PackedVector3Array = (mesh["terrain"] as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            check(points.size() == 384,"two triangles per terrain quad")
            for q in [points[0],points[points.size()/2],points[points.size()-1]]:
                check((q as Vector3).is_finite(),"finite terrain vertices at seams/poles")
                check(absf((q as Vector3).length()-12.0) < 0.03,"tile vertices stay on planet")
    var renderer: Node3D = Stream.new()
    root.add_child(renderer)
    renderer.visible = true
    var observer := Geo.position(30.0,140.0,2.0)
    var initial: Dictionary = renderer.call("refresh",observer)
    check(int(initial["visible"]) >= 1 and int(initial["visible"]) <= 32,
            "horizon-backed visible mesh budget")
    check(int(initial["cache_size"]) <= 64,"mesh cache bound")
    check(int(initial["generated"]) == int(initial["visible"]),"all first-pass tiles generated")
    var first_keys: Array[String] = renderer.call("active_keys")
    var same: Dictionary = renderer.call("refresh",observer)
    check(renderer.call("active_keys") == first_keys,"deterministic tile identity")
    check(int(same["generated"]) == int(initial["generated"]),"revisit does not rebuild tile meshes")
    var observer2 := Geo.position(30.0,142.0,2.0)
    var moved: Dictionary = renderer.call("refresh",observer2)
    check(int(moved["visible"]) <= 32 and int(moved["cache_size"]) <= 64,
            "relocation preserves bounded active/cache tiles")
    check(int(moved["released"]) > 0,"old horizon tiles removed after long movement")
    var observer3 := Geo.position(89.85,-179.9,2.0)
    var polar: Dictionary = renderer.call("refresh",observer3)
    check(int(polar["visible"]) <= 32,"near-pole live tiles remain bounded")
    var camera_a: Dictionary = Stream.flight_camera({
            "latDeg":30.0,"lonDeg":140.0,"altitudeKm":2.0,"headingDeg":90.0})
    var camera_b: Dictionary = Stream.flight_camera({
            "latDeg":30.02,"lonDeg":140.1,"altitudeKm":2.0,"headingDeg":90.0})
    check((camera_a["eye"] as Vector3).is_finite(),"global cubed-sphere camera finite")
    check((camera_a["up"] as Vector3).dot((camera_a["forward"] as Vector3)) < 0.001,
            "flight forward remains tangent to sphere")
    check((camera_a["eye"] as Vector3).distance_to(camera_b["eye"]) > 0.015,
            "camera travels through actual global sphere coordinates")
    renderer.queue_free()
    await process_frame
    if failed.is_empty():
        print("GODOT_WORLDMAP_CUBE_STREAM_PASS: real tile meshes, seams, 6-face samples, bounded LRU, continuous global flight frame")
        quit(0)
    else:
        push_error("GODOT_WORLDMAP_CUBE_STREAM_FAIL: "+", ".join(failed))
        quit(1)
