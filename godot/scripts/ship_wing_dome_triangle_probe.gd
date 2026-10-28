extends RefCounted
## Narrower *diagnostic* triangle SAT overlap of source-exact wing membrane
## meshes against geodesic glass panes. It is NOT a watertight, continuous
## swept-volume or crew clearance certificate; fail closed always.
const ShipSource = preload("res://scripts/ship_visual_3d_rig_study.gd")
const POSES: Array[float] = [0.0, 0.25, 0.50, 0.75, 1.0]
const AXIS_TOLERANCE: float = 0.00001
const AXIS_MIN_LENGTH2: float = 0.000000000001
const MAX_TRIANGLE_TESTS: int = 4000000

static func _bounds(a: Vector3, b: Vector3, c: Vector3) -> AABB:
    var low: Vector3 = a.min(b).min(c)
    var high: Vector3 = a.max(b).max(c)
    return AABB(low, high - low)

static func _separated(a: Array, b: Array, axis: Vector3) -> bool:
    if axis.length_squared() < AXIS_MIN_LENGTH2:
        return false
    var unit: Vector3 = axis.normalized()
    var amin: float = a[0].dot(unit)
    var amax: float = amin
    for i in range(1, 3):
        var p: float = a[i].dot(unit)
        amin = minf(amin, p)
        amax = maxf(amax, p)
    var bmin: float = b[0].dot(unit)
    var bmax: float = bmin
    for i in range(1, 3):
        var p: float = b[i].dot(unit)
        bmin = minf(bmin, p)
        bmax = maxf(bmax, p)
    return amax + AXIS_TOLERANCE < bmin or bmax + AXIS_TOLERANCE < amin

static func triangle_contact(a: Array, b: Array) -> bool:
    # Surface triangle SAT, including coplanar in-plane separating edge axes.
    # Degenerate faces are not trusted: caller counts them separately.
    if a.size() != 3 or b.size() != 3:
        return false
    var ea: Array[Vector3] = [
        a[1] - a[0], a[2] - a[1], a[0] - a[2]
    ]
    var eb: Array[Vector3] = [
        b[1] - b[0], b[2] - b[1], b[0] - b[2]
    ]
    var na: Vector3 = ea[0].cross(a[2] - a[0])
    var nb: Vector3 = eb[0].cross(-eb[2])
    if na.length_squared() < AXIS_MIN_LENGTH2:
        return false
    if nb.length_squared() < AXIS_MIN_LENGTH2:
        return false
    if _separated(a, b, na) or _separated(a, b, nb):
        return false
    for edge in ea:
        if _separated(a, b, edge.cross(na)):
            return false
    for edge in eb:
        if _separated(a, b, edge.cross(nb)):
            return false
    for edge_a in ea:
        for edge_b in eb:
            if _separated(a, b, edge_a.cross(edge_b)):
                return false
    return true

static func _mesh_triangles(ship: Node3D, part: MeshInstance3D) -> Array[Dictionary]:
    var tris: Array[Dictionary] = []
    if part == null or part.mesh == null:
        return tris
    if part.mesh.get_surface_count() == 0:
        return tris
    var mesh: Mesh = part.mesh
    var to_ship: Transform3D = ship.global_transform.affine_inverse() * part.global_transform
    # Procedural original studies use TRIANGLES; get_faces flattens surfaces.
    var faces: PackedVector3Array = mesh.get_faces()
    for i in range(0, faces.size() - 2, 3):
        var a: Vector3 = to_ship * faces[i]
        var b: Vector3 = to_ship * faces[i + 1]
        var c: Vector3 = to_ship * faces[i + 2]
        if (b - a).cross(c - a).length_squared() < AXIS_MIN_LENGTH2:
            continue
        tris.append({
            "vertices": [a, b, c],
            "box": _bounds(a, b, c)
        })
    return tris

