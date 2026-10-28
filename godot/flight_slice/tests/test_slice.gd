extends SceneTree
## Native engine regression for standalone art-only biome slice.
const TerrainStudy = preload("res://terrain.gd")
const ShipStudy = preload("res://ship.gd")
const ForedeckStudy = preload("res://ship_foredeck.gd")
const GeodesicBridge = preload("res://ship_geodesic_bridge.gd")
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
    terrain.update_detail(Vector3(38.0, 32.0, 28.0), 1.0)
    _check_mixed_edges(terrain)
    _check_stitched_reference(terrain)
    # Move across detail bands and return, exercising promotion, demotion,
    # neighbor-mask changes and the return to earlier views.
    for observer in [Vector3(0.0, 20.0, 0.0), Vector3(70.0, 30.0, -20.0),
            Vector3(-25.0, 15.0, 12.0), Vector3(38.0, 32.0, 28.0)]:
        terrain.update_detail(observer, 1.0)
        _check_mixed_edges(terrain)


    var ship = ShipStudy.new()
    get_root().add_child(ship)
    await process_frame
    _check(ship.get_child_count() >= 10, "ship silhouette has authored parts")
    var hull: MeshInstance3D = ship.get_node("LongHull")
    _check(hull.mesh is ArrayMesh, "ship has a shaped original loft hull rather than an elongated primitive")
    var hull_points: PackedVector3Array = hull.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    _check(hull_points.size() >= 500, "ship hull has distinct longitudinal stations")
    var bridge = ship.get_node("GeodesicBridge") as GeodesicBridge
    _check(bridge != null, "real geodesic glass bridge is mounted on the bow cabin")
    var panes: MeshInstance3D = bridge.get_node("GeodesicGlass")
    var framelines: MeshInstance3D = bridge.get_node("GeodesicFrame")
    var collar: MeshInstance3D = bridge.get_node("BridgeBaseCollar")
    _check(panes.mesh is ArrayMesh and framelines.mesh is ArrayMesh,
        "glazing and structural struts are real authored native mesh buffers")
    var pane_vertices: PackedVector3Array = panes.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    var frame_vertices: PackedVector3Array = framelines.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    _check(bridge.panel_count >= 100 and pane_vertices.size() == 3 * bridge.panel_count,
        "clipped subdivided icosphere generates at least one hundred glass triangles")
    _check(bridge.unique_frame_edges > 120 and
        frame_vertices.size() >= bridge.unique_frame_edges * 15,
        "deduplicated geodesic tessellation frames are real batched struts")
    _check(collar.mesh is ArrayMesh and
        collar.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() >= 200,
        "glass dome has its own continuous brass foot ring")
    _check(panes.material_override is StandardMaterial3D and
        panes.material_override.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA,
        "faceted cabin glazing is genuinely translucent")
    var min_height: float = INF
    var max_height: float = -INF
    var outward: bool = true
    for index in range(0, pane_vertices.size(), 3):
        var p0: Vector3 = pane_vertices[index]
        var p1: Vector3 = pane_vertices[index + 1]
        var p2: Vector3 = pane_vertices[index + 2]
        min_height = minf(min_height, minf(p0.y, minf(p1.y, p2.y)))
        max_height = maxf(max_height, maxf(p0.y, maxf(p1.y, p2.y)))
        var normal: Vector3 = (p1 - p0).cross(p2 - p0)
        if (normal.length_squared() <= 0.000000001
                or normal.dot((p0 + p1 + p2) / 3.0
                    - Vector3.UP * GeodesicBridge.CENTER_Y) <= 0.0):
            outward = false
    _check(min_height >= GeodesicBridge.BASE_Y - 0.0001 and
        max_height > 1.17 and outward,
        "glazing forms an outward-facing clipped upper dome, not a sphere primitive")
    _check(bridge.get_node("BridgeNavigationConsole") is MeshInstance3D and
        bridge.get_node("BridgeHarmonicCompass") is MeshInstance3D,
        "helm instruments exist inside the faceted glass canopy")
    _check(ship.get_node("UpperCabin").position.z > 0.75,
        "solid ivory cabin fairing now sits aft of the glass helm")
    for vane in range(3):
        _check(ship.get_node("VaneMast_%s" % vane).position.z > 0.35,
            "navigation vane stays aft of the clear bow-dome view")

    var deck = ship.get_node("Foredeck") as ForedeckStudy
    _check(deck.get_node("OpenPlatform") is MeshInstance3D,
        "forward open-air observation platform is real native geometry")
    var deck_mesh: ArrayMesh = deck.get_node("OpenPlatform").mesh
    var deck_points: PackedVector3Array = deck_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    _check(deck_points.size() == 6, "bow deck is a tapered two-face quad, not floating label")
    _check((deck_points[1] - deck_points[0]).cross(
        deck_points[2] - deck_points[0]).y < 0.0,
        "deck has visible native Godot upper-facing winding")
    for side in ["Port", "Starboard"]:
        for index in range(3):
            _check(deck.get_node("GuardPost_%s_%s" % [side, index]) is MeshInstance3D,
                "three rail posts visually protect each side of the open bow")
        for index in range(2):
            _check(deck.get_node("Handrail_%s_%s" % [side, index]) is MeshInstance3D,
                "continuous side handrail segment")
    _check(deck.get_node("ProwHandrail") is MeshInstance3D and
        deck.get_node("BoardingLip") is MeshInstance3D,
        "bow safety edge and crew-boarding sill are distinct")
    var hood: Node3D = deck.get_node("WeatherHood")
    var roof: MeshInstance3D = hood.get_node("RainCanopyPanels")
    _check(roof.mesh is ArrayMesh and
        roof.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 12,
        "small four-face weather-only canopy uses tapered geometry")
    for strut in ["RidgeBeam", "PortCanopyRim", "StarboardCanopyRim"]:
        _check(hood.get_node(strut) is MeshInstance3D,
            "weather canopy is visibly framed rather than a solid bubble")
    _check(deck.get_node("WeatherHood").visible == false and
        not deck.is_weather_sheltered(),
        "forward observation deck is ordinarily open")
    ship.set_foredeck_weather_shelter(true)
    _check(deck.is_weather_sheltered() and deck.get_node("WeatherHood").visible,
        "optional normal-weather visual cover can be enabled")
    ship.set_foredeck_weather_shelter(false)
    _check(not deck.is_weather_sheltered() and
        not deck.get_node("WeatherHood").visible,
        "ordinary open-air state restores deterministically")

    for wing_name in ["PortFore", "PortAft", "StarboardFore", "StarboardAft"]:
        var wing_rig: Node3D = ship.get_node("WingRig_" + wing_name)
        _check(wing_rig.get_node("Membrane_" + wing_name) is MeshInstance3D,
            "independently articulated wing membrane " + wing_name)
        _check(wing_rig.get_child_count() == 4,
            "wing structure batches into one membrane and three rib meshes " + wing_name)
        for material_group in ["Brass", "Dark", "Glass"]:
            var rib_batch: MeshInstance3D = wing_rig.get_node(
                material_group + "RibBundle_" + wing_name)
            _check(rib_batch.mesh is ArrayMesh and
                rib_batch.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() >= 72,
                "wing preserves nonempty batched tube geometry " + material_group)
        var membrane: MeshInstance3D = wing_rig.get_node("Membrane_" + wing_name)
        var arrays: Array = membrane.mesh.surface_get_arrays(0)
        var membrane_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        _check(membrane_vertices.size() == 54,
            "cambered membrane has six three-panel subdivisions " + wing_name)
        var peak: float = -INF
        var all_faces_valid: bool = true
        for point in membrane_vertices:
            peak = maxf(peak, point.y)
        for i in range(0, membrane_vertices.size(), 3):
            var area: float = (membrane_vertices[i + 1] - membrane_vertices[i]).cross(
                membrane_vertices[i + 2] - membrane_vertices[i]).length()
            if area < 0.00001 or not is_finite(area):
                all_faces_valid = false
        _check(peak > 0.40 and all_faces_valid,
            "wing camber is genuine nondegenerate 3D mesh " + wing_name)
    _check(ship.get_node("AftTurbine").mesh is CylinderMesh,
        "aft drive is no longer a round primitive sphere")
    _check(ship.get_node("ExhaustCollar").mesh is CylinderMesh and
        ship.get_node("ExhaustThroat").mesh is CylinderMesh and
        ship.get_node("ExhaustGlow").mesh is CylinderMesh,
        "aft drive consists of concentric machined barrel details")
    for index in range(4):
        _check(ship.get_node("CabinRoofBow_Port_%s" % index) is MeshInstance3D and
            ship.get_node("CabinRoofBow_Starboard_%s" % index) is MeshInstance3D,
            "cabin roof has readable repeated panel supports")
    for index in range(3):
        _check(ship.get_node("VaneMast_%s" % index) is MeshInstance3D,
            "three navigation vanes have their own supports")
    for side_name in ["Port", "Starboard"]:
        for index in range(3):
            _check(ship.get_node("HearthWindow_%s_%s" % [side_name, index]) is MeshInstance3D,
                "warm lived-in cabin glazing is present")
    ship.set_motion(5.0, false)
    _check(absf(ship.get_node("WingRig_PortFore").rotation.z) > 0.0001,
        "idle wing flex is visible without reduced motion")
    ship.set_motion(5.0, true)
    _check(ship.rotation == Vector3.ZERO, "reduced-motion stillness")
    for wing_name in ["PortFore", "PortAft", "StarboardFore", "StarboardAft"]:
        _check(is_zero_approx(ship.get_node("WingRig_" + wing_name).rotation.z),
            "reduced motion stops visual wing flex " + wing_name)
    ship.set_landing_gear(true)
    _check(ship.get_node("TouchdownFoot_Port").visible and
        ship.get_node("TouchdownFoot_Starboard").visible,
        "native touchdown study keeps its visual feet")
    ship.set_landing_gear(false)
    _check(not ship.get_node("TouchdownFoot_Port").visible and
        not ship.get_node("TouchdownFoot_Starboard").visible,
        "touchdown feet retract as before")
    terrain.queue_free()
    ship.queue_free()
    call_deferred("_finish")

