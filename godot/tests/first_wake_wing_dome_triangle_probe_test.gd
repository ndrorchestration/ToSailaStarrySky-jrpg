extends SceneTree
## Exact original in-world art study, narrower diagnostic: only membrane/glass
## triangles, sampled states, not ribs, continuous movement or crew safety.
const Chapter = preload("res://scenes/first_wake_job_preview.tscn")
const Probe = preload("res://scripts/ship_wing_dome_triangle_probe.gd")
const Rig = preload("res://scripts/ship_visual_3d_rig_study.gd")
var checks: int = 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)

func clear_dialogue(world: Node) -> bool:
    for i in range(20):
        if not world.dialogue_open:
            return true
        if not world.interact():
            return false
    return false

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    # Distinguish mathematically known triangle cases before a real mesh scan.
    var a: Array = [
        Vector3(0, 0, 0), Vector3(2, 0, 0), Vector3(0, 0, 2)
    ]
    var noncoplanar_hit: Array = [
        Vector3(0.5, -1, 0.5), Vector3(0.5, 1, 0.5), Vector3(0.5, 0, 1)
    ]
    var coplanar_hit: Array = [
        Vector3(0.5, 0, 0.5), Vector3(1.5, 0, 0.5), Vector3(0.5, 0, 1.5)
    ]
    var coplanar_miss: Array = [
        Vector3(3, 0, 0), Vector3(4, 0, 0), Vector3(3, 0, 1)
    ]
    var elevated_miss: Array = [
        Vector3(0.5, 0.6, 0.5), Vector3(1.5, 0.6, 0.5),
        Vector3(0.5, 0.6, 1.5)
    ]
    check(Probe.triangle_contact(a, noncoplanar_hit),
        "noncoplanar known intersection recognized")
    check(Probe.triangle_contact(a, coplanar_hit),
        "coplanar overlapping triangles recognized")
    check(not Probe.triangle_contact(a, coplanar_miss),
        "coplanar disjoint triangles correctly separated")
    check(not Probe.triangle_contact(a, elevated_miss),
        "parallel elevated triangle correctly separated")
    check(not Probe.triangle_contact(a, []),
        "invalid empty surface is not accepted as contact")
    check(not bool(Probe.assess(null, null)["measured"]),
        "missing source nodes rejected")

    var scene = Chapter.instantiate()
    root.add_child(scene)
    await process_frame
    check(scene.ship_pose_3d_review == null, "ordinary chapter scene has no 3D rig")
    scene.ender.position = scene.FLYER_POSITION
    check(scene.interact() and clear_dialogue(scene) and scene.flyer_read,
        "real flyer gate executed")
    scene.ender.position = scene.IONIA_DOCK_POSITION
    check(scene.interact() and clear_dialogue(scene) and
        scene.opening.active_party_ids == ["ender", "ionia"],
        "Ionia-first crew verified")
    scene.ender.position = scene.GANGWAY_POSITION
    check(scene.interact() and scene.room == "engineering",
        "actual chapter boarding completed")
    check(scene.set_ship_spaces_review_enabled(true) and
        scene.set_ship_pose_3d_review_enabled(true),
        "opt-in 3D rig available in real engineering scene")
    var preview = scene.ship_pose_3d_review
    check(preview.set_geometry_cross_study_enabled(true),
        "source-exact bridge and foredeck created")
    var state: Dictionary = scene.opening.snapshot()
    var checkpoint: Dictionary = scene.export_revised_checkpoint()
    var original_ship: Transform3D = preview.ship.global_transform
    var original_glass: Transform3D = preview.geometry_bridge.global_transform
    check(scene.request_ship_pose_3d_review("gentle_sweep") and
        scene.advance_ship_pose_3d_review(0.9, false),
        "native pose moved partway before analysis")
    var old_yaw: Dictionary = {}
    for wing in Rig.WING_NAMES:
        old_yaw[wing] = preview.ship.get_node("WingRig_" + wing).rotation.y
    var report: Dictionary = Probe.assess(preview.ship, preview.geometry_bridge)
    print("FIRST_WAKE_TRIANGLE_PROBE_REPORT: ", JSON.stringify(report))
    check(report["measured"] and not report["budget_exhausted"],
        "finite source-mesh triangle scan completed")
    check(report["glass_triangles"] > 0 and
        report["wing_triangles"] > 0 and
        report["triangle_tests"] > 0,
        "source glass and membrane triangles are actually compared")
    check(report["positions"].size() == 5,
        "five original real-geometry wing poses measured")
    var accumulated: int = 0
    var full_wing_sets: bool = true
    for pose in report["positions"]:
        accumulated += int(pose["sat_contacts"])
        full_wing_sets = full_wing_sets and (pose["by_wing"].size() == 4)
    check(full_wing_sets and accumulated == int(report["triangle_sat_contacts"]),
        "all 4 wings accounted for at every sampled pose")
    check(int(report["triangle_sat_contacts"]) <= int(report["triangle_box_candidates"]),
        "narrow-phase candidates do not exceed broad triangle candidates")
    check(not report["physical_integration_ready"] and
        not report["continuous_sweep_verified"] and
        not report["ribs_or_colliders_verified"] and
        not report["actors_verified"],
        "SAT results cannot authorize whole-wing or passenger safety")
    check(report["scope"] == "WING_MEMBRANES_VS_GEODESIC_GLASS_ONLY" and
        report["art_units_only"],
        "limited source and unit scope preserved")
    var same_pose: bool = true
    for wing in Rig.WING_NAMES:
        same_pose = same_pose and is_equal_approx(
            preview.ship.get_node("WingRig_" + wing).rotation.y,
            float(old_yaw[wing]))
    check(same_pose and preview.ship.global_transform == original_ship and
        preview.geometry_bridge.global_transform == original_glass,
        "sampled geometry evaluation returns to exactly current visual pose")
    check(scene.opening.snapshot() == state and
        scene.export_revised_checkpoint() == checkpoint,
        "real Chapter I story state and v2 save unchanged")
    check(scene.resonance_status_label.text.contains("LOCKED"),
        "no combined-party power granted")
    check(not scene.set_ship_spaces_review_enabled(false),
        "review opt-out is supported")
    await process_frame
    check(scene.ship_pose_3d_review == null and
        not scene.ship_spaces_handoff.visible,
        "all temporary 3D nodes released")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("FIRST_WAKE_TRIANGLE_PROBE_PASS checks=", checks,
            " method=DISCRETE_SAT safety=BLOCKED")
        quit(0)
    else:
        for failure in failures:
            push_error("FIRST_WAKE_TRIANGLE_PROBE_FAIL: ", failure)
        quit(1)
