extends Node3D
## Public-safe ocean/sky art layer for optional real 3D First Wake walkthrough.
## No buoyancy, ocean traversal, weather forecast or secret vessel controls.
const VISUAL_STATUS := "REVIEW_ONLY_NOT_SEAWORTHINESS"
const SEA_LEVEL_M: float = -0.95
const SEA_RADIUS_M: float = 240.0
const HORIZON_RADIUS_M: float = 240.0
var ocean: MeshInstance3D
var atmosphere: WorldEnvironment
var sky_energy: float = 0.0
var reduced_motion: bool = false
var twilight_review: bool = false
var sky_material: ProceduralSkyMaterial
var sea_material: ShaderMaterial
var sunlight: DirectionalLight3D

func _ready() -> void:
    name = "OptionalMaritimeAtmosphere"
    _make_sky()
    _make_sunlight()
    _make_sea()

func _make_sky() -> void:
    atmosphere = WorldEnvironment.new()
    atmosphere.name = "ActualSkyAndAerialPerspective"
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var shader := ProceduralSkyMaterial.new()
    shader.sky_top_color = Color(0.07, 0.19, 0.32)
    shader.sky_horizon_color = Color(0.70, 0.74, 0.69)
    shader.ground_bottom_color = Color(0.09, 0.24, 0.32)
    shader.ground_horizon_color = Color(0.42, 0.64, 0.65)
    shader.sun_angle_max = 26.0
    sky_material = shader
    sky.sky_material = shader
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    atmosphere.environment = env
    add_child(atmosphere)
    sky_energy = 1.0

func _make_sunlight() -> void:
    # One original directional key for authored deck surfaces and geodesic
    # bridge glass. Entirely visual; no collider, time, or story authority.
    sunlight = DirectionalLight3D.new()
    sunlight.name = "CinematicMaritimeSun"
    sunlight.rotation_degrees = Vector3(-34.0, -28.0, 0.0)
    sunlight.light_color = Color("#ffe5bf")
    sunlight.light_energy = 0.78
    sunlight.shadow_enabled = true
    add_child(sunlight)

