extends RefCounted
## MATERIAL-P0 S2 rendering adapter. Only caller-selected review patch.
## No autoload, no side effects on real worldmap modes or saved coordinates.
const MaterialShader = preload("res://shaders/worldmap_material_optics.gdshader")
const Geo = preload("res://scripts/planetary/planetary_geometry.gd")
const MODES = {"base":0,"sand":1,"snow":2,"wet_ground":3}

static func local_sun_direction(lat_deg: float, lon_deg: float,
        world_sun: Vector3) -> Vector3:
    if not is_finite(lat_deg) or absf(lat_deg)>90.0 \
            or not is_finite(lon_deg) or not world_sun.is_finite() \
            or world_sun.length_squared()<1.0e-10:
        return Vector3.UP
    var lat := deg_to_rad(lat_deg)
    var lon := deg_to_rad(Geo.normalize_longitude(lon_deg))
    if absf(lat_deg)>=90.0:
        lon=0.0
    var up := Vector3(cos(lat)*cos(lon),sin(lat),cos(lat)*sin(lon))
    var east := Vector3(-sin(lon),0.0,cos(lon))
    var north := Vector3(-sin(lat)*cos(lon),cos(lat),-sin(lat)*sin(lon))
    var sun := world_sun.normalized()
    return Vector3(sun.dot(east),sun.dot(up),-sun.dot(north)).normalized()

static func make_material(context: Dictionary, lat_deg: float,
        lon_deg: float) -> ShaderMaterial:
    if context.is_empty() or not MODES.has(str(context.get("material",""))) \
            or not context.has("wind_tangent") \
            or not context.has("sun_world") \
            or not context.has("optics_strength") \
            or not context.has("wetness_request"):
        return null
    var axis: Vector2=context["wind_tangent"]
    if not axis.is_finite() or axis.length_squared()<0.000001:
        return null
    var sun: Vector3=context["sun_world"]
    if not sun.is_finite() or sun.length_squared()<0.000001:
        return null
    var mat := ShaderMaterial.new()
    mat.shader=MaterialShader
    mat.set_shader_parameter("surface_mode",int(MODES[str(context["material"])]))
    mat.set_shader_parameter("optics_strength",float(context["optics_strength"]))
    mat.set_shader_parameter("rain_intensity",float(context["wetness_request"]))
    mat.set_shader_parameter("wind_tangent",axis)
    mat.set_shader_parameter("sun_direction",local_sun_direction(lat_deg,lon_deg,sun))
    mat.set_shader_parameter("low_quality",
        is_zero_approx(float(context["optics_strength"])))
    return mat

static func attach_to_review_patch(patch: Node3D, context: Dictionary,
        lat_deg: float, lon_deg: float) -> ShaderMaterial:
    # Exactly one existing curved native patch mesh is authorized, never a
    # reconstructed fake dune or a changed Cart/planetary mesh.
    var land := patch.get_node_or_null("CurvedTerrainMesh") as MeshInstance3D
    if land==null or land.mesh==null or land.material_override != null:
        return null
    var mat := make_material(context,lat_deg,lon_deg)
    if mat != null:
        land.material_override=mat
    return mat

static func release_review_patch(patch: Node3D,
        owned_material: ShaderMaterial) -> bool:
    var land := patch.get_node_or_null("CurvedTerrainMesh") as MeshInstance3D
    if land==null or land.material_override != owned_material \
            or owned_material==null:
        return false
    land.material_override=null
    return true
