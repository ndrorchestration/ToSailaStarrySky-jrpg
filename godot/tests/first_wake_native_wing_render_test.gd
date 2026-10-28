extends SceneTree
## Real Chapter I preview + authentic four-wing 3D rig via isolated SubViewport.
## No player-facing asset admission, movement, boarding or save writes.
const Scene = preload("res://scenes/first_wake_job_preview.tscn")
const Rig = preload("res://scripts/ship_visual_3d_rig_study.gd")
const Timeline = preload("res://scripts/ship_visual_pose_timeline.gd")
const Port = preload("res://scripts/first_wake_ship_visual_pose_port.gd")
var checks: int = 0
var failures: Array[String] = []

func check(ok: bool, reason: String) -> void:
    checks += 1
    if not ok:
        failures.append(reason)

func complete_dialogue(world: Node) -> bool:
    for i in range(20):
        if not world.dialogue_open:
            return true
        if not world.interact():
            return false
    return false

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    root.size = Vector2i(960, 640)
    var world = Scene.instantiate()
    root.add_child(world)
    await process_frame
    var initial_state: Dictionary = world.opening.snapshot()
    var initial_checkpoint: Dictionary = world.export_revised_checkpoint()
    var node_count: int = world.get_child_count()
    check(world.ship_pose_3d_review == null, "3D rig absent by default")
    check(not world.set_ship_pose_3d_review_enabled(true),
        "no 3D scene preview before employment")
    check(not world.request_ship_pose_3d_review(Port.CUE_GENTLE_SWEEP),
        "prehire wing actuation denied")
    check(world.get_child_count() == node_count and
        world.opening.snapshot() == initial_state and
        world.export_revised_checkpoint() == initial_checkpoint,
        "failed early activation cannot mutate tree, story or saves")

    world.ender.position = world.FLYER_POSITION
    check(world.interact() and complete_dialogue(world) and world.flyer_read,
        "real flyer interaction accepted")
    world.ender.position = world.IONIA_DOCK_POSITION
    check(world.interact() and complete_dialogue(world) and
        world.opening.active_party_ids == ["ender", "ionia"],
        "Ionia employed before 3D ship display")
    world.ender.position = world.GANGWAY_POSITION
    check(world.interact() and world.room == "engineering",
        "physical Chapter I gangway interaction occurred")
    check(not world.set_ship_pose_3d_review_enabled(true),
        "boarding alone never displays a test renderer")
    check(world.set_ship_spaces_review_enabled(true),
        "existing separate ship-space opt-in granted")
    check(world.set_ship_pose_3d_review_enabled(true),
        "real 3D wing rig allowed by explicit QA opt-in")
    var review = world.ship_pose_3d_review
    check(review != null and review.visible and review.viewport != null and
        review.review_texture != null, "live viewport and texture instantiated")
    check(review.viewport.size == Vector2i(480, 270) and
        review.review_texture.texture == review.viewport.get_texture(),
        "actual 3D rendering is routed through SubViewport texture")
    check(review.ship is Node3D and
        review.ship.get_node_or_null("LongHull") is MeshInstance3D,
        "real original Godot ship rig, not a simulated sink")
    var source: Dictionary = review.source_contract()
    check(source["source_pr"] == 490 and
        source["source_blob"] == "b21327071e2120fd75113d6051af17dd2c45dbfd",
        "exact public-safe 3D art source pinned")
    check(not source["swept_collision_certified"] and
        not source["human_scale_certified"] and
        not source["has_gameplay_input"] and
        not source["has_ship_physics"],
        "review cannot masquerade as walkable/approved vessel")
    var wing_count: int = 0
    for name in Rig.WING_NAMES:
        var wing: Node3D = review.ship.get_node_or_null("WingRig_" + name)
        if wing != null and wing.get_node_or_null("Membrane_" + name) is MeshInstance3D:
            wing_count += 1
    check(wing_count == 4, "actual four veined wing rigs imported unmodified")

    var state: Dictionary = world.opening.snapshot()
    var checkpoint: Dictionary = world.export_revised_checkpoint()
    var position: Vector2 = world.ender.position
    var bounds: Rect2 = world.ender.walking_bounds
    var objective: String = world.objective.text
    var message: String = world.last_message
    var ship_base: Transform3D = review.ship.global_transform
    check(world.request_ship_pose_3d_review(Port.CUE_GENTLE_SWEEP),
        "real chapter scene can emit neutral wing pose request")
    check(world.advance_ship_pose_3d_review(0.9, false),
        "real wing mesh transitions in native viewport")
    for name in Rig.WING_NAMES:
        var wing: Node3D = review.ship.get_node("WingRig_" + name)
        var direction: float = 1.0 if name.begins_with("Port") else -1.0
        check(is_equal_approx(wing.rotation.y, direction * deg_to_rad(7.5)),
            "actual imported geometry is halfway swept " + name)
    check(world.request_ship_pose_3d_review(Port.CUE_NEUTRAL),
        "interrupt request accepted during moving model")
    check(world.advance_ship_pose_3d_review(0.45, false),
        "interrupt reverses actual model wing movement")
    check(not world.advance_ship_pose_3d_review(NAN, false),
        "invalid timestep fails closed in rendered scene")
    check(world.request_ship_pose_3d_review(Port.CUE_GENTLE_SWEEP),
        "new review request accepted")
    check(world.advance_ship_pose_3d_review(0.0, true),
        "reduced motion stabilizes actual four wing rigs")
    for name in Rig.WING_NAMES:
        var wing: Node3D = review.ship.get_node("WingRig_" + name)
        var direction: float = 1.0 if name.begins_with("Port") else -1.0
        check(is_equal_approx(wing.rotation.y, direction * deg_to_rad(15.0)),
            "reduced-motion rig reaches target " + name)
    check(world.opening.snapshot() == state and
        world.export_revised_checkpoint() == checkpoint and
        world.ender.position == position and
        world.ender.walking_bounds == bounds and
        world.objective.text == objective and world.last_message == message,
        "3D wing animation cannot alter Chapter I quest, actor, or save")
    check(review.ship.global_transform == ship_base,
        "rendered wing animation cannot alter 3D ship transform")
    check(world.resonance_status_label.text.contains("LOCKED"),
        "art presentation cannot grant combined abilities")

    check(world.restore_revised_checkpoint(checkpoint),
        "unchanged v2 save restores while renderer preview active")
    await process_frame
    check(world.ship_pose_3d_review == null and
        not world._ship_spaces_requested,
        "save load revokes and frees transient 3D renderer")
    check(world.opening.snapshot() == state and
        world.export_revised_checkpoint() == checkpoint,
        "save restored canonical story bytes")
    check(world.set_ship_spaces_review_enabled(true),
        "eligible test-only review can be opened again")
    check(world.set_ship_pose_3d_review_enabled(true),
        "valid second preview can reinstantiate real art rig")
    check(world.request_ship_pose_3d_review(Port.CUE_GENTLE_SWEEP) and
        world.advance_ship_pose_3d_review(0.9, false),
        "reopened viewport receives pose request")
    check(not world.set_ship_spaces_review_enabled(false),
        "review opt-out disables ship-space preview")
    await process_frame
    check(world.ship_pose_3d_review == null and
        not world.ship_spaces_handoff.visible and
        not world.request_ship_pose_3d_review(Port.CUE_GENTLE_SWEEP),
        "opt-out frees 3D model and revokes pose access")
    check(world.get_child_count() == node_count,
        "closing review removes the entire 3D render node tree")
    world.queue_free()
    await process_frame
    if failures.is_empty():
        print("FIRST_WAKE_NATIVE_WING_RENDER_PASS checks=", checks,
            " scene=REAL_CH1 rig=ORIGINAL_3D preview=TEST_ONLY scale=BLOCKED")
        quit(0)
    else:
        for failure in failures:
            push_error("FIRST_WAKE_NATIVE_WING_RENDER_FAIL: " + failure)
        quit(1)
