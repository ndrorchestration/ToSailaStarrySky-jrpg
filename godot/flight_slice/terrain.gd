extends Node3D
## NON-CANON: a flight-scale, locally planar art slice, NOT a spherical renderer.
## Coordinates here are meters in a standalone study; no world/save/route adapter.
const TILE_EDGE: float = 24.0
const GRID_RADIUS: int = 4
const HIGH_SEGMENTS: int = 18
const LOW_SEGMENTS: int = 6
const SEA_LEVEL: float = -0.15
const NEAR_LOD: float = 43.0
const FAR_LOD: float = 55.0

static var _terrain_noise: FastNoiseLite

var _tiles: Array = []
# CPU-side transform authority: headless Dummy Renderer MultiMesh readback
# can return identity even when real OpenGL instance transforms are populated.
var tree_poses: Array[Transform3D] = []
var broadleaf_poses: Array[Transform3D] = []
# Fixed-budget art placements; no collisions, navigation, or biome-authority changes.
var ground_cover_poses: Array[Transform3D] = []
var shoreline_stone_poses: Array[Transform3D] = []
var alpine_talus_poses: Array[Transform3D] = []
var _terrain_material: StandardMaterial3D
var _lod_clock: float = 0.0
var visible_tiles: int = 0
var detailed_tiles: int = 0

static func coastline_at(z: float) -> float:
    return -6.0 + 4.8 * sin(z * 0.049) + 1.8 * sin(z * 0.137)

# Compact, tilted alpine lobes produce a more varied silhouette while
# keeping the existing coastal and landing-field heights unchanged.
static func _ridge_lobe(x: float, z: float, cx: float, cz: float,
        width_x: float, width_z: float, tilt: float) -> float:
    var dx: float = x - cx
    var dz: float = z - cz + dx * tilt
    # The smooth envelope avoids a mathematical cone; modest cross-cutting
    # undulations make ridgelines less symmetrical without changing the pad.
    var shifted_z: float = dz + 1.9 * sin(dx * 0.15)
    var radial_sq: float = pow(dx / width_x, 2.0) + pow(shifted_z / width_z, 2.0)
    var detail: float = 0.84 + 0.11 * cos(dx * 0.36 + dz * 0.22) \
        + 0.05 * cos(dx * 0.18 - dz * 0.41)
    return exp(-2.0 * radial_sq) * detail

# Reuse a single seeded noise resource. The exact seed is a study fixture,
# not a production-world seed or authored geography.
static func _highland_fractal(x: float, z: float) -> float:
    if x <= 50.0:
        return 0.0
    if _terrain_noise == null:
        _terrain_noise = FastNoiseLite.new()
        _terrain_noise.seed = 23017
        _terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
        _terrain_noise.frequency = 0.12
        _terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
        _terrain_noise.fractal_octaves = 3
        _terrain_noise.fractal_gain = 0.5
        _terrain_noise.fractal_lacunarity = 2.0
    var envelope: float = smoothstep(50.0, 62.0, x)
    return 1.8 * envelope * clampf(_terrain_noise.get_noise_2d(x, z), -1.0, 1.0)

