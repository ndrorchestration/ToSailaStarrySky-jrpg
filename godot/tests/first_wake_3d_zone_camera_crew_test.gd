extends SceneTree
## Native first-wake gameplay camera and animated avatar visual review.
const Wrapper = preload("res://scenes/first_wake_optional_shipboard_3d_review.tscn")
const Codec = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
const CameraScript = preload("res://scripts/first_wake_3d_zone_camera_review.gd")
const Proxy = preload("res://scripts/first_wake_3d_crew_motion_proxy.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures.append(message)

func _approach(actor: CharacterBody3D, target_z: float) -> bool:
    var toward: bool = target_z < actor.position.z
    actor.set_test_direction(Vector2(0, -1 if toward else 1))
    var reached: bool = false
    for tick in range(260):
        await physics_frame
        await process_frame
        if (toward and actor.position.z <= target_z) or (
                not toward and actor.position.z >= target_z):
            reached = true
            break
    actor.set_test_direction(Vector2.ZERO)
    await physics_frame
    await process_frame
    return reached

func _run() -> void:
    var wrapper = Wrapper.instantiate()
    root.add_child(wrapper)
    await process_frame
    var actor: CharacterBody3D = wrapper.ship.crew_walker
    var rig = wrapper.zone_camera
    var visual = wrapper.motion_visual
    check(rig != null and rig.get_script() == CameraScript
        and rig.camera is Camera3D and rig.actor == actor,
        "a real separate zone-aware camera follows the existing physical actor")
    check(visual.get_script() == Proxy
        and visual.get_parent() == actor
        and actor.get_node("ActorCapsulePhysics") is CollisionShape3D,
        "art-only articulated crew attaches to unmodified actual capsule collider")
    check(not actor.get_node("AnonymousCrewBodyVisual").visible
        and not actor.get_node("FacingMarker").visible
        and visual.visible,
        "anonymous original capsule visual replaced, not physical collision")
    check(visual.get_node("PrototypeTunicTorso") is MeshInstance3D
        and visual.get_node("PrototypeUnidentifiedCrewHead") is MeshInstance3D
        and visual.get_node("LeftReviewArm") is MeshInstance3D
        and visual.get_node("RightReviewArm") is MeshInstance3D
        and visual.get_node("LeftReviewLeg") is MeshInstance3D
        and visual.get_node("RightReviewLeg") is MeshInstance3D,
        "six distinct actual Godot geometry components create a recognizable crew silhouette")
    check(not wrapper.cycle_camera_review()
        and not rig.active and not rig.camera.current,
        "the visual camera cannot be activated in Ender-alone job-search mode")
    var fixture: Dictionary = {
        "schema": Codec.SCHEMA,
        "step": "engineering",
        "flyer_read": true,
        "room": "engineering",
        "inspections": [],
        "player_position": {"x": 226.0, "y": 470.0}
    }
    check(wrapper.chapter.restore_revised_checkpoint(fixture)
        and wrapper.request_3d_ship_review(true),
        "real Ionia-first save validator grants controlled opt-in 3D scene only")
    await process_frame
    check(rig.active and rig.camera.current
        and not wrapper.ship.crew_camera.current and rig.zone == "cabin",
        "new camera is active at cabin while legacy distant lens remains inactive")
    check(rig.last_unobstructed_distance >= CameraScript.MIN_CAMERA_DISTANCE_M
        and rig.last_unobstructed_distance < 3.5,
        "cabin camera uses a real bounded third-person distance")
    for tick in range(35):
        await physics_frame
    check(actor.is_on_floor() and visual.walk_cycles == 0,
        "actor grounded; actual idle proxy does not play the walk cycle")
    var cam_before: Vector3 = rig.camera.global_position
    check(await _approach(actor, -1.40), "move physical walker from cabin into helm")
    check(rig.zone == "helm" and rig.camera.current,
        "camera automatically changes to the enclosed geodesic helm shot")
    for settle_tick in range(5):
        await physics_frame
        await process_frame
    print("FIRST_WAKE_ZONE_CAMERA_ANIM_DEBUG cycles=", visual.walk_cycles,
        " speed=", visual.current_speed, " velocity=", actor.velocity)
    check(visual.walk_cycles >= 1,
        "actual physical motion advances the animated visual stride")
    check(visual.current_speed < 0.1,
        "walking proxy ceases animation input after movement stops")
    check(cam_before.distance_to(rig.camera.global_position) > 2.0,
        "actual camera follows character movement, not a fixed staged render")
    check(visual.get_node("LeftReviewArm").rotation.x > -0.60
        and visual.get_node("LeftReviewArm").rotation.x < 0.60,
        "art motion is constrained to an anatomical review-range swing")
    var old_shot: int = rig.shot
    check(wrapper.cycle_camera_review() and rig.shot != old_shot
        and rig.camera.current,
        "C swaps from follow to elevated, no duplicate active cameras")
    check(wrapper.cycle_camera_review() and rig.shot == old_shot,
        "C returns to follow viewpoint without modifying actor position")
    check(await _approach(actor, -4.35),
        "walk physically through the open hatch onto the guarded open foredeck")
    check(rig.zone == "foredeck" and actor.is_on_floor(),
        "camera follows player into the exposed bow and deck remains solid")
    check(rig.last_unobstructed_distance < 3.5,
        "foredeck view stays within the bounded, actor-readable camera arm")
    var prior: Vector3 = rig.camera.global_position
    check(wrapper.cycle_camera_review() and rig.shot == CameraScript.Shot.ELEVATED,
        "elevated deck framing is available for optional inspection")
    check(rig.camera.global_position.distance_to(prior) > 0.18,
        "elevated view changes actual Camera3D position rather than label alone")
    check(wrapper.cycle_camera_review()
        and rig.shot == CameraScript.Shot.FOLLOW,
        "elevated camera reversible on the same physical ship")

    # Add a temporary rigid obstacle on the current camera arm, then require
    # the real ray geometry to shorten the arm before clipping that surface.
    var eye: Vector3 = actor.global_position + Vector3(0, 0.39, 0)
    var desired: Vector3 = eye + Vector3(0.5, 1.16, 1.0)
    var body := StaticBody3D.new()
    body.name = "ReviewCameraOccluderFixture"
    body.position = eye.lerp(desired, 0.56)
    body.collision_layer = 8
    body.collision_mask = 0
    var shape := CollisionShape3D.new()
    var block := BoxShape3D.new()
    block.size = Vector3(0.38, 0.38, 0.38)
    shape.shape = block
    body.add_child(shape)
    wrapper.ship.add_child(body)
    await physics_frame
    var shortened: Vector3 = rig._find_safe_position(eye, desired)
    check(rig.occluded and shortened.distance_to(eye) <
        desired.distance_to(eye) - 0.18,
        "actual static collider interrupts the lens arm and prevents wall clipping")
    body.queue_free()
    await physics_frame
    check(wrapper.request_3d_ship_review(false)
        and not rig.camera.current and not rig.active,
        "return disables separate Camera3D and restores original active 2D scene")
    check(wrapper.chapter.export_revised_checkpoint() == fixture
        and wrapper.chapter.resonance_status_label.text.contains("LOCKED"),
        "animation/camera review cannot mutate 2D checkpoint or Resonance permissions")
    wrapper.queue_free()
    await process_frame
    if failures.is_empty():
        print("FIRST_WAKE_ZONE_CAMERA_PASS checks=", checks,
            " real_camera=ZONE_AWARE",
            " crew=ANIMATED_PROXY",
            " occlusion=PHYSICS",
            " story=UNCHANGED",
            " production=BLOCKED")
        quit(0)
    else:
        for issue in failures:
            push_error("FIRST_WAKE_ZONE_CAMERA_FAIL: " + issue)
        quit(1)
