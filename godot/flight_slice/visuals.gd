extends Node3D
## Reusable materials for a NON-CANON GDScript art study; not product architecture.
const TerrainStudy = preload("res://terrain.gd")
const ForestFloorStudy = preload("res://forest_floor.gd")
const SUN_DIRECTION = Vector3(0.65, 0.43, -0.70)
var water: ShaderMaterial
var land: ShaderMaterial
var foliage: ShaderMaterial
var broadleaf: ShaderMaterial
var sky_material: ShaderMaterial
var low_quality: bool = false
var coverage: ImageTexture
var _terrain: Node3D
var _coverage_bytes := PackedByteArray()
# One near/far mesh per existing species; CPU source poses are unchanged.
# Spatial batches in the bounded visual adapter; not production globe streaming.
const CANOPY_NEAR: float = 29.0
const CANOPY_FAR: float = 39.0
var _evergreen_near: ArrayMesh
var _evergreen_far: ArrayMesh
var _broadleaf_near: ArrayMesh
var _broadleaf_far: ArrayMesh
var _near_forest_detail: bool = false # true when ANY spatial batch is detailed
var _near_patch_count: int = 0
var _forest_batches: Array[Dictionary] = []
var _last_forest_observer: Vector3 = Vector3(-56.0, 20.0, 52.0)
# 0=automatic; 1=force detailed; 2=force coarse for matched framebuffer QA.
var canopy_review_override: int = 0

func _ready() -> void:
    sky_material = _shader("res://shaders/sky.gdshader")
    land = _shader("res://shaders/terrain.gdshader")
    land.set_shader_parameter("forest_floor_detail_strength", 1.0)
    land.set_shader_parameter("low_quality", false)
    water = _shader("res://shaders/water.gdshader")
    foliage = _shader("res://shaders/foliage.gdshader")
    broadleaf = _shader("res://shaders/foliage.gdshader")
    broadleaf.set_shader_parameter("leaf_tint", Vector3(1.16, 1.12, 0.84))
    # Share one light direction across dome and ocean; avoids split sun glints.
    sky_material.set_shader_parameter("sun_direction", SUN_DIRECTION)
    # Explicit runtime defaults: an unbound sky shader uniform may return Nil
    # in the native headless renderer even when the shader declares a default.
    sky_material.set_shader_parameter("cloud_depth_strength", 1.0)
    sky_material.set_shader_parameter("low_quality", false)
    sky_material.set_shader_parameter("study_time", 0.0)
    water.set_shader_parameter("sun_direction", SUN_DIRECTION)
    water.set_shader_parameter("sea_surface_elevation", TerrainStudy.SEA_LEVEL)
    var daylight := DirectionalLight3D.new()
    daylight.name = "GoldenHourKey"
    add_child(daylight)
    daylight.look_at(-SUN_DIRECTION.normalized(), Vector3.UP)
    daylight.light_color = Color(1.0, 0.83, 0.62)
    daylight.light_energy = 1.15
    daylight.shadow_enabled = true
    daylight.directional_shadow_max_distance = 160.0
    daylight.shadow_bias = 0.035
    var fill := DirectionalLight3D.new()
    fill.name = "SkyBounce"
    add_child(fill)
    fill.look_at(Vector3(0.6, -0.8, -0.4), Vector3.UP)
    fill.light_color = Color(0.62, 0.76, 0.88)
    fill.light_energy = 0.55
    var sky := Sky.new()
    sky.sky_material = sky_material
    sky.radiance_size = Sky.RADIANCE_SIZE_32
    sky.process_mode = Sky.PROCESS_MODE_REALTIME
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.35, 0.46, 0.61)
    environment.ambient_light_energy = 0.85
    environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.fog_enabled = true
    environment.fog_light_color = Color(0.39, 0.49, 0.58)
    environment.fog_density = 0.0035
    environment.fog_sky_affect = 0.0
    var world := WorldEnvironment.new()
    world.name = "Atmosphere"
    world.environment = environment
    add_child(world)