func _make_sea() -> void:
    ocean = MeshInstance3D.new()
    ocean.name = "OpenWaterMaterialStudy"
    ocean.position = Vector3(0, SEA_LEVEL_M, 0)
    var plane := PlaneMesh.new()
    plane.size = Vector2(SEA_RADIUS_M * 2.0, SEA_RADIUS_M * 2.0)
    plane.subdivide_width = 112
    plane.subdivide_depth = 112
    ocean.mesh = plane
    var material := ShaderMaterial.new()
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec4 ocean_deep : source_color = vec4(0.032, 0.16, 0.22, 1.0);
uniform vec4 ocean_ridge : source_color = vec4(0.092, 0.305, 0.36, 1.0);
uniform vec4 horizon_mist : source_color = vec4(0.38, 0.61, 0.64, 1.0);
uniform float wave_height = 0.105;
uniform float wave_speed = 0.37;
uniform float visual_motion_scale = 1.0;
uniform float twilight_blend = 0.0;
uniform vec3 twilight_water_deep : source_color = vec3(0.035, 0.075, 0.145);
uniform vec3 twilight_water_ridge : source_color = vec3(0.21, 0.19, 0.27);
varying vec2 sea_position;
varying float wave_crest;
void vertex() {
    vec3 world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    sea_position = world_vertex.xz;
    float broad = sin(world_vertex.x * 0.15 + world_vertex.z * 0.105 + TIME * wave_speed * visual_motion_scale);
    float cross_wave = sin(world_vertex.x * 0.21 - world_vertex.z * 0.17 - TIME * wave_speed * visual_motion_scale * 0.62);
    VERTEX.y += wave_height * (broad * 0.66 + cross_wave * 0.34);
    wave_crest = broad * 0.5 + 0.5;
}
void fragment() {
    float t = TIME * visual_motion_scale;
    // Low-frequency domain warping breaks the rectangular repeated lines
    // that appeared in the first native ocean-horizon render.
    vec2 domain_warp = 2.75 * vec2(
        sin(sea_position.y * 0.105 + sin(sea_position.x * 0.049) * 0.58 + t * 0.13),
        cos(sea_position.x * 0.082 + sin(sea_position.y * 0.043) * 0.44 - t * 0.11)
    );
    vec2 p = sea_position + domain_warp;
    float a = p.x * 0.34 + p.y * 0.18 + t * 0.38;
    float b = -p.x * 0.18 + p.y * 0.39 - t * 0.29;
    float c = p.x * 1.43 - p.y * 1.12 + t * 0.82;
    float wa = sin(a);
    float wb = sin(b + 0.30 * wa);
    float wc = sin(c + 0.28 * wb);
    float dx = 0.34 * cos(a) * 0.16 - 0.18 * cos(b) * 0.11 + 1.43 * cos(c) * 0.014;
    float dz = 0.18 * cos(a) * 0.16 + 0.39 * cos(b) * 0.11 - 1.12 * cos(c) * 0.014;
    vec3 local_wave_normal = normalize(vec3(-dx, 1.0, -dz));
    NORMAL = normalize((VIEW_MATRIX * vec4(local_wave_normal, 0.0)).xyz);
    float ripples = clamp(0.51 + 0.125 * wa + 0.112 * wb + 0.035 * wc, 0.0, 1.0);
    float spark_seed = max(0.0, 0.5 * wa + 0.5 * wb);
    float glints = pow(spark_seed, 20.0) * 0.085;
    float sea_distance = distance(sea_position, CAMERA_POSITION_WORLD.xz);
    float atmospheric_fade = smoothstep(55.0, 215.0, sea_distance);
    vec3 near_water = mix(ocean_deep.rgb, ocean_ridge.rgb, ripples);
    vec3 sunset_water = mix(twilight_water_deep, twilight_water_ridge, ripples);
    vec3 graded_water = mix(near_water, sunset_water, twilight_blend);
    ALBEDO = mix(graded_water, horizon_mist.rgb, atmospheric_fade * (0.61 - 0.18 * twilight_blend));
    METALLIC = 0.085;
    ROUGHNESS = mix(0.29, 0.45, atmospheric_fade);
    SPECULAR = 0.85;
    vec3 light_tint = mix(ocean_ridge.rgb, vec3(0.94, 0.44, 0.24), twilight_blend);
    EMISSION = light_tint * (glints + wave_crest * 0.011) * (1.0 - atmospheric_fade * 0.78);
}
"""
    material.shader = shader
    sea_material = material
    ocean.material_override = material
    set_reduced_motion(reduced_motion)
    add_child(ocean)

func set_reduced_motion(enabled: bool) -> void:
    # Presentation-only: freeze ocean waves without modifying 3D collisions,
    # camera rays, chapter progress, or the sea-level position.
    reduced_motion = enabled
    if sea_material != null:
        sea_material.set_shader_parameter("visual_motion_scale", 0.0 if enabled else 1.0)

func visual_review_snapshot() -> Dictionary:
    return {
        "ocean_mesh_present": ocean != null and ocean.mesh is PlaneMesh,
        "directional_sun_active": sunlight != null and sunlight.shadow_enabled,
        "source_sea_level": SEA_LEVEL_M,
        "reduced_motion": reduced_motion,
        "twilight_review": twilight_review,
        "water_twilight_blend": sea_material.get_shader_parameter("twilight_blend") if sea_material != null else -1.0,
        "motion_scale": sea_material.get_shader_parameter("visual_motion_scale") if sea_material != null else -1.0,
        "has_buoyancy_authority": false,
        "canonical_geography": false,
    }

func set_twilight_review(enabled: bool) -> void:
    # A reversible lighting study, not a story clock or canonical weather event.
    twilight_review = enabled
    if sky_material == null or atmosphere == null:
        return
    sky_material.sky_top_color = Color("#15223c") if enabled else Color(0.07, 0.19, 0.32)
    sky_material.sky_horizon_color = Color("#db9876") if enabled else Color(0.70, 0.74, 0.69)
    sky_material.ground_bottom_color = Color("#17263a") if enabled else Color(0.09, 0.24, 0.32)
    sky_material.ground_horizon_color = Color("#b17c72") if enabled else Color(0.42, 0.64, 0.65)
    atmosphere.environment.ambient_light_energy = 0.65 if enabled else 1.0
    if sea_material != null:
        sea_material.set_shader_parameter("twilight_blend", 1.0 if enabled else 0.0)
    if sunlight != null:
        sunlight.light_color = Color("#ffc29a") if enabled else Color("#ffe5bf")
        sunlight.light_energy = 0.47 if enabled else 0.78