static func sample_height(x: float, z: float) -> float:
    var coast: float = coastline_at(z)
    var rise: float = smoothstep(coast - 8.0, coast + 19.0, x)
    var highland: float = pow(clampf((x - 26.0) / 66.0, 0.0, 1.0), 1.55)
    var broad: float = sin(z * 0.089 + x * 0.031) * 1.1
    var ridges: float = sin(x * 0.22 + z * 0.12) * cos(z * 0.13) * 2.2
    var detail: float = sin(x * 0.71) * sin(z * 0.53) * 0.29
    var summit: float = 11.0 * _ridge_lobe(x, z, 72.0, -12.0, 18.0, 15.0, 0.28)
    summit += 8.0 * _ridge_lobe(x, z, 70.0, 18.0, 17.0, 14.0, -0.22)
    summit += 9.0 * _ridge_lobe(x, z, 75.0, -35.0, 16.0, 14.0, -0.18)
    summit *= smoothstep(50.0, 58.0, x)
    return -2.4 + 5.6 * rise + highland * (14.5 + broad * 1.8 + ridges) + rise * (broad + detail) + summit + _highland_fractal(x, z)

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
    _place_ground_cover()
    _place_geology_scatter()
    _place_distant_ridges()
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
    var neighbors := {}
    # Decide every tile's LOD before stitching any neighbor edge. This avoids
    # depending on iteration order or a neighbor's stale previous selection.
    for record in _tiles:
        var node: MeshInstance3D = record["node"]
        var distance: float = Vector2(observer.x - record["center"].x, observer.z - record["center"].z).length()
        node.visible = distance < 126.0
        neighbors[Vector2i(record["ix"], record["iz"])] = record
        if not node.visible:
            continue
        count += 1
        var is_high: bool = record["high_selected"]
        if is_high and distance > FAR_LOD:
            is_high = false
        elif not is_high and distance < NEAR_LOD:
            is_high = true
        record["high_selected"] = is_high
        if is_high:
            detail_count += 1
    # High-resolution edge vertices lie on the piecewise-linear coarse edge.
    # Eighteen segments is divisible by six, so every coarse corner is also
    # a fine vertex. Keep only one extra stitched mesh per tile.
    for record in _tiles:
        var node: MeshInstance3D = record["node"]
        if not node.visible:
            continue
        if not record["high_selected"]:
            node.mesh = record["low"]
            continue
        var coord := Vector2i(record["ix"], record["iz"])
        var mask: int = 0
        var directions := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
        for side in range(4):
            var neighbor: Dictionary = neighbors.get(coord + directions[side], {})
            if not neighbor.is_empty() and neighbor["node"].visible and not neighbor["high_selected"]:
                mask |= 1 << side
        if mask == 0:
            node.mesh = record["high"]
        else:
            if record["stitched_mesh"] == null or record["stitched_mask"] != mask:
                record["stitched_mesh"] = _stitch_existing_mesh(record["ix"], record["iz"], record["high"], mask)
                record["stitched_mask"] = mask
            node.mesh = record["stitched_mesh"]
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
                "high": high, "low": low, "high_selected": false,
                "stitched_mask": -1, "stitched_mesh": null
            })

# The fine mesh matches the coarse neighbor's linear boundary, including
# every coarse breakpoint. Interior vertices continue to use the sampler.
func _stitched_grid_point(ix: int, iz: int, segments: int, gx: int, gz: int, mask: int) -> Vector3:
    var point: Vector3 = grid_point(ix, iz, segments, gx, gz)
    var vertical: bool = (gx == 0 and (mask & 1) != 0) or (gx == segments and (mask & 2) != 0)
    var horizontal: bool = (gz == 0 and (mask & 4) != 0) or (gz == segments and (mask & 8) != 0)
    if not vertical and not horizontal:
        return point
    var along: int = gz if vertical else gx
    var low_coordinate: float = float(along) * float(LOW_SEGMENTS) / float(segments)
    var index: int = mini(floori(low_coordinate), LOW_SEGMENTS - 1)
    var fraction: float = low_coordinate - float(index)
    var a: Vector3
    var b: Vector3
    if vertical:
        var edge_x: int = 0 if gx == 0 else LOW_SEGMENTS
        a = grid_point(ix, iz, LOW_SEGMENTS, edge_x, index)
        b = grid_point(ix, iz, LOW_SEGMENTS, edge_x, index + 1)
    else:
        var edge_z: int = 0 if gz == 0 else LOW_SEGMENTS
        a = grid_point(ix, iz, LOW_SEGMENTS, index, edge_z)
        b = grid_point(ix, iz, LOW_SEGMENTS, index + 1, edge_z)
    point.y = lerpf(a.y, b.y, fraction)
    return point

