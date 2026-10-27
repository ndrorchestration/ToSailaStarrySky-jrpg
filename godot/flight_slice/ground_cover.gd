extends Node3D
## NON-CANON decorative biome study. No collision, height, save, or route authority.
## Two MultiMeshes give close and middle-distance scale cues without per-blade nodes.
const MAX_TUFTS: int = 950
const MAX_STONES: int = 420
const SPACING: float = 2.8

var tuft_poses: Array[Transform3D] = []
var stone_poses: Array[Transform3D] = []
var _tufts: MultiMeshInstance3D
var _stones: MultiMeshInstance3D

static func _hash01(x: float, z: float) -> float:
    var value: float = sin(x * 12.9898 + z * 78.233) * 43758.5453
    return value - floor(value)

static func _fixture_clear(x: float, z: float) -> bool:
    # Keep the actual native touchdown field and provisional hamlet readable.
    if x >= 2.0 and x <= 19.0 and z >= -25.0 and z <= -2.0:
        return false
    for i in range(5):
        var house_x: float = 27.0 + float(i % 3) * 6.5
        var house_z: float = -19.0 + float(i / 3) * 9.0
        if absf(x - house_x) < 3.5 and absf(z - house_z) < 4.0:
            return false
    return true

# CPU interpolation of the exact mesh-triangle sampler at either visible LOD.
# The original height field can rise above a coarse triangle between vertices:
# placing a boulder at that exact height makes it appear to float in the sky.
static func _render_height(terrain: Node3D, x: float, z: float, segments: int) -> float:
    var edge: float = terrain.TILE_EDGE
    var tile_x: int = floori(x / edge)
    var tile_z: int = floori(z / edge)
    var gx_float: float = (x - float(tile_x) * edge) * float(segments) / edge
    var gz_float: float = (z - float(tile_z) * edge) * float(segments) / edge
    var gx: int = clampi(floori(gx_float), 0, segments - 1)
    var gz: int = clampi(floori(gz_float), 0, segments - 1)
    var fx: float = clampf(gx_float - float(gx), 0.0, 1.0)
    var fz: float = clampf(gz_float - float(gz), 0.0, 1.0)
    var a: float = terrain.grid_point(tile_x, tile_z, segments, gx, gz).y
    var b: float = terrain.grid_point(tile_x, tile_z, segments, gx + 1, gz).y
    var d: float = terrain.grid_point(tile_x, tile_z, segments, gx + 1, gz + 1).y
    var cc: float = terrain.grid_point(tile_x, tile_z, segments, gx, gz + 1).y
    if fx + fz <= 1.0:
        return a * (1.0 - fx - fz) + b * fx + cc * fz
    return d * (fx + fz - 1.0) + b * (1.0 - fz) + cc * (1.0 - fx)

