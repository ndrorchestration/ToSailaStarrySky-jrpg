extends SceneTree
## One-scene real Godot PhysicsServer3D proof: cabin -> faceted helm -> foredeck.
## Never upgrades source art, guarantees sea/weather integrity or alters Chapter I.
const StudyScene = preload("res://scenes/aureate_wake_metric_bridge_study.tscn")
const Study = preload("res://scripts/aureate_wake_metric_bridge_study.gd")
const Admission = preload("res://scripts/ship_space_production_admission_gate.gd")
const Chapter = preload("res://scenes/first_wake_job_preview.tscn")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_verify")

func check(ok: bool, label_text: String) -> void:
    checks += 1
    if not ok:
        failures.append(label_text)

func _capsule_pass_fraction(state: PhysicsDirectSpaceState3D,
        start_z: float = 3.0, end_z: float = -4.60) -> float:
    var actor := CapsuleShape3D.new()
    actor.radius = 0.26
    actor.height = 1.74
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = actor
    query.collision_mask = Study.COLLISION_LAYER
    query.collide_with_areas = false
    query.transform = Transform3D(Basis(), Vector3(0.0, 1.05, start_z))
    query.motion = Vector3(0.0, 0.0, end_z - start_z)
    var fractions: PackedFloat32Array = state.cast_motion(query)
    return fractions[0] if fractions.size() >= 2 else -1.0

