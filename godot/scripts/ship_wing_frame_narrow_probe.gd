extends RefCounted
## Original wing structural tube meshes versus original glass-helm frame/collar.
## Discrete spatial-bucket + SAT diagnosis only; never crew/collision approval.
const Triangle = preload("res://scripts/ship_wing_dome_triangle_probe.gd")
const Ship = preload("res://scripts/ship_visual_3d_rig_study.gd")
const BUCKET: float = 0.28
const MAX_CANDIDATE_TESTS: int = 1500000
const MAX_BUCKET_CELLS: int = 12000
const RIB_PREFIXES: Array[String] = [
    "BrassRibBundle_", "DarkRibBundle_", "GlassRibBundle_"
]
const FRAME_NAMES: Array[String] = [
    "GeodesicFrame", "BridgeBaseCollar"
]

static func _grid_range(box: AABB) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var x0: int = floori(box.position.x / BUCKET)
    var x1: int = floori(box.end.x / BUCKET)
    var z0: int = floori(box.position.z / BUCKET)
    var z1: int = floori(box.end.z / BUCKET)
    for x in range(x0, x1 + 1):
        for z in range(z0, z1 + 1):
            result.append(Vector2i(x, z))
    return result

static func _indexed_target(ship: Node3D, bridge: Node3D) -> Dictionary:
    var all_faces: Array[Dictionary] = []
    var hash: Dictionary = {}
    for name in FRAME_NAMES:
        var mesh: MeshInstance3D = bridge.get_node_or_null(name) as MeshInstance3D
        if mesh == null or mesh.mesh == null:
            return {}
        var triangles: Array[Dictionary] = Triangle._mesh_triangles(ship, mesh)
        if triangles.is_empty():
            return {}
        for item in triangles:
            var index: int = all_faces.size()
            var triangle: Dictionary = item.duplicate()
            triangle["surface"] = name
            all_faces.append(triangle)
            for cell in _grid_range(item["box"]):
                if hash.size() > MAX_BUCKET_CELLS:
                    return {}
                if not hash.has(cell):
                    hash[cell] = []
                hash[cell].append(index)
    return {"faces": all_faces, "buckets": hash}

static func assess(ship: Node3D, bridge: Node3D) -> Dictionary:
    var reject: Dictionary = {
        "status": "NOT_CERTIFIED",
        "physical_integration_ready": false,
        "measured": false,
        "reason": "MISSING_SOURCE_OR_BUDGET",
        "continuous_sweep_verified": false,
        "actor_clearance_verified": false
    }
    if ship == null or bridge == null:
        return reject
    if not is_instance_valid(ship) or not is_instance_valid(bridge):
        return reject
    if not ship.has_method("set_wing_review_sweep"):
        return reject
    var index: Dictionary = _indexed_target(ship, bridge)
    if index.is_empty():
        return reject
    var target: Array = index["faces"]
    var spatial: Dictionary = index["buckets"]
    var yaws: Dictionary = {}
    for name in Ship.WING_NAMES:
        var wing: Node3D = ship.get_node_or_null("WingRig_" + name) as Node3D
        if wing == null:
            return reject
        for prefix in RIB_PREFIXES:
            if wing.get_node_or_null(prefix + name) == null:
                return reject
        yaws[name] = wing.rotation.y

    var report: Dictionary = {
        "status": "NOT_CERTIFIED",
        "physical_integration_ready": false,
        "measured": true,
        "reason": "DISCRETE_STRUCTURE_CONTACTS_NOT_SAFETY_CERTIFICATION",
        "scope": "SOURCE_RIB_BUNDLES_VS_GEODESIC_FRAME_AND_COLLAR",
        "method": "SPATIAL_BUCKET_2D_XZ_PLUS_TRIANGLE_SAT",
        "art_units_only": true,
        "continuous_sweep_verified": false,
        "actor_clearance_verified": false,
        "frame_triangles": target.size(),
        "rib_triangle_observations": 0,
        "tested_pairs": 0,
        "triangle_box_candidates": 0,
        "sat_contacts": 0,
        "contacts_by_target": {"GeodesicFrame": 0, "BridgeBaseCollar": 0},
        "contacts_by_wing": {},
        "poses": [],
        "budget_exhausted": false
    }
    for name in Ship.WING_NAMES:
        report["contacts_by_wing"][name] = 0
    var aborted: bool = false
    for pose in Triangle.POSES:
        if not ship.set_wing_review_sweep(pose):
            aborted = true
            break
        var stage: Dictionary = {
            "pose": pose, "sat_contacts": 0,
            "frame_contacts": 0, "collar_contacts": 0
        }
        for name in Ship.WING_NAMES:
            var wing: Node3D = ship.get_node("WingRig_" + name)
            for prefix in RIB_PREFIXES:
                var rib: MeshInstance3D = wing.get_node(prefix + name) as MeshInstance3D
                var triangles: Array[Dictionary] = Triangle._mesh_triangles(ship, rib)
                report["rib_triangle_observations"] = int(report["rib_triangle_observations"]) + triangles.size()
                for tri in triangles:
                    var candidates: Dictionary = {}
                    for cell in _grid_range(tri["box"]):
                        if spatial.has(cell):
                            for idx in spatial[cell]:
                                candidates[idx] = true
                    for idx in candidates:
                        var face: Dictionary = target[idx]
                        report["tested_pairs"] = int(report["tested_pairs"]) + 1
                        if int(report["tested_pairs"]) > MAX_CANDIDATE_TESTS:
                            aborted = true
                            break
                        if not (tri["box"] as AABB).grow(Triangle.AXIS_TOLERANCE).intersects(face["box"] as AABB):
                            continue
                        report["triangle_box_candidates"] = int(report["triangle_box_candidates"]) + 1
                        if Triangle.triangle_contact(tri["vertices"], face["vertices"]):
                            report["sat_contacts"] = int(report["sat_contacts"]) + 1
                            stage["sat_contacts"] = int(stage["sat_contacts"]) + 1
                            report["contacts_by_wing"][name] = int(report["contacts_by_wing"][name]) + 1
                            var surface: String = face["surface"]
                            report["contacts_by_target"][surface] = int(report["contacts_by_target"][surface]) + 1
                            if surface == "GeodesicFrame":
                                stage["frame_contacts"] = int(stage["frame_contacts"]) + 1
                            else:
                                stage["collar_contacts"] = int(stage["collar_contacts"]) + 1
                    if aborted:
                        break
                if aborted:
                    break
            if aborted:
                break
        report["poses"].append(stage)
        if aborted:
            break

    # Restore every actual wing-root pose after query, including early abort.
    for name in Ship.WING_NAMES:
        ship.get_node("WingRig_" + name).rotation.y = float(yaws[name])
    if aborted:
        report["measured"] = false
        report["budget_exhausted"] = true
        report["reason"] = "INCOMPLETE_STUDY_OR_BUDGET"
    return report