# Reuse the existing fine mesh's normals, colors, and interior vertices.
# Only edge vertices (including skirt vertices) need height adjustments.
# Preserve each skirt's original vertical offset from its source surface.
func _stitch_existing_mesh(ix: int, iz: int, source: ArrayMesh, mask: int) -> ArrayMesh:
    var arrays: Array = source.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX].duplicate()
    var origin_x: float = float(ix) * TILE_EDGE
    var origin_z: float = float(iz) * TILE_EDGE
    for i in range(vertices.size()):
        var p: Vector3 = vertices[i]
        var gx: int = roundi((p.x - origin_x) * float(HIGH_SEGMENTS) / TILE_EDGE)
        var gz: int = roundi((p.z - origin_z) * float(HIGH_SEGMENTS) / TILE_EDGE)
        var boundary: bool = (gx == 0 and (mask & 1) != 0) or \
            (gx == HIGH_SEGMENTS and (mask & 2) != 0) or \
            (gz == 0 and (mask & 4) != 0) or \
            (gz == HIGH_SEGMENTS and (mask & 8) != 0)
        if not boundary:
            continue
        var original: Vector3 = grid_point(ix, iz, HIGH_SEGMENTS, gx, gz)
        var adjusted: Vector3 = _stitched_grid_point(ix, iz, HIGH_SEGMENTS, gx, gz, mask)
        p.y += adjusted.y - original.y
        vertices[i] = p
    arrays[Mesh.ARRAY_VERTEX] = vertices
    var result := ArrayMesh.new()
    result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    result.surface_set_material(0, source.surface_get_material(0))
    return result

func _tile_mesh(ix: int, iz: int, segments: int, stitch_mask: int = 0) -> ArrayMesh:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    tool.set_material(_terrain_material)
    for gx in range(segments):
        for gz in range(segments):
            var a: Vector3 = _stitched_grid_point(ix, iz, segments, gx, gz, stitch_mask)
            var b: Vector3 = _stitched_grid_point(ix, iz, segments, gx + 1, gz, stitch_mask)
            var c: Vector3 = _stitched_grid_point(ix, iz, segments, gx, gz + 1, stitch_mask)
            var d: Vector3 = _stitched_grid_point(ix, iz, segments, gx + 1, gz + 1, stitch_mask)
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
                    a = _stitched_grid_point(ix, iz, segments, i, 0, stitch_mask)
                    b = _stitched_grid_point(ix, iz, segments, i + 1, 0, stitch_mask)
                1:
                    a = _stitched_grid_point(ix, iz, segments, segments, i, stitch_mask)
                    b = _stitched_grid_point(ix, iz, segments, segments, i + 1, stitch_mask)
                2:
                    a = _stitched_grid_point(ix, iz, segments, i + 1, segments, stitch_mask)
                    b = _stitched_grid_point(ix, iz, segments, i, segments, stitch_mask)
                _:
                    a = _stitched_grid_point(ix, iz, segments, 0, i + 1, stitch_mask)
                    b = _stitched_grid_point(ix, iz, segments, 0, i, stitch_mask)
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
    var broad_poses: Array[Transform3D] = []
    var all_poses: Array[Transform3D] = []
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
            var pose := Transform3D(basis, Vector3(x, sample_height(x, z), z))
            all_poses.append(pose)
            # Stable species assignment keeps the original placement footprint.
            if _hash01(float(ix) + 31.0, float(iz) - 17.0) < 0.32:
                broad_poses.append(pose)
            else:
                poses.append(pose)
    tree_poses = poses.duplicate()
    broadleaf_poses = broad_poses.duplicate()
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
    # A single instanced smooth crown replaces a subset of the conical trees.
    # Geometry and placement are a noncanonical, lightweight art study.
    var broad_crowns := MultiMesh.new()
    broad_crowns.transform_format = MultiMesh.TRANSFORM_3D
    var broad_mesh := SphereMesh.new()
    broad_mesh.radius = 1.5
    broad_mesh.height = 3.0
    broad_mesh.radial_segments = 10
    broad_mesh.rings = 6
    broad_crowns.mesh = broad_mesh
    broad_crowns.instance_count = broad_poses.size()
    for i in range(broad_poses.size()):
        var t: Transform3D = broad_poses[i]
        broad_crowns.set_instance_transform(i,
            Transform3D(t.basis, t.origin + Vector3.UP * 2.50 * t.basis.get_scale().y))
    var broad_instance := MultiMeshInstance3D.new()
    broad_instance.name = "BroadleafCrowns"
    broad_instance.multimesh = broad_crowns
    broad_instance.material_override = _material(Color(0.26, 0.38, 0.18), 0.95)
    add_child(broad_instance)
    var trunks := MultiMesh.new()
    trunks.transform_format = MultiMesh.TRANSFORM_3D
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.16
    trunk_mesh.bottom_radius = 0.21
    trunk_mesh.height = 2.3
    trunk_mesh.radial_segments = 5
    trunks.mesh = trunk_mesh
    trunks.instance_count = all_poses.size()
    for i in range(all_poses.size()):
        var t: Transform3D = all_poses[i]
        trunks.set_instance_transform(i, Transform3D(t.basis, t.origin + Vector3.UP * 1.17 * t.basis.get_scale().y))
    var trunk_instance := MultiMeshInstance3D.new()
    trunk_instance.name = "ForestTrunks"
    trunk_instance.multimesh = trunks
    trunk_instance.material_override = _material(Color(0.25, 0.23, 0.20), 1.0)
    add_child(trunk_instance)


