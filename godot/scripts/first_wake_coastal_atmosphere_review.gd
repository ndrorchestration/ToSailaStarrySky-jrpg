extends Node3D
## REVISABLE opt-in coastal atmosphere, never canonical map/sea/flight data.
## Uses original exact-staged PR #476 water ripple PNG, no new binary art.
const WATER_SHADER = preload("res://shaders/first_wake_coastal_ocean_review.gdshader")
const WATER_RIPPLE: Texture2D = preload(
    "res://art-staging/environment-study/water_ripple_detail.png")
const REVIEW_ID := "first-wake-coastal-dusk-source-water.v1"
const SOURCE_PR: int = 476
const SOURCE_BLOB := "b92fc645a777ee2a5abe549cf96aa19bba109926"
const SEA_LEVEL_STUDY_M: float = -1.75
const SEA_PLANE_SIZE_M: float = 152.0
const REVIEW_PRODUCTION_READY: bool = false
const PROFILES := ["flat", "coastal_dusk", "coastal_clear"]

var review_profile: String = "flat"
var sky_environment: WorldEnvironment
var sunlight: DirectionalLight3D
var ocean: MeshInstance3D
var ocean_material: ShaderMaterial
var _original_environment: Environment
var _original_sun_color: Color
var _original_sun_energy: float
var _original_sun_rotation: Vector3

func _ready() -> void:
    name = "OptionalFirstWakeCoastalAtmosphere"
    sky_environment = get_parent().get_node("MetricShipEnvironment")
    sunlight = get_parent().get_node("MetricSunlight")
    _original_environment = sky_environment.environment
    _original_sun_color = sunlight.light_color
    _original_sun_energy = sunlight.light_energy
    _original_sun_rotation = sunlight.rotation_degrees

    var water_plane := PlaneMesh.new()
    water_plane.size = Vector2(SEA_PLANE_SIZE_M, SEA_PLANE_SIZE_M)
    water_plane.subdivide_width = 100
    water_plane.subdivide_depth = 100
    ocean_material = ShaderMaterial.new()
    ocean_material.shader = WATER_SHADER
    ocean_material.set_shader_parameter("ripple_tex", WATER_RIPPLE)
    ocean = MeshInstance3D.new()
    ocean.name = "SourceRippleShaderOceanReview"
    ocean.mesh = water_plane
    ocean.material_override = ocean_material
    ocean.position = Vector3(0.0, SEA_LEVEL_STUDY_M, -14.0)
    ocean.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(ocean)
    set_review_profile("coastal_dusk")

func _sky_profile(tint: String) -> Environment:
    var e: Environment = _original_environment.duplicate(true)
    e.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var atmosphere := ProceduralSkyMaterial.new()
    atmosphere.use_debanding = true
    if tint == "coastal_clear":
        atmosphere.sky_top_color = Color(0.16, 0.38, 0.68)
        atmosphere.sky_horizon_color = Color(0.62, 0.79, 0.87)
        atmosphere.ground_bottom_color = Color(0.13, 0.23, 0.31)
        atmosphere.ground_horizon_color = Color(0.56, 0.72, 0.72)
        e.ambient_light_color = Color(0.60, 0.73, 0.88)
        e.ambient_light_energy = 0.85
    else:
        atmosphere.sky_top_color = Color(0.032, 0.12, 0.25)
        atmosphere.sky_horizon_color = Color(0.89, 0.45, 0.27)
        atmosphere.ground_bottom_color = Color(0.095, 0.14, 0.19)
        atmosphere.ground_horizon_color = Color(0.48, 0.26, 0.26)
        e.ambient_light_color = Color(0.67, 0.62, 0.56)
        e.ambient_light_energy = 0.69
    sky.sky_material = atmosphere
    e.sky = sky
    return e

func set_review_profile(next: String) -> bool:
    if next not in PROFILES:
        return false
    if ocean == null or sky_environment == null or sunlight == null:
        return false
    if next == "flat":
        sky_environment.environment = _original_environment
        sunlight.light_color = _original_sun_color
        sunlight.light_energy = _original_sun_energy
        sunlight.rotation_degrees = _original_sun_rotation
        ocean.visible = false
    else:
        sky_environment.environment = _sky_profile(next)
        sunlight.light_color = (
            Color(0.96, 0.96, 0.91) if next == "coastal_clear"
            else Color(1.0, 0.73, 0.48))
        sunlight.light_energy = 1.35 if next == "coastal_clear" else 1.18
        sunlight.rotation_degrees = (
            Vector3(-52, -31, 0) if next == "coastal_clear"
            else Vector3(-19, -48, 0))
        ocean_material.set_shader_parameter(
            "surface_brightness", 1.15 if next == "coastal_clear" else 0.85)
        ocean_material.set_shader_parameter(
            "sunset_reflection",
            Color(0.75, 0.89, 1.0) if next == "coastal_clear"
            else Color(0.98, 0.64, 0.34))
        ocean.visible = true
    review_profile = next
    return true

func cycle_coastal_lighting() -> bool:
    if review_profile == "flat":
        return set_review_profile("coastal_dusk")
    return set_review_profile(
        "coastal_clear" if review_profile == "coastal_dusk" else "coastal_dusk")

func source_contract() -> Dictionary:
    return {
        "review": REVIEW_ID,
        "source_draft_pr": SOURCE_PR,
        "source_water_git_blob": SOURCE_BLOB,
        "water_resolution": Vector2i(WATER_RIPPLE.get_width(), WATER_RIPPLE.get_height()),
        "simulation": false,
        "real_wave_collision": false,
        "save_state": false,
        "secret_ship_systems": false,
        "production_ready": REVIEW_PRODUCTION_READY
    }
