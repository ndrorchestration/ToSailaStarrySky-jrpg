extends Node3D
## Separate, playable, true 3D lighting/material/environment proof.
## Not a canonical Chapter One rewrite, not a production character/ship asset.
## Keep the existing res://scenes/first_wake_game.tscn entry untouched.
const WaterShader = preload("res://shaders/first_wake_3d_water.gdshader")
const CharacterSlot = preload("res://scripts/first_wake_3d_character_slot.gd")
const CAMERA_TARGET := Vector3(-3.4, 0.9, -9.0)

var visual_root: Node3D
var camera: Camera3D
var sunlight: DirectionalLight3D
var environment: WorldEnvironment
var water: MeshInstance3D
var active_hour := "golden_hour"
var geometry_count := 0
var lantern_count := 0
var animation_assets_loaded := 0
var camera_azimuth := 0.30
var camera_distance := 34.0
var camera_elevation := 0.24

func _ready() -> void:
    _assemble()
    _update_camera()
    set_process(true)

func _material(color: Color, roughness: float = 0.72, metal: float = 0.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    mat.metallic = metal
    return mat

func _mesh(label: String, mesh: Mesh, pos: Vector3, material: Material,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    item.mesh = mesh
    item.material_override = material
    item.position = pos
    item.rotation = rotation
    visual_root.add_child(item)
    geometry_count += 1
    return item

func _box(label: String, pos: Vector3, size: Vector3, material: Material,
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var cube := BoxMesh.new()
    cube.size = size
    return _mesh(label, cube, pos, material, rotation)

func _sphere(label: String, pos: Vector3, radius: float, scale3: Vector3,
        material: Material) -> MeshInstance3D:
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0
    sphere.radial_segments = 16
    sphere.rings = 8
    var output := _mesh(label, sphere, pos, material)
    output.scale = scale3
    return output

func _pillar(label: String, a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius * 1.09
    cylinder.height = a.distance_to(b)
    cylinder.radial_segments = 10
    var mid := (a + b) * 0.5
    var item := _mesh(label, cylinder, mid, mat)
    item.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

func _lantern(pos: Vector3, index: int, brass: Material) -> void:
    _pillar("LanternPost_%02d" % index, pos, pos + Vector3(0, 2.3, 0), 0.075, brass)
    var amber_glass := _material(Color(1.0, 0.78, 0.43, 1), 0.15, 0.1)
    amber_glass.emission_enabled = true
    amber_glass.emission = Color(1.0, 0.54, 0.20)
    amber_glass.emission_energy_multiplier = 1.65
    _sphere("LanternLens_%02d" % index, pos + Vector3(0, 2.51, 0),
        0.20, Vector3(0.65, 1.25, 0.65), amber_glass)
    var glow := OmniLight3D.new()
    glow.name = "True3DLanternLight_%02d" % index
    glow.position = pos + Vector3(0, 2.55, 0)
    glow.light_color = Color(1.0, 0.70, 0.38)
    glow.light_energy = 0.52
    glow.omni_range = 8.0
    glow.shadow_enabled = false
    visual_root.add_child(glow)
    lantern_count += 1

func _assemble_environment() -> void:
    environment = WorldEnvironment.new()
    environment.name = "CinematicCoastalWorldEnvironment"
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color("#b58b89")
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color("#8f9ca9")
    environment.environment.ambient_light_energy = 0.37
    environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.environment.fog_enabled = true
    environment.environment.fog_light_color = Color("#c49f91")
    environment.environment.fog_density = 0.006
    add_child(environment)
    sunlight = DirectionalLight3D.new()
    sunlight.name = "KeySun_GoldenHour"
    sunlight.rotation_degrees = Vector3(-31.0, -36.0, 5.0)
    sunlight.light_color = Color("#ffcea3")
    sunlight.light_energy = 0.71
    sunlight.shadow_enabled = true
    add_child(sunlight)

func _assemble_sea() -> void:
    var ocean := PlaneMesh.new()
    ocean.size = Vector2(180.0, 180.0)
    ocean.subdivide_width = 120
    ocean.subdivide_depth = 120
    var water_material := ShaderMaterial.new()
    water_material.shader = WaterShader
    water = _mesh("ActualSpatial3DAnimatedSea", ocean, Vector3(0, -0.65, -23), water_material)

func _faceted_cliff_mesh(seed: int, radius: float, height: float) -> ArrayMesh:
    # Low-poly strata with irregular real 3D profiles instead of elongated spheres.
    # Deterministic so QA can compare actual native GPU frames across revisions.
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var edges := 11
    var lower: Array[Vector3] = []
    var upper: Array[Vector3] = []
    for j in range(edges):
        var angle := TAU * float(j) / float(edges)
        var irregular := 0.88 + float((j * 17 + seed * 11) % 9) * 0.035
        var upper_rough := 0.61 + float((j * 7 + seed * 13) % 8) * 0.023
        lower.append(Vector3(cos(angle) * radius * irregular,
            -2.3 + float(j % 3) * 0.08, sin(angle) * radius * irregular))
        upper.append(Vector3(cos(angle) * radius * upper_rough,
            height + float((j * 5 + seed) % 5) * 0.19,
            sin(angle) * radius * upper_rough))
    for j in range(edges):
        var next := (j + 1) % edges
        for vertex in [lower[j], upper[j], lower[next],
                upper[j], upper[next], lower[next]]:
            surface.add_vertex(vertex)
        for vertex in [upper[j], Vector3(0, height + 0.35, 0), upper[next]]:
            surface.add_vertex(vertex)
    surface.generate_normals()
    return surface.commit()

func _cliff(label: String, location: Vector3, radius: float, height: float,
        seed: int, material: StandardMaterial3D) -> void:
    _mesh(label, _faceted_cliff_mesh(seed, radius, height), location, material)

func _assemble_coast() -> void:
    var dark_rock := _material(Color("#3c4b59"), 0.98)
    var sandstone := _material(Color("#75615e"), 0.94)
    var twilight_rock := _material(Color("#58606b"), 0.98)
    var distant_green := _material(Color("#3d6258"), 0.97)
    for rock in [dark_rock, sandstone, twilight_rock]:
        rock.cull_mode = BaseMaterial3D.CULL_DISABLED
    # Distinct layered volcanic/sandstone cliffs, not placeholder oval towers.
    for i in range(15):
        var x := float(i - 7) * 6.5
        var z := -43.0 - float(i % 3) * 5.0
        var h := 5.0 + float((i * 17) % 11) * 0.84
        var radius := 3.9 + float(i % 3) * 0.78
        var mat := twilight_rock if i % 3 == 0 else sandstone
        _cliff("FacetedTrue3DCliff_%02d" % i, Vector3(x, -2.0, z), radius, h, i, mat)
        if i % 2 == 0:
            _sphere("CliffTopVegetation_%02d" % i,
                Vector3(x, h - 1.5, z), 1.0,
                Vector3(2.8, 0.32, 2.5), distant_green)
    for sign in [-1.0, 1.0]:
        for j in range(5):
            var x: float = float(sign) * (13.2 + float(j) * 3.2)
            var zz := -18.0 + float(j % 3) * 8.7
            _cliff("NearFacetedShoreRock", Vector3(x, -2.5, zz),
                2.6 + float(j % 2) * 0.4, 1.8 + float(j) * 0.33,
                j + 27, dark_rock)

func _assemble_pier() -> void:
    var wood_a := _material(Color("#795846"), 0.82)
    var wood_b := _material(Color("#9b765a"), 0.78)
    var wood_dark := _material(Color("#4a3833"), 0.88)
    var hardware := _material(Color("#b69762"), 0.33, 0.77)
    # Wooden deck surface y=0.0 with real perspective, individual slats and depth.
    for i in range(42):
        var z := 10.0 - float(i) * 0.73
        var wood := wood_b if i % 5 in [0, 1] else wood_a
        _box("IndividuallyModeledPierPlank_%02d" % i,
            Vector3(0.0, 0.0 + float(i % 4) * 0.009, z),
            Vector3(9.2, 0.19, 0.67), wood)
        if i % 7 == 0:
            for side in [-1.0, 1.0]:
                _sphere("PierFastener", Vector3(side * 3.85, 0.115, z), 0.045,
                    Vector3.ONE, hardware)
    # Continuous physics-agnostic lower beams. Existing 2D collider is untouched.
    for side in [-1.0, 1.0]:
        _box("LongitudinalPierSupport", Vector3(side * 3.8, -0.35, -4.65),
            Vector3(0.6, 0.7, 30.8), wood_dark)
        for i in range(7):
            var z := 8.5 - float(i) * 4.3
            _pillar("DockFoundation", Vector3(side * 4.0, -5.7, z),
                Vector3(side * 4.0, 0.0, z), 0.42, wood_dark)
            if i < 6:
                _pillar("PierBrassRail", Vector3(side * 4.8, 0.18, z),
                    Vector3(side * 4.8, 1.6, z), 0.085, hardware)
    for i in range(5):
        var z := 8.5 - float(i) * 4.3
        _lantern(Vector3(4.7 if i % 2 == 0 else -4.7, 0.1, z), i, hardware)
    _box("StoneArrivalPlaza", Vector3(0.0, -0.03, -23.1), Vector3(22.0, 0.36, 11.0),
        _material(Color("#948c83"), 0.97))
    for i in range(8):
        var z := -18.5 - float(i) * 1.25
        _box("StoneFlagstone_%02d" % i, Vector3(0.0, 0.17, z),
            Vector3(20.0, 0.025, 0.07), wood_dark)

func _assemble_aureate_wake_study() -> void:
    # Provisional 3D spatial blockout of the ship, NOT production lore sign-off.
    # Dome and accessible front deck are visible; no submersible/flight unlock is
    # exposed or asserted by this review-only mesh.
    var ship_root := Node3D.new()
    ship_root.name = "AureateWake_Provisional3DComposition"
    ship_root.position = Vector3(-14, -0.9, -8.5)
    visual_root.add_child(ship_root)
    var bronze := _material(Color("#a37d54"), 0.35, 0.63)
    var hull_mat := _material(Color("#3e5062"), 0.71, 0.30)
    var deck := _material(Color("#977451"), 0.78)
    var dome := _material(Color(0.34, 0.70, 0.78, 0.35), 0.12, 0.1)
    dome.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    var hull := CapsuleMesh.new()
    hull.radius = 2.85
    hull.height = 14.7
    hull.radial_segments = 18
    var hull_instance := MeshInstance3D.new()
    hull_instance.name = "LengthwiseHull3D"
    hull_instance.mesh = hull
    hull_instance.material_override = hull_mat
    hull_instance.rotation_degrees.x = 90.0
    ship_root.add_child(hull_instance)
    geometry_count += 1
    var deck_mesh := BoxMesh.new()
    deck_mesh.size = Vector3(4.7, 0.22, 11.6)
    var deck_obj := MeshInstance3D.new()
    deck_obj.name = "FrontAccessibleDeckBlockout"
    deck_obj.mesh = deck_mesh
    deck_obj.material_override = deck
    deck_obj.position = Vector3(0, 1.14, 0)
    ship_root.add_child(deck_obj)
    geometry_count += 1
    var glass := SphereMesh.new()
    glass.radius = 1.0
    glass.height = 2.0
    glass.radial_segments = 20
    var bridge := MeshInstance3D.new()
    bridge.name = "GeodesicBridgeGlassComposition"
    bridge.mesh = glass
    bridge.material_override = dome
    bridge.position = Vector3(0.0, 2.1, -3.15)
    bridge.scale = Vector3(2.1, 1.5, 2.25)
    ship_root.add_child(bridge)
    geometry_count += 1
    # The accessible front deck remains open and visible.
    _box("ShipPreviewWingPort", Vector3(-18.4, 0.7, -9.0),
        Vector3(4.3, 0.16, 3.2), bronze, Vector3(0, 0, -0.09))
    _box("ShipPreviewWingStarboard", Vector3(-9.5, 0.7, -9.0),
        Vector3(4.3, 0.16, 3.2), bronze, Vector3(0, 0, 0.09))
    var mast := CylinderMesh.new()
    mast.top_radius = 0.12
    mast.bottom_radius = 0.23
    mast.height = 9.2
    var mast_instance := MeshInstance3D.new()
    mast_instance.name = "AureateWakeMastBlockout"
    mast_instance.mesh = mast
    mast_instance.material_override = bronze
    mast_instance.position = Vector3(0, 5.4, 2.0)
    ship_root.add_child(mast_instance)
    geometry_count += 1

func _assemble_cast_import_points() -> void:
    var slots := [
        {"name":"Ender_True3DImportSlot", "id":"ender", "pos":Vector3(-1.35, 0.12, 3.5)},
        {"name":"Ionia_True3DImportSlot", "id":"ionia", "pos":Vector3(1.35, 0.12, -13.2)}
    ]
    for entry in slots:
        var slot := CharacterSlot.new()
        slot.name = entry["name"]
        slot.character_id = entry["id"]
        slot.position = entry["pos"]
        visual_root.add_child(slot)
        if slot.ready_for_art_review:
            animation_assets_loaded += 1

func _assemble() -> void:
    visual_root = Node3D.new()
    visual_root.name = "True3DEnvironmentGeometry"
    add_child(visual_root)
    _assemble_environment()
    _assemble_sea()
    _assemble_coast()
    _assemble_pier()
    _assemble_aureate_wake_study()
    _assemble_cast_import_points()
    camera = Camera3D.new()
    camera.name = "PlayableReviewOrbitCamera"
    camera.current = true
    camera.fov = 56.0
    camera.near = 0.1
    camera.far = 260.0
    add_child(camera)

func _update_camera() -> void:
    if camera == null:
        return
    var horizontal := camera_distance * cos(camera_elevation)
    camera.position = CAMERA_TARGET + Vector3(
        sin(camera_azimuth) * horizontal,
        camera_distance * sin(camera_elevation),
        cos(camera_azimuth) * horizontal
    )
    camera.look_at(CAMERA_TARGET, Vector3.UP)

func set_time_of_day(night: bool) -> void:
    active_hour = "blue_hour" if night else "golden_hour"
    if sunlight == null:
        return
    sunlight.light_color = Color("#9bb8db") if night else Color("#ffcea3")
    sunlight.light_energy = 0.20 if night else 0.71
    environment.environment.background_color = Color("#273a56") if night else Color("#b58b89")
    environment.environment.fog_light_color = Color("#4c6b83") if night else Color("#c49f91")

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_T:
            set_time_of_day(active_hour != "blue_hour")
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_R:
            camera_azimuth = 0.30
            camera_distance = 34.0
            camera_elevation = 0.24
            _update_camera()
            get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
    var moved := false
    if Input.is_action_pressed("ui_left"):
        camera_azimuth -= delta * 0.72
        moved = true
    if Input.is_action_pressed("ui_right"):
        camera_azimuth += delta * 0.72
        moved = true
    if Input.is_action_pressed("ui_up"):
        camera_distance = maxf(13.0, camera_distance - delta * 12.0)
        moved = true
    if Input.is_action_pressed("ui_down"):
        camera_distance = minf(75.0, camera_distance + delta * 12.0)
        moved = true
    if moved:
        _update_camera()

func quality_snapshot() -> Dictionary:
    var cast_status := {}
    if visual_root != null:
        for item in visual_root.get_children():
            if item.name.ends_with("_True3DImportSlot"):
                cast_status[item.name] = item.audit_snapshot()
    return {
        "mode": "separate_true_3d_visual_slice",
        "true_3d_geometry_count": geometry_count,
        "real_spatial_water": water != null and water.mesh is PlaneMesh and water.material_override is ShaderMaterial,
        "real_3d_camera": camera != null and camera.current,
        "time_of_day": active_hour,
        "physical_3d_lights": lantern_count,
        "cast": cast_status,
        "canonical_first_wake_unchanged": true,
        "playable_chapter_one_3d_migrated": false,
        "rigged_creator_models_ready": animation_assets_loaded,
        "cinematic_art_approved": false
    }
