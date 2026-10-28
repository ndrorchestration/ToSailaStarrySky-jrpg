extends SceneTree
## Real physics driven CharacterBody3D and hatch interaction, not teleport QA.
const StudyScene = preload("res://scenes/aureate_wake_metric_bridge_study.tscn")
const Ship = preload("res://scripts/aureate_wake_metric_bridge_study.gd")
const Crew = preload("res://scripts/aureate_wake_crew_walk_review.gd")
const Admission = preload("res://scripts/ship_space_production_admission_gate.gd")
const FirstWake = preload("res://scenes/first_wake_job_preview.tscn")
var count: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, name: String) -> void:
    count += 1
    if not value:
        failures.append(name)

func drive_z(actor: CharacterBody3D, z_target: float,
        max_steps: int = 240) -> bool:
    var toward_front: bool = z_target < actor.position.z
    actor.set_test_direction(Vector2(0, -1 if toward_front else 1))
    var arrived: bool = false
    for step in range(max_steps):
        await physics_frame
        if ((actor.position.z <= z_target) if toward_front
                else (actor.position.z >= z_target)):
            arrived = true
            break
    actor.set_test_direction(Vector2.ZERO)
    await physics_frame
    return arrived

func _run() -> void:
    var ship = StudyScene.instantiate()
    root.add_child(ship)
    await process_frame
    var walker = ship.crew_walker as Crew
    check(walker != null and walker is CharacterBody3D,
        "actual Godot CharacterBody3D inside isolated metric ship")
    check(walker.get_node("ActorCapsulePhysics") is CollisionShape3D
        and walker.get_node("AnonymousCrewBodyVisual") is MeshInstance3D,
        "visible human-scale avatar shares actual capsule shape")
    var capsule := walker.get_node("ActorCapsulePhysics").shape as CapsuleShape3D
    check(is_equal_approx(capsule.radius, 0.26) and
        is_equal_approx(capsule.height, 1.74),
        "1.74 m tall actual player body retains 0.26m capsule radius")
    check(walker.collision_mask == Ship.COLLISION_LAYER,
        "character resolves against real hatch/rails/floors layer")
    walker.manual_controls_enabled = false
    walker.set_test_direction(Vector2.ZERO)
    for frame in range(35):
        await physics_frame
    check(walker.is_on_floor() and walker.position.y > 0.84
        and walker.position.y < 0.92,
        "controller has actually settled onto cabin floor via gravity")
    check(not ship.request_crew_hatch_interaction()
        and ship.is_hatch_open(),
        "remote E interaction rejected from crew cabin")
    check(ship.get_forward_helm_sightline()["clear"],
        "open hatch preserves forward navigation lookout line-of-sight")

    check(await drive_z(walker, -1.58), "walking controls reach helm from cabin")
    check(walker.is_on_floor() and absf(walker.position.x) < 0.10,
        "walking remains grounded and centred across actual cabin→helm seam")
    check(ship.request_crew_hatch_interaction() and not ship.is_hatch_open(),
        "near-hatch interaction closes actual collider at helm station")
    await physics_frame
    var sight: Dictionary = ship.get_forward_helm_sightline()
    check(not sight["clear"] and sight["collider_name"] == "HatchCollisionBody",
        "closed physical hatch occludes helm navigation sightline")
    var blocked_position: float = walker.position.z
    check(not await drive_z(walker, -3.05, 62),
        "real walking body cannot pass closed hatch")
    check(walker.position.z > -2.55 and
        walker.position.z < blocked_position,
        "collision resolves just before the closed hatch without tunneling")
    check(ship.request_crew_hatch_interaction() and ship.is_hatch_open(),
        "actual walker can reopen a nearby physically closed door")
    await physics_frame
    check(ship.get_forward_helm_sightline()["clear"],
        "reopened portal restores real forward camera view to exposed deck")
    check(await drive_z(walker, -4.43),
        "actual CharacterBody3D reaches exposed deck from helm")
    check(walker.is_on_floor() and walker.position.z < -4.30,
        "deck is genuinely grounded under the new moving actor")
    check(not ship.request_crew_hatch_interaction(),
        "open deck cannot remotely toggle a helm hatch")

    var initial_x: float = walker.position.x
    walker.set_test_direction(Vector2(1, 0))
    for frame in range(12):
        await physics_frame
    walker.set_test_direction(Vector2.ZERO)
    await physics_frame
    check(walker.position.x > initial_x + 0.38
        and walker.position.x < 1.0,
        "real CharacterBody3D supports physical turning/movement within rails")
    walker.set_test_direction(Vector2(-1, 0))
    for frame in range(12):
        await physics_frame
    walker.set_test_direction(Vector2.ZERO)
    await physics_frame
    check(absf(walker.position.x) < 0.14,
        "walker returns to center corridor without a teleport")
    check(await drive_z(walker, -1.57),
        "adult actor reverses the genuine 3D helm→deck path")
    check(walker.is_on_floor(), "real actor remains grounded on return")

    ship.set_crew_follow_camera(true)
    for frame in range(3):
        await process_frame
    var camera: Camera3D = ship.crew_camera
    var cam_before: Vector3 = camera.global_position
    check(camera.current and cam_before.distance_to(walker.position) > 0.50,
        "actual follow camera is now active and anchored on moving actor")
    walker.set_test_direction(Vector2(0, 1))
    for frame in range(14):
        await physics_frame
        await process_frame
    walker.set_test_direction(Vector2.ZERO)
    await process_frame
    check(camera.global_position.distance_to(cam_before) > 0.30,
        "follow camera genuinely moves with actual physics-based walking")
    # Build a temporary fully solid occluder on the camera's third-person arm:
    # the ray must shorten before clipping through an intervening body.
    var eye: Vector3 = walker.global_position + Vector3.UP * 0.55
    var desired: Vector3 = eye + Vector3(1.80, 1.50, 3.05)
    var blocker := StaticBody3D.new()
    blocker.name = "CameraOccluderTestFixture"
    blocker.position = eye.lerp(desired, 0.52)
    blocker.collision_layer = Ship.COLLISION_LAYER
    blocker.collision_mask = 0
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.70, 0.70, 0.70)
    shape.shape = box
    blocker.add_child(shape)
    ship.add_child(blocker)
    await physics_frame
    for frame in range(3):
        await process_frame
    check(ship.crew_camera_occluded,
        "actual PhysicsDirectSpaceState3D camera ray detects static occluder")
    check(camera.global_position.distance_to(eye) <
        desired.distance_to(eye) - 0.30,
        "camera shortens its arm before intersecting an opaque structure")
    blocker.queue_free()
    await physics_frame
    for frame in range(3):
        await process_frame
    check(camera.global_position.distance_to(eye) > 0.5,
        "camera returns to a nonzero safe distance after obstacle removed")
    ship.set_crew_follow_camera(false)
    check(not camera.current, "opt-in camera can be disabled without gameplay unlock")

    var game = FirstWake.instantiate()
    root.add_child(game)
    await process_frame
    check(game.opening.step_key() == "job_search" and
        game.opening.active_party_ids == ["ender"] and
        not game.ship_spaces_handoff.visible,
        "3D walk lab is not inserted into real Chapter I flyer scene")
    var unchanged: Dictionary = game.opening.snapshot()
    var slot: Dictionary = game.export_revised_checkpoint()
    var gate: Dictionary = Admission.assess(
        Admission.load_manifest(), game.ship_spaces_handoff.source_contract())
    check(gate["next_prototype_review_allowed"]
        and gate["production_ready"] == false,
        "production gate remains false after new actual character walk")
    check(game.opening.snapshot() == unchanged
        and game.export_revised_checkpoint() == slot
        and game.resonance_status_label.text.contains("LOCKED"),
        "independent actor test changes no actual save, party or Resonance grant")
    game.queue_free()
    ship.queue_free()
    await process_frame

    if failures.is_empty():
        print("AUREATE_WAKE_CREW_WALK_PASS checks=", count,
            " actor=CHARACTERBODY3D",
            " hatch=PROXIMITY_AND_PHYSICS",
            " camera=OCCLUSION_TESTED",
            " production=BLOCKED")
        quit(0)
    else:
        for failure in failures:
            push_error("AUREATE_WAKE_CREW_WALK_FAIL: " + failure)
        quit(1)
