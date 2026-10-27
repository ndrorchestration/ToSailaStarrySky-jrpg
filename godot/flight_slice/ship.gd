extends Node3D
## Noncanonical Aureate Wake / Dragonfly hero-asset study.
## Original procedural geometry, not approved art or physical ship collision.
## Does not implement gameplay powers, celestial access, routes or save state.

var _course_yaw: float = 0.0
const WING_NAMES = ["PortFore", "PortAft", "StarboardFore", "StarboardAft"]

func set_course(yaw: float) -> void:
    _course_yaw = yaw

func set_landing_gear(deployed: bool) -> void:
    # Two old visual feet are retained verbatim for the physics study contract.
    # They do not establish final six-strut geometry or a collision footprint.
    for foot_name in ["TouchdownFoot_Port", "TouchdownFoot_Starboard"]:
        get_node(foot_name).visible = deployed

func _ready() -> void:
    var rootwood := _material(Color(0.14, 0.25, 0.27), 0.62, 0.10)
    var dark_bronze := _material(Color(0.27, 0.24, 0.23), 0.50, 0.55)
    var brass := _material(Color(0.74, 0.54, 0.29), 0.35, 0.68)
    var ivory := _material(Color(0.79, 0.77, 0.64), 0.69, 0.04)
    var glass := _emissive(Color(0.38, 0.72, 0.72), Color(0.07, 0.35, 0.37), 0.36)
    var hearth := _emissive(Color(0.98, 0.67, 0.34), Color(0.79, 0.32, 0.09), 0.42)

    # Purpose-built tapered body: armored prow, habitable thorax, narrow stern.
    # Ring stations are proportions for this local study, not accepted ship metres.
    var hull := MeshInstance3D.new()
    hull.name = "LongHull"
    hull.mesh = _loft_hull()
    hull.material_override = rootwood
    add_child(hull)
    _part("Keel", Vector3(0.0, -0.34, 0.15), Vector3(0.18, 0.20, 1.82), dark_bronze)
    _part("UpperCabin", Vector3(0.0, 0.42, 0.05), Vector3(0.38, 0.22, 0.98), ivory)
    _part("ForwardNose", Vector3(0.0, 0.04, -2.13), Vector3(0.36, 0.19, 0.44), brass)
    # Smaller concentric stern drive: practical machinery rather than a ball.
    _nozzle_piece("AftTurbine", 2.07, 0.21, 0.31, 0.46, dark_bronze)
    _nozzle_piece("ExhaustCollar", 2.34, 0.29, 0.29, 0.075, brass)
    _nozzle_piece("ExhaustThroat", 2.393, 0.20, 0.20, 0.048, dark_bronze)
    _nozzle_piece("ExhaustGlow", 2.423, 0.105, 0.105, 0.045, glass)

    # Long brass rails make the ship legible in flight-scale side and rear shots.
    for side in [-1.0, 1.0]:
        var side_name: String = "Port" if side < 0.0 else "Starboard"
        _rod(self, "ProwRail_" + side_name,
            Vector3(side * 0.20, 0.23, -2.26),
            Vector3(side * 0.58, 0.24, -0.66), 0.027, brass)
        _rod(self, "CabinRail_" + side_name,
            Vector3(side * 0.58, 0.30, -0.66),
            Vector3(side * 0.54, 0.30, 1.20), 0.025, brass)
        for index in range(3):
            # Amber windows imply a lived-in home, without deciding an interior plan.
            var z: float = -0.68 + float(index) * 0.65
            _part("WindowRim_%s_%s" % [side_name, index],
                Vector3(side * 0.60, 0.17, z),
                Vector3(0.052, 0.135, 0.18), brass)
            _part("HearthWindow_%s_%s" % [side_name, index],
                Vector3(side * 0.647, 0.17, z),
                Vector3(0.030, 0.088, 0.126), hearth)
        _wing(side, true, brass, glass)
        _wing(side, false, brass, glass)
        _rod(self, "WingRootPylon_" + side_name,
            Vector3(side * 0.54, 0.12, -0.6),
            Vector3(side * 1.28, 0.16, 0.48), 0.075, dark_bronze)
        var foot_name: String = "TouchdownFoot_Port" if side < 0.0 else "TouchdownFoot_Starboard"
        _part(foot_name, Vector3(side * 0.50, -0.78, 0.50),
            Vector3(0.18, 0.17, 0.55), brass)
        get_node(foot_name).visible = false

    # Segmented roof ribs break the undifferentiated white-capsule cabin.
    for index in range(4):
        var z: float = -0.75 + float(index) * 0.51
        _rod(self, "CabinRoofBow_Port_%s" % index,
            Vector3(-0.38, 0.46, z),
            Vector3(0.0, 0.69, z), 0.021, brass)
        _rod(self, "CabinRoofBow_Starboard_%s" % index,
            Vector3(0.0, 0.69, z),
            Vector3(0.38, 0.46, z), 0.021, brass)

    # Three modest navigational vanes, not full-size galleon masts.
    for index in range(3):
        var z: float = -1.08 + float(index) * 1.09
        var height: float = 0.91 if index != 1 else 1.21
        _rod(self, "VaneMast_%s" % index,
            Vector3(0.0, 0.53, z), Vector3(0.0, height, z), 0.035, brass)
        _vane(index, z, height, ivory)
    _part("HelmGlass", Vector3(0.0, 0.68, -0.47),
        Vector3(0.22, 0.09, 0.34), glass)

    var lamp := OmniLight3D.new()
    lamp.name = "SmallDeckGlow"
    lamp.position = Vector3(0.0, 0.67, -0.75)
    lamp.light_color = Color(0.42, 0.82, 0.81)
    lamp.light_energy = 0.32
    lamp.omni_range = 3.4
    lamp.shadow_enabled = false
    add_child(lamp)

