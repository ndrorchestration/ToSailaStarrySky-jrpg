extends SceneTree
## Conservative real-scene geometry comparison. This NEVER authorizes a
## person-sized player, flight mode or final shared metre-scale hull.
const Scene = preload("res://scenes/first_wake_job_preview.tscn")
const Cross = preload("res://scripts/ship_cross_study_clearance_contract.gd")
const Rig = preload("res://scripts/ship_visual_3d_rig_study.gd")
const Deck = preload("res://scripts/ship_foredeck_cross_study.gd")
const Bridge = preload("res://scripts/ship_geodesic_bridge_cross_study.gd")
var failures: Array[String] = []
var checks: int = 0

func verify(ok: bool, note: String) -> void:
    checks += 1
    if not ok:
        failures.append(note)

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
    root.size = Vector2i(960, 640)
    var world = Scene.instantiate()
    root.add_child(world)
    await process_frame
    var default_nodes: int = world.get_child_count()
    verify(world.ship_pose_3d_review == null, "native ship reviewer initially absent")
    verify(not world.set_ship_pose_3d_review_enabled(true),
        "hidden 3D viewport cannot be requested from dock")
    var initial_save: Dictionary = world.export_revised_checkpoint()
    world.ender.position = world.FLYER_POSITION
    verify(world.interact() and finish_dialogue(world) and world.flyer_read,
        "first flyer route preserved")
    world.ender.position = world.IONIA_DOCK_POSITION
    verify(world.interact() and finish_dialogue(world) and
        world.opening.active_party_ids == ["ender", "ionia"],
        "Ionia first hiring preserved")
    world.ender.position = world.GANGWAY_POSITION
    verify(world.interact() and world.room == "engineering",
        "legitimate gangway required")
    verify(world.set_ship_spaces_review_enabled(true),
        "actual native chapter space review admitted")
    verify(world.set_ship_pose_3d_review_enabled(true),
        "test-only original four-wing renderer admitted")
    var review = world.ship_pose_3d_review
    var rig: Node3D = review.ship
    verify(rig.get_node("LongHull") is MeshInstance3D,
        "original unmodified hull mesh present")
    verify(review.geometry_deck == null and review.geometry_bridge == null,
        "foredeck and glass are absent by default")
    var before: Dictionary = world.opening.snapshot()
    var save_before: Dictionary = world.export_revised_checkpoint()
    var actor_before: Vector2 = world.ender.position
    var actor_bounds: Rect2 = world.ender.walking_bounds
    var objective: String = world.objective.text
    var base_ship: Transform3D = rig.global_transform
    var base_rig_names: Array[String] = []
    for name in Rig.WING_NAMES:
        base_rig_names.append(name)
    verify(base_rig_names.size() == 4, "four original wing identities retained")
    verify(world.request_ship_pose_3d_review("gentle_sweep") and
        world.advance_ship_pose_3d_review(0.9, false),
        "halfway wing pose established before geometry query")
    var original_yaw: Dictionary = {}
    for name in Rig.WING_NAMES:
        var wing: Node3D = rig.get_node("WingRig_" + name)
        original_yaw[name] = wing.rotation.y
    var closed: Dictionary = review.assess_geometry_cross_study()
    verify(not closed["physical_integration_ready"] and
        closed["reason"] == "MISSING_STUDY_NODE",
        "query without both study sources fails closed")
    verify(review.set_geometry_cross_study_enabled(true),
        "opt-in source-exact foredeck and dome imported for diagnostic")
    verify(review.geometry_deck is Node3D and
        review.geometry_bridge is Node3D,
        "both independent real Godot 3D parts instantiated")
    verify(review.geometry_deck.get_node("OpenPlatform") is MeshInstance3D and
        review.geometry_bridge.get_node("GeodesicGlass") is MeshInstance3D,
        "actual physical-study meshes present rather than schematic labels")
    verify(review.geometry_deck.scale == Vector3.ONE and
        is_equal_approx(review.geometry_bridge.position.z, Cross.BRIDGE_SHIP_Z),
        "same *art-unit* frame, not silently rescaled to metres")
    var report: Dictionary = review.assess_geometry_cross_study()
    verify(report["source_pinned"] and
        report["ship_blob"] == Cross.SOURCE_SHIP_BLOB and
        report["foredeck_blob"] == Cross.SOURCE_FOREDECK_BLOB and
        report["bridge_blob"] == Cross.SOURCE_BRIDGE_BLOB,
        "exact three independent source blobs are preserved")
    verify(report["admission"] ==
        "BLOCKED_ON_HULL_SCALE_EGRESS_AND_SWEPT_VOLUME" and
        not report["physical_integration_ready"],
        "incompatible studies never become production-ready")
    verify(report["samples"] == 5 and
        report["poses"].size() == 5 and
        report["overlap_pairs"] >= 0,
        "five native 0%-100% wing poses compared against AABBs")
    verify(report["minimum_clearance_art_units"] >= 0.0 and
        not report["actors_collidable"] and
        not report["deck_clearance_test_is_certification"],
        "bounding-box analysis is conservatively nonauthorizing")
    verify(is_equal_approx(float(report["bridge_diameter_study_m"]), 3.8) and
        is_equal_approx(float(report["entry_width_study_m"]), 2.35) and
        is_equal_approx(float(report["bridge_width_overhang_m"]), 1.45),
        "cross-study dome/entry width incompatibility is preserved")
    verify(is_equal_approx(float(report["summit_height_study_m"]), 1.825) and
        is_equal_approx(float(report["standing_shortfall_m"]), 0.225),
        "upper-summit standing shortfall remains blocking")
    verify(is_equal_approx(float(report["foredeck_bridge_seam_gap_m"]), 0.075),
        "independent bow/dome seam projection is recorded")
    var all_yaws_same: bool = true
    for name in Rig.WING_NAMES:
        var current: Node3D = rig.get_node("WingRig_" + name)
        all_yaws_same = (all_yaws_same
            and is_equal_approx(current.rotation.y, float(original_yaw[name])))
    verify(all_yaws_same and rig.global_transform == base_ship,
        "swept review samples restore original in-progress presentation")
    verify(world.opening.snapshot() == before and
        world.export_revised_checkpoint() == save_before and
        world.ender.position == actor_before and
        world.ender.walking_bounds == actor_bounds and
        world.objective.text == objective,
        "geometry comparison does not mutate live story/save/actor")
    verify(world.resonance_status_label.text.contains("LOCKED"),
        "geometry study cannot grant magical abilities")
    print("FIRST_WAKE_CROSS_STUDY_NUMERIC: ", JSON.stringify(report))
    verify(not review.set_geometry_cross_study_enabled(false),
        "geometry overlay can be disabled independently of wing model")
    await process_frame
    verify(review.geometry_deck == null and review.geometry_bridge == null,
        "diagnostic deck and dome are not persistent gameplay nodes")
    verify(not world.set_ship_spaces_review_enabled(false),
        "existing scene opt-out revokes all visual review")
    await process_frame
    verify(world.ship_pose_3d_review == null and
        world.get_child_count() == default_nodes,
        "complete 3D preview released after opt-out")
    verify(world.export_revised_checkpoint() == save_before,
        "saved checkpoint unaffected by real mesh intake")
    world.queue_free()
    await process_frame
    if failures.is_empty():
        print("FIRST_WAKE_CROSS_STUDY_PASS checks=", checks,
            " source=ACTUAL_MESHES metres=PROVISIONAL safety=BLOCKED")
        quit(0)
    else:
        for fail in failures:
            push_error("FIRST_WAKE_CROSS_STUDY_FAIL: " + fail)
        quit(1)
