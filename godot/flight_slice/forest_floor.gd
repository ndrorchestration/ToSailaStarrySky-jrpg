extends Node3D
## Noncanonical bounded woodland-floor art layer. No collision or gameplay authority.
const TerrainStudy = preload("res://terrain.gd")
const MAX_FERNS: int = 480
const MAX_SHRUBS: int = 320

# CPU authority: headless Dummy renderer MultiMesh readback can be identity.
var fern_poses: Array[Transform3D] = []
var shrub_poses: Array[Transform3D] = []

func populate() -> void:
    if has_node("FernClumps"):
        return
    for ix in range(18, 56, 3):
        for iz in range(-78, 82, 3):
            var x: float = float(ix) + (TerrainStudy._hash01(float(ix), float(iz)) - 0.5) * 1.6
            var z: float = float(iz) + (TerrainStudy._hash01(float(iz) + 9.0, float(ix) - 4.0) - 0.5) * 1.6
            if TerrainStudy.classify(x, z) != "forest" or not _clear_of_hamlet(x, z):
                continue
            if sampled_slope(x, z) > 0.90:
                continue
            var selector: float = TerrainStudy._hash01(float(ix) + 17.0, float(iz) - 23.0)
            var rotation: float = TAU * TerrainStudy._hash01(float(ix) - 11.0, float(iz) + 7.0)
            var spread: float = 0.78 + TerrainStudy._hash01(float(iz) - 5.0, float(ix) + 3.0) * 0.53
            var pose := Transform3D(Basis(Vector3.UP, rotation).scaled(
                Vector3(spread, spread, spread)),
                Vector3(x, TerrainStudy.sample_height(x, z) + 0.025, z))
            if selector < 0.49 and fern_poses.size() < MAX_FERNS:
                fern_poses.append(pose)
            elif selector >= 0.49 and selector < 0.76 and shrub_poses.size() < MAX_SHRUBS:
                shrub_poses.append(pose)
    _add_layer("FernClumps", _fern_mesh(), fern_poses)
    _add_layer("UnderstoryShrubs", _shrub_mesh(), shrub_poses)

static func sampled_slope(x: float, z: float) -> float:
    return Vector2(
        TerrainStudy.sample_height(x + 0.5, z) - TerrainStudy.sample_height(x - 0.5, z),
        TerrainStudy.sample_height(x, z + 0.5) - TerrainStudy.sample_height(x, z - 0.5)
    ).length()

static func _clear_of_hamlet(x: float, z: float) -> bool:
    # The five existing buildings are scale references, not canon locations.
    for i in range(5):
        var house := Vector2(27.0 + float(i % 3) * 6.5,
            -19.0 + float(i / 3) * 9.0)
        if Vector2(x, z).distance_to(house) < 4.6:
            return false
    return true

func _add_layer(label_name: String, mesh: ArrayMesh,
        poses: Array[Transform3D]) -> void:
    var instances := MultiMesh.new()
    instances.transform_format = MultiMesh.TRANSFORM_3D
    instances.mesh = mesh
    instances.instance_count = poses.size()
    for i in range(poses.size()):
        instances.set_instance_transform(i, poses[i])
    var node := MultiMeshInstance3D.new()
    node.name = label_name
    node.multimesh = instances
    node.material_override = _leaf_material()
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(node)

func _leaf_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.97
    material.metallic = 0.0
    # Original opaque ribbons rather than alpha-overdraw billboard cards.
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

func _fern_mesh() -> ArrayMesh:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for blade in range(7):
        var angle: float = TAU * float(blade) / 7.0 + 0.13
        var direction := Vector3(cos(angle), 0.0, sin(angle))
        var across := Vector3(-direction.z, 0.0, direction.x)
        var reach: float = 0.66 + 0.11 * sin(float(blade) * 2.17)
        var root := Vector3(0.0, 0.045, 0.0)
        var shoulder: Vector3 = direction * (reach * 0.53) + Vector3.UP * 0.39
        var tip: Vector3 = direction * reach + Vector3.UP * 0.18
        var half_width: float = 0.105 + 0.020 * sin(float(blade) * 1.7)
        var tint := Color(0.23, 0.36, 0.24).lerp(
            Color(0.39, 0.49, 0.28), float(blade % 3) / 2.0)
        _plant_triangle(tool, root, shoulder - across * half_width,
            shoulder + across * half_width, tint.darkened(0.12))
        _plant_triangle(tool, shoulder - across * half_width, tip,
            shoulder + across * half_width, tint)
    return tool.commit()

func _shrub_mesh() -> ArrayMesh:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Four offset woody volumes share one opaque instanced mesh.
    var centers: Array[Vector3] = [
        Vector3(-0.23, 0.45, -0.06), Vector3(0.24, 0.51, 0.09),
        Vector3(0.01, 0.76, -0.18), Vector3(-0.03, 0.37, 0.28)]
    var radii: Array[Vector3] = [
        Vector3(0.43, 0.39, 0.39), Vector3(0.42, 0.43, 0.44),
        Vector3(0.37, 0.37, 0.38), Vector3(0.36, 0.30, 0.38)]
    for lobe in range(centers.size()):
        var center: Vector3 = centers[lobe]
        var radius: Vector3 = radii[lobe]
        var top := center + Vector3.UP * radius.y
        var bottom := center - Vector3.UP * radius.y * 0.85
        var tone := Color(0.26, 0.39, 0.23).lerp(
            Color(0.40, 0.48, 0.28), float(lobe) / 3.0)
        for side in range(8):
            var a: float = TAU * float(side) / 8.0 + float(lobe) * 0.23
            var b: float = TAU * float(side + 1) / 8.0 + float(lobe) * 0.23
            var pa := center + Vector3(cos(a) * radius.x, 0.0, sin(a) * radius.z)
            var pb := center + Vector3(cos(b) * radius.x, 0.0, sin(b) * radius.z)
            _plant_triangle(tool, top, pa, pb, tone.lightened(0.07))
            _plant_triangle(tool, bottom, pb, pa, tone.darkened(0.14))
    return tool.commit()

func _plant_triangle(tool: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, tint: Color) -> void:
    var normal: Vector3 = (b - a).cross(c - a).normalized()
    for point in [a, b, c]:
        tool.set_normal(normal)
        tool.set_color(tint)
        tool.add_vertex(point)