func bind_terrain(terrain: Node3D) -> void:
    _terrain = terrain
    for child in terrain.get_children():
        if child is MeshInstance3D and String(child.name).begins_with("Chunk_"):
            child.material_override = land
    # Fixed bounded bake from the exact terrain sampler, including offshore area.
    var field := Image.create(256, 256, false, Image.FORMAT_RF)
    for y in range(256):
        for x in range(256):
            var px: float = (float(x) + 0.5) / 256.0 * 260.0 - 130.0
            var pz: float = (float(y) + 0.5) / 256.0 * 260.0 - 130.0
            field.set_pixel(x, y, Color(TerrainStudy.sample_height(px, pz), 0, 0))
    water.set_shader_parameter("height_field", ImageTexture.create_from_image(field))
    terrain.get_node("OceanSurface").material_override = water
    refresh_coverage()
    _evergreen_near = _layered_crown(true)
    _evergreen_far = _layered_crown(false)
    _broadleaf_near = _broadleaf_crown(true)
    _broadleaf_far = _broadleaf_crown(false)
    _build_forest_batches(terrain)
    # Independent presentation-only ground cover; no route or collision changes.
    if not terrain.has_node("ForestGroundCover"):
        var floor = ForestFloorStudy.new()
        floor.name = "ForestGroundCover"
        terrain.add_child(floor)
        floor.populate()
    update_forest_detail(_last_forest_observer)

# 2x5 cells: x [16..64] / z [-80..120], deterministically derived
# from ORIGINAL tree transforms; no new/removed trees or duplicate crown nodes.
# Each original Crown node is repurposed as the first occupied spatial cell.
func _build_forest_batches(terrain: Node3D) -> void:
    if not _forest_batches.is_empty():
        return
    for species in ["evergreen", "broadleaf"]:
        var poses: Array[Transform3D] = terrain.tree_poses if species == "evergreen" else terrain.broadleaf_poses
        var original: MultiMeshInstance3D = terrain.get_node(
            "ForestCrowns" if species == "evergreen" else "BroadleafCrowns")
        var groups: Dictionary = {}
        for pose in poses:
            var ix: int = clampi(floori((pose.origin.x - 16.0) / 24.0), 0, 1)
            var iz: int = clampi(floori((pose.origin.z + 80.0) / 40.0), 0, 4)
            var cell := Vector2i(ix, iz)
            var bucket: Array = groups.get(cell, [])
            bucket.append(pose)
            groups[cell] = bucket
        var first: bool = true
        for ix in range(2):
            for iz in range(5):
                var cell := Vector2i(ix, iz)
                var group: Array = groups.get(cell, [])
                if group.is_empty():
                    continue
                var instances := MultiMesh.new()
                instances.transform_format = MultiMesh.TRANSFORM_3D
                instances.mesh = _evergreen_far if species == "evergreen" else _broadleaf_far
                instances.instance_count = group.size()
                for i in range(group.size()):
                    var t: Transform3D = group[i]
                    var y_offset: float = 2.55 if species == "evergreen" else 2.50
                    instances.set_instance_transform(i, Transform3D(t.basis,
                        t.origin + Vector3.UP * y_offset * t.basis.get_scale().y))
                var node: MultiMeshInstance3D
                if first:
                    node = original
                    first = false
                else:
                    node = MultiMeshInstance3D.new()
                    node.name = ("Evergreen" if species == "evergreen" else "Broadleaf") + (
                        "Patch_%s_%s" % [ix, iz])
                    terrain.add_child(node)
                node.multimesh = instances
                node.material_override = foliage if species == "evergreen" else broadleaf
                _forest_batches.append({"node": node, "species": species,
                    "ix": ix, "iz": iz, "detailed": false,
                    "cpu_poses": group.duplicate()})

func _forest_distance(observer: Vector3) -> float:
    var closest := Vector3(clampf(observer.x, 18.0, 56.0),
        5.0, clampf(observer.z, -80.0, 82.0))
    return observer.distance_to(closest)

func _batch_distance(observer: Vector3, batch: Dictionary) -> float:
    var x0: float = 16.0 + float(batch["ix"]) * 24.0
    var z0: float = -80.0 + float(batch["iz"]) * 40.0
    return observer.distance_to(Vector3(
        clampf(observer.x, x0, x0 + 24.0),
        5.0, clampf(observer.z, z0, z0 + 40.0)))

