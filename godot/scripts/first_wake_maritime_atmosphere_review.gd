extends Node3D
## Public-safe ocean/sky art layer for optional real 3D First Wake walkthrough.
## No buoyancy, ocean traversal, weather forecast or secret vessel controls.
const VISUAL_STATUS := "REVIEW_ONLY_NOT_SEAWORTHINESS"
const SEA_LEVEL_M: float = -0.95
const SEA_RADIUS_M: float = 150.0
const HORIZON_RADIUS_M: float = 165.0
var ocean: MeshInstance3D
var atmosphere: WorldEnvironment
var sky_energy: float = 0.0

func _ready() -> void:
    name = "OptionalMaritimeAtmosphere"
    _make_sky()
    _make_sea()

func _make_sky() -> void:
    atmosphere = WorldEnvironment.new()
    atmosphere.name = "ActualSkyAndAerialPerspective"
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var shader := ProceduralSkyMaterial.new()
    shader.sky_top_color = Color(0.08, 0.23, 0.38)
    shader.sky_horizon_color = Color(0.64, 0.71, 0.69)
    shader.ground_bottom_color = Color(0.09, 0.24, 0.32)
    shader.ground_horizon_color = Color(0.46, 0.65, 0.67)
    shader.sun_angle_max = 26.0
    sky.sky_material = shader
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    atmosphere.environment = env
    add_child(atmosphere)
    sky_energy = 1.0

func _make_sea() -> void:
    ocean = MeshInstance3D.new()
    ocean.name = "OpenWaterMaterialStudy"
    ocean.position = Vector3(0, SEA_LEVEL_M, 0)
    var plane := PlaneMesh.new()
    plane.size = Vector2(SEA_RADIUS_M * 2.0, SEA_RADIUS_M * 2.0)
    plane.subdivide_width = 4
    plane.subdivide_depth = 4
    ocean.mesh = plane
    var material := ShaderMaterial.new()
    var shader := Shader.new()
    shader.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec4 shallow_color : source_color = vec4(0.12, 0.38, 0.45, 1.0);
uniform vec4 deep_color : source_color = vec4(0.025, 0.15, 0.24, 1.0);
uniform float wave_height = 0.075;
uniform float wave_speed = 0.28;
varying float foam_mask;
void vertex() {
    float long_wave = sin(VERTEX.x * 0.095 + TIME * wave_speed) * cos(VERTEX.z * 0.07 - TIME * wave_speed * 0.73);
    float short_wave = sin(VERTEX.x * 0.64 - TIME * 0.51) * sin(VERTEX.z * 0.43 + TIME * 0.37);
    VERTEX.y += wave_height * (long_wave + 0.18 * short_wave);
    foam_mask = abs(short_wave) * 0.15;
}
void fragment() {
    float sparkle = pow(max(dot(NORMAL, normalize(vec3(0.22, 0.92, 0.28))), 0.0), 28.0);
    ALBEDO = mix(deep_color.rgb, shallow_color.rgb, 0.42 + foam_mask);
    METALLIC = 0.18;
    ROUGHNESS = 0.27;
    SPECULAR = 0.85;
    EMISSION = shallow_color.rgb * (0.05 + 0.15 * sparkle);
}
"""
    material.shader = shader
    ocean.material_override = material
    add_child(ocean)
