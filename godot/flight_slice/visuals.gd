extends Node3D
## Reusable materials for a NON-CANON GDScript art study; not product architecture.
const TerrainStudy = preload("res://terrain.gd")
const SUN_DIRECTION = Vector3(0.65, 0.43, -0.70)
var water: ShaderMaterial
var land: ShaderMaterial
var foliage: ShaderMaterial
var sky_material: ShaderMaterial
var low_quality: bool = false
var coverage: ImageTexture
var _terrain: Node3D
var _coverage_bytes := PackedByteArray()

func _ready() -> void:
    sky_material = _shader("res://shaders/sky.gdshader")
    land = _shader("res://shaders/terrain.gdshader")
    water = _shader("res://shaders/water.gdshader")
    foliage = _shader("res://shaders/foliage.gdshader")
    # Share one light direction across dome and ocean; avoids split sun glints.
    sky_material.set_shader_parameter("sun_direction", SUN_DIRECTION)
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
    var crowns: MultiMeshInstance3D = terrain.get_node("ForestCrowns")
    crowns.multimesh.mesh = _layered_crown()
    crowns.material_override = foliage

func set_clock(seconds: float, reduced: bool) -> void:
    refresh_coverage()
    var clock: float = 0.0 if reduced else seconds
    for material in [water, land, foliage, sky_material]:
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

func _shader(path: String) -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = load(path)
    return material

func _layered_crown() -> ArrayMesh:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Same crown height and instance transforms; layered branches break cone repetition.
    for tier in range(3):
        var base: float = -1.8 + tier * 1.05
        var radius: float = 1.3 - tier * 0.30
        for side in range(7):
            var a: float = float(side) / 7.0 * TAU + tier * 0.27
            var b: float = float(side + 1) / 7.0 * TAU + tier * 0.27
            var p := Vector3(cos(a)*radius, base, sin(a)*radius)
            var q := Vector3(cos(b)*radius, base, sin(b)*radius)
            var top := Vector3(0, base + 1.6, 0)
            var normal: Vector3 = (top-p).cross(q-p).normalized()
            for vertex in [p, q, top]:
                surface.set_normal(normal)
                surface.set_color(Color(0.78,0.83,0.78) if vertex == p or vertex == q else Color(1.15,1.11,0.95))
                surface.add_vertex(vertex)
    return surface.commit()
