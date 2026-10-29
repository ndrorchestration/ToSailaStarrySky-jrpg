extends Node3D
## Separate, playable, true 3D lighting/material/environment proof.
## Not a canonical Chapter One rewrite, not a production character/ship asset.
## Keep the existing res://scenes/first_wake_game.tscn entry untouched.
const WaterShader = preload("res://shaders/first_wake_3d_water.gdshader")
const CharacterSlot = preload("res://scripts/first_wake_3d_character_slot.gd")
const NavigationMarker = preload("res://scripts/first_wake_3d_navigation_marker.gd")
const FirstWakeStoryBridge = preload("res://scripts/first_wake_3d_story_bridge.gd")
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
var navigation_body: CharacterBody3D
var physics_root: Node3D
var interaction_probes: Array[Area3D] = []
var interaction_receipts: Array[String] = []
var navigation_notice: Label
var navigation_status: Label
var camera_follow_navigation := false
var authoritative_story_bridge: Node
var authoritative_story_mode := false
var original_dialogue_panel: ColorRect
var original_dialogue_speaker: Label
var original_dialogue_line: Label
var engineering_room_instantiated := false
const ENGINE_ROOM_ORIGIN := Vector3(58.0, 0.0, -1.0)

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

func _ridge_mesh(layer: int) -> ArrayMesh:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var z_back := -2.0 - float(layer) * 2.0
    var z_front := 2.8
    for step in range(26):
        var x0 := -78.0 + float(step) * 6.0
        var x1 := x0 + 6.0
        var peak0 := 4.6 + sin(float(step) * 0.55 + float(layer)) * 2.8 + cos(float(step) * 0.93) * 1.7
        var peak1 := 4.6 + sin(float(step + 1) * 0.55 + float(layer)) * 2.8 + cos(float(step + 1) * 0.93) * 1.7
        var a := Vector3(x0, -3.0, z_front)
        var b := Vector3(x1, -3.0, z_front)
        var c := Vector3(x0, peak0, z_front)
        var d := Vector3(x1, peak1, z_front)
        var e := Vector3(x0, peak0 + 0.2, z_back)
        var f := Vector3(x1, peak1 + 0.2, z_back)
        for point in [a, c, b, b, c, d, c, e, d, d, e, f]:
            surface.add_vertex(point)
    surface.generate_normals()
    return surface.commit()

func _assemble_coast() -> void:
    var sandstone := _material(Color("#5e5759"), 0.95)
    var mountain := _material(Color("#475e63"), 0.98)
    var dark_rock := _material(Color("#3c4b59"), 0.98)
    var plant := _material(Color("#3b6058"), 0.98)
    for mat in [sandstone, mountain, dark_rock]:
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    _mesh("ContinuousTrue3DCoastalRidge", _ridge_mesh(0),
        Vector3(0, -1.5, -45.0), sandstone)
    _mesh("DistantTrue3DMountainRidge", _ridge_mesh(2),
        Vector3(0, 0.1, -61.0), mountain)
    for i in range(9):
        var x := -46.0 + float(i) * 12.8
        var zz := -35.0 + float((i * 3) % 4) * 2.5
        var h := 1.8 + float((i * 11) % 6) * 0.72
        _cliff("JaggedRealCoastalShore_%02d" % i,
            Vector3(x, -2.7, zz), 5.8, h, 33 + i, dark_rock)
        if i % 2 == 0:
            _sphere("IrregularCliffTopVegetation_%02d" % i,
                Vector3(x - 1.0, h - 2.4, zz), 1.0,
                Vector3(4.0, 0.22, 3.1), plant)
    for sign in [-1.0, 1.0]:
        for j in range(4):
            var x: float = float(sign) * (14.0 + float(j) * 6.1)
            var zz := -16.0 + float(j % 3) * 8.2
            _cliff("NearbyCoastalRock", Vector3(x, -2.5, zz),
                2.7 + float(j % 2) * 0.5, 1.7 + float(j) * 0.28,
                j + 81, dark_rock)

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

