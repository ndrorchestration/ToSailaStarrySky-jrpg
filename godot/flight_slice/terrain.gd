extends Node3D
## NON-CANON: a flight-scale, locally planar art slice, NOT a spherical renderer.
## Coordinates here are meters in a standalone study; no world/save/route adapter.
const TILE_EDGE: float = 24.0
const GRID_RADIUS: int = 4
const HIGH_SEGMENTS: int = 16
const LOW_SEGMENTS: int = 6
const SEA_LEVEL: float = -0.15
const NEAR_LOD: float = 43.0
const FAR_LOD: float = 55.0

var _tiles: Array = []
# CPU-side transform authority: headless Dummy Renderer MultiMesh readback
# can return identity even when real OpenGL instance transforms are populated.
var tree_poses: Array[Transform3D] = []
var _terrain_material: StandardMaterial3D
var _lod_clock: float = 0.0
var visible_tiles: int = 0
var detailed_tiles: int = 0

static func coastline_at(z: float) -> float:
    return -6.0 + 4.8 * sin(z * 0.049) + 1.8 * sin(z * 0.137)

static func sample_height(x: float, z: float) -> float:
    var coast: float = coastline_at(z)
    var rise: float = smoothstep(coast - 8.0, coast + 19.0, x)
    var highland: float = pow(clampf((x - 26.0) / 66.0, 0.0, 1.0), 1.55)
    var broad: float = sin(z * 0.089 + x * 0.031) * 1.1
    var ridges: float = sin(x * 0.22 + z * 0.12) * cos(z * 0.13) * 2.2
    var detail: float = sin(x * 0.71) * sin(z * 0.53) * 0.29
    return -2.4 + 5.6 * rise + highland * (14.5 + broad * 1.8 + ridges) + rise * (broad + detail)

static func classify(x: float, z: float) -> String:
    var y: float = sample_height(x, z)
    if y < SEA_LEVEL - 1.1:
        return "submerged"
    if y < 1.4:
        return "coast"
    if y > 18.0:
        return "summit"
    if y > 11.0:
        return "alpine"
    if x > 17.0 and x < 56.0:
        return "forest"
    return "grassland"

static func sample_color(x: float, z: float) -> Color:
    var biome: String = classify(x, z)
    var v: float = 0.92 + 0.08 * sin(x * 0.22 + z * 0.31)
    match biome:
        "submerged":
            return Color(0.08, 0.30, 0.35) * v
        "coast":
            return Color(0.83, 0.68, 0.44) * v
        "grassland":
            return Color(0.36, 0.53, 0.34) * v
        "forest":
            return Color(0.20, 0.37, 0.29) * v
        "alpine":
            return Color(0.49, 0.53, 0.53) * v
        _:
            return Color(0.79, 0.84, 0.85) * v

static func grid_point(ix: int, iz: int, segments: int, gx: int, gz: int) -> Vector3:
    var x: float = (float(ix) + float(gx) / float(segments)) * TILE_EDGE
    var z: float = (float(iz) + float(gz) / float(segments)) * TILE_EDGE
    return Vector3(x, sample_height(x, z), z)

func _ready() -> void:
    _terrain_material = StandardMaterial3D.new()
    _terrain_material.vertex_color_use_as_albedo = true
    _terrain_material.roughness = 0.96
    _build_tiles()
    _place_tree_instances()
    _place_landmarks()
    _place_water()

func chunk_count() -> int:
    return _tiles.size()

func update_detail(observer: Vector3, delta: float) -> void:
    _lod_clock += delta
    if _lod_clock < 0.18:
        return
    _lod_clock = 0.0
    var count: int = 0
    var detail_count: int = 0
    for record in _tiles:
        var node: MeshInstance3D = record["node"]
        var distance: float = Vector2(observer.x - record["center"].x, observer.z - record["center"].z).length()
        node.visible = distance < 126.0
        if not node.visible:
            continue
        count += 1
        var is_high: bool = record["high_selected"]
        if is_high and distance > FAR_LOD:
            is_high = false
        elif not is_high and distance < NEAR_LOD:
            is_high = true
        if record["high_selected"] != is_high:
            node.mesh = record["high"] if is_high else record["low"]
            record["high_selected"] = is_high
        if is_high:
            detail_count += 1
    visible_tiles = count
    detailed_tiles = detail_count

