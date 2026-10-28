extends SceneTree
## Public-safe integration demonstration: wing pose + existing weather/flight.
## Does not enable a gameplay control, cinematic reveal or save mutation.
const Study = preload("res://main.tscn")
const PosePipeline = preload("res://wing_pose_pipeline.gd")
const WINGS = ["PortFore", "PortAft", "StarboardFore", "StarboardAft"]
var checks: int = 0
var failures: Array[String] = []

func check(ok: bool, note: String) -> void:
    checks += 1
    if not ok:
        failures.append(note)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.ship.set_motion(0.0, true)
    var controller = PosePipeline.new()
    var original_position: Vector3 = scene.ship.global_position
    var original_pose: Transform3D = scene.ship.global_transform
    var hull_mesh: Mesh = (scene.ship.get_node("LongHull") as MeshInstance3D).mesh
    var terrain_count: int = scene.terrain.chunk_count()
    var look: Dictionary = scene.visuals.current_mood.duplicate(true)

    # Same 1.8-second review window; intentionally independent state machines.
    check(controller.request_pose(1.0, 1.8), "accept generic review movement")
    scene.visuals.queue_environment_look(3, 3, true, 1.8)
    check(controller.advance(scene.ship, 0.9, false),
        "wing pose advances during storm grade")
    scene.visuals.advance_environment_transition(0.9, false)
    check(is_equal_approx(controller.current_pose, 0.5),
        "halfway smoothstep returns neutral halfway wing pose")
    check(controller.active, "halfway wing transition remains active")
    check(scene.visuals.transition_active,
        "weather transition remains separately active")
    check(scene.visuals.current_mood != look,
        "same-frame weather visually responds without owning wing pose")
    for name in WINGS:
        var wing: Node3D = scene.ship.get_node("WingRig_" + name)
        var signed: float = 1.0 if name.begins_with("Port") else -1.0
        check(is_equal_approx(wing.rotation.y, signed * deg_to_rad(7.5)),
            "half-sweep remains symmetric: " + name)

    # Interrupt from currently interpolated state, never jump back to start.
    check(controller.request_pose(0.0, 1.8), "request return while moving")
    check(is_equal_approx(controller.current_pose, 0.5),
        "interruption does not snap rendered pose")
    check(controller.advance(scene.ship, 0.45, false), "reverse progresses")
    check(controller.current_pose > 0.0 and controller.current_pose < 0.5,
        "reverse continues from halfway state")
    var before_bad: float = controller.current_pose
    check(not controller.request_pose(NAN, 1.8), "reject non-finite request")
    check(not controller.request_pose(0.0, 0.0), "reject invalid duration")
    check(not controller.advance(scene.ship, NAN, false),
        "reject non-finite frame delta")
    check(is_equal_approx(controller.current_pose, before_bad),
        "rejected actions do not alter pose")
    check(controller.advance(scene.ship, 0.0, false),
        "zero dt valid while paused")
    check(is_equal_approx(controller.current_pose, before_bad),
        "paused pose remains stationary")

    # M reduced motion snaps to the target, independently of weather effects.
    check(controller.request_pose(1.0, 1.8), "new preview request accepted")
    check(controller.advance(scene.ship, 0.0, true),
        "reduced motion snaps wing pose safely")
    check(is_equal_approx(controller.current_pose, 1.0) and not controller.active,
        "reduced motion reaches stable target")
    scene.ship.set_motion(12.0, true)
    for name in WINGS:
        var wing: Node3D = scene.ship.get_node("WingRig_" + name)
        check(is_zero_approx(wing.rotation.z),
            "no procedural flex in reduced motion: " + name)
    check(controller.request_pose(0.0), "return to default pose")
    check(controller.advance(scene.ship, 0.0, true),
        "reduced motion restores original geometry without animation")
    for name in WINGS:
        var wing: Node3D = scene.ship.get_node("WingRig_" + name)
        check(is_zero_approx(wing.rotation.y),
            "neutral yaw restored: " + name)

    # A wing review must never authorize flight or touchdown.
    check(scene.ship.global_position == original_position,
        "wing pose did not move ship")
    check(scene.ship.global_transform == original_pose,
        "wing review did not steer or rotate ship")
    check((scene.ship.get_node("LongHull") as MeshInstance3D).mesh == hull_mesh,
        "hull mesh preserved")
    check(scene.terrain.chunk_count() == terrain_count,
        "streamed terrain budget preserved")
    check(scene.landing.state == "FLYING", "no landing state granted by wing pose")
    scene.set_manual_mode(true)
    check(scene.request_touchdown(), "native flight scene retains touchdown request")
    check(scene.landing.state == "FLYING",
        "wing preview cannot bypass physics-confirmed touchdown gate")
    scene.set_manual_mode(false)
    check(not scene._touchdown_requested, "flight reset clears queued touchdown")
    check(scene.landing.state == "FLYING", "flight reset restores landing authority")

    # A failed / missing ship is rejected without committing pending pose.
    check(controller.request_pose(1.0, 1.8), "pending request for missing ship")
    check(not controller.advance(null, 0.5, false), "missing ship rejected")
    check(is_zero_approx(controller.current_pose),
        "missing ship cannot advance controller state")

    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_WING_POSE_PIPELINE_PASS checks=", checks)
        quit(0)
    else:
        for note in failures:
            push_error("GODOT_WING_POSE_PIPELINE_FAIL: " + note)
        quit(1)