# Sparse, deterministic forest-floor and meadow foliage. Neither GPU transform
# readback nor global RNG is used; all height/biome authority remains in this
# existing sampler. Skip the hamlet, safe landing field, and steep slopes.
func _place_ground_cover() -> void:
    var poses: Array[Transform3D] = []
    for ix in range(5, 76, 3):
        for iz in range(-78, 83, 4):
            var x: float = float(ix) + (_hash01(float(ix), float(iz)) - 0.5) * 1.6
            var z: float = float(iz) + (_hash01(float(iz), float(ix)) - 0.5) * 1.6
            var biome: String = classify(x, z)
            if biome != "forest" and biome != "grassland":
                continue
            if x > 22.0 and x < 45.0 and z > -27.0 and z < 3.0:
                continue
            if x > 5.5 and x < 16.0 and z > -19.0 and z < -6.0:
                continue
            var density_cut: float = 0.32 if biome == "forest" else 0.73
            if _hash01(x + 12.0, z - 9.0) < density_cut:
                continue
            var dx: float = (sample_height(x + 0.65, z) - sample_height(x - 0.65, z)) / 1.30
            var dz: float = (sample_height(x, z + 0.65) - sample_height(x, z - 0.65)) / 1.30
            if Vector2(dx, dz).length() > 0.55:
                continue
            var size: float = 0.68 + 0.48 * _hash01(z + 5.0, x - 3.0)
            var height_scale: float = 0.82 + 0.46 * _hash01(x - 4.0, z + 7.0)
            var yaw: float = TAU * _hash01(x + 33.0, z - 17.0)
            var basis := Basis(Vector3.UP, yaw).scaled(Vector3(size, size * height_scale, size))
            poses.append(Transform3D(basis, Vector3(x, sample_height(x, z) + 0.05, z)))
    ground_cover_poses = poses.duplicate()
    # Presentation opts in to the rendered mesh and shader; the bare baseline
    # and all gameplay systems remain unchanged.
    var foliage_mesh := MultiMesh.new()
    foliage_mesh.transform_format = MultiMesh.TRANSFORM_3D
    foliage_mesh.mesh = QuadMesh.new()
    foliage_mesh.instance_count = poses.size()
    for i in range(poses.size()):
        foliage_mesh.set_instance_transform(i, poses[i])
    var foliage_instance := MultiMeshInstance3D.new()
    foliage_instance.name = "GroundUnderstory"
    foliage_instance.multimesh = foliage_mesh
    foliage_instance.visible = false
    foliage_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(foliage_instance)


