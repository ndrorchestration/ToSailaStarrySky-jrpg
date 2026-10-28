extends Node3D
## Noncanonical optical weather material prototype on existing smooth terrain.
## No collision, precipitation actors, world/biome tags, or save mutations.
const DuneStudy = preload("res://dune_study.gd")
const GroundShader = preload("res://shaders/precipitation_ground.gdshader")
const WIND_AXIS: Vector2 = Vector2(0.93,0.37)
const SUN_DIRECTION: Vector3 = Vector3(0.65,0.43,-0.70)

var study_mesh: Node3D
var ground_material: ShaderMaterial
var weather_mode: int = 0

func _ready() -> void:
    study_mesh = DuneStudy.new()
    add_child(study_mesh)
    ground_material = ShaderMaterial.new()
    ground_material.shader = GroundShader
    study_mesh.dune_mesh.material_override = ground_material
    ground_material.set_shader_parameter("prevailing_wind", WIND_AXIS)
    ground_material.set_shader_parameter("sun_direction", SUN_DIRECTION)
    ground_material.set_shader_parameter("weather_mode", 0)
    ground_material.set_shader_parameter("weather_optics_strength", 1.0)
    ground_material.set_shader_parameter("low_quality", false)
    ground_material.set_shader_parameter("study_time", 9.0)

func set_weather_mode(value: int) -> void:
    weather_mode = clampi(value,0,1)
    ground_material.set_shader_parameter("weather_mode",weather_mode)

func set_optics_strength(value: float) -> void:
    ground_material.set_shader_parameter("weather_optics_strength",
        clampf(value,0.0,1.0))

func set_low_quality(enabled: bool) -> void:
    ground_material.set_shader_parameter("low_quality",enabled)

func set_clock(value: float, reduced_motion: bool) -> void:
    ground_material.set_shader_parameter("study_time",
        0.0 if reduced_motion else value)
