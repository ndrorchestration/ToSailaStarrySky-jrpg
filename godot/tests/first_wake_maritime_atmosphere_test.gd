extends SceneTree
## Real optional Chapter I sky/water presence plus physical/save isolation.
const Scene = preload("res://scenes/first_wake_optional_shipboard_3d_review.tscn")
const Codec = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
const Atmosphere = preload("res://scripts/first_wake_maritime_atmosphere_review.gd")
var count: int = 0
var errors: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, label: String) -> void:
    count += 1
    if not ok:
        errors.append(label)

func _run() -> void:
    var wrapper = Scene.instantiate()
    root.add_child(wrapper)
    await process_frame
    var layer = wrapper.maritime_atmosphere
    check(layer != null and layer.get_script() == Atmosphere,
        "real optional Godot scene owns new environmental art layer")
    check(layer.ocean is MeshInstance3D and layer.ocean.mesh is PlaneMesh
        and layer.ocean.material_override is ShaderMaterial,
        "ocean is actual Godot mesh with native compiled water shader")
    check(layer.atmosphere is WorldEnvironment
        and layer.atmosphere.environment != null,
        "native Godot world environment provides procedural sky")
    check(layer.atmosphere.environment.background_mode == Environment.BG_SKY
        and layer.atmosphere.environment.sky != null,
        "world sky is actual procedural Sky not plain dark background")
    check(layer.sky_energy == 1.0 and Atmosphere.SEA_LEVEL_M < -0.40,
        "ocean visual remains below traversable deck at provisional elevation")
    check(layer.ocean.get_node_or_null("CollisionShape3D") == null,
        "wave mesh cannot grant buoyancy or alter collision")
    check(wrapper.ship.get_node("MetricShipEnvironment").environment == null,
        "underlying old dark environment deactivated only in optional review")
    check(not wrapper.request_3d_ship_review(true)
        and not wrapper.three_d_review_active,
        "unhired Ender cannot activate visual ship walkthrough")
    var fixture: Dictionary = {
        "schema": Codec.SCHEMA, "step": "engineering",
        "flyer_read": true, "room": "engineering", "inspections": [],
        "player_position": {"x": 226.0, "y": 470.0}
    }
    check(wrapper.chapter.restore_revised_checkpoint(fixture)
        and wrapper.request_3d_ship_review(true),
        "Ionia-first verified engineering scene still admits optional 3D")
    await physics_frame
    check(wrapper.ship.visible and wrapper.zone_camera.camera.current,
        "scene still has real controllable 3D camera and ship")
    check(wrapper.ship.crew_walker.get_node("ActorCapsulePhysics") is CollisionShape3D,
        "actual actor collision survives atmospheric art change")
    check(wrapper.ship.get_node("ForedeckNoseInfill0Body") is StaticBody3D,
        "physical bow safety infill preserved independently of ocean plane")
    check(wrapper.ship.get_node("HatchCollisionBody") is StaticBody3D,
        "the physical hatch remains intact over visual-only sea")
    check(wrapper.request_3d_ship_review(false)
        and wrapper.chapter.export_revised_checkpoint() == fixture,
        "2D return and exact First Wake checkpoint untouched")
    check(wrapper.chapter.resonance_status_label.text.contains("LOCKED")
        and not wrapper.three_d_review_active,
        "ship's sky art never grants story or magic authority")
    wrapper.queue_free()
    await process_frame
    if errors.is_empty():
        print("FIRST_WAKE_MARITIME_ATMOSPHERE_PASS checks=", count,
            " sea=SHADER_ONLY sky=PROCEDURAL",
            " story=UNCHANGED production=BLOCKED")
        quit(0)
    else:
        for issue in errors:
            push_error("FIRST_WAKE_MARITIME_ATMOSPHERE_FAIL: " + issue)
        quit(1)
