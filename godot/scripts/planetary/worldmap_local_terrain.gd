extends Node3D
## Native curved local terrain/water review patch, with deterministic material
## variation and sunlight-visible sea waves. All sampled geography is NON-CANON.
## This remains render-only: no terrain collision, vessel landing or chunk LOD.
const Geo = preload("res://scripts/planetary/planetary_geometry.gd")
const Cart = preload("res://scripts/planetary/worldmap_cartography.gd")
const UNITS_PER_KM := 0.02
const PLANET_KM := 6371.0

var _surface: MeshInstance3D
var _water: MeshInstance3D
var _origin: Dictionary = {}
var _extent_km := 0.0
var _land_cells := 0
var _water_cells := 0

func _ready() -> void:
    name = "LowSkyTerrainDevelopmentPatch"
    position = Vector3(1000.0,0.0,0.0)
    _surface = MeshInstance3D.new()
    _surface.name = "CurvedTerrainMesh"
    add_child(_surface)
    _water = MeshInstance3D.new()
    _water.name = "OceanSurface"
    add_child(_water)
    visible = false

func _sea_material() -> ShaderMaterial:
    # Shader colors and deterministic waves are illustrative, not a calibrated
    # physical ocean or accepted environmental look.
    var shader := Shader.new()
    shader.code = """shader_type spatial;
render_mode cull_back;
varying vec3 sea_local;
void vertex() {
    sea_local = VERTEX;
    float swell = sin(VERTEX.x * 12.0 + TIME * 0.47) * cos(VERTEX.z * 10.0 - TIME * 0.31);
    swell += 0.35 * sin(VERTEX.x * 29.0 - VERTEX.z * 17.0 + TIME * 0.83);
    VERTEX.y += 0.009 * swell;
}
void fragment() {
    float long_wave = sin(sea_local.x * 16.0 + TIME * 0.55) *
            cos(sea_local.z * 19.0 - TIME * 0.34);
    float cross_wave = sin(sea_local.x * 45.0 - sea_local.z * 28.0 + TIME * 0.90);
    float ripples = 0.5 + 0.5 * (long_wave * 0.73 + cross_wave * 0.27);
    float crest = smoothstep(0.78, 0.99, ripples);
    float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)),0.0,1.0), 2.6);
    float foam = clamp(COLOR.r, 0.0, 1.0) * (0.38 + 0.62 * crest);
    vec3 deep = vec3(0.018,0.135,0.215);
    vec3 shelf = vec3(0.080,0.38,0.43);
    vec3 water = mix(deep, shelf, clamp(0.24 + 0.38 * ripples + COLOR.g * 0.20,0.0,1.0));
    ALBEDO = mix(water,vec3(0.67,0.84,0.78),foam*0.75);
    ROUGHNESS = mix(0.31,0.16,crest);
    METALLIC = 0.06;
    SPECULAR = 0.80;
    EMISSION = vec3(0.06,0.18,0.20)*(fresnel*0.32 + crest*0.20 + foam*0.14);
}
"""
    var mat := ShaderMaterial.new()
    mat.shader = shader
    return mat

func _append_triangle(builder: SurfaceTool, vertices: Array[Vector3],
        colors: Array[Color], i0: int, i1: int, i2: int) -> void:
    for index in [i0,i1,i2]:
        builder.set_color(colors[index])
        builder.add_vertex(vertices[index])