func populate(terrain: Node3D) -> void:
    var tuft_colors: Array[Color] = []
    var stone_colors: Array[Color] = []
    # Fixed spatial lattice with reproducible jitter. No RNG/global state, and
    # all instances use the existing authoritative visual height/classifier.
    for gx in range(-3, 29):
        for gz in range(-26, 27):
            var fx: float = float(gx)
            var fz: float = float(gz)
            var x: float = fx * SPACING + (_hash01(fx + 3.0, fz - 5.0) - 0.5) * 1.2
            var z: float = fz * SPACING + (_hash01(fx - 7.0, fz + 2.0) - 0.5) * 1.2
            if not _fixture_clear(x, z):
                continue
            var y: float = terrain.sample_height(x, z)
            if y <= terrain.SEA_LEVEL + 0.30:
                continue
            var biome: String = terrain.classify(x, z)
            var normal := Vector3(
                terrain.sample_height(x - 0.35, z) - terrain.sample_height(x + 0.35, z),
                0.70,
                terrain.sample_height(x, z - 0.35) - terrain.sample_height(x, z + 0.35)
            ).normalized()
            var roll: float = _hash01(fx + 13.1, fz - 6.3)
            var yaw: float = _hash01(fx - 9.2, fz + 4.0) * TAU
            if (biome == "forest" or biome == "grassland") and normal.y >= 0.82 \
                    and roll > 0.43 and tuft_poses.size() < MAX_TUFTS:
                var size: float = 0.68 + _hash01(fx * 0.8, fz + 12.0) * 0.65
                tuft_poses.append(Transform3D(
                    Basis(Vector3.UP, yaw).scaled(Vector3(size, size, size)),
                    Vector3(x, y + 0.02, z)))
                var variation: float = _hash01(fx + 2.3, fz - 11.4)
                tuft_colors.append(Color(0.25, 0.38, 0.20).lerp(
                    Color(0.43, 0.44, 0.23), variation * 0.62)
                    if biome == "grassland" else
                    Color(0.14, 0.28, 0.16).lerp(
                        Color(0.33, 0.40, 0.19), variation * 0.68))
            elif (biome == "alpine" or biome == "summit" or biome == "coast") \
                    and roll > 0.52 and normal.y >= 0.78 \
                    and stone_poses.size() < MAX_STONES:
                # Check both rendered LOD triangle elevations. The higher
                # analytic height alone is insufficient on coarser ridgelines.
                var low_y: float = _render_height(
                    terrain, x, z, terrain.LOW_SEGMENTS)
                var high_y: float = _render_height(
                    terrain, x, z, terrain.HIGH_SEGMENTS)
                if absf(low_y - high_y) > 0.85:
                    continue
                var size: float = 0.36 + _hash01(fx - 4.0, fz * 0.7) * 0.54
                var aspect: float = 0.72 + _hash01(fx + 9.0, fz + 19.0) * 0.56
                # Embed the stone below the lower of the two actual LOD
                # surfaces and slope-align the flat cobble silhouette.
                var tilt := Basis(Quaternion(Vector3.UP, normal))
                var basis: Basis = (tilt * Basis(Vector3.UP, yaw)).scaled(
                    Vector3(size * aspect, size * 0.48, size / aspect))
                var ground_y: float = minf(low_y, high_y)
                stone_poses.append(Transform3D(basis,
                    Vector3(x, ground_y - size * 0.24, z)))
                stone_colors.append(Color(0.28, 0.30, 0.31).lerp(
                    Color(0.47, 0.43, 0.37), _hash01(fx + 5.1, fz - 3.2)))
    _tufts = _instance_group("MeadowTufts", _tuft_mesh(), tuft_poses, tuft_colors)
    _stones = _instance_group("SlopeStones", _stone_mesh(), stone_poses, stone_colors)

func _instance_group(label_name: String, mesh: Mesh,
        poses: Array[Transform3D], colors: Array[Color]) -> MultiMeshInstance3D:
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.use_colors = true
    multi.mesh = mesh
    multi.instance_count = poses.size()
    for i in range(poses.size()):
        multi.set_instance_transform(i, poses[i])
        multi.set_instance_color(i, colors[i])
    var node := MultiMeshInstance3D.new()
    node.name = label_name
    node.multimesh = multi
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.98
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    node.material_override = material
    add_child(node)
    return node

func _tuft_mesh() -> ArrayMesh:
    # Five bent, crossed opaque blades: silhouette/parallax without alpha cards.
    # Double-sided shading prevents view-dependent disappearance at low angles.
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for blade in range(5):
        var theta: float = float(blade) * TAU / 5.0
        var direction := Vector3(cos(theta), 0.0, sin(theta))
        var across := Vector3(-direction.z, 0.0, direction.x)
        var base: Vector3 = direction * 0.085
        var left: Vector3 = base - across * 0.135
        var right: Vector3 = base + across * 0.135
        var tip: Vector3 = base + direction * 0.25 + Vector3.UP * (
            0.56 + 0.13 * sin(float(blade) * 2.1))
        var normal: Vector3 = (right - left).cross(tip - left).normalized()
        for point in [left, right, tip]:
            tool.set_normal(normal)
            tool.add_vertex(point)
    return tool.commit()

func _stone_mesh() -> Mesh:
    var pebble := SphereMesh.new()
    pebble.radius = 1.0
    pebble.height = 2.0
    pebble.radial_segments = 7
    pebble.rings = 3
    return pebble

func set_low_quality(enabled: bool) -> void:
    # Cull the costlier small-scale grass layer; keep large stone landmarks.
    if _tufts != null:
        _tufts.visible = not enabled
