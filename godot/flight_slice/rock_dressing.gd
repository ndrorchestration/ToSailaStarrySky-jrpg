extends MultiMeshInstance3D
## Original fixed-budget noncollision rocky outcrops, presentation-only.
## The geometry does not replace or modify the authoritative land mesh.
const TerrainStudy = preload("res://terrain.gd")
const MAX_OUTCROPS: int = 64
var poses: Array[Transform3D] = []

func _ready() -> void:
    name = "VisualRockOutcrops"
    cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var rock_mesh: ArrayMesh = _make_rock()
    # Deterministic world-space sampling; no engine RNG and no extra colliders.
    for ix in range(49, 90, 3):
        for iz in range(-76, 77, 5):
            var x: float = float(ix) + 1.1 * sin(float(ix + iz) * 0.73)
            var z: float = float(iz) + 0.8 * cos(float(ix - iz) * 0.37)
            var height: float = TerrainStudy.sample_height(x,z)
            if height < 9.0:
                continue
            var dx: float = (TerrainStudy.sample_height(x+0.7,z)
                - TerrainStudy.sample_height(x-0.7,z)) / 1.4
            var dz: float = (TerrainStudy.sample_height(x,z+0.7)
                - TerrainStudy.sample_height(x,z-0.7)) / 1.4
            var gradient: float = Vector2(dx,dz).length()
            if gradient < 0.42 and height < 17.0:
                continue
            if sin(x*2.7+z*3.1) < 0.18:
                continue
            var variation: float = 0.73+0.42*absf(sin(x*0.73+z*0.21))
            var size: Vector3 = Vector3(variation*1.09,
                0.38+0.42*absf(cos(x*0.41-z*0.28)),variation*0.96)
            var yaw: float = fposmod(x*0.35+z*0.16,TAU)
            var basis := Basis(Vector3.UP,yaw).scaled(size)
            poses.append(Transform3D(basis,Vector3(x,height-0.18,z)))
            if poses.size() >= MAX_OUTCROPS:
                break
        if poses.size() >= MAX_OUTCROPS:
            break
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = rock_mesh
    batch.instance_count = poses.size()
    for i in range(poses.size()):
        batch.set_instance_transform(i,poses[i])
    multimesh = batch

func _make_rock() -> ArrayMesh:
    var points: Array[Vector3] = [
        Vector3(-0.85,0.0,-0.67),
        Vector3(0.76,-0.02,-0.57),
        Vector3(0.87,0.0,0.71),
        Vector3(-0.65,0.03,0.87),
        Vector3(0.02,0.83,-0.16),
        Vector3(0.13,0.58,0.49)]
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in [[0,1,4],[1,2,4],[2,5,4],[2,3,5],
            [3,0,4],[3,4,5],[0,3,2],[0,2,1]]:
        var a: Vector3 = points[face[0]]
        var b: Vector3 = points[face[1]]
        var c: Vector3 = points[face[2]]
        var normal: Vector3 = (b-a).cross(c-a).normalized()
        for point in [a,b,c]:
            surface.set_normal(normal)
            surface.set_color(Color(0.80,0.85,0.91))
            surface.add_vertex(point)
    return surface.commit()
