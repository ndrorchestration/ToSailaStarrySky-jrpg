extends Node3D
## Optional camera-local rain for the noncanonical visual lab.
## One bounded instanced mesh. No collision, weather gameplay or saved state.
const STREAK_COUNT: int = 112
const WeatherShader = preload("res://shaders/rain.gdshader")
var instances: MultiMeshInstance3D
var material: ShaderMaterial

static func _hash01(index: int, salt: float) -> float:
    var v: float = sin(float(index) * 12.9898 + salt * 78.233) * 43758.5453
    return v - floor(v)

func _ready() -> void:
    var quad := QuadMesh.new()
    quad.size = Vector2(0.022, 0.72)
    material = ShaderMaterial.new()
    material.shader = WeatherShader
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = quad
    batch.instance_count = STREAK_COUNT
    for i in range(STREAK_COUNT):
        var x: float = (_hash01(i, 1.0) - 0.5) * 30.0
        var z: float = (_hash01(i, 2.0) - 0.5) * 30.0
        var y: float = 4.0 + _hash01(i, 3.0) * 9.0
        batch.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(x, y, z)))
    instances = MultiMeshInstance3D.new()
    instances.name = "CameraLocalRain"
    instances.multimesh = batch
    instances.material_override = material
    instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    instances.visible = false
    add_child(instances)

func set_conditions(weather_index: int, scene_clock: float,
        reduced_motion: bool, low_quality: bool) -> void:
    # Hide moving streaks entirely for low-detail and reduced-motion modes.
    # Clouds and fog still convey conditions without moving foreground particles.
    instances.visible = weather_index >= 2 and not reduced_motion and not low_quality
    material.set_shader_parameter("study_time", scene_clock)
    material.set_shader_parameter("opacity", 0.70 if weather_index == 2 else 1.0)

func follow_camera(view: Camera3D) -> void:
    global_transform = view.global_transform
