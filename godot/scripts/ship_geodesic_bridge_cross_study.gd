extends Node3D
## Original, tessellated geodesic bridge DOME: visual study only.
## The hull below it is NOT a physical glass pressure boundary.
## All dimensions are local hero-art units, not certified interior metres.
const RADIUS: float = 0.76
const CENTER_Y: float = 0.40
const BASE_Y: float = 0.26
const CLIP_LOCAL_Y: float = BASE_Y - CENTER_Y
const SUBDIVISIONS: int = 1

const PANORAMA_GLASS = preload("res://shaders/bridge_panorama_glass.gdshader")
var panel_count: int = 0
var unique_frame_edges: int = 0
var glass_review_profile: String = "clear"

func set_glass_review_profile(profile: String) -> void:
    # Art-review only; no storm protection or navigation-mode gameplay.
    if profile != "clear" and profile != "low_glare":
        return
    glass_review_profile = profile
    var panes: MeshInstance3D = get_node_or_null("GeodesicGlass")
    if panes == null:
        return
    var material := panes.material_override as ShaderMaterial
    if material == null:
        return
    if profile == "low_glare":
        material.set_shader_parameter("glass_tint", Color(0.38, 0.57, 0.62, 1.0))
        material.set_shader_parameter("face_alpha", 0.085)
        material.set_shader_parameter("edge_alpha", 0.045)
        material.set_shader_parameter("highlight_gain", 0.10)
    else:
        material.set_shader_parameter("glass_tint", Color(0.43, 0.65, 0.71, 1.0))
        material.set_shader_parameter("face_alpha", 0.13)
        material.set_shader_parameter("edge_alpha", 0.12)
        material.set_shader_parameter("highlight_gain", 0.30)


func _ready() -> void:
    _build_geodesic_shell()
    _build_base_ring()
    _build_helm()
    set_glass_review_profile("clear")

func _icosphere() -> Array:
    var phi: float = (1.0 + sqrt(5.0)) * 0.5
    var vertices: Array[Vector3] = [
        Vector3(-1.0, phi, 0.0), Vector3(1.0, phi, 0.0),
        Vector3(-1.0, -phi, 0.0), Vector3(1.0, -phi, 0.0),
        Vector3(0.0, -1.0, phi), Vector3(0.0, 1.0, phi),
        Vector3(0.0, -1.0, -phi), Vector3(0.0, 1.0, -phi),
        Vector3(phi, 0.0, -1.0), Vector3(phi, 0.0, 1.0),
        Vector3(-phi, 0.0, -1.0), Vector3(-phi, 0.0, 1.0)
    ]
    for index in range(vertices.size()):
        vertices[index] = vertices[index].normalized()
    var faces: Array[Vector3i] = [
        Vector3i(0, 11, 5), Vector3i(0, 5, 1), Vector3i(0, 1, 7),
        Vector3i(0, 7, 10), Vector3i(0, 10, 11),
        Vector3i(1, 5, 9), Vector3i(5, 11, 4),
        Vector3i(11, 10, 2), Vector3i(10, 7, 6), Vector3i(7, 1, 8),
        Vector3i(3, 9, 4), Vector3i(3, 4, 2), Vector3i(3, 2, 6),
        Vector3i(3, 6, 8), Vector3i(3, 8, 9),
        Vector3i(4, 9, 5), Vector3i(2, 4, 11), Vector3i(6, 2, 10),
        Vector3i(8, 6, 7), Vector3i(9, 8, 1)
    ]
    for level in range(SUBDIVISIONS):
        var middle: Dictionary = {}
        var refined: Array[Vector3i] = []
        for face in faces:
            var ab: int = _midpoint(face.x, face.y, vertices, middle)
            var bc: int = _midpoint(face.y, face.z, vertices, middle)
            var ca: int = _midpoint(face.z, face.x, vertices, middle)
            refined.append(Vector3i(face.x, ab, ca))
            refined.append(Vector3i(face.y, bc, ab))
            refined.append(Vector3i(face.z, ca, bc))
            refined.append(Vector3i(ab, bc, ca))
        faces = refined
    return [vertices, faces]