func update_forest_detail(observer: Vector3) -> void:
    _last_forest_observer = observer
    if _terrain == null or _forest_batches.is_empty():
        return
    _near_patch_count = 0
    for batch in _forest_batches:
        var distance: float = _batch_distance(observer, batch)
        var detailed: bool = bool(batch["detailed"])
        if distance > CANOPY_FAR:
            detailed = false
        elif distance < CANOPY_NEAR:
            detailed = true
        if low_quality or canopy_review_override == 2:
            detailed = false
        elif canopy_review_override == 1:
            detailed = true
        if detailed != bool(batch["detailed"]):
            batch["detailed"] = detailed
            var node: MultiMeshInstance3D = batch["node"]
            if batch["species"] == "evergreen":
                node.multimesh.mesh = _evergreen_near if detailed else _evergreen_far
            else:
                node.multimesh.mesh = _broadleaf_near if detailed else _broadleaf_far
        if detailed:
            _near_patch_count += 1
    _near_forest_detail = _near_patch_count > 0
    # Ground-cover remains one independent noncollision MultiMesh per type.
    # It is still culled as a whole; spatial splitting is only for canopy LOD.
    var distance: float = _forest_distance(observer)
    var show_floor: bool = distance < CANOPY_NEAR
    if distance > CANOPY_FAR:
        show_floor = false
    elif distance >= CANOPY_NEAR:
        show_floor = _terrain.get_node("ForestGroundCover/FernClumps").visible
    if canopy_review_override == 1:
        show_floor = true
    elif canopy_review_override == 2:
        show_floor = false
    if low_quality:
        show_floor = false
    for layer_name in ["FernClumps", "UnderstoryShrubs"]:
        _terrain.get_node("ForestGroundCover/" + layer_name).visible = show_floor

func set_canopy_review_override(mode: int) -> void:
    # Native paired captures only; normal gameplay always uses 0.
    canopy_review_override = clampi(mode, 0, 2)
    update_forest_detail(_last_forest_observer)

func set_clock(seconds: float, reduced: bool) -> void:
    refresh_coverage()
    var clock: float = 0.0 if reduced else seconds
    for material in [water, land, foliage, broadleaf, sky_material]:
        material.set_shader_parameter("study_time", clock)

func refresh_coverage() -> void:
    if _terrain == null: return
    var pixels := PackedByteArray()
    pixels.resize(64)
    pixels.fill(0)
    for tile in _terrain._tiles:
        if tile["node"].visible:
            pixels[(tile["iz"] + 4) * 8 + tile["ix"] + 4] = 255
    if pixels == _coverage_bytes: return
    _coverage_bytes = pixels
    var mask := Image.create_from_data(8, 8, false, Image.FORMAT_R8, pixels)
    if coverage == null:
        coverage = ImageTexture.create_from_image(mask)
        water.set_shader_parameter("terrain_coverage", coverage)
    else:
        coverage.update(mask)

func set_low_quality(enabled: bool) -> void:
    low_quality = enabled
    water.set_shader_parameter("low_quality", enabled)
    sky_material.set_shader_parameter("low_quality", enabled)
    land.set_shader_parameter("low_quality", enabled)
    update_forest_detail(_last_forest_observer)

func _shader(path: String) -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = load(path)
    return material