func _check(ok: bool, label_name: String) -> void:
    checks += 1
    if not ok:
        failures.append(label_name)


# Inspect actual top-surface mesh vertices, not the sampler at matching inputs.
# Skirts follow the top triangles in the vertex buffer and are intentionally
# excluded: they can obscure a gap without making the two surfaces meet.
func _edge_profile(record: Dictionary, vertical: bool, boundary: float) -> Array[Vector2]:
    var mesh_node: MeshInstance3D = record["node"]
    var arrays: Array = mesh_node.mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var segments: int = TerrainStudy.HIGH_SEGMENTS if record["high_selected"] else TerrainStudy.LOW_SEGMENTS
    var positions := {}
    for i in range(6 * segments * segments):
        var v: Vector3 = vertices[i]
        var along: float = v.z if vertical else v.x
        var across: float = v.x if vertical else v.z
        if absf(across - boundary) < 0.0001:
            positions[roundi(along * 100000.0)] = v.y
    var keys: Array = positions.keys()
    keys.sort()
    var profile: Array[Vector2] = []
    for k in keys:
        profile.append(Vector2(float(k) / 100000.0, float(positions[k])))
    return profile

func _profile_height(profile: Array[Vector2], at: float) -> float:
    for i in range(profile.size() - 1):
        var a: Vector2 = profile[i]
        var b: Vector2 = profile[i + 1]
        if at >= a.x - 0.0001 and at <= b.x + 0.0001:
            return lerpf(a.y, b.y, clampf((at - a.x) / (b.x - a.x), 0.0, 1.0))
    return NAN