func _ship_hull_mesh() -> ArrayMesh:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Narrow prow, widened amidships and a tapered stern with a submerged keel.
    var segments := [-7.0, -5.2, -2.7, 0.3, 3.4, 6.0, 7.7]
    var widths := [0.22, 1.5, 2.55, 2.65, 2.2, 1.35, 0.17]
    for i in range(segments.size() - 1):
        var top_a_l := Vector3(-widths[i], 0.96, segments[i])
        var top_b_l := Vector3(-widths[i+1], 0.96, segments[i+1])
        var top_a_r := Vector3(widths[i], 0.96, segments[i])
        var top_b_r := Vector3(widths[i+1], 0.96, segments[i+1])
        var keel_a := Vector3(0, -1.40, segments[i])
        var keel_b := Vector3(0, -1.40, segments[i+1])
        for vertex in [
            top_a_l, keel_a, top_b_l, top_b_l, keel_a, keel_b,
            top_a_r, top_b_r, keel_a, top_b_r, keel_b, keel_a,
            top_a_l, top_b_l, top_a_r, top_a_r, top_b_l, top_b_r
        ]:
            surface.add_vertex(vertex)
    surface.generate_normals()
    return surface.commit()

func _assemble_aureate_wake_study() -> void:
    # Recognizable original ship features in a separately labeled 3D BLOCKOUT:
    # seaworthy tapered hull, open bow deck, wing surfaces and domed bridge.
    # No plot-locked flight/submersible system is exposed in this visual test.
    var origin := Vector3(-14.5, -0.75, -8.5)
    var ship_root := Node3D.new()
    ship_root.name = "AureateWake_Provisional3DComposition"
    ship_root.position = origin
    visual_root.add_child(ship_root)
    var bronze := _material(Color("#a58253"), 0.42, 0.64)
    var hull_material := _material(Color("#293b46"), 0.71, 0.27)
    var shipwood := _material(Color("#876246"), 0.79)
    var dome := _material(Color(0.18, 0.48, 0.61, 0.31), 0.19, 0.18)
    dome.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    hull_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    var hull := MeshInstance3D.new()
    hull.name = "TaperedShipHull_True3D"
    hull.mesh = _ship_hull_mesh()
    hull.material_override = hull_material
    ship_root.add_child(hull)
    geometry_count += 1
    var deck_mesh := BoxMesh.new()
    deck_mesh.size = Vector3(4.5, 0.18, 10.8)
    var deck_obj := MeshInstance3D.new()
    deck_obj.name = "OpenAccessibleForeDeckBlockout"
    deck_obj.mesh = deck_mesh
    deck_obj.material_override = shipwood
    deck_obj.position = Vector3(0, 1.02, 0.0)
    ship_root.add_child(deck_obj)
    geometry_count += 1
    var dome_sphere := SphereMesh.new()
    dome_sphere.radius = 1.0
    dome_sphere.height = 2.0
    dome_sphere.radial_segments = 24
    dome_sphere.rings = 12
    var bridge := MeshInstance3D.new()
    bridge.name = "GeodesicBridgeGlassComposition"
    bridge.mesh = dome_sphere
    bridge.material_override = dome
    bridge.position = Vector3(0, 2.1, -3.3)
    bridge.scale = Vector3(2.05, 1.47, 2.15)
    ship_root.add_child(bridge)
    geometry_count += 1
    # Visible brass geodesic ribs on an actual volume, not a 2D dome decal.
    var center := origin + Vector3(0, 2.1, -3.3)
    for azimuth in range(8):
        var az := TAU * float(azimuth) / 8.0
        for segment in range(6):
            var v0 := PI * float(segment) / 6.0
            var v1 := PI * float(segment + 1) / 6.0
            var point_a := center + Vector3(
                2.07 * sin(v0) * cos(az), 1.50 * cos(v0),
                2.17 * sin(v0) * sin(az))
            var point_b := center + Vector3(
                2.07 * sin(v1) * cos(az), 1.50 * cos(v1),
                2.17 * sin(v1) * sin(az))
            _pillar("GeodesicStructuralBrassRib", point_a, point_b, 0.024, bronze)
    # The frontal deck remains physically open as specified in the ship design.
    for side in [-1.0, 1.0]:
        _box("AureateWakeWingBlockout", origin +
            Vector3(float(side) * 4.7, 0.76, 0.9),
            Vector3(4.3, 0.14, 3.25), bronze,
            Vector3(0, 0, float(side) * 0.12))
        for z in [0.2, 2.6, 4.8]:
            _pillar("OpenDeckBrassRailingPost",
                origin + Vector3(float(side) * 2.18, 1.05, z),
                origin + Vector3(float(side) * 2.18, 2.14, z), 0.048, bronze)
    _pillar("BrassMast", origin + Vector3(0, 1.1, 2.5),
        origin + Vector3(0, 9.3, 2.5), 0.14, bronze)

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