func _midpoint(a: int, b: int, points: Array[Vector3], cache: Dictionary) -> int:
    var key: Vector2i = Vector2i(mini(a, b), maxi(a, b))
    if cache.has(key):
        return int(cache[key])
    var index: int = points.size()
    points.append((points[a] + points[b]).normalized())
    cache[key] = index
    return index

func _clipped_polygon(points: Array[Vector3]) -> Array[Vector3]:
    # Clip a real triangulated sphere to a horizontal plane; no giant sphere
    # primitive and no unintentional underground glass hemisphere.
    var clipped: Array[Vector3] = []
    for i in range(points.size()):
        var a: Vector3 = points[i]
        var b: Vector3 = points[(i + 1) % points.size()]
        var in_a: bool = a.y >= CLIP_LOCAL_Y
        var in_b: bool = b.y >= CLIP_LOCAL_Y
        if in_a:
            clipped.append(a)
        if in_a != in_b:
            var ratio: float = (CLIP_LOCAL_Y - a.y) / (b.y - a.y)
            clipped.append(a.lerp(b, ratio))
    return clipped

func _edge_key(a: Vector3, b: Vector3) -> String:
    var qa: Vector3i = Vector3i(roundi(a.x * 10000.0),
        roundi(a.y * 10000.0), roundi(a.z * 10000.0))
    var qb: Vector3i = Vector3i(roundi(b.x * 10000.0),
        roundi(b.y * 10000.0), roundi(b.z * 10000.0))
    var aa: String = str(qa.x) + ":" + str(qa.y) + ":" + str(qa.z)
    var bb: String = str(qb.x) + ":" + str(qb.y) + ":" + str(qb.z)
    return aa + "|" + bb if aa < bb else bb + "|" + aa

func _build_geodesic_shell() -> void:
    var data: Array = _icosphere()
    var vertices: Array[Vector3] = data[0]
    var faces: Array[Vector3i] = data[1]
    var panes := SurfaceTool.new()
    panes.begin(Mesh.PRIMITIVE_TRIANGLES)
    var structure := SurfaceTool.new()
    structure.begin(Mesh.PRIMITIVE_TRIANGLES)
    var unique: Dictionary = {}
    for face in faces:
        var polygon: Array[Vector3] = _clipped_polygon([
            vertices[face.x], vertices[face.y], vertices[face.z]
        ])
        if polygon.size() < 3:
            continue
        # Every piece is clipped to the same root sphere, including perimeter.
        var tone: Color = Color(0.40, 0.68, 0.74, 0.22)
        if panel_count % 5 == 0:
            tone = Color(0.28, 0.57, 0.65, 0.23)
        elif panel_count % 7 == 0:
            tone = Color(0.65, 0.77, 0.77, 0.19)
        for k in range(1, polygon.size() - 1):
            var a: Vector3 = polygon[0] * RADIUS + Vector3.UP * CENTER_Y
            var b: Vector3 = polygon[k] * RADIUS + Vector3.UP * CENTER_Y
            var c: Vector3 = polygon[k + 1] * RADIUS + Vector3.UP * CENTER_Y
            var normal: Vector3 = (b - a).cross(c - a)
            if normal.length_squared() < 0.00000001:
                continue
            if normal.dot((a + b + c) / 3.0 - Vector3.UP * CENTER_Y) < 0.0:
                var tmp: Vector3 = b
                b = c
                c = tmp
            for vertex in [a, b, c]:
                panes.set_color(tone)
                panes.add_vertex(vertex)
            panel_count += 1
        for index in range(polygon.size()):
            var start: Vector3 = polygon[index] * RADIUS + Vector3.UP * CENTER_Y
            var finish: Vector3 = polygon[(index + 1) % polygon.size()] * RADIUS + Vector3.UP * CENTER_Y
            var key: String = _edge_key(start, finish)
            if not unique.has(key):
                unique[key] = true
                _append_tube(structure, start, finish, 0.007)
    unique_frame_edges = unique.size()
    panes.generate_normals()
    structure.generate_normals()

    var glazing := MeshInstance3D.new()
    glazing.name = "GeodesicGlass"
    glazing.mesh = panes.commit()
    var glass_mat := ShaderMaterial.new()
    glass_mat.shader = PANORAMA_GLASS
    glazing.material_override = glass_mat
    add_child(glazing)

    var edges := MeshInstance3D.new()
    edges.name = "GeodesicFrame"
    edges.mesh = structure.commit()
    var bronze := StandardMaterial3D.new()
    bronze.albedo_color = Color(0.50, 0.45, 0.36)
    bronze.roughness = 0.53
    bronze.metallic = 0.38
    bronze.cull_mode = BaseMaterial3D.CULL_DISABLED
    edges.material_override = bronze
    add_child(edges)