func _verify() -> void:
    var ship = StudyScene.instantiate()
    root.add_child(ship)
    await process_frame
    await physics_frame
    await physics_frame

    check(ship is Study and Study.REVIEW_STATUS == (
        "SINGLE_SCENE_PHYSICS_PROTOTYPE_NOT_PRODUCTION"),
        "metric ship is a real Godot scene, explicitly a nonproduction proxy")
    check(Study.BEAM_M == 3.50 and Study.HULL_REAR_Z == 6.0
        and Study.HULL_FORWARD_Z == -2.60,
        "all main hull stations declared in one actual metre-unit coordinate frame")
    check(Study.DOME_PEAK_Y >= Study.REVIEW_HEADROOM_M + 0.80
        and Study.DOME_RADIUS_M * 2.0 <= Study.BEAM_M,
        "new 3.20 m faceted dome fits the 3.50 m hull beam, with adequate apex")
    check(Study.HATCH_CLEAR_WIDTH_M >= 1.20
        and Study.HATCH_CLEAR_HEIGHT_M >= Study.REVIEW_HEADROOM_M,
        "front entrance is adult-scale and is aligned to proposed roof station")
    check(Study.RAIL_HEIGHT_M >= 0.90,
        "normal-deck physical rails exceed provisional 0.90 m review target")
    check(ship.dome_panels >= 190 and ship.dome_frame_edges >= 280,
        "helmside glazing is a real larger faceted triangle mesh plus diagonal support struts")
    check(ship.get_node("MetricFacetedGlassStudy") is MeshInstance3D
        and ship.get_node("GeodesicLatticeStudy") is MeshInstance3D,
        "new authored native 3D geometry renders inside the same metric ship")
    var glass: MeshInstance3D = ship.get_node("MetricFacetedGlassStudy")
    check(glass.mesh.get_surface_count() == 1
        and glass.material_override is StandardMaterial3D,
        "faceted glass is visible original study geometry, not an imported final asset")
    check(not ship.has_node("ShipWaterPressureSystem")
        and not ship.has_node("FinalStructuralGlass"),
        "preview adds no unverified hidden systems or certified glazing")
    check(ship.get_node("CrewCabinWalkingFloorBody") is StaticBody3D
        and ship.get_node("GeodesicHelmWalkingFloorBody") is StaticBody3D
        and ship.get_node("OpenForedeckWalkingFloorBody") is StaticBody3D,
        "three physically separate zones have actual adjacent native floor colliders")
    var rail: StaticBody3D = ship.get_node("PortSafetyRailBody")
    check(rail.collision_layer == Study.COLLISION_LAYER and
        ship.get_node("ForedeckNoseRailBody") is StaticBody3D,
        "deck safety railing has physical collision in addition to painted trim")
    var hatch: StaticBody3D = ship.get_node(
        "ForedeckHatchHinge/HatchCollisionBody")
    check(hatch.collision_layer == Study.COLLISION_LAYER
        and hatch.get_node("HatchPanelPhysics") is CollisionShape3D,
        "hinged hatch is a real collision body, not a toggled sprite")

    var physics: PhysicsDirectSpaceState3D = ship.get_world_3d().direct_space_state
    for zone in [
        ["crew", 4.3], ["cabin_neck", 0.24], ["helm", -1.4],
        ["hatch_interior", -2.40], ["foredeck", -3.15],
        ["foredeck_nose", -5.25]
    ]:
        var source: Vector3 = Vector3(0, 2.5, zone[1])
        var ray := PhysicsRayQueryParameters3D.create(
            source, source + Vector3.DOWN * 3.0, Study.COLLISION_LAYER)
        var hit: Dictionary = physics.intersect_ray(ray)
        check(not hit.is_empty() and hit["collider"] is StaticBody3D
            and hit["position"].y <= 0.1
            and hit["position"].y >= -0.05,
            "real physics floor under ordinary room station: " + zone[0])

    check(ship.is_hatch_open(), "ordinary crew opening defaults to unlatched")
    var clear: float = _capsule_pass_fraction(physics)
    check(clear > 0.995,
        "adult-height 0.26 radius capsule can cross full cabin/helm/bow path")
    check(_capsule_pass_fraction(physics, -4.60, 3.0) > 0.995,
        "adult capsule can return from open bow through helm to cabin")
    ship.set_hatch_open(false)
    await physics_frame
    await physics_frame
    check(not ship.is_hatch_open(), "hatch can genuinely close")
    var blocked: float = _capsule_pass_fraction(physics)
    check(blocked >= 0.0 and blocked < 0.85,
        "closed collision panel physically interrupts same actor passage")
    var reverse_blocked: float = _capsule_pass_fraction(physics, -4.60, 3.0)
    check(reverse_blocked >= 0.0 and reverse_blocked < 0.85,
        "closed hatch also blocks unauthorized movement from deck to cabin")
    ship.set_hatch_open(true)
    await physics_frame
    await physics_frame
    check(_capsule_pass_fraction(physics) > 0.995,
        "opening hatch restores complete real 3D actor-sized passage")
    check(_capsule_pass_fraction(physics, -4.60, 3.0) > 0.995,
        "reopened hatch restores return passage and emergency-exit direction")
    check(ship.get_node("ForedeckHatchHinge").rotation.y < -1.5,
        "hatch opens by real Node3D hinge rotation")

    # Previous PR #503 only permits staged prototype work, not art admission.
    var first_wake = Chapter.instantiate()
    root.add_child(first_wake)
    await process_frame
    var baseline: Dictionary = first_wake.opening.snapshot()
    var prior_save: Dictionary = first_wake.export_revised_checkpoint()
    var stage: Dictionary = Admission.assess(
        Admission.load_manifest(),
        first_wake.ship_spaces_handoff.source_contract())
    check(stage["next_prototype_review_allowed"]
        and stage["production_ready"] == false
        and stage["physical_bridge_approved"] == false,
        "successful physics lab does not rewrite the earlier production gate")
    check(first_wake.opening.snapshot() == baseline
        and first_wake.export_revised_checkpoint() == prior_save
        and first_wake.resonance_status_label.text.contains("LOCKED"),
        "native scene inspection never touches actual Chapter I roster/save powers")
    check(not first_wake.ship_spaces_handoff.visible,
        "real Chapter I remains unchanged, with prototype bridge excluded")
    first_wake.queue_free()
    ship.queue_free()
    await process_frame

    if failures.is_empty():
        print("AUREATE_WAKE_METRIC_PHYSICS_PASS checks=", checks,
            " path=REAL_3D_OPEN_CLOSED_OPEN",
            " production=BLOCKED")
        quit(0)
    else:
        for failure in failures:
            push_error("AUREATE_WAKE_METRIC_PHYSICS_FAIL: " + failure)
        quit(1)
