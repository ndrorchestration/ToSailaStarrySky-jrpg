extends RefCounted
## Conservative, public-safe cross-study geometry gate. Source geometries are
## unchanged; results do NOT establish physical collisions or metre certification.
const Ship = preload("res://scripts/ship_visual_3d_rig_study.gd")
const Foredeck = preload("res://scripts/ship_foredeck_cross_study.gd")
const Bridge = preload("res://scripts/ship_geodesic_bridge_cross_study.gd")
const Interior = preload("res://scripts/ship_interior_layout_cross_study.gd")

const STUDY_ART_TO_METRES: float = 2.5  # From independent boarding PR #461.
const CANDIDATE_ENTRY_WIDTH_M: float = 2.35
const REVIEW_MIN_HEADROOM_M: float = 2.05
const BRIDGE_SHIP_Z: float = -0.50
const REVIEW_POSES: Array[float] = [0.0, 0.25, 0.50, 0.75, 1.0]
const SOURCE_SHIP_BLOB := "b21327071e2120fd75113d6051af17dd2c45dbfd"
const SOURCE_FOREDECK_BLOB := "638b2e1d2761cd27870ec38a470f6e3f47c027cc"
const SOURCE_BRIDGE_BLOB := "88bb7540df89ab552f5ef415ab5c0b1da8945086"
const SOURCE_INTERIOR_BLOB := "036ada9a33ddb6ce8a56886156c4f22992d319fd"

static func _ship_local_box(ship: Node3D, part: MeshInstance3D) -> AABB:
    # Mesh vertices remain in their original authoring coordinates;
    # include all object, parent hinge and study transforms.
    var to_ship: Transform3D = ship.global_transform.affine_inverse() * part.global_transform
    return to_ship * part.get_aabb()

static func _gap(first: AABB, second: AABB) -> float:
    # Exact separation of axis-aligned *bounding boxes* only; 0 can be a
    # false-positive for real triangle collision, never a certificate of safety.
    var a: Vector3 = first.position
    var b: Vector3 = first.end
    var c: Vector3 = second.position
    var d: Vector3 = second.end
    var dx: float = maxf(maxf(c.x - b.x, a.x - d.x), 0.0)
    var dy: float = maxf(maxf(c.y - b.y, a.y - d.y), 0.0)
    var dz: float = maxf(maxf(c.z - b.z, a.z - d.z), 0.0)
    return Vector3(dx, dy, dz).length()

static func _surface_nodes(node: Node3D, output: Array[MeshInstance3D]) -> void:
    for child in node.get_children():
        if child is MeshInstance3D:
            output.append(child as MeshInstance3D)
        if child is Node3D:
            _surface_nodes(child as Node3D, output)