# Landscape-specific rock accents for the separate cinematic art lab only.
# The flight, tile meshes, height sampler, and safe touchdown collider are
# unchanged. Ground cover and rock transforms are CPU-authoritative fixtures.
func _place_geology_scatter() -> void:
    var shore: Array[Transform3D] = []
    var talus: Array[Transform3D] = []
    # Coastal stones occupy the narrow DRY surf margin and avoid the pier.
    for iz in range(-72, 73, 5):
        for band in range(4):
            var z: float = float(iz) + (_hash01(float(iz), float(band + 17)) - 0.5) * 2.4
            var x: float = coastline_at(z) + 2.8 + float(band) * 2.4
            x += (_hash01(float(band + 11), float(iz - 9)) - 0.5) * 1.8
            var surface_height: float = sample_height(x, z)
            if surface_height <= SEA_LEVEL + 0.18 or surface_height >= 2.7:
                continue
            if classify(x, z) != "coast" and classify(x, z) != "grassland":
                continue
            if absf(z + 23.0) < 11.0 and x < 11.0:
                continue
            # A slow coastal envelope prevents evenly spaced rock confetti.
            var drift_band: float = sin(z * 0.08 + 1.2 * sin(z * 0.037))
            if drift_band < -0.48:
                continue
            if _hash01(x + 8.0, z + 12.0) < 0.36:
                continue
            var width: float = 0.68 + 0.62 * _hash01(z - 11.0, x + 4.0)
            var depth: float = 0.75 + 0.36 * _hash01(x - 13.0, z + 16.0)
            var height: float = 0.42 + 0.48 * _hash01(z + 19.0, x - 2.0)
            var heading: float = TAU * _hash01(x + 31.0, z - 42.0)
            shore.append(Transform3D(
                Basis(Vector3.UP, heading).scaled(Vector3(width, height, depth)),
                Vector3(x, surface_height + 0.05, z)))
    # Sparse exposed rock in the alpine/summit slope, not the village.
    for ix in range(53, 92, 4):
        for iz in range(-70, 77, 7):
            var x: float = float(ix) + (_hash01(float(ix), float(iz)) - 0.5) * 2.6
            var z: float = float(iz) + (_hash01(float(iz + 5), float(ix - 3)) - 0.5) * 3.0
            var biome: String = classify(x, z)
            if biome != "alpine" and biome != "summit":
                continue
            # Scree collects in patchy exposures rather than dotting snowfields.
            var scree_band: float = sin(x * 0.12 + z * 0.09) * 0.55
            scree_band += cos(x * 0.17 - z * 0.08) * 0.45
            if scree_band < 0.10 or _hash01(x - 2.0, z + 15.0) < 0.46:
                continue
            var gradient_x: float = (sample_height(x + 0.7, z) - sample_height(x - 0.7, z)) / 1.4
            var gradient_z: float = (sample_height(x, z + 0.7) - sample_height(x, z - 0.7)) / 1.4
            if Vector2(gradient_x, gradient_z).length() > 1.15:
                continue
            var scale: float = 0.43 + 0.57 * _hash01(z + 6.0, x - 21.0)
            var rise: float = 0.33 + 0.16 * _hash01(x + 8.0, z - 13.0)
            var yaw: float = TAU * _hash01(x - 24.0, z + 4.0)
            talus.append(Transform3D(
                Basis(Vector3.UP, yaw).scaled(Vector3(scale, scale * rise, scale * 0.82)),
                Vector3(x, sample_height(x, z) + 0.04, z)))
    shoreline_stone_poses = shore.duplicate()
    alpine_talus_poses = talus.duplicate()
    _add_geology_instances("ShorelineStones", shore)
    _add_geology_instances("AlpineTalus", talus)