func set_motion(clock: float, reduced: bool) -> void:
    if reduced:
        rotation = Vector3(0.0, _course_yaw, 0.0)
    else:
        rotation = Vector3(0.0, _course_yaw + sin(clock * 0.15) * 0.018,
            sin(clock * 0.95) * 0.035)
    # Gentle wing-borne flex is visual only: no changed collision or handling.
    for name in WING_NAMES:
        var rig: Node3D = get_node("WingRig_" + name)
        var handedness: float = -1.0 if name.begins_with("Port") else 1.0
        var phase: float = 0.65 if name.ends_with("Aft") else 0.0
        rig.rotation.z = 0.0 if reduced else handedness * sin(clock * 0.66 + phase) * 0.018

func _loft_hull() -> ArrayMesh:
    var stations: Array[Vector3] = [
        Vector3(0.16, 0.16, -2.38),
        Vector3(0.47, 0.31, -1.90),
        Vector3(0.62, 0.40, -1.05),
        Vector3(0.68, 0.46, 0.15),
        Vector3(0.59, 0.41, 1.04),
        Vector3(0.40, 0.31, 1.78),
        Vector3(0.26, 0.22, 2.28)
    ]
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments: int = 16
    for station in range(stations.size() - 1):
        for segment in range(segments):
            var a: float = TAU * float(segment) / float(segments)
            var b: float = TAU * float(segment + 1) / float(segments)
            var p0: Vector3 = _loft_point(stations[station], a)
            var p1: Vector3 = _loft_point(stations[station], b)
            var p2: Vector3 = _loft_point(stations[station + 1], b)
            var p3: Vector3 = _loft_point(stations[station + 1], a)
            for vertex in [p0, p1, p2, p0, p2, p3]:
                surface.add_vertex(vertex)
    surface.generate_normals()
    return surface.commit()

func _loft_point(section: Vector3, angle: float) -> Vector3:
    return Vector3(cos(angle) * section.x,
        sin(angle) * section.y + 0.02, section.z)