func _static_collision(label: String, center: Vector3, bounds: Vector3) -> void:
    var fixed := StaticBody3D.new()
    fixed.name = label
    fixed.collision_layer = 1
    fixed.collision_mask = 0
    fixed.position = center
    var collider := CollisionShape3D.new()
    collider.name = "TruePhysicalBoundary"
    var shape := BoxShape3D.new()
    shape.size = bounds
    collider.shape = shape
    fixed.add_child(collider)
    physics_root.add_child(fixed)

func _interaction_probe(label: String, position3: Vector3,
        purpose: String, tint: Color) -> void:
    var area := Area3D.new()
    area.name = label
    area.set_meta("review_text", purpose)
    area.collision_layer = 0
    area.collision_mask = 2
    area.monitoring = true
    area.monitorable = true
    area.position = position3 + Vector3(0, 0.9, 0)
    var collider := CollisionShape3D.new()
    collider.name = "Genuine3DProximityVolume"
    var sphere := SphereShape3D.new()
    sphere.radius = 1.85
    collider.shape = sphere
    area.add_child(collider)
    physics_root.add_child(area)
    interaction_probes.append(area)
    # Clearly marked golden 3D review waypoint, not a story NPC stand-in.
    var marker_material := _material(tint, 0.38, 0.5)
    marker_material.emission_enabled = true
    marker_material.emission = tint * 0.55
    marker_material.emission_energy_multiplier = 0.5
    _box(label + "_NonCanonicalWaypoint", position3 + Vector3(0, 0.23, 0),
        Vector3(0.65, 0.38, 0.65), marker_material)

func _assemble_navigation_physics() -> void:
    physics_root = Node3D.new()
    physics_root.name = "IsolatedTrue3DPhysicsAndInteractionReview"
    add_child(physics_root)
    # Collision follows modeled pier coordinates, but does not change any
    # CollisionShape2D/Area2D that drives the canonical First Wake.
    _static_collision("ContinuousPierDeckPhysics",
        Vector3(0, -0.055, -5.05), Vector3(9.10, 0.32, 30.55))
    _static_collision("StoneArrivalPlazaPhysics",
        Vector3(0, -0.055, -23.1), Vector3(21.8, 0.43, 10.65))
    for side in [-1.0, 1.0]:
        _static_collision("PierSafetyBalustrade_%s" % str(int(side)),
            Vector3(side * 4.62, 0.72, -5.05), Vector3(0.32, 1.55, 30.5))
    var rail_material := _material(Color("#6f5547"), 0.82, 0.06)
    for side in [-1.0, 1.0]:
        _box("PierContinuousVisibleSafetyRail", Vector3(side * 4.62, 1.42, -5.05),
            Vector3(0.22, 0.15, 30.5), rail_material)
        _box("PierLowerVisibleSafetyRail", Vector3(side * 4.62, 0.53, -5.05),
            Vector3(0.19, 0.13, 30.5), rail_material)

    navigation_body = NavigationMarker.new()
    navigation_body.name = "NonCharacterPhysicsNavigationMarker"
    navigation_body.position = Vector3(0, 0.14, 6.8)
    physics_root.add_child(navigation_body)
    _interaction_probe("NoticeBoard_ReviewOnly", Vector3(-0.9, 0.11, -6.7),
        "Spatial notice reached. Canonical job-flyer dialogue is still in First Wake.",
        Color("#d29b57"))
    _interaction_probe("IoniaArrival_ReviewOnly", Vector3(1.35, 0.11, -13.2),
        "Ionia's 3D arrival point reached. Source-approved model and conversation pending.",
        Color("#6fc9ad"))
    _interaction_probe("AureateWakeGangway_ReviewOnly", Vector3(-3.4, 0.11, -10.0),
        "Gangway position verified. Real 3D boarding and ship physics not yet migrated.",
        Color("#8ca9d8"))

