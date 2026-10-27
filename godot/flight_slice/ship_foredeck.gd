extends Node3D
## Public-safe, strictly visual open prow platform study.
## No physics, watertightness, life support or hidden traversal implementation.
## Deployment in early story is ordinary weather handling; not a gameplay unlock.
const PLATFORM_FRONT_Z: float = -2.18
const PLATFORM_BACK_Z: float = -1.23
const PLATFORM_Y: float = 0.43
const AISLE_MIN_HALF_WIDTH: float = 0.17

var _weather_sheltered: bool = false

func _ready() -> void:
    var planks := _material(Color(0.31, 0.39, 0.33), 0.77, 0.02)
    var bronze := _material(Color(0.58, 0.42, 0.28), 0.41, 0.62)
    var darkwood := _material(Color(0.13, 0.20, 0.21), 0.67, 0.08)
    var shelter := _material(Color(0.30, 0.56, 0.62, 0.38), 0.35, 0.06)
    shelter.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    shelter.cull_mode = BaseMaterial3D.CULL_DISABLED
    # Deck is fully exposed by default; rail pairs remain open at aft boarding gap.
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var a := Vector3(-0.22, PLATFORM_Y, PLATFORM_FRONT_Z)
    var b := Vector3(0.22, PLATFORM_Y, PLATFORM_FRONT_Z)
    var c := Vector3(0.47, PLATFORM_Y, PLATFORM_BACK_Z)
    var d := Vector3(-0.47, PLATFORM_Y, PLATFORM_BACK_Z)
    for point in [a, b, c, a, c, d]:
        surface.add_vertex(point)
    surface.generate_normals()
    var deck := MeshInstance3D.new()
    deck.name = "OpenPlatform"
    deck.mesh = surface.commit()
    deck.material_override = planks
    add_child(deck)
    for side in [-1.0, 1.0]:
        var name_side: String = "Port" if side < 0.0 else "Starboard"
        # Rail sets do not cross the open aft boarding/crew transit channel.
        var rail_points: Array[Vector3] = [
            Vector3(side * 0.21, PLATFORM_Y, -2.16),
            Vector3(side * 0.34, PLATFORM_Y, -1.76),
            Vector3(side * 0.46, PLATFORM_Y, -1.27)
        ]
        for index in range(rail_points.size()):
            _bar("GuardPost_%s_%s" % [name_side, index],
                rail_points[index],
                rail_points[index] + Vector3(0.0, 0.29, 0.0),
                0.022, bronze)
        for index in range(rail_points.size() - 1):
            _bar("Handrail_%s_%s" % [name_side, index],
                rail_points[index] + Vector3(0.0, 0.29, 0.0),
                rail_points[index + 1] + Vector3(0.0, 0.29, 0.0),
                0.019, bronze)
        _bar("RaisedToeRail_" + name_side,
            rail_points[0] + Vector3(0.0, 0.08, 0.0),
            rail_points[2] + Vector3(0.0, 0.08, 0.0), 0.024, darkwood)
    _bar("ProwHandrail", a + Vector3(0.0, 0.29, 0.01),
        b + Vector3(0.0, 0.29, 0.01), 0.023, bronze)
    # Rear opening faces the crew cabin, visibly distinct from a bulkhead.
    _bar("BoardingLip", Vector3(-0.46, PLATFORM_Y + 0.018, PLATFORM_BACK_Z),
        Vector3(0.46, PLATFORM_Y + 0.018, PLATFORM_BACK_Z), 0.022, bronze)
    _bar("ShelterArch_Port", Vector3(-0.46, PLATFORM_Y, PLATFORM_BACK_Z),
        Vector3(-0.40, PLATFORM_Y + 0.62, PLATFORM_BACK_Z), 0.035, bronze)
    _bar("ShelterArch_Starboard", Vector3(0.46, PLATFORM_Y, PLATFORM_BACK_Z),
        Vector3(0.40, PLATFORM_Y + 0.62, PLATFORM_BACK_Z), 0.035, bronze)
    _bar("ShelterArch_Crown", Vector3(-0.40, PLATFORM_Y + 0.62, PLATFORM_BACK_Z),
        Vector3(0.40, PLATFORM_Y + 0.62, PLATFORM_BACK_Z), 0.029, bronze)

    # Weather-only lightweight folding canopy, not a sealed glass pressure pod.
    # It follows the tapered bow and leaves the railings visible from outside.
    var hood := Node3D.new()
    hood.name = "WeatherHood"
    add_child(hood)
    var canopy_surface := SurfaceTool.new()
    canopy_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var front_port := Vector3(-0.18, PLATFORM_Y + 0.38, -2.10)
    var front_center := Vector3(0.0, PLATFORM_Y + 0.58, -2.10)
    var front_starboard := Vector3(0.18, PLATFORM_Y + 0.38, -2.10)
    var rear_port := Vector3(-0.44, PLATFORM_Y + 0.57, -1.26)
    var rear_center := Vector3(0.0, PLATFORM_Y + 0.79, -1.26)
    var rear_starboard := Vector3(0.44, PLATFORM_Y + 0.57, -1.26)
    for point in [
        front_port, rear_port, rear_center,
        front_port, rear_center, front_center,
        front_center, rear_center, rear_starboard,
        front_center, rear_starboard, front_starboard
    ]:
        canopy_surface.add_vertex(point)
    canopy_surface.generate_normals()
    var roof := MeshInstance3D.new()
    roof.name = "RainCanopyPanels"
    roof.mesh = canopy_surface.commit()
    shelter.albedo_color = Color(0.33, 0.59, 0.63, 0.24)
    roof.material_override = shelter
    hood.add_child(roof)
    _bar_in(hood, "RidgeBeam", front_center, rear_center, 0.015, bronze)
    _bar_in(hood, "PortCanopyRim", front_port, rear_port, 0.017, bronze)
    _bar_in(hood, "StarboardCanopyRim", front_starboard, rear_starboard, 0.017, bronze)
    hood.visible = false

func set_weather_sheltered(value: bool) -> void:
    _weather_sheltered = value
    if has_node("WeatherHood"):
        get_node("WeatherHood").visible = value

func is_weather_sheltered() -> bool:
    return _weather_sheltered

func _bar(name_part: String, start: Vector3, finish: Vector3,
        radius: float, material: Material) -> void:
    _bar_in(self, name_part, start, finish, radius, material)

func _bar_in(parent: Node3D, name_part: String, start: Vector3, finish: Vector3,
        radius: float, material: Material) -> void:
    var axis: Vector3 = finish - start
    var item := MeshInstance3D.new()
    item.name = name_part
    var model := CylinderMesh.new()
    model.height = axis.length()
    model.top_radius = radius
    model.bottom_radius = radius
    model.radial_segments = 7
    item.mesh = model
    item.position = (start + finish) * 0.5
    item.quaternion = Quaternion(Vector3.UP, axis.normalized())
    item.material_override = material
    parent.add_child(item)

func _material(color: Color, roughness: float, metalness: float) -> StandardMaterial3D:
    var surface := StandardMaterial3D.new()
    surface.albedo_color = color
    surface.roughness = roughness
    surface.metallic = metalness
    return surface
