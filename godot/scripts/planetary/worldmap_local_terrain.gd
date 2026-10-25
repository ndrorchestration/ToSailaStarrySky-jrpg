extends Node3D
## Native local-space spherical-tangent terrain mesh. This is a NON-CANON visual
## development patch, NOT collision-certified streaming or approved geography.
## Curvature uses actual globe-radius geometry (in prototype km), not flatland.
const Geo = preload("res://scripts/planetary/planetary_geometry.gd")
const Cart = preload("res://scripts/planetary/worldmap_cartography.gd")
const UNITS_PER_KM := 0.02
const PLANET_KM := 6371.0

var _surface: MeshInstance3D
var _origin: Dictionary = {}
var _extent_km := 0.0

func _ready() -> void:
    name = "LowSkyTerrainDevelopmentPatch"
    position = Vector3(1000.0,0.0,0.0)
    _surface = MeshInstance3D.new()
    _surface.name = "CurvedTerrainMesh"
    add_child(_surface)
    visible = false

func rebuild(anchor: Dictionary, extent_km: float = 190.0, divisions: int = 64) -> void:
    assert(extent_km >= 8.0 and extent_km <= 800.0, "LOW_SKY_PATCH_EXTENT")
    assert(divisions >= 8 and divisions <= 128, "LOW_SKY_PATCH_DIVISIONS")
    _origin = Geo.position(float(anchor["latDeg"]),float(anchor["lonDeg"]),0.0)
    _extent_km = extent_km
    var vertices: Array[Vector3] = []
    var colors: Array[Color] = []
    for row in range(divisions+1):
        var north_km := (0.5-float(row)/float(divisions))*2.0*extent_km
        for col in range(divisions+1):
            var east_km := (float(col)/float(divisions)-0.5)*2.0*extent_km
            # Great-circle position sample, north-up tangent-plane display.
            var point := Geo.from_local_km(_origin,east_km,north_km,PLANET_KM)
            var record := Cart.sample(float(point["latDeg"]),float(point["lonDeg"]))
            var horizontal_sq := east_km*east_km+north_km*north_km
            var sagitta := sqrt(maxf(0.0,PLANET_KM*PLANET_KM-horizontal_sq)) - PLANET_KM
            var relief_km := maxf(float(record["elevation"]),0.0)*2.0
            var tone: Color = record["color"]
            if not bool(record["land"]):
                # Shallow ocean swells are render-only; not navigable collision.
                var wave := 0.07*sin(east_km*0.24+north_km*0.19)
                wave += 0.04*cos(north_km*0.43-east_km*0.16)
                relief_km = wave
                tone = tone.lerp(Color("#298e9a"),clampf(0.19+wave*1.6,0.0,0.37))
            var position3 := Vector3(east_km*UNITS_PER_KM,
                    (sagitta+relief_km)*UNITS_PER_KM,-north_km*UNITS_PER_KM)
            vertices.append(position3)
            colors.append(tone)
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for row in range(divisions):
        for col in range(divisions):
            var a := row*(divisions+1)+col
            var b := a+1
            var c := a+divisions+1
            var d := c+1
            # Local +Z is south; vertex order faces +Y from above.
            for index in [a,c,b,b,c,d]:
                tool.set_color(colors[index])
                tool.add_vertex(vertices[index])
    tool.generate_normals()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.83
    material.metallic = 0.04
    tool.set_material(material)
    _surface.mesh = tool.commit()

func origin() -> Dictionary:
    return _origin.duplicate(true)

func extent_km() -> float:
    return _extent_km

func has_mesh() -> bool:
    return _surface != null and _surface.mesh != null

func camera_position(anchor: Dictionary) -> Vector3:
    var altitude := maxf(0.0,float(anchor.get("altitudeKm",2.0)))
    return position + Vector3(0.0,altitude*UNITS_PER_KM+0.018,0.0)