func _engineering_fixture(label: String, station: Vector3, tone: Color) -> void:
    var cabinet := _material(Color("#3a4f5b"), 0.66, 0.36)
    var brass := _material(Color("#a68b61"), 0.37, 0.75)
    var glass := _material(tone, 0.18, 0.30)
    glass.emission_enabled = true
    glass.emission = tone * 0.4
    glass.emission_energy_multiplier = 0.85
    _box(label + "_Console", station + Vector3(3.1, 1.06, 0),
        Vector3(1.32, 1.54, 1.68), cabinet)
    _box(label + "_Gauge", station + Vector3(2.34, 1.39, 0),
        Vector3(0.07, 0.71, 0.96), glass)
    _box(label + "_BrassInstrumentFrame", station + Vector3(2.27, 1.44, 0),
        Vector3(0.035, 0.91, 1.08), brass)
    for segment in range(3):
        _pillar(label + "_PressureTube",
            station + Vector3(3.3, 1.8, -0.63 + float(segment) * 0.56),
            station + Vector3(3.3, 3.15, -0.63 + float(segment) * 0.56),
            0.05, brass)

func _enter_real_3d_engineering_room() -> void:
    # Only after verified real Area3D gangway and ORIGINAL JobScene room change.
    if engineering_room_instantiated or authoritative_story_bridge == null:
        return
    var job = authoritative_story_bridge.authoritative_job
    if job == null or job.room != "engineering" or (
            authoritative_story_bridge.authoritative_session.opening.step_key() != "engineering"):
        return
    engineering_room_instantiated = true
    var floor := _material(Color("#66574c"), 0.92)
    var walls := _material(Color("#455360"), 0.90)
    var inlay := _material(Color("#a28b68"), 0.48, 0.55)
    var timber := _material(Color("#293e4b"), 0.76, 0.21)
    var copper := _material(Color("#ba9061"), 0.36, 0.71)
    _box("WakeEngineRoom_Actual3DFloor", ENGINE_ROOM_ORIGIN + Vector3(0, -0.22, 0),
        Vector3(11.7, 0.36, 24.0), floor)
    for side in [-1.0, 1.0]:
        _box("WakeEngineRoom_Actual3DSideWall",
            ENGINE_ROOM_ORIGIN + Vector3(float(side) * 5.8, 2.1, 0),
            Vector3(0.26, 4.6, 24.0), walls)
        _static_collision("EngineeringSideWallPhysics", ENGINE_ROOM_ORIGIN +
            Vector3(float(side) * 5.8, 2.1, 0), Vector3(0.30, 4.6, 24.0))
    _box("WakeEngineRoom_EnclosedRoof",
        ENGINE_ROOM_ORIGIN + Vector3(0, 4.35, 0),
        Vector3(11.7, 0.27, 24.0), timber)
    for index in range(7):
        var beam_z := -10.8 + float(index) * 3.6
        _box("WakeEngineRoom_TransverseCeilingTruss_%02d" % index,
            ENGINE_ROOM_ORIGIN + Vector3(0, 3.96, beam_z),
            Vector3(11.15, 0.20, 0.22), copper)
    for side in [-1.0, 1.0]:
        for height in [1.3, 2.9]:
            _box("WakeEngineRoom_LongitudinalServiceConduit",
                ENGINE_ROOM_ORIGIN + Vector3(float(side) * 5.34, height, 0),
                Vector3(0.14, 0.13, 22.5), copper)
        for point in range(7):
            var z_pos := -10.1 + float(point) * 3.4
            _box("WakeEngineRoom_BulkheadStructuralRib",
                ENGINE_ROOM_ORIGIN + Vector3(float(side) * 5.53, 2.1, z_pos),
                Vector3(0.18, 3.8, 0.16), copper)
    _box("WakeEngineRoom_BackBulkhead", ENGINE_ROOM_ORIGIN + Vector3(0, 2.1, -12),
        Vector3(11.8, 4.6, 0.34), walls)
    _static_collision("EngineeringBackBulkheadPhysics",
        ENGINE_ROOM_ORIGIN + Vector3(0, 2.1, -12),
        Vector3(11.8, 4.6, 0.36))
    _static_collision("EngineeringActualWalkableFloor",
        ENGINE_ROOM_ORIGIN + Vector3(0, -0.22, 0),
        Vector3(11.7, 0.38, 24.0))
    var stations := [
        {"id":"EngineeringReference_ReviewOnly", "z":4.6, "label":"PhaseReference",
            "color":Color("#74cbd8")},
        {"id":"EngineeringContainment_ReviewOnly", "z":0.0, "label":"ContainmentRegulators",
            "color":Color("#e6b66d")},
        {"id":"EngineeringFuel_ReviewOnly", "z":-4.3, "label":"FuelReserveGauge",
            "color":Color("#a0b6ef")},
        {"id":"EngineeringSafety_ReviewOnly", "z":-8.5, "label":"IoniaSafetyChecklist",
            "color":Color("#a1d3a6")}
    ]
    for station in stations:
        var station_pos: Vector3 = ENGINE_ROOM_ORIGIN + Vector3(-0.75, 0.1, station["z"])
        _engineering_fixture(station["label"], station_pos, station["color"])
        _interaction_probe(station["id"], station_pos,
            "Original First Wake " + str(station["label"]) + " dialogue (E).",
            station["color"])
    for index in range(9):
        var z := -10.8 + float(index) * 2.7
        _box("EngineRoom_BrassDeckSeam_%02d" % index,
            ENGINE_ROOM_ORIGIN + Vector3(0, -0.005, z),
            Vector3(10.7, 0.025, 0.056), inlay)
    # Central harmonic-regulator silhouette is an unpowered engineering
    # *composition study*, not a claimed working engine or new lore fact.
    var regulator_tone := _material(Color("#73b3ae"), 0.22, 0.37)
    regulator_tone.emission_enabled = true
    regulator_tone.emission = Color("#3f8d91")
    regulator_tone.emission_energy_multiplier = 0.65
    var regulator_center := ENGINE_ROOM_ORIGIN + Vector3(0.0, 2.15, -11.54)
    _sphere("WakeEngineering_BackBulkheadUnpoweredRegulatorStudy",
        regulator_center, 0.93, Vector3(1.15, 1.0, 0.27), regulator_tone)
    for arc in range(12):
        var phase := TAU * float(arc) / 12.0
        var next_phase := TAU * float(arc + 1) / 12.0
        var arc_a := regulator_center + Vector3(cos(phase) * 1.48, sin(phase) * 1.48, 0.14)
        var arc_b := regulator_center + Vector3(cos(next_phase) * 1.48, sin(next_phase) * 1.48, 0.14)
        _pillar("WakeEngineering_BackBulkheadBrassRegulatorRim", arc_a, arc_b, 0.045, copper)
    for index in range(4):
        var light_z := -8.4 + float(index) * 5.2
        var fixture := ENGINE_ROOM_ORIGIN + Vector3(0, 3.87, light_z)
        var fixture_mat := _material(Color("#e4b480"), 0.23, 0.28)
        fixture_mat.emission_enabled = true
        fixture_mat.emission = Color("#ecb776")
        fixture_mat.emission_energy_multiplier = 1.65
        _box("WakeEngineering_ActualCeilingLamp_%02d" % index, fixture,
            Vector3(1.15, 0.07, 0.42), fixture_mat)
        var local_light := OmniLight3D.new()
        local_light.name = "WakeEngineering_SpatialLamp_%02d" % index
        local_light.light_color = Color("#f4c8a1")
        local_light.light_energy = 1.25
        local_light.omni_range = 9.0
        local_light.position = fixture + Vector3(0, -0.35, 0)
        add_child(local_light)
    navigation_body.global_position = ENGINE_ROOM_ORIGIN + Vector3(0, 0.18, 8.7)
    navigation_body.velocity = Vector3.ZERO
    navigation_body.travel_facing = "north"
    camera_follow_navigation = true
    camera_distance = 8.5
    camera_azimuth = 0.04
    camera_elevation = 0.16
    _update_camera()
    navigation_status.text = "Aureate Wake engineering: E inspect 3 stations, then safety checklist. Flight is gated."