func _wing(side: float, fore: bool, brass: Material, glazing: Material) -> void:
    var side_name: String = "Port" if side < 0.0 else "Starboard"
    var wing_name: String = side_name + ("Fore" if fore else "Aft")
    var rig := Node3D.new()
    rig.name = "WingRig_" + wing_name
    add_child(rig)
    # Scalloped tips and separate fore/aft outlines distinguish these membranes
    # from rigid aircraft panels. Coordinates are local study proportions.
    var outline: Array[Vector3]
    if fore:
        outline = [
            Vector3(side * 0.38, 0.18, -1.18),
            Vector3(side * 1.58, 0.24, -1.86),
            Vector3(side * 3.48, 0.33, -2.29),
            Vector3(side * 4.46, 0.38, -2.00),
            Vector3(side * 4.84, 0.32, -1.40),
            Vector3(side * 4.40, 0.26, -0.92),
            Vector3(side * 2.48, 0.20, -0.60),
            Vector3(side * 1.17, 0.15, -0.28)
        ]
    else:
        outline = [
            Vector3(side * 0.40, 0.17, 0.08),
            Vector3(side * 1.61, 0.23, -0.22),
            Vector3(side * 3.23, 0.34, 0.17),
            Vector3(side * 4.34, 0.42, 0.82),
            Vector3(side * 4.35, 0.35, 1.33),
            Vector3(side * 3.58, 0.30, 2.02),
            Vector3(side * 2.08, 0.21, 1.70),
            Vector3(side * 0.95, 0.16, 1.10)
        ]
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Camber is an actual raised ridge, not a screen-space painted highlight.
    for i in range(1, outline.size() - 1):
        var root: Vector3 = outline[0]
        var ridge: Vector3 = root.lerp((outline[i] + outline[i + 1]) * 0.5, 0.58)
        ridge.y += 0.13
        _membrane_triangle(surface, root, outline[i], ridge,
            Color(0.18, 0.45, 0.49, 0.77))
        _membrane_triangle(surface, ridge, outline[i], outline[i + 1],
            Color(0.37, 0.66, 0.69, 0.73))
        _membrane_triangle(surface, root, ridge, outline[i + 1],
            Color(0.23, 0.51, 0.58, 0.80))
    surface.generate_normals()
    var membrane := MeshInstance3D.new()
    membrane.name = "Membrane_" + wing_name
    membrane.mesh = surface.commit()
    var membrane_material := StandardMaterial3D.new()
    membrane_material.vertex_color_use_as_albedo = true
    membrane_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    membrane_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    membrane_material.metallic = 0.07
    membrane_material.roughness = 0.42
    membrane.material_override = membrane_material
    rig.add_child(membrane)

    # Collect structure by material, not one MeshInstance3D per thin vein.
    # This retains the geometry while reducing per-wing draw submissions.
    var brass_rods: Array[Dictionary] = [
        {"start": outline[0], "end": outline[1], "radius": 0.035},
        {"start": outline[outline.size() - 1], "end": outline[0],
            "radius": 0.027}
    ]
    var dark_rods: Array[Dictionary] = []
    for i in range(1, outline.size() - 1):
        dark_rods.append({"start": outline[i], "end": outline[i + 1],
            "radius": 0.013})
    var glass_rods: Array[Dictionary] = []
    for i in range(2, outline.size() - 1):
        var center: Vector3 = outline[0].lerp(outline[i], 0.56)
        center.y += 0.12
        glass_rods.append({"start": outline[0], "end": center, "radius": 0.013})
        glass_rods.append({"start": center, "end": outline[i], "radius": 0.009})
    var dark_edge := _material(Color(0.34, 0.36, 0.32), 0.48, 0.30)
    _rod_batch(rig, "BrassRibBundle_" + wing_name, brass_rods, brass)
    _rod_batch(rig, "DarkRibBundle_" + wing_name, dark_rods, dark_edge)
    _rod_batch(rig, "GlassRibBundle_" + wing_name, glass_rods, glazing)