func _build_base_ring() -> void:
    var band := SurfaceTool.new()
    band.begin(Mesh.PRIMITIVE_TRIANGLES)
    var clip_radius: float = sqrt(1.0 - CLIP_LOCAL_Y * CLIP_LOCAL_Y) * RADIUS
    for i in range(40):
        var a: float = TAU * float(i) / 40.0
        var b: float = TAU * float(i + 1) / 40.0
        _append_tube(band,
            Vector3(cos(a) * clip_radius, BASE_Y, sin(a) * clip_radius),
            Vector3(cos(b) * clip_radius, BASE_Y, sin(b) * clip_radius),
            0.023)
    band.generate_normals()
    var ring := MeshInstance3D.new()
    ring.name = "BridgeBaseCollar"
    ring.mesh = band.commit()
    var metal := StandardMaterial3D.new()
    metal.albedo_color = Color(0.76, 0.56, 0.32)
    metal.metallic = 0.61
    metal.roughness = 0.32
    ring.material_override = metal
    add_child(ring)

func _build_helm() -> void:
    # Warm, practical interior cues: Ionia pilots a vessel, not a naked glass pod.
    # Instrument geometry is not a steering control or a real crew-usable bridge.
    var console := MeshInstance3D.new()
    console.name = "BridgeNavigationConsole"
    var block := CylinderMesh.new()
    block.top_radius = 0.26
    block.bottom_radius = 0.35
    block.height = 0.18
    block.radial_segments = 12
    console.mesh = block
    console.position = Vector3(0.0, 0.36, 0.04)
    var panel := StandardMaterial3D.new()
    panel.albedo_color = Color(0.25, 0.34, 0.33)
    panel.metallic = 0.24
    console.material_override = panel
    add_child(console)
    var compass := MeshInstance3D.new()
    compass.name = "BridgeHarmonicCompass"
    var disc := CylinderMesh.new()
    disc.top_radius = 0.16
    disc.bottom_radius = 0.16
    disc.height = 0.015
    disc.radial_segments = 16
    compass.mesh = disc
    compass.position = Vector3(0.0, 0.48, 0.04)
    var lit := StandardMaterial3D.new()
    lit.albedo_color = Color(0.32, 0.71, 0.76)
    lit.emission_enabled = true
    lit.emission = Color(0.08, 0.34, 0.37)
    lit.emission_energy_multiplier = 0.54
    compass.material_override = lit
    add_child(compass)

func _append_tube(tool: SurfaceTool, a: Vector3, b: Vector3, radius: float) -> void:
    var d: Vector3 = b - a
    if d.length_squared() < 0.000000001:
        return
    var tangent: Vector3 = d.normalized()
    var u: Vector3 = tangent.cross(Vector3.UP)
    if u.length_squared() < 0.01:
        u = tangent.cross(Vector3.RIGHT)
    u = u.normalized()
    var v: Vector3 = tangent.cross(u).normalized()
    for step in range(5):
        var angle_a: float = TAU * float(step) / 5.0
        var angle_b: float = TAU * float(step + 1) / 5.0
        var q0: Vector3 = (u * cos(angle_a) + v * sin(angle_a)) * radius
        var q1: Vector3 = (u * cos(angle_b) + v * sin(angle_b)) * radius
        for point in [a + q0, b + q0, b + q1, a + q0, b + q1, a + q1]:
            tool.add_vertex(point)
