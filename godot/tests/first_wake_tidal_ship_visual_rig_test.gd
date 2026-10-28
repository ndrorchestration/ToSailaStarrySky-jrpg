extends SceneTree
## Native visual-only admission for the current physical First Wake scene.
## Ship geometry/sea shader must NOT change the water sensor, collider,
## story gates, actor rights, release status or the hull's real RigidBody2D.

const Opening = preload("res://scripts/first_wake_revised_opening_contract.gd")
const Stage = preload("res://scenes/first_wake_flight_water_review.tscn")
const Rig = preload("res://scripts/first_wake_aureate_wake_visual_review.gd")
const SeaShader = preload("res://shaders/first_wake_tidal_surface_review.gdshader")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var story = Opening.new()
    if not story.accept_ionia_job() or not story.complete_engineering_checks():
        _fail("Ionia-first preflight contract not available")
        return
    var scene = Stage.instantiate()
    if not scene.configure_preflight(story):
        _fail("physical stage declined verified preflight")
        return
    root.add_child(scene)
    await process_frame

    if not (scene.ship_body is RigidBody2D):
        _fail("new visual rig replaced the actual physical ship")
        return
    if scene.ship_body.name != "AureateWakeLocalBuoyancyProof":
        _fail("real physics vessel identity changed")
        return
    var shape = scene.ship_body.get_node_or_null("CollisionShape2D")
    if not (shape is CollisionShape2D):
        _fail("ship's verified physics collider removed")
        return
    if not (shape.shape is RectangleShape2D) or shape.shape.size != Vector2(144, 34):
        _fail("ship visual change altered the collision geometry")
        return
    if scene.sea_area == null or not (scene.sea_area is Area2D) or scene.berth_area == null:
        _fail("physical water/berth sensors missing")
        return
    var sea = scene.tidal_surface_visual
    if not (sea is ColorRect) or sea.position != Vector2(0, scene.SURFACE_Y):
        _fail("animated tidal surface is not in the expected optical layer")
        return
    if sea.size != Vector2(960, 640.0 - scene.SURFACE_Y):
        _fail("water shader does not fill native 960x640 seascape")
        return
    if sea.mouse_filter != Control.MOUSE_FILTER_IGNORE:
        _fail("water material traps gameplay input")
        return
    if not (sea.material is ShaderMaterial) or sea.material.shader != SeaShader:
        _fail("authored original water shader not bound")
        return
    if not (scene.ship_visual_rig is Node2D) or scene.ship_visual_rig.get_script() != Rig:
        _fail("real rigidbody is not carrying the Aureate Wake dome visual")
        return
    var contract: Dictionary = scene.ship_visual_rig.visual_contract()
    if contract.get("review_only") != true or contract.get("art_accepted") != false:
        _fail("visual art was silently approved")
        return
    for denied in ["physics_authority", "combat_authority", "world_travel_authority", "ship_transformation_revealed"]:
        if contract.get(denied) != false:
            _fail("decorative rig acquired unsupported capability: " + denied)
            return
    if contract.get("bridge_profile") != "provisional_geodesic_dome":
        _fail("review silhouette lost its bridge identity")
        return
    if scene.review_snapshot()["production_ocean_verified"] or scene.review_snapshot()["approved_shoreline_or_tow_method"]:
        _fail("painted ocean was mistaken for production travel proof")
        return
    if scene.phase != "awaiting_launch" or scene.ship_visual_rig.stage != scene.phase:
        _fail("ship visual not synchronized to actual stage")
        return
    if not scene.interact():
        _fail("decorative water blocked real player flight input")
        return
    if scene.phase != "ascent" or scene.ship_visual_rig.stage != "ascent":
        _fail("animated material/engine highlight lost stage updates")
        return
    if scene.opening.active_party_ids != ["ender", "ionia"]:
        _fail("cosmetic upgrade changed opening story authority")
        return
    scene.ship_visual_rig.reduced_motion = true
    var stage: String = scene.ship_visual_rig.stage
    scene.ship_visual_rig._process(0.1)
    if scene.ship_visual_rig.stage != stage:
        _fail("reduced-motion setting changes scene gameplay")
        return

    scene.queue_free()
    await process_frame
    print("TSTSS_WAKE_TIDAL_VISUAL_RIG_PASS: shader + dome present; original RigidBody2D 144x34 collider, Ionia-first story, input, water/berth sensors and zero gameplay/canon authority preserved")
    quit(0)

func _fail(message: String) -> void:
    push_error("TSTSS_WAKE_TIDAL_VISUAL_RIG_FAIL: " + message)
    quit(1)
