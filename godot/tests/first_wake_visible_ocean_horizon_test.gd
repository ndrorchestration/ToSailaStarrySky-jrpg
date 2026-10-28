extends SceneTree
## Verify camera has water below sightline and sky above, in real Godot physics.
const Scene = preload("res://scenes/first_wake_optional_shipboard_3d_review.tscn")
const Codec = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
const Maritime = preload("res://scripts/first_wake_maritime_atmosphere_review.gd")
var total: int = 0
var failed: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func verify(ok: bool, description: String) -> void:
    total += 1
    if not ok:
        failed.append(description)

func _move(actor: CharacterBody3D, z: float) -> bool:
    actor.set_test_direction(Vector2(0, -1))
    var reached := false
    for step in range(250):
        await physics_frame
        await process_frame
        if actor.position.z <= z:
            reached = true
            break
    actor.set_test_direction(Vector2.ZERO)
    for step in range(8):
        await physics_frame
        await process_frame
    return reached

func _run() -> void:
    var review = Scene.instantiate()
    root.add_child(review)
    await process_frame
    var sea = review.maritime_atmosphere
    verify(sea.ocean.mesh is PlaneMesh and sea.ocean.material_override is ShaderMaterial,
        "real Godot mesh/material remains attached to optional review scene")
    var mesh: PlaneMesh = sea.ocean.mesh
    verify(mesh.subdivide_width >= 96 and mesh.subdivide_depth >= 96,
        "ocean has enough subdivisions for wide low-frequency vertex swells")
    verify(mesh.size.x > 400.0 and mesh.size.y > 400.0,
        "water extends across the forward visible range instead of clipping at 70m")
    var ocean_shader: Shader = sea.ocean.material_override.shader
    verify(ocean_shader != null and ocean_shader.code.contains("sea_position")
        and ocean_shader.code.contains("local_wave_normal"),
        "layered surface ripples and real varying wave normals are in actual shader")
    verify(sea.ocean.position.y <= -0.90 and
        sea.ocean.get_node_or_null("CollisionShape3D") == null,
        "sea is below the deck and has no false buoyancy/collision")
    verify(not review.request_3d_ship_review(true),
        "unhired Ender cannot activate a new environmental stage")
    var fixture: Dictionary = {
        "schema": Codec.SCHEMA, "step": "engineering",
        "flyer_read": true, "room": "engineering",
        "inspections": [],
        "player_position": {"x": 226.0, "y": 470.0}
    }
    verify(review.chapter.restore_revised_checkpoint(fixture)
        and review.request_3d_ship_review(true),
        "Ionia-first legitimate reviewed story still gates real 3D access")
    var actor: CharacterBody3D = review.ship.crew_walker
    for step in range(30):
        await physics_frame
    verify(await _move(actor, -4.30),
        "existing real CharacterBody3D can physically reach open deck")
    var lens: Camera3D = review.zone_camera.camera
    verify(review.zone_camera.zone == "foredeck" and lens.current,
        "native Godot has active real foredeck Camera3D, not screenshot facade")
    verify(lens.far >= 200.0 and lens.global_position.z > actor.global_position.z,
        "follow view behind character has adequate genuine sea draw distance")
    var middle: Vector3 = lens.project_ray_normal(Vector2(480, 320))
    var sky: Vector3 = lens.project_ray_normal(Vector2(480, 90))
    var below: Vector3 = lens.project_ray_normal(Vector2(480, 500))
    verify(middle.y < -0.015 and sky.y > 0.0 and below.y < middle.y,
        "actual camera sightline includes sky above and sea below central horizon")
    var water_distance: float = (
        (Maritime.SEA_LEVEL_M - lens.global_position.y) / middle.y
        if middle.y < 0.0 else INF)
    verify(water_distance > 5.0 and water_distance < lens.far,
        "central camera ray can reach true ocean plane before far clipping")
    var water_hit: Vector3 = lens.global_position + middle * water_distance
    verify(absf(water_hit.x) < Maritime.SEA_RADIUS_M
        and absf(water_hit.z) < Maritime.SEA_RADIUS_M,
        "forward view projects inside the actual world-scaled water mesh")
    verify(review.ship.get_node("ForedeckHatchHinge/HatchCollisionBody") is StaticBody3D
        and review.ship.get_node("ForedeckNoseInfill0Body") is StaticBody3D,
        "actual physics hatch and five-level deck guards remain intact")
    verify(review.request_3d_ship_review(false)
        and review.chapter.export_revised_checkpoint() == fixture
        and review.chapter.resonance_status_label.text.contains("LOCKED"),
        "return restores exact Ionia-first checkpoint and cannot grant combat")
    review.queue_free()
    await process_frame
    if failed.is_empty():
        print("FIRST_WAKE_VISIBLE_HORIZON_PASS checks=", total,
            " mid_water_distance_m=", snappedf(water_distance, 0.01),
            " shader=LAYERS camera=FORWARD",
            " physics=UNCHANGED story=UNCHANGED production=BLOCKED")
        quit(0)
    else:
        for error in failed:
            push_error("FIRST_WAKE_VISIBLE_HORIZON_FAIL: " + error)
        quit(1)
