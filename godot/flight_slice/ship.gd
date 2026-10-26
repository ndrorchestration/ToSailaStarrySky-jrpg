extends Node3D
## Independently authored placeholder silhouette for review, not approved Dragonfly art.
## No game-specific abilities, access rights, routes or save data.
var _idle_clock: float = 0.0
var _course_yaw: float = 0.0

func set_course(yaw: float) -> void:
    _course_yaw = yaw

func _ready() -> void:
    var hull_material := _material(Color(0.09, 0.21, 0.26), 0.38, 0.18)
    var hull_trim := _material(Color(0.81, 0.66, 0.39), 0.46, 0.65)
    var pearl := _material(Color(0.85, 0.87, 0.75), 0.57, 0.13)
    _part("LongHull", Vector3(0, 0, 0.0), Vector3(0.58, 0.38, 2.4), hull_material)
    _part("Keel", Vector3(0, -0.36, 0.15), Vector3(0.22, 0.26, 1.95), hull_trim)
    _part("UpperCabin", Vector3(0, 0.42, 0.0), Vector3(0.35, 0.22, 0.9), pearl)
    _part("ForwardNose", Vector3(0, 0.0, -2.1), Vector3(0.30, 0.22, 0.75), hull_trim)
    _part("AftTurbine", Vector3(0, 0.02, 2.14), Vector3(0.52, 0.40, 0.44), hull_trim)
    for side in [-1.0, 1.0]:
        _wing(side)
        _part("SidePylon", Vector3(side * 1.08, 0.0, 0.28), Vector3(0.9, 0.12, 0.13), hull_trim)
    var lamp := OmniLight3D.new()
    lamp.name = "SmallDeckGlow"
    lamp.position = Vector3(0.0, 0.6, -0.75)
    lamp.light_color = Color(0.25, 0.83, 0.83)
    lamp.light_energy = 0.35
    lamp.omni_range = 3.5
    lamp.shadow_enabled = false
    add_child(lamp)

func set_motion(clock: float, reduced: bool) -> void:
    _idle_clock = clock
    if reduced:
        rotation = Vector3(0.0, _course_yaw, 0.0)
    else:
        rotation = Vector3(0.0, _course_yaw + sin(clock * 0.15) * 0.018,
            sin(clock * 0.95) * 0.035)

func _wing(side: float) -> void:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var outline: Array[Vector3] = [
        Vector3(side * 0.30, 0.12, -1.3),
        Vector3(side * 2.7, 0.03, -1.86),
        Vector3(side * 4.9, 0.06, -0.48),
        Vector3(side * 4.25, 0.19, 0.84),
        Vector3(side * 1.48, 0.12, 1.45)
    ]
    for i in range(1, outline.size() - 1):
        for point in [outline[0], outline[i], outline[i + 1]]:
            tool.set_normal(Vector3.UP)
            tool.set_color(Color(0.67, 0.85, 0.79) if i % 2 == 0 else Color(0.23, 0.66, 0.65))
            tool.add_vertex(point)
    var wing_mesh: ArrayMesh = tool.commit()
    var wing := MeshInstance3D.new()
    wing.name = "Membrane_%s" % ("Port" if side < 0 else "Starboard")
    wing.mesh = wing_mesh
    var wing_material := StandardMaterial3D.new()
    wing_material.vertex_color_use_as_albedo = true
    wing_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    wing_material.metallic = 0.22
    wing_material.roughness = 0.53
    wing.material_override = wing_material
    add_child(wing)
    var spar := MeshInstance3D.new()
    spar.name = "WingSpar_%s" % ("Port" if side < 0 else "Starboard")
    var bar := CylinderMesh.new()
    bar.top_radius = 0.07
    bar.bottom_radius = 0.13
    bar.height = 3.0
    bar.radial_segments = 5
    spar.mesh = bar
    spar.position = Vector3(side * 1.6, 0.19, 0.0)
    spar.rotation.z = side * PI / 2.0
    spar.material_override = _material(Color(0.78, 0.65, 0.43), 0.47, 0.55)
    add_child(spar)

func _part(label_name: String, pos: Vector3, scales: Vector3, surface: Material) -> void:
    var model := MeshInstance3D.new()
    model.name = label_name
    var shell := SphereMesh.new()
    shell.radius = 1.0
    shell.height = 2.0
    shell.radial_segments = 12
    shell.rings = 6
    model.mesh = shell
    model.scale = scales
    model.position = pos
    model.material_override = surface
    add_child(model)

func _material(tint: Color, rough: float, metal: float) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = tint
    result.roughness = rough
    result.metallic = metal
    return result
