extends RefCounted
## S2 standalone read-only context -> actual Godot spherical ShaderMaterial.
## No planet mesh, physical heights, navigation, save or weather owner changes.
const ShaderSource = preload("res://shaders/planetary_surface_study.gdshader")
const FAMILY = {"base":0,"snow":1,"sand":2,"wet_ground":3}

static func build(context: Dictionary, enabled: bool = true) -> ShaderMaterial:
    if context.is_empty() or not FAMILY.has(context.get("material")):
        return null
    if not context.has("wind_tangent") or not context["wind_tangent"] is Vector2:
        return null
    if not context.has("sun_world") or not context["sun_world"] is Vector3:
        return null
    if not context.has("weather") or not ["clear","mist","rain","storm"].has(context["weather"]):
        return null
    var optics: float = float(context.get("optics_strength",-1.0))
    var wet: float = float(context.get("wetness_request",-1.0))
    if not is_finite(optics) or not is_finite(wet) or optics < 0.0 or optics > 1.0 or wet < 0.0 or wet > 1.0:
        return null
    # Camera-independent weather normals are controlled by one global vector;
    # the context's tile-tangent axis is already validated by the S1 resolver.
    var tangent: Vector2 = context["wind_tangent"]
    if not tangent.is_finite() or absf(tangent.length()-1.0) > 0.001:
        return null
    var sun: Vector3 = context["sun_world"]
    if not sun.is_finite() or absf(sun.length()-1.0) > 0.001:
        return null
    var shader_material := ShaderMaterial.new()
    shader_material.shader = ShaderSource
    shader_material.set_shader_parameter("surface_family",int(FAMILY[str(context["material"])]))
    shader_material.set_shader_parameter("effect_strength",optics if enabled else 0.0)
    shader_material.set_shader_parameter("wetness",wet)
    shader_material.set_shader_parameter("global_wind",Vector3(0.68,0.17,-0.71).normalized())
    return shader_material
