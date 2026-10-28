extends SceneTree
## Immutable-source shader intake and real native Godot scene/physics checks.
const Study = preload("res://scenes/aureate_wake_metric_bridge_study.tscn")
const Ship = preload("res://scripts/aureate_wake_metric_bridge_study.gd")
const FirstWake = preload("res://scenes/first_wake_job_preview.tscn")
const SOURCE_MANIFEST := "res://art-staging/ship-glass-study/source-manifest.v1.json"
const SOURCE_SHADER := "res://art-staging/ship-glass-study/bridge_panorama_glass.gdshader"
var count: int = 0
var problems: Array[String] = []

func _initialize() -> void:
    call_deferred("_verify")

func check(ok: bool, message: String) -> void:
    count += 1
    if not ok:
        problems.append(message)

func _full_walk_fraction(state: PhysicsDirectSpaceState3D) -> float:
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.26
    capsule.height = 1.74
    var q := PhysicsShapeQueryParameters3D.new()
    q.shape = capsule
    q.transform = Transform3D(Basis(), Vector3(0, 1.05, 3.0))
    q.motion = Vector3(0, 0, -7.60)
    q.collision_mask = Ship.COLLISION_LAYER
    var interval: PackedFloat32Array = state.cast_motion(q)
    return interval[0] if interval.size() >= 2 else -1.0

func _verify() -> void:
    var raw := FileAccess.open(SOURCE_MANIFEST, FileAccess.READ)
    check(raw != null, "review-only source manifest exists")
    var manifest: Dictionary = {}
    if raw != null:
        var parsed: Variant = JSON.parse_string(raw.get_as_text())
        if parsed is Dictionary:
            manifest = parsed
    var source: Dictionary = manifest.get("source", {})
    var staging: Dictionary = manifest.get("staging", {})
    check(manifest.get("schema") == "tstss.aureate-wake-glass-source.v1",
        "source manifest has versioned exact meaning")
    check(source.get("commit") == (
        "8f7112d0f8ed3afcad8faa76b5d0b224d25cdce9"),
        "source SHA points to original verified isolated PR482")
    check(source.get("git_blob_sha1") == Ship.SOURCE_GLASS_GIT_BLOB_SHA,
        "original exact Git blob identity is pinned")
    check(source.get("content_sha256") == Ship.SOURCE_GLASS_SHA256
        and FileAccess.get_sha256(SOURCE_SHADER) == Ship.SOURCE_GLASS_SHA256,
        "actual native staged shader bytes equal independent source SHA256")
    check(staging.get("mode") == "review_only" and
        staging.get("full_mesh_import") == false and
        staging.get("collision_glazing") == false and
        staging.get("physical_glass_approved") == false and
        staging.get("production_ready") == false,
        "source import grants neither mesh, collision nor production promotion")
    check(manifest.get("allowable_presets") ==
        ["metric_proxy", "source_clear", "source_low_glare"],
        "art intake has exactly three bounded reviewed settings")

    var ship = Study.instantiate()
    root.add_child(ship)
    await process_frame
    await physics_frame
    await physics_frame
    var panes: MeshInstance3D = ship.get_node("MetricFacetedGlassStudy")
    var physical_world: PhysicsDirectSpaceState3D = ship.get_world_3d().direct_space_state
    var previous_mesh: Mesh = panes.mesh
    var prev_panels: int = ship.dome_panels
    var prev_edges: int = ship.dome_frame_edges
    check(ship.glass_review_profile == "metric_proxy"
        and panes.material_override is StandardMaterial3D,
        "isolated ship retains earlier meter-proxy material by default")
    check(ship.set_glass_art_review("source_clear")
        and panes.material_override is ShaderMaterial,
        "an opt-in real ShaderMaterial can load byte-identical original study")
    var shader_material := panes.material_override as ShaderMaterial
    check(shader_material.shader == Ship.SOURCE_GLASS_SHADER,
        "runtime uses exactly source-imported native GL shader")
    check(is_equal_approx(
        float(shader_material.get_shader_parameter("face_alpha")), 0.13),
        "source original clear setting is bounded")
    check(_full_walk_fraction(physical_world) > 0.995,
        "source material never blocks adult capsule in open physical portal")
    check(ship.set_glass_art_review("source_low_glare"),
        "original source shader exposes restrained low-glare review")
    shader_material = panes.material_override as ShaderMaterial
    check(shader_material.shader == Ship.SOURCE_GLASS_SHADER
        and is_equal_approx(float(
            shader_material.get_shader_parameter("highlight_gain")), 0.10)
        and is_equal_approx(float(
            shader_material.get_shader_parameter("edge_alpha")), 0.045),
        "low-glare variant retains original source constraints")
    check(not ship.set_glass_art_review("sealed_pressure_glass")
        and ship.glass_review_profile == "source_low_glare",
        "unapproved pressure/glass gameplay mode cannot be introduced")
    check(panes.mesh == previous_mesh and
        ship.dome_panels == prev_panels and
        ship.dome_frame_edges == prev_edges,
        "source shader intake changes zero material geometry or physical seams")
    ship.set_hatch_open(false)
    await physics_frame
    await physics_frame
    check(_full_walk_fraction(physical_world) < 0.85,
        "closed hatch still physically blocks real capsule under source shader")
    ship.set_hatch_open(true)
    await physics_frame
    await physics_frame
    check(_full_walk_fraction(physical_world) > 0.995,
        "reopened hatch remains traversable with original glass bytes")
    check(ship.set_glass_art_review("metric_proxy")
        and panes.material_override is StandardMaterial3D
        and ship.glass_review_profile == "metric_proxy",
        "staged visual source is fully reversible without changing scene topology")

    var chapter = FirstWake.instantiate()
    root.add_child(chapter)
    await process_frame
    var before: Dictionary = chapter.opening.snapshot()
    var save_before: Dictionary = chapter.export_revised_checkpoint()
    check(chapter.opening.active_party_ids == ["ender"]
        and chapter.resonance_status_label.text.contains("LOCKED")
        and chapter.ship_spaces_handoff.visible == false,
        "real Ionia-first scene remains unaffected by independent glass intake")
    check(chapter.opening.snapshot() == before
        and chapter.export_revised_checkpoint() == save_before,
        "review-only shader import cannot change story, save or spell grants")
    chapter.queue_free()
    ship.queue_free()
    await process_frame

    if problems.is_empty():
        print("AUREATE_WAKE_SOURCE_GLASS_PASS checks=", count,
            " source_blob=EXACT",
            " native_shader=REVIEW_ONLY",
            " production=BLOCKED")
        quit(0)
    else:
        for problem in problems:
            push_error("AUREATE_WAKE_SOURCE_GLASS_FAIL: " + problem)
        quit(1)