func _build_tiles() -> void:
    for ix in range(-GRID_RADIUS, GRID_RADIUS):
        for iz in range(-GRID_RADIUS, GRID_RADIUS):
            var high: ArrayMesh = _tile_mesh(ix, iz, HIGH_SEGMENTS)
            var low: ArrayMesh = _tile_mesh(ix, iz, LOW_SEGMENTS)
            var mesh_instance := MeshInstance3D.new()
            mesh_instance.name = "Chunk_%s_%s" % [ix, iz]
            mesh_instance.mesh = low
            # World-local mesh vertices align exactly between neighboring tiles.
            mesh_instance.position = Vector3.ZERO
            mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
            add_child(mesh_instance)
            _tiles.append({
                "node": mesh_instance,
                "ix": ix,
                "iz": iz,
                "center": Vector3((float(ix) + 0.5) * TILE_EDGE, 0.0, (float(iz) + 0.5) * TILE_EDGE),
                "high": high, "low": low, "high_selected": false
            })

func _tile_mesh(ix: int, iz: int, segments: int) -> ArrayMesh:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    tool.set_material(_terrain_material)
    for gx in range(segments):
        for gz in range(segments):
            var a: Vector3 = grid_point(ix, iz, segments, gx, gz)
            var b: Vector3 = grid_point(ix, iz, segments, gx + 1, gz)
            var c: Vector3 = grid_point(ix, iz, segments, gx, gz + 1)
            var d: Vector3 = grid_point(ix, iz, segments, gx + 1, gz + 1)
            # Godot's CW front-face winding: these triangles must face upward.
            _triangle(tool, a, b, c)
            _triangle(tool, b, d, c)
    # Border skirts obscure cracks where adjacent meshes use different detail.
    for edge in range(4):
        for i in range(segments):
            var a: Vector3
            var b: Vector3
            match edge:
                0:
                    a = grid_point(ix, iz, segments, i, 0)
                    b = grid_point(ix, iz, segments, i + 1, 0)
                1:
                    a = grid_point(ix, iz, segments, segments, i)
                    b = grid_point(ix, iz, segments, segments, i + 1)
                2:
                    a = grid_point(ix, iz, segments, i + 1, segments)
                    b = grid_point(ix, iz, segments, i, segments)
                _:
                    a = grid_point(ix, iz, segments, 0, i + 1)
                    b = grid_point(ix, iz, segments, 0, i)
            var lower_a: Vector3 = a - Vector3.UP * 0.9
            var lower_b: Vector3 = b - Vector3.UP * 3.8
            _triangle(tool, a, b, lower_a)
            _triangle(tool, lower_a, b, lower_b)
    return tool.commit()

func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    for p in [a, b, c]:
        var eps: float = 0.28
        var nx: float = sample_height(p.x - eps, p.z) - sample_height(p.x + eps, p.z)
        var nz: float = sample_height(p.x, p.z - eps) - sample_height(p.x, p.z + eps)
        tool.set_normal(Vector3(nx, eps * 2.0, nz).normalized())
        tool.set_color(sample_color(p.x, p.z))
        tool.add_vertex(p)

func _place_water() -> void:
    var ocean := MeshInstance3D.new()
    ocean.name = "OceanSurface"
    var plane := PlaneMesh.new()
    plane.size = Vector2(260.0, 260.0)
    ocean.mesh = plane
    ocean.position = Vector3(0.0, SEA_LEVEL, 0.0)
    var water := StandardMaterial3D.new()
    water.albedo_color = Color(0.055, 0.31, 0.43)
    water.metallic = 0.28
    water.roughness = 0.29
    ocean.material_override = water
    add_child(ocean)