static func assess(ship: Node3D, deck: Node3D, bridge: Node3D) -> Dictionary:
    var refused: Dictionary = {
        "admission": "BLOCKED_ON_HULL_SCALE_EGRESS_AND_SWEPT_VOLUME",
        "physical_integration_ready": false,
        "source_pinned": false,
        "samples": 0,
        "overlap_pairs": 0,
        "minimum_clearance_art_units": -1.0,
        "deck_clearance_test_is_certification": false,
        "actors_collidable": false,
        "reason": "MISSING_STUDY_NODE"
    }
    if ship == null or deck == null or bridge == null:
        return refused
    if not is_instance_valid(ship) or not is_instance_valid(deck) or not is_instance_valid(bridge):
        return refused
    if not ship.has_method("set_wing_review_sweep"):
        return refused
    var hull: MeshInstance3D = ship.get_node_or_null("LongHull") as MeshInstance3D
    if hull == null or hull.mesh == null:
        return refused
    var original_hull_box: AABB = hull.get_aabb()
    var outer_hull_beam_m: float = original_hull_box.size.x * STUDY_ART_TO_METRES
    var outer_hull_length_m: float = original_hull_box.size.z * STUDY_ART_TO_METRES
    var domediameter: float = 2.0 * Bridge.RADIUS * STUDY_ART_TO_METRES
    var summit: float = (Bridge.CENTER_Y + Bridge.RADIUS - Foredeck.PLATFORM_Y) * STUDY_ART_TO_METRES
    var seam: float = absf(
        (BRIDGE_SHIP_Z - Bridge.RADIUS) - Foredeck.PLATFORM_BACK_Z
    ) * STUDY_ART_TO_METRES

    var report: Dictionary = {
        "admission": "BLOCKED_ON_HULL_SCALE_EGRESS_AND_SWEPT_VOLUME",
        "physical_integration_ready": false,
        "source_pinned": true,
        "ship_blob": SOURCE_SHIP_BLOB,
        "foredeck_blob": SOURCE_FOREDECK_BLOB,
        "bridge_blob": SOURCE_BRIDGE_BLOB,
        "interior_blob": SOURCE_INTERIOR_BLOB,
        "outer_hull_beam_study_m": outer_hull_beam_m,
        "outer_hull_loft_length_study_m": outer_hull_length_m,
        "interior_beam_study_m": Interior.BEAM_M,
        "interior_length_study_m": Interior.LENGTH_M,
        "interior_wider_than_outer": Interior.BEAM_M > outer_hull_beam_m,
        "unit_assumption": "UNAPPROVED_2_5_METRES_PER_ART_UNIT",
        "bridge_diameter_study_m": domediameter,
        "entry_width_study_m": CANDIDATE_ENTRY_WIDTH_M,
        "bridge_width_overhang_m": domediameter - CANDIDATE_ENTRY_WIDTH_M,
        "summit_height_study_m": summit,
        "standing_target_review_m": REVIEW_MIN_HEADROOM_M,
        "standing_shortfall_m": REVIEW_MIN_HEADROOM_M - summit,
        "foredeck_bridge_seam_gap_m": seam,
        "samples": 0,
        "overlap_pairs": 0,
        "minimum_clearance_art_units": -1.0,
        "deck_clearance_test_is_certification": false,
        "actors_collidable": false,
        "reason": "INDEPENDENT_PROVISIONAL_SCALE_CONFLICT"
    }

    # AABB contacts are a *conservative blocker*: they are not triangle
    # collisions, swept continuous physics or an occupied actor volume.
    var obstacles: Array[MeshInstance3D] = []
    _surface_nodes(deck, obstacles)
    _surface_nodes(bridge, obstacles)
    if obstacles.is_empty():
        return refused
    var original_yaws: Dictionary = {}
    var original_positions: Dictionary = {}
    for name in Ship.WING_NAMES:
        var rig: Node3D = ship.get_node_or_null("WingRig_" + name) as Node3D
        if rig == null:
            return refused
        original_yaws[name] = rig.rotation.y
        original_positions[name] = rig.position
    var overlaps: int = 0
    var min_clearance: float = INF
    var sample_poses: Array[Dictionary] = []
    for progress in REVIEW_POSES:
        if not ship.set_wing_review_sweep(progress):
            for name in Ship.WING_NAMES:
                var old: Node3D = ship.get_node("WingRig_" + name)
                old.rotation.y = float(original_yaws[name])
            return refused
        var frame_overlaps: int = 0
        var frame_min: float = INF
        for name in Ship.WING_NAMES:
            var rig: Node3D = ship.get_node("WingRig_" + name)
            for child in rig.get_children():
                if not child is MeshInstance3D:
                    continue
                var wing_box: AABB = _ship_local_box(ship, child as MeshInstance3D)
                for obstacle in obstacles:
                    var gap: float = _gap(wing_box, _ship_local_box(ship, obstacle))
                    frame_min = minf(frame_min, gap)
                    if gap <= 0.00001:
                        frame_overlaps += 1
        min_clearance = minf(min_clearance, frame_min)
        overlaps += frame_overlaps
        sample_poses.append({
            "progress": progress,
            "bounding_box_overlap_pairs": frame_overlaps,
            "minimum_aabb_gap_art_units": frame_min
        })
    # Restore presentation exactly; no scene or timeline state changed.
    for name in Ship.WING_NAMES:
        var rig: Node3D = ship.get_node("WingRig_" + name)
        rig.rotation.y = float(original_yaws[name])
        if rig.position != original_positions[name]:
            return refused
    report["samples"] = REVIEW_POSES.size()
    report["overlap_pairs"] = overlaps
    report["minimum_clearance_art_units"] = min_clearance
    report["poses"] = sample_poses
    # Blocking remains in place even when AABBs happen not to overlap, since
    # independent 3D parts and scale are not approved as a coherent whole.
    return report
