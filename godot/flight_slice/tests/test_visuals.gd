extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
    call_deferred("_run")
func check(value: bool, label_text: String) -> void:
    if not value: failures.append(label_text)
func _run() -> void:
    var scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    check(scene.has_node("FlightPresentation"), "presentation is installed")
    if not scene.has_node("FlightPresentation"):
        push_error("VISUALS_FAIL: presentation is installed")
        quit(1)
        return
    var visuals = scene.get_node("FlightPresentation")
    check(scene.terrain.chunk_count() == 64, "geometry budget preserved")
    # Cinematic light synchronization is explicit, independent of screen captures.
    check(visuals.sky_material.get_shader_parameter("sun_direction") == visuals.SUN_DIRECTION,
        "sky uses authored key-light vector")
    check(visuals.water.get_shader_parameter("sun_direction") == visuals.SUN_DIRECTION,
        "ocean sun glint follows the same key light")
    var height: float = scene.terrain.sample_height(30.0, -12.0)
    visuals.set_clock(12.0, false)
    check(is_equal_approx(visuals.water.get_shader_parameter("study_time"), 12.0), "explicit water clock")
    visuals.set_clock(22.0, true)
    check(is_equal_approx(visuals.water.get_shader_parameter("study_time"), 0.0), "reduced motion freezes water")
    check(is_equal_approx(visuals.foliage.get_shader_parameter("study_time"), 0.0), "reduced motion freezes foliage")
    visuals.set_low_quality(true)
    check(visuals.water.get_shader_parameter("low_quality") == true, "low quality applied")
    visuals.set_low_quality(false)
    check(visuals.water.get_shader_parameter("low_quality") == false, "high quality restored")
    check(is_equal_approx(height, scene.terrain.sample_height(30.0, -12.0)), "quality preserves heights")
    check(visuals.has_method("refresh_coverage"), "shore effects require rendered terrain coverage")
    if not visuals.has_method("refresh_coverage"):
        push_error("VISUALS_FAIL: shore effects require rendered terrain coverage")
        quit(1)
        return
    scene.terrain.update_detail(Vector3(500.0,10.0,500.0),0.5)
    visuals.refresh_coverage()
    # Dummy/headless renderer retains the original texture readback after update.
    # Check CPU mask here; capture_study checks real GL texture readback separately.
    for value in visuals._coverage_bytes:
        check(value == 0, "hidden tiles cannot create foam")
    scene.terrain.update_detail(Vector3(0.0,13.0,0.0),0.5)
    visuals.refresh_coverage()
    check(visuals._coverage_bytes[4*8+4] == 255, "visible center tile permits surf")
    var field: Image = visuals.water.get_shader_parameter("height_field").get_image()
    for point in [Vector2i(5,20),Vector2i(120,128),Vector2i(172,93),Vector2i(240,210)]:
        var x: float = (float(point.x)+0.5)/256.0*260.0-130.0
        var z: float = (float(point.y)+0.5)/256.0*260.0-130.0
        check(absf(field.get_pixelv(point).r-scene.terrain.sample_height(x,z)) < 0.00001, "height bake uses existing sampler")
    var arrays: Array = visuals._layered_crown().surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    for i in range(0,vertices.size(),3):
        check((vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i]).dot(normals[i]) < 0, "crown outward CW winding")
    # Real native geometry: roofs must be pitched triangles, not BoxMesh slabs.
    for house in range(5):
        var roof: MeshInstance3D = scene.terrain.get_node("GableRoof_%s" % house)
        check(roof.mesh is ArrayMesh, "gable house roof is generated mesh")
        var roof_arrays: Array = roof.mesh.surface_get_arrays(0)
        var roof_vertices: PackedVector3Array = roof_arrays[Mesh.ARRAY_VERTEX]
        var roof_normals: PackedVector3Array = roof_arrays[Mesh.ARRAY_NORMAL]
        check(roof_vertices.size() == 18, "gable roof has two slopes and two end caps")
        var min_y: float = 1000.0
        var max_y: float = -1000.0
        for p in roof_vertices:
            min_y = minf(min_y, p.y)
            max_y = maxf(max_y, p.y)
        check(max_y - min_y > 1.2, "pitched roof silhouette has real height")
        for k in range(12):
            check(roof_normals[k].y > 0.0, "roof slopes point upward")
        check(scene.terrain.has_node("Door_%s" % house), "house door grounded")
        var pane: MeshInstance3D = scene.terrain.get_node("WindowGlow_%s" % house)
        var pane_material: StandardMaterial3D = pane.material_override
        check(pane_material.emission_enabled, "window has warm emission without point lights")
    var branches: MultiMeshInstance3D = scene.terrain.get_node("ForestCrowns")
    var cpu_poses: Array[Transform3D] = scene.terrain.tree_poses
    check(cpu_poses.size() > 5, "forest authored CPU transforms retained")
    check(branches.multimesh.instance_count == cpu_poses.size(), "GPU instance budget mirrors authored forest")
    # RenderingServer Dummy readback can report identity for every MultiMesh
    # transform in --headless; validate the actual CPU inputs, not fake GPU data.
    var first_tree: Transform3D = cpu_poses[0]
    var varied: bool = false
    for tree in range(1, mini(16, cpu_poses.size())):
        var other_tree: Transform3D = cpu_poses[tree]
        if first_tree.basis.x.normalized().distance_to(other_tree.basis.x.normalized()) > 0.12:
            varied = true
            break
    check(varied, "forest crowns have deterministic varied CPU orientations")
    scene._clock = 9.0
    scene._paused = true
    scene._process(0.2)
    check(is_equal_approx(scene._clock, 9.0), "pause freezes scene")
    check(is_equal_approx(visuals.water.get_shader_parameter("study_time"), 9.0), "pause freezes effect clock")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("FLIGHT_PRESENTATION_TEST_PASS")
        quit(0)
    else:
        for failure in failures: push_error("VISUALS_FAIL: " + failure)
        quit(1)
