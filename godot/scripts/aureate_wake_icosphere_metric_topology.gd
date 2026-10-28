extends RefCounted
## METRIC ADAPTATION of PR #471's triangulated normalized icosphere topology.
## This is NEW parameterized geometry, not an identical original art mesh.
## Source: 6a1f21258900027156251aa63107371ab29da7b9 / PR #471.
## Clip front shell to actual adult-sized hatch review aperture; no glass physics.
const SOURCE_PR: int = 471
const SOURCE_HEAD := "6a1f21258900027156251aa63107371ab29da7b9"
const SUBDIVISIONS: int = 2
const EPSILON: float = 0.00001

static func _normalized_icosphere() -> Array:
    var phi: float = (1.0 + sqrt(5.0)) * 0.5
    var vertices: Array[Vector3] = [
        Vector3(-1.0, phi, 0), Vector3(1.0, phi, 0),
        Vector3(-1.0, -phi, 0), Vector3(1.0, -phi, 0),
        Vector3(0, -1.0, phi), Vector3(0, 1.0, phi),
        Vector3(0, -1.0, -phi), Vector3(0, 1.0, -phi),
        Vector3(phi, 0, -1.0), Vector3(phi, 0, 1.0),
        Vector3(-phi, 0, -1.0), Vector3(-phi, 0, 1.0)
    ]
    for i in range(vertices.size()):
        vertices[i] = vertices[i].normalized()
    var faces: Array[Vector3i] = [
        Vector3i(0, 11, 5), Vector3i(0, 5, 1),
        Vector3i(0, 1, 7), Vector3i(0, 7, 10),
        Vector3i(0, 10, 11), Vector3i(1, 5, 9),
        Vector3i(5, 11, 4), Vector3i(11, 10, 2),
        Vector3i(10, 7, 6), Vector3i(7, 1, 8),
        Vector3i(3, 9, 4), Vector3i(3, 4, 2),
        Vector3i(3, 2, 6), Vector3i(3, 6, 8),
        Vector3i(3, 8, 9), Vector3i(4, 9, 5),
        Vector3i(2, 4, 11), Vector3i(6, 2, 10),
        Vector3i(8, 6, 7), Vector3i(9, 8, 1)
    ]
    for level in range(SUBDIVISIONS):
        var cache: Dictionary = {}
        var next: Array[Vector3i] = []
        for face in faces:
            var ab: int = _midpoint(face.x, face.y, vertices, cache)
            var bc: int = _midpoint(face.y, face.z, vertices, cache)
            var ca: int = _midpoint(face.z, face.x, vertices, cache)
            next.append(Vector3i(face.x, ab, ca))
            next.append(Vector3i(face.y, bc, ab))
            next.append(Vector3i(face.z, ca, bc))
            next.append(Vector3i(ab, bc, ca))
        faces = next
    return [vertices, faces]

static func _midpoint(a: int, b: int, points: Array[Vector3],
        memo: Dictionary) -> int:
    var key: Vector2i = Vector2i(mini(a, b), maxi(a, b))
    if memo.has(key):
        return int(memo[key])
    var idx: int = points.size()
    points.append((points[a] + points[b]).normalized())
    memo[key] = idx
    return idx

static func _clip(polygon: Array[Vector3], axis: Vector3,
        value: float, greater: bool) -> Array[Vector3]:
    var output: Array[Vector3] = []
    if polygon.size() < 3:
        return output
    for i in range(polygon.size()):
        var a: Vector3 = polygon[i]
        var b: Vector3 = polygon[(i + 1) % polygon.size()]
        var da: float = axis.dot(a) - value
        var db: float = axis.dot(b) - value
        var inside_a: bool = da >= -EPSILON if greater else da <= EPSILON
        var inside_b: bool = db >= -EPSILON if greater else db <= EPSILON
        if inside_a:
            output.append(a)
        if inside_a != inside_b:
            var t: float = da / (da - db)
            output.append(a.lerp(b, t))
    return output if output.size() >= 3 else []

