extends Node3D
## Reusable materials for a NON-CANON GDScript art study; not product architecture.
const TerrainStudy = preload("res://terrain.gd")
const EnvironmentMood = preload("res://environment_mood.gd")
const WeatherStreaks = preload("res://weather_streaks.gd")
const SUN_DIRECTION = Vector3(0.65, 0.43, -0.70)
var water: ShaderMaterial
var land: ShaderMaterial
var foliage: ShaderMaterial
var broadleaf: ShaderMaterial
var understory: ShaderMaterial
var sky_material: ShaderMaterial
var low_quality: bool = false
var rain: Node3D
var current_mood: Dictionary = {}
var _time_index: int = 0
var _weather_index: int = 0
var _magic_enabled: bool = false
var _last_clock: float = 0.0
var _reduced_motion: bool = false
var coverage: ImageTexture
var _terrain: Node3D
var _coverage_bytes := PackedByteArray()

func _ready() -> void:
    sky_material = _shader("res://shaders/sky.gdshader")
    land = _shader("res://shaders/terrain.gdshader")
    water = _shader("res://shaders/water.gdshader")
    foliage = _shader("res://shaders/foliage.gdshader")
    broadleaf = _shader("res://shaders/foliage.gdshader")
    understory = _shader("res://shaders/understory.gdshader")
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
    rain = WeatherStreaks.new()
    rain.name = "WeatherVeil"
    add_child(rain)
    set_environment_look(0, 0, false)

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
    var crowns: MultiMeshInstance3D = terrain.get_node("ForestCrowns")
    crowns.multimesh.mesh = _layered_crown()
    crowns.material_override = foliage
    var broad_crowns: MultiMeshInstance3D = terrain.get_node("BroadleafCrowns")
    broad_crowns.multimesh.mesh = _broadleaf_crown()
    broad_crowns.material_override = broadleaf
    var floor_plants: MultiMeshInstance3D = terrain.get_node("GroundUnderstory")
    floor_plants.multimesh.mesh = _understory_mesh()
    floor_plants.material_override = understory
    floor_plants.visible = not low_quality

func set_clock(seconds: float, reduced: bool) -> void:
    refresh_coverage()
    _last_clock = seconds
    _reduced_motion = reduced
    var clock: float = 0.0 if reduced else seconds
    for material in [water, land, foliage, broadleaf, understory, sky_material]:
        material.set_shader_parameter("study_time", clock)
    understory.set_shader_parameter("motion_scale", 0.0 if reduced else 1.0)
    rain.set_conditions(_weather_index, clock, reduced, low_quality)

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
    rain.set_conditions(_weather_index, 0.0 if _reduced_motion else _last_clock,
        _reduced_motion, low_quality)
    if _terrain != null:
        _terrain.get_node("GroundUnderstory").visible = not enabled

## These modes grade the local art study, never the actual game clock.
func set_environment_look(time_index: int, weather_index: int,
        magic_enabled: bool) -> void:
    _time_index = posmod(time_index, EnvironmentMood.TIMES.size())
    _weather_index = posmod(weather_index, EnvironmentMood.WEATHER.size())
    _magic_enabled = magic_enabled
    current_mood = EnvironmentMood.sample(_time_index, _weather_index, magic_enabled)
    var key: DirectionalLight3D = get_node("GoldenHourKey")
    var fill: DirectionalLight3D = get_node("SkyBounce")
    var environment: Environment = (get_node("Atmosphere") as WorldEnvironment).environment
    key.light_color = current_mood["key_color"]
    key.light_energy = current_mood["key_energy"]
    fill.light_color = current_mood["fill_color"]
    fill.light_energy = current_mood["fill_energy"]
    environment.ambient_light_color = current_mood["ambient_color"]
    environment.ambient_light_energy = current_mood["ambient_energy"]
    environment.fog_light_color = current_mood["fog_color"]
    environment.fog_density = current_mood["fog_density"]
    for uniform_name in ["time_palette", "weather_strength",
            "magic_veil_strength", "sun_visibility"]:
        sky_material.set_shader_parameter(uniform_name, current_mood[uniform_name])
    rain.set_conditions(_weather_index, 0.0 if _reduced_motion else _last_clock,
        _reduced_motion, low_quality)

func set_camera_frame(view: Camera3D) -> void:
    rain.follow_camera(view)

func _shader(path: String) -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = load(path)
    return material

func _layered_crown() -> ArrayMesh:
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
    return surface.commit()

# Three overlapping, compressed leaf masses make a less spherical silhouette.
# They are one instanced mesh, not individual meshes per tree or final foliage.
func _broadleaf_crown() -> ArrayMesh:
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
    for lobe in range(centers.size()):
        var scale: Vector3 = scales[lobe]
        for index in indices:
            var n: Vector3 = normals[index]
            var transformed_normal := Vector3(n.x / scale.x, n.y / scale.y, n.z / scale.z).normalized()
            surface.set_normal(transformed_normal)
            surface.set_color(colors[lobe])
            surface.add_vertex(points[index] * scale + centers[lobe])
    return surface.commit()


# One double-sided, opaque, instanced clump; no alpha transparency or textures.
# Fronds change direction and height inside the shared mesh to avoid rigid Xs.
func _understory_mesh() -> ArrayMesh:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for frond in range(7):
        var angle: float = TAU * float(frond) / 7.0 + 0.13 * sin(float(frond) * 2.1)
        var direction := Vector3(cos(angle), 0.0, sin(angle))
        var across := Vector3(-direction.z, 0.0, direction.x)
        var rise: float = 0.41 + 0.18 * sin(float(frond) * 2.3 + 0.5)
        var reach: float = 0.48 + 0.12 * cos(float(frond) * 1.9)
        var stem := Vector3(0.0, 0.025, 0.0)
        var shoulder := direction * (reach * 0.53) + Vector3.UP * (rise * 0.81)
        var blade_width: float = 0.115 + 0.03 * sin(float(frond) * 1.2)
        var tip := direction * reach + Vector3.UP * rise
        var moss := Color(0.41, 0.54, 0.34)
        var blade := Color(0.69, 0.83, 0.53)
        _plant_triangle(surface, stem, shoulder - across * blade_width, tip, moss, blade)
        _plant_triangle(surface, stem, tip, shoulder + across * blade_width, moss, blade)
    return surface.commit()

func _plant_triangle(surface: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, base: Color, tip_tint: Color) -> void:
    var normal: Vector3 = (b - a).cross(c - a).normalized()
    for point in [a, b, c]:
        surface.set_normal(normal)
        surface.set_color(base if point == a else tip_tint)
        surface.add_vertex(point)

func _crown_triangle(surface: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, tint: Color) -> void:
    # Godot renders the CW-facing side; match the existing winding and test.
    var outward: Vector3 = (c - a).cross(b - a).normalized()
    for point in [a, b, c]:
        surface.set_normal(outward)
        surface.set_color(tint)
        surface.add_vertex(point)