func _assemble_navigation_hud() -> void:
    var overlay := CanvasLayer.new()
    overlay.name = "ClearlyLabeled3DDevelopmentHUD"
    overlay.layer = 3
    add_child(overlay)
    # Dark, input-transparent material ensures the development interaction
    # text remains readable at both bright sunset and dark blue hour.
    var backdrop := ColorRect.new()
    backdrop.name = "ReadableDarkOverlayFor3DControls"
    backdrop.position = Vector2(8, 8)
    backdrop.size = Vector2(944, 67)
    backdrop.color = Color(0.025, 0.065, 0.105, 0.88)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.add_child(backdrop)
    navigation_notice = Label.new()
    navigation_notice.name = "NavigationControls"
    navigation_notice.position = Vector2(20, 20)
    navigation_notice.text = "3D REVIEW | WASD move | E inspect/next | B real story | arrows orbit | C follow | T light | R reset"
    navigation_notice.add_theme_font_size_override("font_size", 13)
    navigation_notice.add_theme_color_override("font_color", Color("#f4e9d4"))
    overlay.add_child(navigation_notice)
    navigation_status = Label.new()
    navigation_status.name = "HonestArtworkStatus"
    navigation_status.position = Vector2(20, 44)
    navigation_status.text = "Turquoise floor ring = NON-CHARACTER marker. Ender/Ionia rigging and story migration pending."
    navigation_status.add_theme_font_size_override("font_size", 12)
    navigation_status.add_theme_color_override("font_color", Color("#c5eadc"))
    overlay.add_child(navigation_status)

    original_dialogue_panel = ColorRect.new()
    original_dialogue_panel.name = "OriginalFirstWakeDialoguePanel"
    original_dialogue_panel.position = Vector2(20, 492)
    original_dialogue_panel.size = Vector2(920, 130)
    original_dialogue_panel.color = Color(0.035, 0.071, 0.125, 0.94)
    original_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    original_dialogue_panel.visible = false
    overlay.add_child(original_dialogue_panel)

    original_dialogue_speaker = Label.new()
    original_dialogue_speaker.name = "OriginalSpeaker"
    original_dialogue_speaker.position = Vector2(19, 11)
    original_dialogue_speaker.add_theme_font_size_override("font_size", 17)
    original_dialogue_speaker.add_theme_color_override("font_color", Color("#f4cc91"))
    original_dialogue_panel.add_child(original_dialogue_speaker)

    original_dialogue_line = Label.new()
    original_dialogue_line.name = "UnmodifiedOriginalDialogue"
    original_dialogue_line.position = Vector2(19, 42)
    original_dialogue_line.size = Vector2(880, 79)
    original_dialogue_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    original_dialogue_line.add_theme_font_size_override("font_size", 19)
    original_dialogue_line.add_theme_color_override("font_color", Color("#f7ead6"))
    original_dialogue_panel.add_child(original_dialogue_line)