func _layered_crown(detailed: bool = true) -> ArrayMesh:
    # Irregular overlapping leaf masses replace the uniform triangular cones.
    # All positions remain local to one instanced tree: no new draw calls.
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var sides: int = 11
    for tier in range(4):
        var base: float = -1.75 + float(tier) * 0.77
        var radius: float = 1.42 - float(tier) * 0.26
        var crown_top := Vector3(0.07 * sin(float(tier) * 2.1),
            base + 1.19, 0.06 * cos(float(tier) * 2.3))
        var depth_shade: float = 0.79 + float(tier) * 0.075
        var underside := Color(0.68, 0.77, 0.71) * depth_shade
        var sunward := Color(0.97, 1.04, 0.86) * depth_shade
        for side in range(sides):
            var a: float = float(side) / float(sides) * TAU + float(tier) * 0.17
            var b: float = float(side + 1) / float(sides) * TAU + float(tier) * 0.17
            var edge_a: float = 0.91 + 0.12 * sin(float(side) * 2.53 + float(tier) * 1.37)
            var edge_b: float = 0.91 + 0.12 * sin(float(side + 1) * 2.53 + float(tier) * 1.37)
            var lower_a := Vector3(cos(a) * radius * edge_a,
                base + 0.08 * sin(a * 3.0), sin(a) * radius * edge_a)
            var lower_b := Vector3(cos(b) * radius * edge_b,
                base + 0.08 * sin(b * 3.0), sin(b) * radius * edge_b)
            var shoulder_a := Vector3(lower_a.x * 0.67,
                base + 0.61, lower_a.z * 0.67)
            var shoulder_b := Vector3(lower_b.x * 0.67,
                base + 0.61, lower_b.z * 0.67)
            _crown_triangle(surface, lower_a, lower_b, shoulder_a, underside)
            _crown_triangle(surface, shoulder_a, lower_b, shoulder_b, underside)
            _crown_triangle(surface, shoulder_a, shoulder_b, crown_top, sunward)
            if detailed and side % 2 == 0:
                # A restrained asymmetric bough reaches beyond the original
                # lower ring; deterministic silhouette breakup without new nodes.
                var direction: float = a + 0.15
                var tip := Vector3(cos(direction) * radius * 1.24,
                    base + 0.20 + 0.11 * sin(a * 3.1),
                    sin(direction) * radius * 1.24)
                _crown_triangle(surface, lower_a, tip, shoulder_a,
                    underside.lerp(sunward, 0.22))
    return surface.commit()

# Three overlapping, compressed leaf masses make a less spherical silhouette.
# They are one instanced mesh, not individual meshes per tree or final foliage.
func _broadleaf_crown(detailed: bool = true) -> ArrayMesh:
    var primitive := SphereMesh.new()
    primitive.radius = 0.90
    primitive.height = 1.80
    primitive.radial_segments = 7
    primitive.rings = 3
    var source: Array = primitive.surface_get_arrays(0)
    var points: PackedVector3Array = source[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = source[Mesh.ARRAY_NORMAL]
    var indices: PackedInt32Array = source[Mesh.ARRAY_INDEX]
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var centers: Array[Vector3] = [
        Vector3(-0.43, -0.15, -0.12), Vector3(0.43, -0.02, 0.13),
        Vector3(0.04, 0.36, -0.18)]
    var scales: Array[Vector3] = [
        Vector3(1.0, 0.77, 0.94), Vector3(0.91, 0.80, 1.0),
        Vector3(0.84, 0.78, 0.86)]
    var colors: Array[Color] = [
        Color(0.91, 0.96, 0.81), Color(1.0, 1.0, 0.86), Color(1.04, 1.02, 0.90)]
    if detailed:
        # Smaller nested lobes create flatter, asymmetric woodland edges
        # instead of a uniform silhouette of three visibly spherical balls.
        centers.append_array([
            Vector3(-0.87, -0.12, 0.15),
            Vector3(0.82, -0.22, -0.29),
            Vector3(-0.07, 0.58, 0.26)])
        scales.append_array([
            Vector3(0.56, 0.45, 0.59),
            Vector3(0.62, 0.42, 0.51),
            Vector3(0.64, 0.48, 0.58)])
        colors.append_array([
            Color(0.83, 0.93, 0.78),
            Color(0.93, 0.97, 0.82),
            Color(0.97, 1.01, 0.87)])
    for lobe in range(centers.size()):
        var scale: Vector3 = scales[lobe]
        for index in indices:
            var n: Vector3 = normals[index]
            var transformed_normal := Vector3(n.x / scale.x, n.y / scale.y, n.z / scale.z).normalized()
            surface.set_normal(transformed_normal)
            surface.set_color(colors[lobe])
            surface.add_vertex(points[index] * scale + centers[lobe])
    return surface.commit()

func _crown_triangle(surface: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, tint: Color) -> void:
    # Godot renders the CW-facing side; match the existing winding and test.
    var outward: Vector3 = (c - a).cross(b - a).normalized()
    for point in [a, b, c]:
        surface.set_normal(outward)
        surface.set_color(tint)
        surface.add_vertex(point)