static func _hash01(x: float, z: float) -> float:
    var value: float = sin(x * 12.9898 + z * 78.233) * 43758.5453
    return value - floor(value)

func _place_tree_instances() -> void:
    var poses: Array[Transform3D] = []
    for ix in range(8, 72, 5):
        for iz in range(-78, 83, 5):
            var x: float = float(ix) + (_hash01(ix, iz) - 0.5) * 3.1
            var z: float = float(iz) + (_hash01(iz, ix) - 0.5) * 3.1
            if classify(x, z) != "forest" or _hash01(x, z) < 0.23:
                continue
            var size: float = 0.8 + _hash01(z, x) * 1.1
            # Stable shape diversity: varying crowns, width and trunk height
            # without adding procedural randomness or extra tree draw calls.
            var width_scale: float = 0.84 + _hash01(float(ix + 9), float(iz - 7)) * 0.39
            var height_scale: float = 0.86 + _hash01(float(ix - 3), float(iz + 11)) * 0.42
            var depth_scale: float = 0.84 + _hash01(float(ix + 4), float(iz + 8)) * 0.36
            var yaw: float = float(posmod(ix * 3 + iz * 7, 29)) * (TAU / 29.0)
            var basis := Basis(Vector3.UP, yaw).scaled(Vector3(
                size * width_scale, size * height_scale, size * depth_scale))
            poses.append(Transform3D(basis, Vector3(x, sample_height(x, z), z)))
    tree_poses = poses.duplicate()
    var crowns := MultiMesh.new()
    crowns.transform_format = MultiMesh.TRANSFORM_3D
    var cone := CylinderMesh.new()
    cone.top_radius = 0.05
    cone.bottom_radius = 1.25
    cone.height = 3.7
    cone.radial_segments = 5
    crowns.mesh = cone
    crowns.instance_count = poses.size()
    for i in range(poses.size()):
        var t: Transform3D = poses[i]
        var transformed := Transform3D(t.basis, t.origin + Vector3.UP * 2.55 * t.basis.get_scale().y)
        crowns.set_instance_transform(i, transformed)
    var forest := MultiMeshInstance3D.new()
    forest.name = "ForestCrowns"
    forest.multimesh = crowns
    forest.material_override = _material(Color(0.11, 0.28, 0.24), 0.95)
    add_child(forest)
    var trunks := MultiMesh.new()
    trunks.transform_format = MultiMesh.TRANSFORM_3D
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.16
    trunk_mesh.bottom_radius = 0.21
    trunk_mesh.height = 2.3
    trunk_mesh.radial_segments = 5
    trunks.mesh = trunk_mesh
    trunks.instance_count = poses.size()
    for i in range(poses.size()):
        var t: Transform3D = poses[i]
        trunks.set_instance_transform(i, Transform3D(t.basis, t.origin + Vector3.UP * 1.17 * t.basis.get_scale().y))
    var trunk_instance := MultiMeshInstance3D.new()
    trunk_instance.name = "ForestTrunks"
    trunk_instance.multimesh = trunks
    trunk_instance.material_override = _material(Color(0.25, 0.23, 0.20), 1.0)
    add_child(trunk_instance)

func _place_landmarks() -> void:
    # Scale references and inhabited silhouettes; temporary, not canon locations.
    _box("CliffsideDock", Vector3(-1.0, 0.5, -23.0), Vector3(5.0, 1.1, 8.0), Color(0.37, 0.35, 0.32))
    _tower("BeaconStudy", Vector2(0.0, -23.0), 11.0, Color(0.83, 0.77, 0.60))
    for i in range(5):
        var x: float = 27.0 + float(i % 3) * 6.5
        var z: float = -19.0 + float(i / 3) * 9.0
        _box("HighlandHamlet_%s" % i, Vector3(x, sample_height(x, z) + 1.7, z), Vector3(3.6, 3.4, 4.2), Color(0.70, 0.59, 0.43))
        var surface_y: float = sample_height(x, z)
        var slate := Color(0.22, 0.31, 0.35).lerp(Color(0.36, 0.27, 0.25), float(i % 3) / 3.0)
        _gable_roof("GableRoof_%s" % i,
            Vector3(x, surface_y + 3.41, z),
            Vector2(4.7, 5.35), 1.25 + float(i % 3) * 0.20, slate)
        _lit_window("WindowGlow_%s" % i,
            Vector3(x - 0.85, surface_y + 2.15, z + 2.13))
        _box("Door_%s" % i, Vector3(x + 0.75, surface_y + 1.08, z + 2.13),
            Vector3(0.85, 2.12, 0.12), Color(0.21, 0.27, 0.26))