func _check_mixed_edges(terrain: Node3D) -> void:
    var by_coordinate := {}
    for tile in terrain._tiles:
        by_coordinate[Vector2i(tile["ix"], tile["iz"])] = tile
    var pair_count: int = 0
    var max_gap: float = 0.0
    for tile in terrain._tiles:
        if not tile["node"].visible:
            continue
        for direction in [Vector2i(1, 0), Vector2i(0, 1)]:
            var coord := Vector2i(tile["ix"], tile["iz"])
            var neighbor: Dictionary = by_coordinate.get(coord + direction, {})
            if neighbor.is_empty() or not neighbor["node"].visible:
                continue
            if bool(tile["high_selected"]) == bool(neighbor["high_selected"]):
                continue
            var vertical: bool = direction.x == 1
            var boundary: float = float(coord.x + 1 if vertical else coord.y + 1) * TerrainStudy.TILE_EDGE
            var left: Array[Vector2] = _edge_profile(tile, vertical, boundary)
            var right: Array[Vector2] = _edge_profile(neighbor, vertical, boundary)
            if left.size() < 2 or right.size() < 2:
                _check(false, "mixed-resolution edge has complete profiles")
                continue
            pair_count += 1
            for sample in left:
                max_gap = maxf(max_gap, absf(sample.y - _profile_height(right, sample.x)))
            for sample in right:
                max_gap = maxf(max_gap, absf(sample.y - _profile_height(left, sample.x)))
    print("MIXED_LOD_EDGE_GAP pairs=", pair_count, " max=", max_gap)
    _check(pair_count > 0, "test exercises visible mixed-resolution neighbors")
    _check(max_gap < 0.0001, "mixed-resolution top surfaces meet")


