extends SceneTree
## Real Godot PhysicsServer verification of a SMALL isolated crew entry.
## Does not certify flight-hull scale, rails, leak-tightness or ship handling.
const Study = preload("res://ship_boarding_interface.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, label_text: String) -> void:
    checks += 1
    if not ok:
        failures.append(label_text)

func _physics_tick() -> void:
    await physics_frame
    await process_frame

func _ray(origin: Vector3, end: Vector3) -> Dictionary:
    var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
    var query := PhysicsRayQueryParameters3D.create(origin, end, Study.COLLISION_LAYER)
    query.hit_back_faces = true
    return space.intersect_ray(query)

func _capsule_safe_fraction(start: Vector3, distance: Vector3) -> float:
    var shape := CapsuleShape3D.new()
    shape.height = 1.74
    shape.radius = 0.26
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = shape
    query.transform = Transform3D(Basis.IDENTITY, start)
    query.motion = distance
    query.collision_mask = Study.COLLISION_LAYER
    var progress: PackedFloat32Array = root.world_3d.direct_space_state.cast_motion(query)
    if progress.size() < 2:
        return -1.0
    return progress[0]

func _run() -> void:
    var world := Study.new()
    root.add_child(world)
    await process_frame
    await _physics_tick()
    check(world.get_node("MappedForedeck") != null, "reuses the actual authored bow deck")
    check(is_equal_approx(world.get_node("MappedForedeck").scale.x,
        Study.ART_TO_METRES), "art-to-metre study mapping is explicit")
    check(is_equal_approx(Study.ART_TO_METRES, 2.5),
        "standalone conversion is pinned and not the full cabin dimension")
    check(Study.DOORWAY_WIDTH_M >= 1.2 and Study.DOORWAY_HEIGHT_M >= 1.85,
        "modelled crew opening has bounded adult-scale nominal dimensions")
    check(world.get_node("BowFloorPhysics") is StaticBody3D,
        "physics body attached to exact native tapered deck mesh")
    var collision: CollisionShape3D = world.get_node(
        "MappedForedeck/BowFloorPhysics/ExactForedeckTriangleCollision")
    check(collision.shape is ConcavePolygonShape3D,
        "native surface collision actually uses deck triangulation")
    check(world.get_node("CrewEntryFloorPhysics/VerifiedBox").shape is BoxShape3D,
        "cabin entry has its own physical floor")
    check(world.get_node("DoorHinge/SwingDoor/DoorPanelCollision").shape is BoxShape3D,
        "door has an actual moving native collision shape")

    # Foredeck and cabin should read as contiguous *in this isolated mapping*,
    # at y=0. Test both sides, not only the conceptual floor labels.
    for z in [-4.3, -3.35, -3.15, -3.01, -2.65, -1.35]:
        var impact: Dictionary = _ray(Vector3(0.0, 2.8, z),
            Vector3(0.0, -0.75, z))
        check(not impact.is_empty(), "Godot downward physics ray touches walkway " + str(z))
        if not impact.is_empty():
            check(absf(float(impact["position"].y)) < 0.09,
                "deck-to-cabin seam has no dangerous step height " + str(z))

    check(world.is_door_open(), "crew door starts open for ordinary use")
    check(not world.get_node("MappedForedeck").is_weather_sheltered(),
        "ordinary forward lookout remains uncovered")
    var direction := Vector3(0.0, 0.0, -2.05)
    var actor_start := Vector3(0.0, 1.02, -2.10)
    var open_fraction: float = _capsule_safe_fraction(actor_start, direction)
    check(open_fraction >= 0.98,
        "1.74 m adult-size capsule passes from cabin toward deck with door open")

    world.set_door_open(false)
    await _physics_tick()
    check(not world.is_door_open(), "closure state correctly stored")
    var closed_fraction: float = _capsule_safe_fraction(actor_start, direction)
    check(closed_fraction < 0.80 and closed_fraction >= 0.0,
        "closed physical door actually stops actor-size capsule sweep")
    var hit: Dictionary = _ray(Vector3(0.0, 1.05, -2.10),
        Vector3(0.0, 1.05, -4.15))
    check(not hit.is_empty(), "closed crew door physically blocks centerline ray")
    world.set_door_open(true)
    await _physics_tick()
    var reopened_fraction: float = _capsule_safe_fraction(actor_start, direction)
    check(reopened_fraction >= 0.98,
        "opening door restores real Godot swept capsule passage")
    check(world.get_node("DoorHinge/SwingDoor/TimberPanel") is MeshInstance3D,
        "hatch remains visually represented after physics transitions")

    # Known blockers deliberately kept as tests: decorative rails only reach
    # 0.725 m, below common full-height guardrail design targets.
    check(Study.MODEL_RAIL_HEIGHT_M < 0.90,
        "provisional deck rails are too low for final safety acceptance")
    check(Study.DOORWAY_WIDTH_M < 1.45,
        "door opening and final cargo/reduced-mobility access remain unresolved")
    check(not world.get_node("CrewEntryFloor").mesh == null,
        "crew entry has concrete native visual floor mesh")
    world.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_SHIP_BOARDING_PASS checks=", checks,
            " walkway=PHYSICS_ONLY final_hull_scale=UNRESOLVED")
        quit(0)
    else:
        for f in failures:
            push_error("GODOT_SHIP_BOARDING_FAIL: " + f)
        quit(1)