func _gable_roof(label_name: String, center: Vector3, span: Vector2,
        ridge_rise: float, tint: Color) -> void:
    # Bounded, hand-readable timber roof silhouette; no fictional architecture canon.
    # Local origin is the wall's upper edge. Open eaves and ridge overhang the wall.
    var hx: float = span.x * 0.5
    var hz: float = span.y * 0.5
    var a := Vector3(-hx, 0.0, -hz)
    var b := Vector3(0.0, ridge_rise, -hz)
    var c := Vector3(hx, 0.0, -hz)
    var d := Vector3(-hx, 0.0, hz)
    var e := Vector3(0.0, ridge_rise, hz)
    var f := Vector3(hx, 0.0, hz)
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Both sloped planes and triangular gable caps, all with explicit flat normals.
    for face in [[a, b, e], [a, e, d], [b, c, f], [b, f, e],
            [a, c, b], [d, e, f]]:
        _roof_triangle(tool, face[0], face[1], face[2])
    var instance := MeshInstance3D.new()
    instance.name = label_name
    instance.mesh = tool.commit()
    instance.position = center
    var material := _material(tint, 0.84)
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.metallic = 0.05
    instance.material_override = material
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    add_child(instance)

func _roof_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    var normal: Vector3 = (b - a).cross(c - a).normalized()
    if absf(normal.y) > 0.1 and normal.y < 0.0:
        var swap: Vector3 = b
        b = c
        c = swap
        normal = -normal
    for vertex in [a, b, c]:
        tool.set_normal(normal)
        tool.add_vertex(vertex)

func _lit_window(label_name: String, pos: Vector3) -> void:
    # Emissive art accent, intentionally NO point lights or gameplay triggers.
    var window := MeshInstance3D.new()
    window.name = label_name
    var pane := BoxMesh.new()
    pane.size = Vector3(0.73, 0.64, 0.11)
    window.mesh = pane
    window.position = pos
    var glass := _material(Color(0.76, 0.63, 0.36), 0.38)
    glass.emission_enabled = true
    glass.emission = Color(0.95, 0.62, 0.27)
    glass.emission_energy_multiplier = 0.48
    window.material_override = glass
    add_child(window)

func _tower(label_name: String, place: Vector2, height: float, tint: Color) -> void:
    var node := MeshInstance3D.new()
    node.name = label_name
    var mesh := CylinderMesh.new()
    mesh.bottom_radius = 1.7
    mesh.top_radius = 1.2
    mesh.height = height
    mesh.radial_segments = 7
    node.mesh = mesh
    node.position = Vector3(place.x, sample_height(place.x, place.y) + height * 0.5, place.y)
    node.material_override = _material(tint, 0.86)
    add_child(node)
    _box(label_name + "_Beacon", node.position + Vector3.UP * (height * 0.5 + 0.6), Vector3(3.1, 1.2, 3.1), Color(0.91, 0.57, 0.28))

func _box(label_name: String, pos: Vector3, size: Vector3, tint: Color) -> void:
    var item := MeshInstance3D.new()
    item.name = label_name
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.position = pos
    item.material_override = _material(tint, 0.88)
    add_child(item)

func _material(tint: Color, rough: float) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = tint
    result.roughness = rough
    return result
