extends SceneTree
## Test original ico-derived physical-size VISUAL shell and real guard infill.
## This is game geometry QA, NOT a structural life-safety certificate.
const StudyScene = preload("res://scenes/aureate_wake_metric_bridge_study.tscn")
const Ship = preload("res://scripts/aureate_wake_metric_bridge_study.gd")
const Topology = preload("res://scripts/aureate_wake_icosphere_metric_topology.gd")
const FirstWake = preload("res://scenes/first_wake_job_preview.tscn")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_verify")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures.append(message)

func _ray_collision(ship: Node3D, start: Vector3, ending: Vector3) -> Dictionary:
    var query := PhysicsRayQueryParameters3D.create(
        start, ending, Ship.COLLISION_LAYER)
    return ship.get_world_3d().direct_space_state.intersect_ray(query)

func _walk(actor: CharacterBody3D, direction: Vector2,
        frames: int) -> void:
    actor.set_test_direction(direction)
    for i in range(frames):
        await physics_frame
    actor.set_test_direction(Vector2.ZERO)
    await physics_frame

func _verify() -> void:
    var ship = StudyScene.instantiate()
    root.add_child(ship)
    await process_frame
    await physics_frame
    await physics_frame
    check(ship.dome_topology_source_head == Topology.SOURCE_HEAD
        and Topology.SOURCE_PR == 471,
        "metric dome explicitly tracks the original normalized icosphere lineage")
    check(Topology.SUBDIVISIONS == 2
        and ship.dome_panels >= 190 and ship.dome_frame_edges >= 280,
        "genuine clipped geodesic triangular facets replace latitude ring proxy")
    check(ship.visual_hatch_aperture_in_mesh,
        "original-geometry-adapted front shell has cut glass opening")
    var topology: Dictionary = Topology.make_metric_shell(
        Ship.DOME_RADIUS_M, Vector3(0, Ship.DOME_CENTER_Y, Ship.HELM_CENTER_Z),
        Ship.DOME_BASE_Y, Ship.HELM_CENTER_Z - 0.65, 0.78, 2.33)
    check(topology["panels"] == ship.dome_panels
        and topology["frame_edges"] == ship.dome_frame_edges,
        "runtime geometry is deterministic from documented metre-based inputs")
    check(topology["bounding_min"].y >= Ship.DOME_BASE_Y - 0.001
        and topology["bounding_max"].y <= Ship.DOME_PEAK_Y + 0.001,
        "icosphere shell remains clipped to its physically declared base and apex")
    check(topology["bounding_min"].x >= -Ship.DOME_RADIUS_M - 0.005
        and topology["bounding_max"].x <= Ship.DOME_RADIUS_M + 0.005,
        "glass does not extend beyond the proposed 3.20m metric dome width")
    var pane: MeshInstance3D = ship.get_node("MetricFacetedGlassStudy")
    check(pane is MeshInstance3D and pane.mesh.get_surface_count() == 1,
        "real Godot ArrayMesh glass panes exist and remain material-selectable")
    check(ship.get_node("GeodesicLatticeStudy") is MeshInstance3D,
        "triangular frame is a separate real visual mesh")
    var triangles: Array = topology["triangles"]
    check(triangles.size() > 500 and triangles.size() % 3 == 0,
        "icosphere parser constructs actual renderable triangle vertices")
    var occluding: int = 0
    var mouth_rim: int = 0
    for index in range(0, triangles.size(), 3):
        var centroid: Vector3 = (triangles[index] +
            triangles[index + 1] + triangles[index + 2]) / 3.0
        if centroid.z < Ship.HELM_CENTER_Z - 0.67 and (
                absf(centroid.x) < 0.75) and (
                centroid.y < 2.28):
            occluding += 1
        if absf(centroid.x) < 1.1 and centroid.y < 2.5 and (
                centroid.z < Ship.HELM_CENTER_Z - 0.66):
            mouth_rim += 1
    check(occluding == 0, "front hatch is an actual empty pane aperture, not alpha trick")
    check(mouth_rim > 0, "glass rim near door remains visually framed, not whole dome missing")

    check(Ship.RAIL_HEIGHT_M >= 1.0
        and Ship.RAIL_INFILL_VERTICAL_STEP_M <= 0.18
        and Ship.RAIL_INFILL_RUNG_COUNT == 5,
        "rails meet provisional review count/height/spacing contract")
    for side in ["Port", "Starboard"]:
        for rung in range(Ship.RAIL_INFILL_RUNG_COUNT):
            var node: StaticBody3D = ship.get_node_or_null(
                side + "RailInfill" + str(rung) + "Body")
            check(node != null and node.collision_layer == Ship.COLLISION_LAYER,
                "each side guard rung is solid physics: " + side + str(rung))
    for rung in range(Ship.RAIL_INFILL_RUNG_COUNT):
        check(ship.get_node_or_null(
            "ForedeckNoseInfill" + str(rung) + "Body") is StaticBody3D,
            "forward deck nose infill rung exists with a physical collider")

    for h in [0.18, 0.36, 0.54, 0.72, 0.90]:
        var port: Dictionary = _ray_collision(ship,
            Vector3(-0.70, h, -4.25), Vector3(-1.50, h, -4.25))
        var starboard: Dictionary = _ray_collision(ship,
            Vector3(0.70, h, -4.25), Vector3(1.50, h, -4.25))
        check(not port.is_empty() and str(port["collider"].name).contains(
            "PortRailInfill"), "native ray hits port infill at height " + str(h))
        check(not starboard.is_empty() and str(starboard["collider"].name).contains(
            "StarboardRailInfill"), "native ray hits starboard infill " + str(h))
        var bow: Dictionary = _ray_collision(ship,
            Vector3(0, h, -5.02), Vector3(0, h, -5.80))
        check(not bow.is_empty() and str(bow["collider"].name).contains(
            "ForedeckNoseInfill"), "native ray hits bow infill " + str(h))

    var walker: CharacterBody3D = ship.crew_walker
    walker.manual_controls_enabled = false
    for frame in range(30):
        await physics_frame
    check(walker.is_on_floor(), "actual CharacterBody3D settles via gravity")
    await _walk(walker, Vector2(0, -1), 158)
    check(walker.is_on_floor() and walker.position.z < -4.15
        and walker.position.z > -5.45,
        "physics-driven crew crosses hatch and reaches guarded open deck")
    var forward_position: float = walker.position.z
    await _walk(walker, Vector2(1, 0), 90)
    check(walker.position.x > 0.65 and walker.position.x < 0.95,
        "solid starboard infill blocks avatar from walking over right deck edge")
    await _walk(walker, Vector2(-1, 0), 100)
    check(walker.position.x > -0.95 and walker.position.x < -0.65,
        "solid port infill blocks avatar from walking over left deck edge")
    # Avoid attributing future ship collision/crew safety to a single flat deck.
    check(absf(walker.position.z - forward_position) < 0.12
        and walker.is_on_floor(), "lateral tests do not teleport actor or remove deck contact")
    await _walk(walker, Vector2(1, 0), 20)
    check(absf(walker.position.x) < 0.40,
        "review crew can recover toward the walkable deck center after collisions")
    await _walk(walker, Vector2(0, -1), 95)
    check(walker.position.z > -5.47 and walker.is_on_floor(),
        "front infill prevents simple physics walker from leaving deck nose")

    var before_scene = FirstWake.instantiate()
    root.add_child(before_scene)
    await process_frame
    var saved: Dictionary = before_scene.export_revised_checkpoint()
    var story: Dictionary = before_scene.opening.snapshot()
    check(before_scene.room == "dock"
        and before_scene.opening.active_party_ids == ["ender"],
        "test is isolated from original Ionia-first live Chapter I startup")
    check(before_scene.export_revised_checkpoint() == saved
        and before_scene.opening.snapshot() == story
        and before_scene.resonance_status_label.text.contains("LOCKED"),
        "source adapted hull/guards grant no new story or resonance permissions")
    before_scene.queue_free()
    ship.queue_free()
    await process_frame
    if failures.is_empty():
        print("AUREATE_WAKE_ICOSPHERE_GUARD_PASS checks=", checks,
            " mesh=SOURCE_DERIVED_ICO",
            " aperture=GLASS_HOLE",
            " rails=REAL_COLLISION",
            " production=BLOCKED")
        quit(0)
    else:
        for error in failures:
            push_error("AUREATE_WAKE_ICOSPHERE_GUARD_FAIL: " + error)
        quit(1)
