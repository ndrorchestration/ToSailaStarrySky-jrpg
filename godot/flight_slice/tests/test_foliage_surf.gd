extends SceneTree
## Exact-material and unchanged-geometry-authority contracts for the isolated
## cinematic canopy/swashes, not the canonical globe.
const Study = preload("res://main.tscn")
const Terrain = preload("res://terrain.gd")
var failures: Array[String] = []
var checks: int = 0

func check(ok: bool, note: String) -> void:
    checks += 1
    if not ok:
        failures.append(note)

func _initialize() -> void:
    call_deferred("_run")

func _vertices(mesh: Mesh) -> PackedVector3Array:
    return mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func _run() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var v = scene.visuals
    var pines: MultiMeshInstance3D = scene.terrain.get_node("ForestCrowns")
    var broad: MultiMeshInstance3D = scene.terrain.get_node("BroadleafCrowns")
    var conifer_instances: int = pines.multimesh.instance_count
    var broad_instances: int = broad.multimesh.instance_count
    var pine_current: PackedVector3Array = _vertices(pines.multimesh.mesh)
    var broad_current: PackedVector3Array = _vertices(broad.multimesh.mesh)
    check(v.foliage_shape_enabled, "organic mesh defaults on")
    check(v.coastal_surf_enabled, "narrow shoreline swash defaults on")
    check(is_equal_approx(float(v.water.get_shader_parameter(
        "coastal_surf_strength")),0.68), "subtle swash starts in high detail")
    check(v.water.get_shader_parameter("coast_distance_field") == v.coastal_distance,
        "swash shares one signed-source coastline")
    check(v.water.get_shader_parameter("height_field") != null,
        "swash still follows source terrain bathymetry")
    var poses_before: Array[Transform3D] = scene.terrain.tree_poses.duplicate(true)
    var broad_before: Array[Transform3D] = scene.terrain.broadleaf_poses.duplicate(true)
    var ship_before: Vector3 = scene.ship.position
    var clock_before: float = scene._clock
    var elevation: float = Terrain.sample_height(ship_before.x,ship_before.z)
    v.set_foliage_shape_enabled(false)
    check(not v.foliage_shape_enabled, "Y turns off static canopy shaping")
    var pine_reference: PackedVector3Array = _vertices(pines.multimesh.mesh)
    var broad_reference: PackedVector3Array = _vertices(broad.multimesh.mesh)
    check(pine_reference.size() == pine_current.size(),
        "same conifer vertex budget with or without asymmetry")
    check(broad_reference.size() == broad_current.size(),
        "same broadleaf vertex budget with or without asymmetry")
    check(pine_reference != pine_current, "conifer perimeter changes real geometry")
    check(broad_reference != broad_current, "broadleaf lobes change real geometry")
    check(pines.multimesh.instance_count == conifer_instances,
        "Y cannot add/remove conifer instances")
    check(broad.multimesh.instance_count == broad_instances,
        "Y cannot add/remove broadleaf instances")
    v.set_foliage_shape_enabled(true)
    check(_vertices(pines.multimesh.mesh) == pine_current,
        "conifer asymmetry deterministic on replay")
    check(_vertices(broad.multimesh.mesh) == broad_current,
        "broadleaf asymmetry deterministic on replay")
    v.set_coastal_surf_enabled(false)
    check(is_zero_approx(float(v.water.get_shader_parameter(
        "coastal_surf_strength"))), "U removes surf without affecting base foam")
    v.set_coastal_surf_enabled(true)
    check(is_equal_approx(float(v.water.get_shader_parameter(
        "coastal_surf_strength")),0.68), "U restores authored surf")
    v.set_low_quality(true)
    check(is_zero_approx(float(v.water.get_shader_parameter(
        "coastal_surf_strength"))), "V skips animated surf shader branch")
    v.set_coastal_surf_enabled(true)
    check(is_zero_approx(float(v.water.get_shader_parameter(
        "coastal_surf_strength"))), "U never overrides V low detail")
    v.set_low_quality(false)
    check(is_equal_approx(float(v.water.get_shader_parameter(
        "coastal_surf_strength")),0.68), "high detail recovers U preference")
    v.set_clock(28.0,true)
    check(is_zero_approx(float(v.water.get_shader_parameter("study_time"))),
        "M still freezes surf time to nonflashing static appearance")
    v.set_clock(28.0,false)
    check(is_equal_approx(float(v.water.get_shader_parameter("study_time")),28.0),
        "normal surf follows the same deterministic scene clock")
    check(scene.terrain.tree_poses == poses_before,
        "conifer poses remain governed by original deterministic terrain sampler")
    check(scene.terrain.broadleaf_poses == broad_before,
        "broadleaf poses remain governed by original deterministic terrain sampler")
    check(scene.ship.position == ship_before and scene._clock == clock_before,
        "Y and U never move ship or gameplay time")
    check(is_equal_approx(Terrain.sample_height(ship_before.x,ship_before.z), elevation),
        "surf and canopy never change terrain elevations")
    check(scene.terrain.chunk_count() == 64,
        "unchanged world mesh streaming budget")
    check(scene.landing_ground != null,
        "real physics landing body retained")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_FOLIAGE_SURF_PASS checks=",checks)
        quit(0)
    else:
        for issue in failures:
            push_error("GODOT_FOLIAGE_SURF_FAIL: " + issue)
        quit(1)