# Compare stitched meshes with the original full-rebuild path. This exercises
# geometry and normals, including skirts, not just the seam edge endpoints.
func _check_stitched_reference(terrain: Node3D) -> void:
    var examined: int = 0
    var largest_vertex_error: float = 0.0
    var largest_normal_error: float = 0.0
    var complete: bool = true
    for tile in terrain._tiles:
        if not tile["node"].visible or not tile["high_selected"]:
            continue
        var stitched: ArrayMesh = tile["stitched_mesh"]
        if stitched == null or tile["node"].mesh != stitched:
            continue
        var reference: ArrayMesh = terrain._tile_mesh(tile["ix"], tile["iz"],
            TerrainStudy.HIGH_SEGMENTS, tile["stitched_mask"])
        var actual_arrays: Array = stitched.surface_get_arrays(0)
        var reference_arrays: Array = reference.surface_get_arrays(0)
        var vertices: PackedVector3Array = actual_arrays[Mesh.ARRAY_VERTEX]
        var expected: PackedVector3Array = reference_arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array = actual_arrays[Mesh.ARRAY_NORMAL]
        var expected_normals: PackedVector3Array = reference_arrays[Mesh.ARRAY_NORMAL]
        if vertices.size() != expected.size() or normals.size() != expected_normals.size():
            complete = false
            continue
        for i in range(vertices.size()):
            largest_vertex_error = maxf(largest_vertex_error, vertices[i].distance_to(expected[i]))
            largest_normal_error = maxf(largest_normal_error, normals[i].distance_to(expected_normals[i]))
        examined += 1
        if examined >= 3:
            break
    print("STITCH_REFERENCE meshes=", examined, " vertex_error=", largest_vertex_error,
        " normal_error=", largest_normal_error)
    _check(examined >= 3 and complete, "reference compares three complete stitched meshes")
    _check(largest_vertex_error < 0.0001 and largest_normal_error < 0.0001,
        "stitched meshes preserve full rebuild geometry and normals")

func _finish() -> void:
    if failures.is_empty():
        print("GODOT_FLIGHT_SLICE_NATIVE_PASS checks=", checks)
        quit(0)
    else:
        for message in failures:
            push_error("GODOT_FLIGHT_SLICE_FAIL: " + message)
        quit(1)