func rebuild(anchor: Dictionary, extent_km: float = 190.0, divisions: int = 64) -> void:
    assert(extent_km >= 8.0 and extent_km <= 800.0,"LOW_SKY_PATCH_EXTENT")
    assert(divisions >= 8 and divisions <= 128,"LOW_SKY_PATCH_DIVISIONS")
    _origin = Geo.position(float(anchor["latDeg"]),float(anchor["lonDeg"]),0.0)
    _extent_km = extent_km
    _land_cells = 0
    _water_cells = 0
    var vertices: Array[Vector3] = []
    var colors: Array[Color] = []
    var ocean_vertices: Array[Vector3] = []
    var ocean_colors: Array[Color] = []
    var elevations: Array[float] = []
    for row in range(divisions+1):
        var north_km := (0.5-float(row)/float(divisions))*2.0*extent_km
        for col in range(divisions+1):
            var east_km := (float(col)/float(divisions)-0.5)*2.0*extent_km
            var point := Geo.from_local_km(_origin,east_km,north_km,PLANET_KM)
            var record := Cart.sample(float(point["latDeg"]),float(point["lonDeg"]))
            var elevation: float = float(record["elevation"])
            var color: Color = record["color"]
            elevations.append(elevation)
            var horizontal_sq := east_km*east_km+north_km*north_km
            var sagitta := sqrt(maxf(0.0,PLANET_KM*PLANET_KM-horizontal_sq))-PLANET_KM
            # Physical curvature plus a bounded visual relief; km-to-unit
            # conversion is intentionally separate from canonical world scale.
            var relief_km := maxf(elevation,0.0)*2.8
            var fine := sin(east_km*0.57+north_km*0.39)*cos(north_km*0.61)
            if elevation > 0.0:
                relief_km += fine*0.11*clampf(elevation*4.0,0.0,1.0)
                color = color.lerp(Color("#c8b99a"),clampf(absf(fine)*0.08,0.0,0.11))
            else:
                # Bathymetry physically BELOW a separate coherent sea surface.
                relief_km = maxf(elevation*2.6,-2.6)
                color = color.darkened(0.14)
            vertices.append(Vector3(east_km*UNITS_PER_KM,
                    (sagitta+relief_km)*UNITS_PER_KM,-north_km*UNITS_PER_KM))
            colors.append(color)
            ocean_vertices.append(Vector3(east_km*UNITS_PER_KM,
                    (sagitta+0.015)*UNITS_PER_KM,-north_km*UNITS_PER_KM))
            # COLOR.r becomes the foam-at-coast mask in the sea shader.
            var shoreline := clampf((0.12-absf(elevation))*7.8,0.0,1.0)
            ocean_colors.append(Color(shoreline,float(record["moisture"]),0.0,1.0))
    var ground_builder := SurfaceTool.new()
    ground_builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    var water_builder := SurfaceTool.new()
    water_builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for row in range(divisions):
        for col in range(divisions):
            var a := row*(divisions+1)+col
            var b := a+1
            var c := a+divisions+1
            var d := c+1
            # Positive Y winding on Godot X/east Z/south tangent frame.
            _append_triangle(ground_builder,vertices,colors,a,c,b)
            _append_triangle(ground_builder,vertices,colors,b,c,d)
            var mean_elev := (elevations[a]+elevations[b]+elevations[c]+elevations[d])*0.25
            if mean_elev <= 0.0:
                _water_cells += 1
                _append_triangle(water_builder,ocean_vertices,ocean_colors,a,c,b)
                _append_triangle(water_builder,ocean_vertices,ocean_colors,b,c,d)
            else:
                _land_cells += 1
    ground_builder.generate_normals()
    var ground_material := StandardMaterial3D.new()
    ground_material.vertex_color_use_as_albedo = true
    ground_material.roughness = 0.89
    ground_material.metallic = 0.02
    ground_builder.set_material(ground_material)
    _surface.mesh = ground_builder.commit()
    if _water_cells > 0:
        water_builder.generate_normals()
        water_builder.set_material(_sea_material())
        _water.mesh = water_builder.commit()
        _water.visible = true
    else:
        _water.mesh = null
        _water.visible = false

func origin() -> Dictionary:
    return _origin.duplicate(true)

func extent_km() -> float:
    return _extent_km

func surface_stats() -> Dictionary:
    return {"land_cells":_land_cells,"water_cells":_water_cells,
            "has_terrain":has_mesh(),"has_water":_water.mesh != null}

func has_mesh() -> bool:
    return _surface != null and _surface.mesh != null

func camera_position(anchor: Dictionary) -> Vector3:
    var altitude := maxf(0.0,float(anchor.get("altitudeKm",2.0)))
    return position + Vector3(0.0,altitude*UNITS_PER_KM+0.018,0.0)
