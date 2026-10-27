extends Node3D
## Standalone, reversible shipboard cutaway. NOT the actual flight ship interior.
## Rendered geometry is concept-scale: no approved physical floorplan or collision.
const Layout = preload("res://ship_interior_layout.gd")

var _oak: StandardMaterial3D
var _bronze: StandardMaterial3D
var _cream: StandardMaterial3D
var _teal: StandardMaterial3D
var _amber: StandardMaterial3D
var _night: StandardMaterial3D

func _ready() -> void:
    _oak = _material(Color(0.20, 0.28, 0.28), 0.64, 0.03)
    _bronze = _material(Color(0.68, 0.49, 0.29), 0.38, 0.55)
    _cream = _material(Color(0.80, 0.75, 0.59), 0.75, 0.04)
    _teal = _material(Color(0.20, 0.60, 0.65), 0.38, 0.09)
    _amber = _material(Color(0.98, 0.55, 0.23), 0.40, 0.08)
    _night = _material(Color(0.085, 0.13, 0.19), 0.64, 0.08)
    _teal.emission_enabled = true
    _teal.emission = Color(0.05, 0.25, 0.28)
    _teal.emission_energy_multiplier = 0.35
    _amber.emission_enabled = true
    _amber.emission = Color(0.53, 0.20, 0.055)
    _amber.emission_energy_multiplier = 0.35
    _install_environment()
    _build_deck()
    _build_fixtures()
    _install_camera()

func _build_deck() -> void:
    _box(self, "DeckFoundation", Vector3(0.0, -0.15, 0.0),
        Vector3(Layout.BEAM_M, 0.30, Layout.LENGTH_M), _oak)
    # Three lightly contrasting floor lengths break up obvious untextured slabs.
    for index in range(12):
        var x: float = -1.69 + float(index) * 0.305
        _box(self, "DeckBoard_%02d" % index,
            Vector3(x, 0.022, 0.0),
            Vector3(0.289, 0.043, Layout.LENGTH_M - 0.17),
            _cream if index % 3 == 0 else _oak)
    # Continuous central accessibility lane, no decorative obstruction.
    for side in [-1.0, 1.0]:
        _box(self, "AisleInlay_%s" % ("Port" if side < 0.0 else "Starboard"),
            Vector3(side * Layout.AISLE_HALF_WIDTH_M, 0.055, 0.0),
            Vector3(0.028, 0.016, Layout.AISLE_BACK_Z - Layout.AISLE_FRONT_Z),
            _bronze)
        _box(self, "HullSill_%s" % ("Port" if side < 0.0 else "Starboard"),
            Vector3(side * 1.85, 0.21, 0.0),
            Vector3(0.10, 0.39, Layout.LENGTH_M), _bronze)
        for station in range(6):
            var z: float = -4.65 + float(station) * 1.85
            _beam("HullRib_%s_%s" % [side, station],
                Vector3(side * 1.84, 0.20, z),
                Vector3(side * 1.72, 1.20, z), 0.055, _bronze)
    for zone in Layout.zones():
        var boundary: float = float(zone["to_z"])
        if boundary < Layout.LENGTH_M * 0.5 - 0.3:
            _box(self, "DeckSeam_" + str(zone["id"]),
                Vector3(0.0, 0.061, boundary),
                Vector3(Layout.BEAM_M - 0.18, 0.009, 0.034), _bronze)

