extends SceneTree
const BathymetryStudy = preload("res://bathymetry.gd")
const TerrainStudy = preload("res://terrain.gd")
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
    check(is_equal_approx(
        float(visuals.water.get_shader_parameter("sea_surface_elevation")),
        TerrainStudy.SEA_LEVEL), "ocean and rendered seabed use one datum")
    for station in [Vector2(-60.0, 0.0), Vector2(-2.0, 0.0), Vector2(30.0, 0.0)]:
        var bed: Dictionary = BathymetryStudy.sample(station.x, station.y)
        check(is_equal_approx(
            float(bed["bed_elevation"]), TerrainStudy.sample_height(station.x, station.y)),
            "seabed elevation shares terrain sampler")
        check(is_equal_approx(float(bed["water_depth"]),
            maxf(TerrainStudy.SEA_LEVEL - float(bed["bed_elevation"]), 0.0)),
            "water depth is nonnegative and datum-consistent")
        check(bool(bed["submerged"]) == (float(bed["bed_elevation"]) < TerrainStudy.SEA_LEVEL),
            "submerged classification comes from same datum")
    check(BathymetryStudy.water_depth(-60.0, 0.0) > 0.0,
        "offshore terrain has sampled positive depth")
    check(not BathymetryStudy.is_submerged(30.0, 0.0),
        "exposed forest terrain is not underwater")
    var height: float = scene.terrain.sample_height(30.0, -12.0)
    visuals.set_clock(12.0, false)
    check(is_equal_approx(visuals.water.get_shader_parameter("study_time"), 12.0), "explicit water clock")
    visuals.set_clock(22.0, true)
    check(is_equal_approx(visuals.water.get_shader_parameter("study_time"), 0.0), "reduced motion freezes water")
    check(is_equal_approx(visuals.foliage.get_shader_parameter("study_time"), 0.0), "reduced motion freezes foliage")
    check(is_equal_approx(visuals.broadleaf.get_shader_parameter("study_time"), 0.0), "reduced motion freezes broadleaf foliage")
    check(is_equal_approx(visuals.understory.get_shader_parameter("study_time"), 0.0), "reduced motion freezes understory clock")
    check(is_equal_approx(visuals.understory.get_shader_parameter("motion_scale"), 0.0), "reduced motion suppresses understory sway")
    visuals.set_low_quality(true)
    check(visuals.water.get_shader_parameter("low_quality") == true, "low quality applied")
    check(visuals.land.get_shader_parameter("low_quality") == true,
        "low quality disables extra alpine wind-scour shader detail")
    check(not scene.terrain.get_node("GroundUnderstory").visible, "low quality omits undergrowth")
    check(not scene.terrain.get_node("ShorelineStones").visible, "low quality omits coast stones")
    check(not scene.terrain.get_node("AlpineTalus").visible, "low quality omits decorative talus")
    visuals.set_low_quality(false)
    check(visuals.water.get_shader_parameter("low_quality") == false, "high quality restored")
    check(visuals.land.get_shader_parameter("low_quality") == false,
        "high quality restores material-only snow detail")
    check(scene.terrain.get_node("GroundUnderstory").visible, "high quality restores undergrowth")
    check(scene.terrain.get_node("ShorelineStones").visible, "high quality restores coastline accents")
    check(scene.terrain.get_node("AlpineTalus").visible, "high quality restores talus accents")
    check(is_equal_approx(height, scene.terrain.sample_height(30.0, -12.0)), "quality preserves heights")
    for sample in [Vector2(30.0, -12.0), Vector2(72.0, -11.0),
            Vector2(75.0, 17.0), Vector2(70.0, -35.0)]:
        check(is_equal_approx(TerrainStudy.sample_height(sample.x, sample.y),
            scene.terrain.sample_height(sample.x, sample.y)),
            "snow visual material does not introduce an alternative terrain sampler")
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
    check(vertices.size() >= 300, "layered irregular crowns provide shaped silhouette")
    check(vertices.size() == normals.size() and vertices.size() % 3 == 0,
        "crown triangles retain complete normal data")
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
    var nonuniform: bool = false
    for tree in cpu_poses:
        var axes: Vector3 = tree.basis.get_scale()
        if absf(axes.y - axes.x) > 0.10 or absf(axes.y - axes.z) > 0.10:
            nonuniform = true
            break
    check(nonuniform, "deterministic forest contains varied height-width profiles")
    # A mixed forest must contain a separate, visible canopy type, with its
    # transforms grounded in the same sampled forest as the existing trees.
    var has_broadleaf: bool = scene.terrain.has_node("BroadleafCrowns")
    check(has_broadleaf, "forest includes a second canopy type")
    if has_broadleaf:
        var broadleaf: MultiMeshInstance3D = scene.terrain.get_node("BroadleafCrowns")
        check(broadleaf.multimesh.mesh is ArrayMesh, "broadleaf has clustered mesh")
        var leaf_arrays: Array = broadleaf.multimesh.mesh.surface_get_arrays(0)
        var leaf_vertices: PackedVector3Array = leaf_arrays[Mesh.ARRAY_VERTEX]
        var leaf_normals: PackedVector3Array = leaf_arrays[Mesh.ARRAY_NORMAL]
        check(leaf_vertices.size() >= 500 and leaf_vertices.size() <= 1200,
            "multi-lobe crown geometry improves silhouette inside the vertex budget")
        var leaf_bounds: AABB = broadleaf.multimesh.mesh.get_aabb()
        check(leaf_bounds.size.x > 2.0 and leaf_bounds.size.x < 3.5,
            "asymmetric canopy stays within an appropriate tree width")
        check(leaf_bounds.size.y > 1.75 and leaf_bounds.size.y < 3.1,
            "asymmetric canopy stays within the authored trunk-height scale")
        check(leaf_vertices.size() == leaf_normals.size(), "clustered crown normals are complete")
        var broad_poses: Array[Transform3D] = scene.terrain.broadleaf_poses
        check(broad_poses.size() > 5, "second canopy has multiple placements")
        check(broadleaf.multimesh.instance_count == broad_poses.size(),
            "second canopy instance count mirrors authored placements")
        var trunk_nodes: MultiMeshInstance3D = scene.terrain.get_node("ForestTrunks")
        check(trunk_nodes.multimesh.instance_count == cpu_poses.size() + broad_poses.size(),
            "each mixed-forest crown retains a trunk")
        for pose in broad_poses:
            check(scene.terrain.classify(pose.origin.x, pose.origin.z) == "forest",
                "second canopy belongs to forest biome")
            check(absf(pose.origin.y - scene.terrain.sample_height(pose.origin.x, pose.origin.z)) < 0.0001,
                "second canopy placement is grounded")

    # Exact terrain sampler authorizes every fixed art placement. Decorative
    # geology must never become a hidden physics collider or landing obstacle.
    var shore: MultiMeshInstance3D = scene.terrain.get_node("ShorelineStones")
    var talus: MultiMeshInstance3D = scene.terrain.get_node("AlpineTalus")
    var shore_poses: Array[Transform3D] = scene.terrain.shoreline_stone_poses
    var talus_poses: Array[Transform3D] = scene.terrain.alpine_talus_poses
    check(shore_poses.size() > 8 and shore_poses.size() <= 120,
        "shoreline accent scatter count remains nonempty and bounded")
    check(talus_poses.size() > 8 and talus_poses.size() <= 250,
        "highland accent scatter count remains nonempty and bounded")
    check(shore.multimesh.instance_count == shore_poses.size(),
        "coastal scatter matches CPU placement authority")
    check(talus.multimesh.instance_count == talus_poses.size(),
        "talus scatter matches CPU placement authority")
    check(shore.multimesh.mesh == talus.multimesh.mesh,
        "shore and alpine instances share one generated stone mesh")
    check(shore.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        and talus.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
        "small rock accents do not add shadow draw work")
    check(shore.get_child_count() == 0 and talus.get_child_count() == 0,
        "rock accents add no collision bodies or per-instance scene nodes")
    var geology_mesh: ArrayMesh = shore.multimesh.mesh
    var geology: Array = geology_mesh.surface_get_arrays(0)
    var geology_vertices: PackedVector3Array = geology[Mesh.ARRAY_VERTEX]
    var geology_normals: PackedVector3Array = geology[Mesh.ARRAY_NORMAL]
    var geology_colors: PackedColorArray = geology[Mesh.ARRAY_COLOR]
    check(geology_vertices.size() == 81,
        "nine-sided faceted stone stays inside tiny mesh budget")
    check(geology_vertices.size() == geology_normals.size()
        and geology_vertices.size() == geology_colors.size(),
        "stone mesh has complete face normals and colors")
    for pose in shore_poses:
        var location: Vector3 = pose.origin
        check(location.y > TerrainStudy.SEA_LEVEL,
            "shore stones cannot be placed under the water datum")
        check(TerrainStudy.classify(location.x, location.z) in ["coast", "grassland"],
            "shore rock location has a dry near-coast biome")
        check(absf(location.y - TerrainStudy.sample_height(location.x, location.z) - 0.05) < 0.0001,
            "shore stone placement is sample-height grounded")
        check(not (absf(location.z + 23.0) < 11.0 and location.x < 11.0),
            "shore stone scatter clears the cliffside dock")
    for pose in talus_poses:
        var location: Vector3 = pose.origin
        check(pose.basis.get_scale().y < pose.basis.get_scale().x * 0.65,
            "alpine scree keeps a shallow debris silhouette")
        check(TerrainStudy.classify(location.x, location.z) in ["alpine", "summit"],
            "talus remains restricted to rocky upper elevations")
        check(absf(location.y - TerrainStudy.sample_height(location.x, location.z) - 0.04) < 0.0001,
            "talus placement is sample-height grounded")
        check(not (location.x > 5.5 and location.x < 16.0
            and location.z > -19.0 and location.z < -6.0),
            "geology does not obstruct the touchdown field")
    check(is_equal_approx(float(visuals.shore_minerals.get_shader_parameter("wetness")), 0.32),
        "coastal rock material is restrained and weathered")
    check(is_zero_approx(float(visuals.alpine_minerals.get_shader_parameter("wetness"))),
        "alpine rock has no ocean-wet material")
    
    # An opaque single-mesh undergrowth layer adds ground-scale visual texture
    # without changing biome, terrain height, safe landing, or tree placements.
    var plants: MultiMeshInstance3D = scene.terrain.get_node("GroundUnderstory")
    var plant_poses: Array[Transform3D] = scene.terrain.ground_cover_poses
    check(plant_poses.size() > 50 and plant_poses.size() < 700,
        "terrain-grounded understory has a bounded deterministic instance budget")
    check(plants.multimesh.instance_count == plant_poses.size(),
        "understory GPU instance count matches CPU pose authority")
    check(plants.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
        "understory does not add shadow draw work")
    var clump_mesh: ArrayMesh = plants.multimesh.mesh
    check(clump_mesh is ArrayMesh, "understory uses a compact custom leaf mesh")
    var clump_arrays: Array = clump_mesh.surface_get_arrays(0)
    var clump_vertices: PackedVector3Array = clump_arrays[Mesh.ARRAY_VERTEX]
    var clump_normals: PackedVector3Array = clump_arrays[Mesh.ARRAY_NORMAL]
    var clump_colors: PackedColorArray = clump_arrays[Mesh.ARRAY_COLOR]
    check(clump_vertices.size() == 42, "seven two-triangle fronds bound leaf geometry")
    check(clump_vertices.size() == clump_normals.size()
        and clump_vertices.size() == clump_colors.size(),
        "undergrowth has vertex normal and color data")
    for pose in plant_poses:
        var position: Vector3 = pose.origin
        check(TerrainStudy.classify(position.x, position.z) in ["forest", "grassland"],
            "undergrowth is restricted to dry forest/meadow biomes")
        check(absf(position.y - TerrainStudy.sample_height(position.x, position.z) - 0.05) < 0.0001,
            "undergrowth follows terrain height, with fixed soil offset")
        check(not (position.x > 5.5 and position.x < 16.0
            and position.z > -19.0 and position.z < -6.0),
            "ground cover leaves safe landing fixture clear")
    visuals.set_clock(3.0, false)
    check(is_equal_approx(visuals.understory.get_shader_parameter("study_time"), 3.0)
        and is_equal_approx(visuals.understory.get_shader_parameter("motion_scale"), 1.0),
        "understory wind is controlled by the shared scene clock")
    visuals.set_clock(24.0, true)
    check(is_zero_approx(visuals.understory.get_shader_parameter("motion_scale")),
        "reduced motion restores stationary foliage")

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