func _rod_batch(parent: Node3D, label_name: String,
        segments: Array[Dictionary], surface: Material) -> void:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for part in segments:
        _append_tube(tool, part["start"], part["end"], float(part["radius"]))
    tool.generate_normals()
    var model := MeshInstance3D.new()
    model.name = label_name
    model.mesh = tool.commit()
    # Tubes are thin in far views; double-sided for consistent visibility.
    var batch_material := surface.duplicate() as StandardMaterial3D
    batch_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    model.material_override = batch_material
    parent.add_child(model)

func _append_tube(tool: SurfaceTool, start: Vector3,
        finish: Vector3, radius: float) -> void:
    var axis: Vector3 = finish - start
    if axis.length_squared() <= 0.000001:
        return
    var direction: Vector3 = axis.normalized()
    var radial_x: Vector3 = direction.cross(Vector3.UP)
    if radial_x.length_squared() < 0.01:
        radial_x = direction.cross(Vector3.RIGHT)
    radial_x = radial_x.normalized()
    var radial_y: Vector3 = direction.cross(radial_x).normalized()
    for index in range(6):
        var a: float = TAU * float(index) / 6.0
        var b: float = TAU * float(index + 1) / 6.0
        var offset_a: Vector3 = (radial_x * cos(a) + radial_y * sin(a)) * radius
        var offset_b: Vector3 = (radial_x * cos(b) + radial_y * sin(b)) * radius
        var p0: Vector3 = start + offset_a
        var p1: Vector3 = finish + offset_a
        var p2: Vector3 = finish + offset_b
        var p3: Vector3 = start + offset_b
        for vertex in [p0, p1, p2, p0, p2, p3]:
            tool.add_vertex(vertex)

func _membrane_triangle(surface: SurfaceTool, a: Vector3,
        b: Vector3, c: Vector3, color: Color) -> void:
    surface.set_color(color)
    surface.add_vertex(a)
    surface.add_vertex(b)
    surface.add_vertex(c)

func _nozzle_piece(label_name: String, z: float, fore_radius: float,
        aft_radius: float, depth: float, surface: Material) -> void:
    var model := MeshInstance3D.new()
    model.name = label_name
    var barrel := CylinderMesh.new()
    barrel.top_radius = aft_radius
    barrel.bottom_radius = fore_radius
    barrel.height = depth
    barrel.radial_segments = 16
    model.mesh = barrel
    model.rotation.x = PI * 0.5
    model.position = Vector3(0.0, 0.0, z)
    model.material_override = surface
    add_child(model)

func _vane(index: int, z: float, height: float, cloth: Material) -> void:
    var sail := MeshInstance3D.new()
    sail.name = "VaneCloth_%s" % index
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for point in [
        Vector3(0.0, height - 0.04, z),
        Vector3(0.0, 0.55, z),
        Vector3(0.0, 0.61, z + 0.28)
    ]:
        surface.set_normal(Vector3.RIGHT)
        surface.add_vertex(point)
    sail.mesh = surface.commit()
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.84, 0.77, 0.60, 0.85)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.roughness = 0.91
    sail.material_override = material
    add_child(sail)

func _rod(parent: Node3D, label_name: String, start: Vector3,
        finish: Vector3, radius: float, surface: Material) -> void:
    var axis: Vector3 = finish - start
    if axis.length_squared() <= 0.000001:
        return
    var model := MeshInstance3D.new()
    model.name = label_name
    var beam := CylinderMesh.new()
    beam.top_radius = radius
    beam.bottom_radius = radius
    beam.height = axis.length()
    beam.radial_segments = 6
    model.mesh = beam
    model.position = (start + finish) * 0.5
    model.quaternion = Quaternion(Vector3.UP, axis.normalized())
    model.material_override = surface
    parent.add_child(model)

func _part(label_name: String, pos: Vector3, scales: Vector3,
        surface: Material) -> void:
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

func _emissive(tint: Color, light: Color, energy: float) -> StandardMaterial3D:
    var result := _material(tint, 0.31, 0.08)
    result.emission_enabled = true
    result.emission = light
    result.emission_energy_multiplier = energy
    return result