func _build_fixtures() -> void:
    for item in Layout.fixtures():
        var c: Vector2 = item["center"]
        var h: Vector2 = item["half_footprint"]
        var fixture := Node3D.new()
        fixture.name = "Fixture_" + str(item["id"])
        fixture.position = Vector3(c.x, 0.0, c.y)
        add_child(fixture)
        var kind: String = str(item["kind"])
        var top: float = 0.58 if kind == "berth" else 0.83
        if kind == "storage" or kind == "galley":
            top = 1.24
        _box(fixture, "Case", Vector3(0.0, top * 0.5, 0.0),
            Vector3(h.x * 2.0, top, h.y * 2.0),
            _cream if kind == "berth" or kind == "table" else _oak)
        _box(fixture, "WorkSurface", Vector3(0.0, top + 0.042, 0.0),
            Vector3(h.x * 2.0 + 0.02, 0.084, h.y * 2.0 + 0.02), _bronze)
        if kind == "console" or kind == "chart" or kind == "repair":
            _box(fixture, "IlluminatedInstrument", Vector3(0.0, top + 0.12, 0.0),
                Vector3(h.x * 1.2, 0.085, h.y * 1.2), _teal)
        elif kind == "berth":
            _box(fixture, "Bedding", Vector3(0.0, top + 0.11, 0.0),
                Vector3(h.x * 1.55, 0.13, h.y * 1.70), _cream)
            _box(fixture, "Pillow", Vector3(0.0, top + 0.20, -h.y * 0.56),
                Vector3(h.x * 1.25, 0.09, 0.28), _amber)
        elif kind == "table":
            _box(fixture, "Lamp", Vector3(0.0, top + 0.16, 0.0),
                Vector3(0.18, 0.21, 0.18), _amber)
        else:
            _box(fixture, "Handle", Vector3(0.0, top * 0.75, -h.y - 0.035),
                Vector3(0.35, 0.044, 0.05), _bronze)
    # Compact central phase apparatus is intentionally BEHIND engineering;
    # the aisle continues to it and none of its geometry is a gameplay collider.
    var apparatus := Node3D.new()
    apparatus.name = "PhaseDriveObservation"
    apparatus.position = Vector3(0.0, 0.0, 4.53)
    add_child(apparatus)
    _box(apparatus, "EnginePedestal", Vector3(0.0, 0.28, 0.0),
        Vector3(0.63, 0.55, 0.65), _night)
    var coil := MeshInstance3D.new()
    coil.name = "HarmonicRing"
    var ring := TorusMesh.new()
    ring.inner_radius = 0.30
    ring.outer_radius = 0.37
    coil.mesh = ring
    coil.position = Vector3(0.0, 0.85, 0.0)
    coil.rotation.x = PI * 0.5
    coil.material_override = _teal
    apparatus.add_child(coil)
    _box(apparatus, "FuelTheoryUnknown", Vector3(0.0, 0.85, 0.0),
        Vector3(0.22, 0.22, 0.22), _amber)
    # Warm practical lights show ship-as-home rather than military bridge.
    for station in [-3.1, -0.2, 3.1]:
        var lamp := OmniLight3D.new()
        lamp.name = "CabinLamp_%s" % str(station)
        lamp.position = Vector3(0.0, 2.15, station)
        lamp.light_color = Color(1.0, 0.74, 0.47)
        lamp.light_energy = 0.55
        lamp.omni_range = 5.2
        lamp.shadow_enabled = false
        add_child(lamp)

func _install_environment() -> void:
    var env := WorldEnvironment.new()
    env.name = "CutawayWorldLighting"
    var state := Environment.new()
    state.background_mode = Environment.BG_COLOR
    state.background_color = Color(0.055, 0.10, 0.16)
    state.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    state.ambient_light_color = Color(0.34, 0.45, 0.49)
    state.ambient_light_energy = 0.65
    env.environment = state
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.name = "StudyKeyLight"
    sun.rotation_degrees = Vector3(-60.0, 35.0, 0.0)
    sun.light_color = Color(1.0, 0.88, 0.70)
    sun.light_energy = 0.86
    sun.shadow_enabled = true
    add_child(sun)

func _install_camera() -> void:
    var camera := Camera3D.new()
    camera.name = "InteriorReviewCamera"
    camera.position = Vector3(9.0, 13.0, 10.0)
    camera.fov = 54.0
    camera.near = 0.15
    camera.far = 80.0
    camera.current = true
    add_child(camera)
    camera.look_at(Vector3(0.0, 0.30, 0.0), Vector3.UP)

func _box(parent: Node3D, node_name: String, pos: Vector3,
        dimensions: Vector3, surface: Material) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = node_name
    var geometry := BoxMesh.new()
    geometry.size = dimensions
    mesh.mesh = geometry
    mesh.position = pos
    mesh.material_override = surface
    parent.add_child(mesh)

func _beam(node_name: String, a: Vector3, b: Vector3,
        radius: float, surface: Material) -> void:
    var direction: Vector3 = b - a
    var beam := MeshInstance3D.new()
    beam.name = node_name
    var cylinder := CylinderMesh.new()
    cylinder.height = direction.length()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.radial_segments = 7
    beam.mesh = cylinder
    beam.position = (a + b) * 0.5
    beam.quaternion = Quaternion(Vector3.UP, direction.normalized())
    beam.material_override = surface
    add_child(beam)

func _material(color: Color, rough: float, metallic: float) -> StandardMaterial3D:
    var surface := StandardMaterial3D.new()
    surface.albedo_color = color
    surface.roughness = rough
    surface.metallic = metallic
    return surface
