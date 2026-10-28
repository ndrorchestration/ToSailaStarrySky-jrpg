extends SceneTree
## Source-exact ribs/frame/collar diagnostic in true Ionia-first Chapter I.
## This does not test crew occupancy, continuous sweep or collision physics.
const Scene = preload("res://scenes/first_wake_job_preview.tscn")
const RibProbe = preload("res://scripts/ship_wing_frame_narrow_probe.gd")
const SourceShip = preload("res://scripts/ship_visual_3d_rig_study.gd")
var checks: int = 0
var failures: Array[String] = []

func check(ok: bool, description: String) -> void:
    checks += 1
    if not ok:
        failures.append(description)

func finish_dialogue(world: Node) -> bool:
    for i in range(20):
        if not world.dialogue_open:
            return true
        if not world.interact():
            return false
    return false

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    check(not RibProbe.assess(null, null)["measured"], "missing geometry rejects")
    var world = Scene.instantiate()
    root.add_child(world)
    await process_frame
    check(world.ship_pose_3d_review == null, "normal game does not load 3D")
    world.ender.position = world.FLYER_POSITION
    check(world.interact() and finish_dialogue(world), "authentic flyer")
    world.ender.position = world.IONIA_DOCK_POSITION
    check(world.interact() and finish_dialogue(world) and
        world.opening.active_party_ids == ["ender", "ionia"],
        "real Ionia-first recruitment")
    world.ender.position = world.GANGWAY_POSITION
    check(world.interact() and world.room == "engineering", "authentic gangway")
    check(world.set_ship_spaces_review_enabled(true) and
        world.set_ship_pose_3d_review_enabled(true),
        "explicitly authorized technical view")
    var view = world.ship_pose_3d_review
    check(view.set_geometry_cross_study_enabled(true),
        "actual original geodesic helm loaded")
    var before_state: Dictionary = world.opening.snapshot()
    var before_save: Dictionary = world.export_revised_checkpoint()
    var ship_base: Transform3D = view.ship.global_transform
    check(world.request_ship_pose_3d_review("gentle_sweep") and
        world.advance_ship_pose_3d_review(0.9, false),
        "original 3D wing timeline already in motion")
    var yaw: Dictionary = {}
    for wing in SourceShip.WING_NAMES:
        yaw[wing] = view.ship.get_node("WingRig_" + wing).rotation.y
    var report: Dictionary = RibProbe.assess(view.ship, view.geometry_bridge)
    print("FIRST_WAKE_FRAME_NARROW_REPORT: ", JSON.stringify(report))
    check(report["measured"] and not report["budget_exhausted"],
        "bounded spatial narrow phase completed")
    check(report["frame_triangles"] > 0 and
        report["rib_triangle_observations"] > 0 and
        report["tested_pairs"] > 0,
        "source-original structural triangle faces were evaluated")
    check(report["poses"].size() == 5 and
        report["contacts_by_wing"].size() == 4,
        "all wing names and all five pose frames evaluated")
    var total: int = 0
    for pose in report["poses"]:
        check(int(pose["sat_contacts"]) ==
            int(pose["frame_contacts"]) + int(pose["collar_contacts"]),
            "each pose separates geodesic frame and collar")
        total += int(pose["sat_contacts"])
    check(total == int(report["sat_contacts"]) and
        int(report["contacts_by_target"]["GeodesicFrame"]) +
        int(report["contacts_by_target"]["BridgeBaseCollar"]) == total,
        "all per-pose structural contact totals reconcile")
    check(int(report["sat_contacts"]) <= int(report["triangle_box_candidates"]) and
        int(report["triangle_box_candidates"]) <= int(report["tested_pairs"]),
        "SAT candidates are bounded by spatial+triangle broad-phase")
    check(not report["physical_integration_ready"] and
        not report["actor_clearance_verified"] and
        not report["continuous_sweep_verified"] and report["art_units_only"],
        "structural contact result never certifies physical safety")
    var restored: bool = true
    for wing in SourceShip.WING_NAMES:
        restored = restored and is_equal_approx(
            view.ship.get_node("WingRig_" + wing).rotation.y,
            float(yaw[wing]))
    check(restored and view.ship.global_transform == ship_base,
        "all original 3D wing poses and ship transform restored")
    check(world.opening.snapshot() == before_state and
        world.export_revised_checkpoint() == before_save,
        "actual story and v2 checkpoint unchanged")
    check(world.resonance_status_label.text.contains("LOCKED"),
        "structural scan cannot unlock party powers")
    check(not world.set_ship_spaces_review_enabled(false),
        "user review opt-out closes source mesh scene")
    await process_frame
    check(world.ship_pose_3d_review == null and
        not world.ship_spaces_handoff.visible,
        "all preview parts released")
    world.queue_free()
    await process_frame
    if failures.is_empty():
        print("FIRST_WAKE_FRAME_NARROW_PASS checks=", checks,
            " scope=RIBS_FRAME_COLLAR safety=BLOCKED")
        quit(0)
    else:
        for failure in failures:
            push_error("FIRST_WAKE_FRAME_NARROW_FAIL: ", failure)
        quit(1)
