extends RefCounted
## S2 standalone read-only context -> actual Godot spherical ShaderMaterial.
## No planet mesh, physical heights, navigation, save or weather owner changes.
const ShaderSource = preload("res://shaders/planetary_surface_study.gdshader")
const Tile = preload("res://scripts/planetary/planetary_tiles.gd")
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

## The same exact face coordinates used by the native cubed-sphere geometry
## builder. Never rewrite tile mesh, UV, colors, collider or cache key.
static func tile_edge_fraction(tile: Dictionary, point_world: Vector3) -> float:
    if not point_world.is_finite() or point_world.length_squared()<1.0e-12:
        return 0.0
    var face: String=str(tile["face"])
    var n: Vector3=_godot_axis(Tile.vector_from_face_uv(face,0.0,0.0))
    var axis_u: Vector3=_godot_axis(Tile.vector_from_face_uv(face,1.0,0.0))
    var axis_v: Vector3=_godot_axis(Tile.vector_from_face_uv(face,0.0,1.0))
    axis_u=(axis_u-n*axis_u.dot(n)).normalized()
    axis_v=(axis_v-n*axis_v.dot(n)).normalized()
    var d: Vector3=point_world.normalized()
    var scale: float=maxf(d.dot(n),0.000001)
    var uv:=Vector2(d.dot(axis_u)/scale,d.dot(axis_v)/scale)
    var bound: Vector4=_tile_bounds(tile)
    var margin_u: float=minf(uv.x-bound.x,bound.y-uv.x)/(bound.y-bound.x)
    var margin_v: float=minf(uv.y-bound.z,bound.w-uv.y)/(bound.w-bound.z)
    return clampf(minf(margin_u,margin_v),0.0,0.5)

static func _godot_axis(math_xyz: Vector3) -> Vector3:
    return Vector3(math_xyz.x,math_xyz.z,math_xyz.y).normalized()

static func _tile_bounds(tile: Dictionary) -> Vector4:
    var count: int=Tile.validate_tile(tile)
    var step: float=2.0/float(count)
    var u0: float=-1.0+float(tile["x"])*step
    var v0: float=-1.0+float(tile["y"])*step
    return Vector4(u0,u0+step,v0,v0+step)

static func configure_review_tile_edge(material: ShaderMaterial,
        tile: Dictionary, blend_width: float=0.22) -> bool:
    if material==null or material.shader!=ShaderSource \
            or not is_finite(blend_width) or blend_width<0.0 \
            or blend_width>0.45:
        return false
    Tile.validate_tile(tile)
    var face: String=str(tile["face"])
    var n: Vector3=_godot_axis(Tile.vector_from_face_uv(face,0.0,0.0))
    var axis_u: Vector3=_godot_axis(Tile.vector_from_face_uv(face,1.0,0.0))
    var axis_v: Vector3=_godot_axis(Tile.vector_from_face_uv(face,0.0,1.0))
    axis_u=(axis_u-n*axis_u.dot(n)).normalized()
    axis_v=(axis_v-n*axis_v.dot(n)).normalized()
    material.set_shader_parameter("tile_face_normal",n)
    material.set_shader_parameter("tile_face_u",axis_u)
    material.set_shader_parameter("tile_face_v",axis_v)
    material.set_shader_parameter("tile_face_bounds",_tile_bounds(tile))
    material.set_shader_parameter("tile_edge_blend_width",blend_width)
    return true