func _add_geology_instances(node_name: String, poses: Array[Transform3D]) -> void:
    var scatter := MultiMesh.new()
    scatter.transform_format = MultiMesh.TRANSFORM_3D
    # Replaced by one shared custom mesh in the presentation; baseline hides
    # these nodes and retains the original standalone scene comparison.
    var placeholder := SphereMesh.new()
    placeholder.radius = 0.75
    placeholder.height = 1.15
    placeholder.radial_segments = 6
    placeholder.rings = 3
    scatter.mesh = placeholder
    scatter.instance_count = poses.size()
    for index in range(poses.size()):
        scatter.set_instance_transform(index, poses[index])
    var instance := MultiMeshInstance3D.new()
    instance.name = node_name
    instance.multimesh = scatter
    instance.visible = false
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(instance)


# Cinematic background only, beyond the outer local 8x8 terrain footprint.
# The curtains never replace the authoritative ground sampler: they are
# noncolliding, deterministic silhouettes for the NON-CANON flight study.
static func distant_ridge_height(z: float, is_far: bool) -> float:
    if is_far:
        return clampf(31.0 + 13.0 * sin(z * 0.032 + 1.4)
            + 7.0 * cos(z * 0.075 - 0.8) + 4.0 * sin(z * 0.127),
            11.0, 53.0)
    return clampf(18.0 + 8.0 * sin(z * 0.046 - 0.4)
        + 4.8 * cos(z * 0.093 + 0.7) + 2.0 * sin(z * 0.17),
        6.0, 34.0)

static func distant_ridge_x(z: float, is_far: bool) -> float:
    var distance: float = 192.0 if is_far else 130.0
    return distance + 5.0 * sin(z * 0.041 + (1.2 if is_far else 0.2))

func _place_distant_ridges() -> void:
    for is_far in [true, false]:
        var node := MeshInstance3D.new()
        node.name = "FarRidgeSilhouette" if is_far else "NearRidgeSilhouette"
        node.mesh = _distant_ridge_mesh(is_far)
        node.visible = false # Bare/baseline comparison remains unchanged.
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(node)

func _distant_ridge_mesh(is_far: bool) -> ArrayMesh:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Two contours with a differently colored middle shelf add faceted depth,
    # rather than a flat untextured giant rectangular background polygon.
    # Sixty 6-unit segments, 4 triangles each, fixed under 800 vertices/ridge.
    var segments: int = 60
    for segment in range(segments):
        var az: float = -180.0 + float(segment) * 6.0
        var bz: float = az + 6.0
        var ax: float = distant_ridge_x(az, is_far)
        var bx: float = distant_ridge_x(bz, is_far)
        var ay: float = distant_ridge_height(az, is_far)
        var by: float = distant_ridge_height(bz, is_far)
        var base_a := Vector3(ax, -14.0, az)
        var base_b := Vector3(bx, -14.0, bz)
        var shoulder_a := Vector3(ax - 0.85, lerpf(-14.0, ay, 0.57), az)
        var shoulder_b := Vector3(bx - 0.85, lerpf(-14.0, by, 0.57), bz)
        var crest_a := Vector3(ax + 0.8, ay, az)
        var crest_b := Vector3(bx + 0.8, by, bz)
        var shadow := Color(0.74, 0.79, 0.85)
        var midtone := Color(0.91, 0.93, 0.96)
        var highlight := Color(1.0, 1.0, 1.0)
        _distant_ridge_triangle(tool, base_a, base_b, shoulder_a, shadow)
        _distant_ridge_triangle(tool, shoulder_a, base_b, shoulder_b, shadow)
        _distant_ridge_triangle(tool, shoulder_a, shoulder_b, crest_a, midtone)
        _distant_ridge_triangle(tool, crest_a, shoulder_b, crest_b, highlight)
    return tool.commit()

func _distant_ridge_triangle(tool: SurfaceTool, a: Vector3,
        b: Vector3, c: Vector3, tint: Color) -> void:
    var normal: Vector3 = (b - a).cross(c - a).normalized()
    for p in [a, b, c]:
        tool.set_normal(normal)
        tool.set_color(tint)
        tool.add_vertex(p)

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
