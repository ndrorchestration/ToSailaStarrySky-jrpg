extends SceneTree
## One-way exact-source PNG -> real 3D ship water and sky, no story/physics.
const Wrapper = preload("res://scenes/first_wake_optional_shipboard_3d_review.tscn")
const Coastal = preload("res://scripts/first_wake_coastal_atmosphere_review.gd")
const Codec = preload("res://scripts/first_wake_revised_checkpoint_codec.gd")
const SHADER = preload("res://shaders/first_wake_coastal_ocean_review.gdshader")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func verify(ok: bool, note: String) -> void:
    checks += 1
    if not ok:
        failures.append(note)

func _source_manifest_ok() -> bool:
    var path := "res://art-staging/environment-study/intake-manifest.json"
    var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not (manifest is Dictionary):
        return false
    for item in manifest.get("assets", []):
        if item.get("key") == "water":
            return item.get("gitBlob") == Coastal.SOURCE_BLOB and (
                item.get("width") == 128) and (item.get("height") == 128) and (
                item.get("destinationPath") ==
                "godot/art-staging/environment-study/water_ripple_detail.png")
    return false

func _step(actor: CharacterBody3D, z: float) -> bool:
    actor.set_test_direction(Vector2(0, -1))
    var reached: bool = false
    for i in range(270):
        await physics_frame
        await process_frame
        if actor.position.z < z:
            reached = true
            break
    actor.set_test_direction(Vector2.ZERO)
    await physics_frame
    return reached

func _run() -> void:
    var scene = Wrapper.instantiate()
    root.add_child(scene)
    await process_frame
    var atmosphere = scene.atmosphere_review
    var ship = scene.ship
    verify(atmosphere.get_script() == Coastal
        and atmosphere.get_parent() == ship,
        "real review environment is attached only to optional ship scene")
    verify(_source_manifest_ok(),
        "actual staged original PR 476 source ripple blob has exact manifest identity")
    var source: Dictionary = atmosphere.source_contract()
    verify(source["source_draft_pr"] == 476
        and source["water_resolution"] == Vector2i(128, 128),
        "source texture loads through actual Godot Texture2D with 128x128 resolution")
    verify(source["simulation"] == false
        and source["real_wave_collision"] == false
        and source["production_ready"] == false,
        "water/sky never claimed simulated or final physical environment")
    verify(atmosphere.ocean is MeshInstance3D
        and atmosphere.ocean.mesh is PlaneMesh
        and atmosphere.ocean.material_override is ShaderMaterial,
        "water is actual textured 3D mesh and active in-engine Godot shader")
    verify(atmosphere.ocean_material.shader == SHADER
        and atmosphere.ocean_material.get_shader_parameter("ripple_tex") is Texture2D,
        "native water shader actually samples imported texture from staged source")
    verify(atmosphere.ocean.position.y < -1.5
        and atmosphere.ocean.mesh.size.x > 140.0,
        "ocean stays visually below ship deck with useful distant horizon coverage")
    verify(atmosphere.ocean.get_child_count() == 0
        and not (atmosphere.ocean is CollisionObject3D),
        "ocean plane adds no collision/physics/ship buoyancy grant")
    verify(not scene.three_d_review_active
        and not scene.cycle_atmosphere_review(),
        "environment controls inaccessible when Ender is alone/job searching")
    var legal: Dictionary = {
        "schema": Codec.SCHEMA, "step": "engineering",
        "flyer_read": true, "room": "engineering",
        "inspections": [],
        "player_position": {"x": 226.0, "y": 470.0}
    }
    verify(scene.chapter.restore_revised_checkpoint(legal)
        and scene.request_3d_ship_review(true),
        "V is eligible only after legitimate Ionia-first engineering progression")
    var saved: Dictionary = scene.chapter.export_revised_checkpoint()
    var story: Dictionary = scene.chapter.opening.snapshot()
    verify(atmosphere.review_profile == "coastal_dusk"
        and atmosphere.ocean.visible,
        "coastal dusk preview is actually visible after approved entry")
    var e: Environment = ship.get_node("MetricShipEnvironment").environment
    verify(e.background_mode == Environment.BG_SKY
        and e.sky != null and e.sky.sky_material is ProceduralSkyMaterial,
        "native Godot environment uses real procedural panoramic sky")
    verify(e.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR,
        "sky change retains original ambient light authority without arbitrary sky lighting")
    var dusk_sun: Color = ship.get_node("MetricSunlight").light_color
    verify(atmosphere.cycle_coastal_lighting()
        and atmosphere.review_profile == "coastal_clear",
        "environment switching to clear palette succeeds only in review")
    verify(ship.get_node("MetricSunlight").light_color != dusk_sun,
        "real world sunlight temperature differs between clear and dusk profiles")
    verify(atmosphere.set_review_profile("flat")
        and not atmosphere.ocean.visible,
        "flat A/B restores absent ocean for strictly reversible original look")
    verify(ship.get_node("MetricShipEnvironment").environment
        == atmosphere._original_environment,
        "flat profile restores original unchanged Environment Resource")
    verify(not atmosphere.set_review_profile("supernova")
        and atmosphere.review_profile == "flat",
        "unknown/restricted atmospheric or ship abilities cannot be requested")
    verify(scene.cycle_atmosphere_review()
        and atmosphere.review_profile == "coastal_dusk"
        and atmosphere.ocean.visible,
        "V explicitly enables real original-source dusk ocean after flat QA state")
    verify(scene.cycle_atmosphere_review()
        and atmosphere.review_profile == "coastal_clear",
        "V cycles between visible clear and dusk lighting without unlocking magic")
    verify(scene.cycle_atmosphere_review()
        and atmosphere.review_profile == "coastal_dusk",
        "V cycles back to dusk without changing any physics objects")
    verify(scene.helm_feedback.visible
        and scene.helm_feedback_body.text.contains("visual only"),
        "the actual Godot game HUD identifies atmosphere switch as nonphysical")
    var actor: CharacterBody3D = ship.crew_walker
    for i in range(27):
        await physics_frame
    var reached_deck: bool = await _step(actor, -4.25)
    verify(actor.is_on_floor() and reached_deck,
        "genuine CharacterBody3D remains walkable onto guarded 3D foredeck")
    verify(actor.is_on_floor() and actor.position.z < -4.1,
        "water mesh never replaces physical deck footing/collision")
    verify(scene.chapter.export_revised_checkpoint() == saved
        and scene.chapter.opening.snapshot() == story,
        "animated weather/sky art does not alter the original story/save")
    verify(scene.request_3d_ship_review(false)
        and not scene.cycle_atmosphere_review()
        and scene.chapter.visible,
        "return to real 2D engineering disables all review atmosphere controls")
    verify(scene.chapter.export_revised_checkpoint() == saved
        and scene.chapter.resonance_status_label.text.contains("LOCKED"),
        "real v2 saved checkpoint and Resonance lock unchanged on return")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("FIRST_WAKE_COASTAL_ATMOSPHERE_PASS checks=", checks,
            " water=EXACT_SOURCE_BLOB_STAGED",
            " sky=REAL_GODOT",
            " collision=UNCHANGED",
            " story=UNCHANGED",
            " production=BLOCKED")
        quit(0)
    else:
        for reason in failures:
            push_error("FIRST_WAKE_COASTAL_ATMOSPHERE_FAIL: " + reason)
        quit(1)