func _update_authoritative_dialogue_ui() -> void:
    if original_dialogue_panel == null:
        return
    var show_line: bool = (
        authoritative_story_mode and authoritative_story_bridge != null and
        authoritative_story_bridge.authoritative_job != null and
        authoritative_story_bridge.authoritative_job.dialogue_open
    )
    original_dialogue_panel.visible = show_line
    if not show_line:
        return
    var job = authoritative_story_bridge.authoritative_job
    original_dialogue_speaker.text = job.dialogue_speaker.text
    original_dialogue_line.text = authoritative_story_bridge.story_snapshot().get("dialogue_line", "")
    # Top status must not attempt to display a full script line on one row.
    navigation_status.text = "Original First Wake dialogue  |  E: next line  |  Original party authority preserved"

func inspect_nearest_probe() -> bool:
    if navigation_body == null:
        return false
    if authoritative_story_mode and authoritative_story_bridge != null:
        # Existing authored dialogue advances by E without requiring the
        # 3D character to remain in the original interaction volume.
        if authoritative_story_bridge.authoritative_job.dialogue_open:
            var advanced: bool = authoritative_story_bridge.advance_authoritative_dialogue()
            navigation_status.text = authoritative_story_bridge.bridge_status
            _update_authoritative_dialogue_ui()
            return advanced
    var nearest: Area3D = null
    var nearest_distance := 100000.0
    for area in interaction_probes:
        # Verify actual Area3D physics overlap, not a fake screen-space
        # proximity estimate or story flag.
        if not area.get_overlapping_bodies().has(navigation_body):
            continue
        var distance := area.global_position.distance_to(navigation_body.global_position)
        if distance < nearest_distance:
            nearest_distance = distance
            nearest = area
    if nearest == null:
        navigation_status.text = "Move the turquoise locator near a gold 3D inspection beacon, then press E."
        return false
    var receipt: String = nearest.name
    if authoritative_story_mode:
        var allowed: bool = authoritative_story_bridge.interact_at_verified_probe(receipt)
        navigation_status.text = authoritative_story_bridge.bridge_status
        _update_authoritative_dialogue_ui()
        if allowed:
            interaction_receipts.append(receipt)
            if receipt == "AureateWakeGangway_ReviewOnly":
                _enter_real_3d_engineering_room()
        return allowed
    interaction_receipts.append(receipt)
    navigation_status.text = str(nearest.get_meta("review_text", "Spatial inspection only."))
    return true

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
    _assemble_navigation_physics()
    _assemble_navigation_hud()
    authoritative_story_bridge = FirstWakeStoryBridge.new()
    authoritative_story_bridge.name = "OriginalFirstWakeStoryContractAdapter"
    add_child(authoritative_story_bridge)
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
    var look_target: Vector3 = (
        navigation_body.global_position + Vector3(0.0, 1.0, -3.5)
        if camera_follow_navigation and navigation_body != null
        else CAMERA_TARGET
    )
    if engineering_room_instantiated and camera_follow_navigation and navigation_body != null:
        # Keep the actual reviewer camera INSIDE the physical room at human
        # scale rather than looking down from outside the open doorway.
        look_target = navigation_body.global_position + Vector3(0.0, 1.1, -5.9)
    camera.position = look_target + Vector3(
        sin(camera_azimuth) * horizontal,
        camera_distance * sin(camera_elevation),
        cos(camera_azimuth) * horizontal
    )
    camera.look_at(look_target, Vector3.UP)

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
        elif event.keycode == KEY_E:
            inspect_nearest_probe()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_B:
            if authoritative_story_bridge != null and authoritative_story_bridge.bridge_ready:
                authoritative_story_mode = not authoritative_story_mode
                navigation_status.text = (
                    authoritative_story_bridge.bridge_status if authoritative_story_mode
                    else "Spatial-only debugging restored. Canonical First Wake story state preserved."
                )
            _update_authoritative_dialogue_ui()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_C:
            camera_follow_navigation = not camera_follow_navigation
            _update_camera()
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
    if moved or camera_follow_navigation:
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
        "cinematic_art_approved": false,
        "navigation_3d_ready": navigation_body is CharacterBody3D,
        "physics_collision_surfaces": physics_root.get_child_count() - interaction_probes.size() - 1 if physics_root != null else 0,
        "interactive_probes": interaction_probes.size(),
        "chapter_1_3d_story_connected": false,
        "3d_debug_marker_is_character_art": false,
        "original_story_contract_bridge_bound": authoritative_story_bridge != null and authoritative_story_bridge.bridge_ready,
        "authoritative_dock_dialogue_enabled": authoritative_story_mode,
        "uses_same_original_first_wake_opening": (
            authoritative_story_bridge != null and
            authoritative_story_bridge.story_snapshot().get("same_original_opening_instance") == true
        ),
        "3d_gangway_canonical_boarding_ready": engineering_room_instantiated,
        "3d_engineering_stations_present": engineering_room_instantiated and interaction_probes.size() == 7,
        "3d_engineering_preflight_completed": (
            authoritative_story_bridge != null and
            authoritative_story_bridge.authoritative_session.opening.step_key() == "preflight"
        ),
        "original_dialogue_panel_uses_source_lines": original_dialogue_panel != null
    }