static func _partition_aperture(polygon: Array[Vector3],
        front_limit_z: float, half_width: float,
        portal_top_y: float) -> Array:
    # Back half of shell kept. Front hemisphere polygons divided into three
    # mutually exclusive outside-door pieces; center below header removed.
    # This creates an ACTUAL hole in the visual panes, not alpha-only glass.
    var kept: Array = []
    var rear: Array[Vector3] = _clip(
        polygon, Vector3(0, 0, 1), front_limit_z, true)
    if rear.size() >= 3:
        kept.append(rear)
    var front: Array[Vector3] = _clip(
        polygon, Vector3(0, 0, 1), front_limit_z, false)
    if front.size() < 3:
        return kept
    var port: Array[Vector3] = _clip(
        front, Vector3(1, 0, 0), -half_width, false)
    if port.size() >= 3:
        kept.append(port)
    var starboard: Array[Vector3] = _clip(
        front, Vector3(1, 0, 0), half_width, true)
    if starboard.size() >= 3:
        kept.append(starboard)
    var middle: Array[Vector3] = _clip(
        front, Vector3(1, 0, 0), -half_width, true)
    middle = _clip(middle, Vector3(1, 0, 0), half_width, false)
    middle = _clip(middle, Vector3(0, 1, 0), portal_top_y, true)
    if middle.size() >= 3:
        kept.append(middle)
    return kept

static func _edge_id(a: Vector3, b: Vector3) -> String:
    var va: Vector3i = Vector3i(
        roundi(a.x * 10000.0), roundi(a.y * 10000.0), roundi(a.z * 10000.0))
    var vb: Vector3i = Vector3i(
        roundi(b.x * 10000.0), roundi(b.y * 10000.0), roundi(b.z * 10000.0))
    var p: String = str(va)
    var q: String = str(vb)
    return p + "|" + q if p < q else q + "|" + p

static func make_metric_shell(radius_m: float, center_m: Vector3,
        base_y_m: float, front_limit_z: float,
        half_width_m: float, portal_top_y: float) -> Dictionary:
    var source: Array = _normalized_icosphere()
    var vertices: Array[Vector3] = source[0]
    var faces: Array[Vector3i] = source[1]
    var tris: Array[Vector3] = []
    var lines: Array = []
    var unique_edges: Dictionary = {}
    var actual_faces: int = 0
    var bounding_min: Vector3 = Vector3(INF, INF, INF)
    var bounding_max: Vector3 = Vector3(-INF, -INF, -INF)
    for face in faces:
        var original: Array[Vector3] = [
            vertices[face.x] * radius_m + center_m,
            vertices[face.y] * radius_m + center_m,
            vertices[face.z] * radius_m + center_m
        ]
        var cut_floor: Array[Vector3] = _clip(
            original, Vector3.UP, base_y_m, true)
        if cut_floor.size() < 3:
            continue
        for polygon in _partition_aperture(
                cut_floor, front_limit_z, half_width_m, portal_top_y):
            for k in range(1, polygon.size() - 1):
                var a: Vector3 = polygon[0]
                var b: Vector3 = polygon[k]
                var c: Vector3 = polygon[k + 1]
                var normal: Vector3 = (b - a).cross(c - a)
                if normal.length_squared() < 0.00000001:
                    continue
                if normal.dot((a + b + c) / 3.0 - center_m) < 0.0:
                    var temp: Vector3 = b
                    b = c
                    c = temp
                for v in [a, b, c]:
                    tris.append(v)
                    bounding_min = bounding_min.min(v)
                    bounding_max = bounding_max.max(v)
                actual_faces += 1
            for k in range(polygon.size()):
                var p: Vector3 = polygon[k]
                var q: Vector3 = polygon[(k + 1) % polygon.size()]
                if p.distance_squared_to(q) < 0.00000001:
                    continue
                var key: String = _edge_id(p, q)
                if unique_edges.has(key):
                    continue
                unique_edges[key] = true
                lines.append([p, q])
    return {
        "triangles": tris,
        "edges": lines,
        "panels": actual_faces,
        "frame_edges": lines.size(),
        "bounding_min": bounding_min,
        "bounding_max": bounding_max,
        "source_head": SOURCE_HEAD,
        "source_pr": SOURCE_PR,
        "aperture_visual_only": true,
        "production_ready": false
    }