static func assess(ship: Node3D, bridge: Node3D) -> Dictionary:
    var denied: Dictionary = {
        "status": "NOT_CERTIFIED",
        "physical_integration_ready": false,
        "continuous_sweep_verified": false,
        "ribs_or_colliders_verified": false,
        "actors_verified": false,
        "measured": false,
        "reason": "MISSING_GEOMETRY"
    }
    if ship == null or bridge == null or not is_instance_valid(ship) or not is_instance_valid(bridge):
        return denied
    if not ship.has_method("set_wing_review_sweep"):
        return denied
    var glass: MeshInstance3D = bridge.get_node_or_null("GeodesicGlass") as MeshInstance3D
    if glass == null or glass.mesh == null:
        return denied
    var panes: Array[Dictionary] = _mesh_triangles(ship, glass)
    if panes.is_empty():
        return denied
    var yaws: Dictionary = {}
    for wing_name in ShipSource.WING_NAMES:
        var rig: Node3D = ship.get_node_or_null("WingRig_" + wing_name) as Node3D
        if rig == null or rig.get_node_or_null("Membrane_" + wing_name) == null:
            return denied
        yaws[wing_name] = rig.rotation.y
    var report: Dictionary = {
        "status": "NOT_CERTIFIED",
        "physical_integration_ready": false,
        "continuous_sweep_verified": false,
        "ribs_or_colliders_verified": false,
        "actors_verified": false,
        "measured": true,
        "method": "DISCRETE_TRIANGLE_SAT_WITH_COPLANAR_AXES",
        "scope": "WING_MEMBRANES_VS_GEODESIC_GLASS_ONLY",
        "art_units_only": true,
        "positions": [],
        "glass_triangles": panes.size(),
        "wing_triangles": 0,
        "triangle_box_candidates": 0,
        "triangle_sat_contacts": 0,
        "triangle_tests": 0,
        "budget_exhausted": false,
        "reason": "PILOT_NOT_PHYSICAL_ADMISSION"
    }
    var exhausted: bool = false
    for pose in POSES:
        if not ship.set_wing_review_sweep(pose):
            exhausted = true
            break
        var by_wing: Dictionary = {}
        var pose_hits: int = 0
        for wing_name in ShipSource.WING_NAMES:
            var rig: Node3D = ship.get_node("WingRig_" + wing_name)
            var membrane: MeshInstance3D = rig.get_node("Membrane_" + wing_name) as MeshInstance3D
            var wing: Array[Dictionary] = _mesh_triangles(ship, membrane)
            report["wing_triangles"] = int(report["wing_triangles"]) + wing.size()
            var contacts: int = 0
            for tri in wing:
                for pane in panes:
                    if not (tri["box"] as AABB).grow(AXIS_TOLERANCE).intersects(pane["box"] as AABB):
                        continue
                    report["triangle_box_candidates"] = int(report["triangle_box_candidates"]) + 1
                    report["triangle_tests"] = int(report["triangle_tests"]) + 1
                    if int(report["triangle_tests"]) > MAX_TRIANGLE_TESTS:
                        exhausted = true
                        break
                    if triangle_contact(tri["vertices"], pane["vertices"]):
                        contacts += 1
                if exhausted:
                    break
            by_wing[wing_name] = contacts
            pose_hits += contacts
            if exhausted:
                break
        report["positions"].append({
            "pose": pose,
            "sat_contacts": pose_hits,
            "by_wing": by_wing
        })
        report["triangle_sat_contacts"] = int(report["triangle_sat_contacts"]) + pose_hits
        if exhausted:
            break
    # Restore pose even when budget exhausted; no scene/camera/physics changes.
    for wing_name in ShipSource.WING_NAMES:
        var rig: Node3D = ship.get_node("WingRig_" + wing_name)
        rig.rotation.y = float(yaws[wing_name])
    report["budget_exhausted"] = exhausted
    if exhausted:
        report["measured"] = false
        report["reason"] = "INCOMPLETE_BUDGET_OR_BAD_POSE"
    return report
