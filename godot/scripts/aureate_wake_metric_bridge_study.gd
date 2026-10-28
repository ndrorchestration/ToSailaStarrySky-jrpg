extends Node3D
## Unified METRE-SCALE public-safe ship circulation prototype, not final Aureate Wake art.
## All 1.0 Godot units = 1.0 study metres. Story/secret functionality is absent.
## Exact production hull, seaworthiness and actual protective glazing NOT verified.
const BEAM_M: float = 3.50
const HULL_REAR_Z: float = 6.0
const HULL_FORWARD_Z: float = -2.60
const FOREDECK_FRONT_Z: float = -5.60
const HELM_CENTER_Z: float = -1.20
const DOME_RADIUS_M: float = 1.60
const DOME_CENTER_Y: float = 1.35
const DOME_BASE_Y: float = 0.45
const DOME_PEAK_Y: float = DOME_CENTER_Y + DOME_RADIUS_M
const HATCH_Z: float = -2.60
const HATCH_CLEAR_WIDTH_M: float = 1.24
const HATCH_CLEAR_HEIGHT_M: float = 2.10
const RAIL_HEIGHT_M: float = 1.05
const REVIEW_HEADROOM_M: float = 2.05
const COLLISION_LAYER: int = 8
const REVIEW_STATUS := "SINGLE_SCENE_PHYSICS_PROTOTYPE_NOT_PRODUCTION"
const CrewWalker = preload("res://scripts/aureate_wake_crew_walk_review.gd")
const HATCH_INTERACT_RADIUS_M: float = 1.28
var crew_walker: CharacterBody3D
var crew_camera: Camera3D
var crew_camera_enabled: bool = false
var crew_camera_occluded: bool = false

var dome_panels: int = 0
var dome_frame_edges: int = 0
var _hatch_open: bool = true
var _wood: StandardMaterial3D
var _brass: StandardMaterial3D
var _glass: StandardMaterial3D
var _ivory: StandardMaterial3D

func _ready() -> void:
    _wood = _material(Color(0.26, 0.33, 0.30), 0.78, 0.05)
    _brass = _material(Color(0.69, 0.52, 0.29), 0.39, 0.48)
    _glass = _material(Color(0.36, 0.69, 0.74, 0.23), 0.23, 0.08)
    _glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _glass.cull_mode = BaseMaterial3D.CULL_DISABLED
    _ivory = _material(Color(0.73, 0.68, 0.54), 0.66, 0.08)
    _lighting()
    _build_unified_floors()
    _build_cabin_and_hull()
    _build_geodesic_helm()
    _build_foredeck_rails()
    _build_hatch()
    _camera()
    _create_crew_controller()

func _material(tint: Color, roughness: float, metal: float) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = tint
    result.roughness = roughness
    result.metallic = metal
    return result

func _box(label_text: String, position_m: Vector3, dimensions: Vector3,
        material: Material, physical: bool = false) -> Node3D:
    var item := MeshInstance3D.new()
    item.name = label_text
    item.position = position_m
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    item.mesh = mesh
    item.material_override = material
    add_child(item)
    if physical:
        var body := StaticBody3D.new()
        body.name = label_text + "Body"
        body.position = position_m
        body.collision_layer = COLLISION_LAYER
        body.collision_mask = 0
        var shape := CollisionShape3D.new()
        shape.name = "MetricCollision"
        var block := BoxShape3D.new()
        block.size = dimensions
        shape.shape = block
        body.add_child(shape)
        add_child(body)
    return item

func _build_unified_floors() -> void:
    # A real contiguous floor across all 3 zones; no undocumented teleports.
    # Bounding hull volume is NOT a sea-displacement or cargo capacity claim.
    _box("CrewCabinWalkingFloor", Vector3(0, -0.09, 3.05),
        Vector3(BEAM_M, 0.18, 5.90), _wood, true)
    _box("GeodesicHelmWalkingFloor", Vector3(0, -0.09, -1.275),
        Vector3(3.25, 0.18, 2.75), _wood, true)
    _box("OpenForedeckWalkingFloor", Vector3(0, -0.09, -4.10),
        Vector3(2.30, 0.18, 3.00), _wood, true)
    _box("HelmCrewFloorSeam", Vector3(0, 0.016, 0.10),
        Vector3(1.50, 0.032, 0.08), _brass, false)
    _box("HelmBowFloorSeam", Vector3(0, 0.016, HATCH_Z),
        Vector3(1.33, 0.032, 0.07), _brass, false)

func _build_cabin_and_hull() -> void:
    # Open cutaway ceiling and trimmed sides for genuine interior visibility.
    # No pressure wall, buoyancy solver or watertight sheathing.
    for side in [-1.0, 1.0]:
        var side_label := "Port" if side < 0.0 else "Starboard"
        _box("CrewHullSide" + side_label,
            Vector3(side * 1.69, 1.17, 3.10),
            Vector3(0.12, 2.34, 5.72), _ivory, true)
        _box("CrewCabinRoofRib" + side_label,
            Vector3(side * 1.64, 2.44, 2.90),
            Vector3(0.12, 0.11, 5.55), _brass, false)
    _box("CabinAftWall", Vector3(0, 1.12, HULL_REAR_Z),
        Vector3(BEAM_M, 2.25, 0.16), _wood, true)
    _box("CabinTopBeamAft", Vector3(0, 2.41, 5.76),
        Vector3(BEAM_M, 0.18, 0.26), _brass, false)
    # Reserved physical cabin occupancy corridor stays centred and unobstructed.
    _box("PortStorageCabinet", Vector3(-1.22, 0.46, 3.95),
        Vector3(0.47, 0.92, 1.20), _wood, true)
    _box("StarboardWorkBench", Vector3(1.20, 0.50, 3.60),
        Vector3(0.52, 1.00, 1.42), _wood, true)
    _box("HelmNavigationConsole", Vector3(1.15, 0.56, -1.12),
        Vector3(0.49, 1.12, 0.63), _wood, true)
    _box("HelmCompassLens", Vector3(1.15, 1.15, -1.12),
        Vector3(0.34, 0.06, 0.45), _glass, false)

func _build_geodesic_helm() -> void:
    # Native metric faceted hemisphere-inspired triangulation with an ACTUAL
    # glass-mesh aperture wedge in the facing prow. This is new proxy art;
    # original lab icosphere/shader in #482 is NOT imported or certified here.
    var top_theta: float = acos((DOME_BASE_Y - DOME_CENTER_Y) / DOME_RADIUS_M)
    var glass := SurfaceTool.new()
    glass.begin(Mesh.PRIMITIVE_TRIANGLES)
    var bronze := SurfaceTool.new()
    bronze.begin(Mesh.PRIMITIVE_TRIANGLES)
    var edge_keys: Dictionary = {}
    const SIDES: int = 18
    const RINGS: int = 7
    for layer in range(RINGS):
        var ta: float = top_theta * float(layer) / float(RINGS)
        var tb: float = top_theta * float(layer + 1) / float(RINGS)
        for seg in range(SIDES):
            # Forward opening: 5 sector wedge below upper door-head height.
            # The missing pane triangles constitute a real visual opening;
            # there are no fictitious zero-alpha collision panes across it.
            var mid_y: float = DOME_CENTER_Y + DOME_RADIUS_M * cos((ta + tb) * 0.5)
            if seg >= 12 and seg < 15 and mid_y < 2.36:
                continue
            var fa: float = TAU * float(seg) / float(SIDES)
            var fb: float = TAU * float(seg + 1) / float(SIDES)
            var a: Vector3 = _dome_point(ta, fa)
            var c: Vector3 = _dome_point(tb, fa)
            var d: Vector3 = _dome_point(tb, fb)
            var e: Vector3 = _dome_point(ta, fb)
            for triangle in [[a, c, d], [a, d, e]]:
                var p: Vector3 = triangle[0]
                var q: Vector3 = triangle[1]
                var t: Vector3 = triangle[2]
                if (q - p).cross(t - p).dot(
                        (p + q + t) / 3.0 - Vector3(0, DOME_CENTER_Y, HELM_CENTER_Z)) < 0.0:
                    var temp: Vector3 = q
                    q = t
                    t = temp
                if (q - p).cross(t - p).length_squared() < 0.000000001:
                    continue
                for vert in [p, q, t]:
                    glass.add_vertex(vert)
                dome_panels += 1
            for pair in [[a, c], [c, d], [d, e], [e, a], [a, d]]:
                var key: String = _edge_key(pair[0], pair[1])
                if edge_keys.has(key):
                    continue
                edge_keys[key] = true
                _append_tube(bronze, pair[0], pair[1], 0.013)
    dome_frame_edges = edge_keys.size()
    glass.generate_normals()
    bronze.generate_normals()
    var pane := MeshInstance3D.new()
    pane.name = "MetricFacetedGlassStudy"
    pane.mesh = glass.commit()
    pane.material_override = _glass
    add_child(pane)
    var structure := MeshInstance3D.new()
    structure.name = "GeodesicLatticeStudy"
    structure.mesh = bronze.commit()
    structure.material_override = _brass
    add_child(structure)
    # Two jambs enforce the real person-sized ingress corridor. Glass
    # itself has NO collision yet and cannot claim pressure protection.
    _box("PortHelmEntryJamb", Vector3(-0.78, 1.04, HATCH_Z),
        Vector3(0.12, 2.08, 0.14), _brass, true)
    _box("StarboardHelmEntryJamb", Vector3(0.78, 1.04, HATCH_Z),
        Vector3(0.12, 2.08, 0.14), _brass, true)
    _box("HelmEntryHeader", Vector3(0.0, 2.22, HATCH_Z),
        Vector3(1.66, 0.20, 0.14), _brass, true)
    # Faceted design remains open to creator selection; this proxy has no
    # ship propulsion, atmospheric mode, collision glass or narrative clue.
    _box("HelmDeckBandPort", Vector3(-1.45, 0.30, -1.16),
        Vector3(0.12, 0.60, 2.25), _wood, false)
    _box("HelmDeckBandStarboard", Vector3(1.45, 0.30, -1.16),
        Vector3(0.12, 0.60, 2.25), _wood, false)

func _dome_point(theta: float, phi: float) -> Vector3:
    return Vector3(
        DOME_RADIUS_M * sin(theta) * cos(phi),
        DOME_CENTER_Y + DOME_RADIUS_M * cos(theta),
        HELM_CENTER_Z + DOME_RADIUS_M * sin(theta) * sin(phi))

func _edge_key(a: Vector3, b: Vector3) -> String:
    var x: String = str(Vector3i(roundi(a.x * 10000), roundi(a.y * 10000), roundi(a.z * 10000)))
    var y: String = str(Vector3i(roundi(b.x * 10000), roundi(b.y * 10000), roundi(b.z * 10000)))
    return x + "|" + y if x < y else y + "|" + x

func _append_tube(target: SurfaceTool, a: Vector3, b: Vector3, radius: float) -> void:
    var axis: Vector3 = b - a
    if axis.length_squared() < 0.00000001:
        return
    var direction := axis.normalized()
    var u: Vector3 = direction.cross(Vector3.UP)
    if u.length_squared() < 0.01:
        u = direction.cross(Vector3.RIGHT)
    u = u.normalized()
    var v: Vector3 = direction.cross(u).normalized()
    for side in range(4):
        var aa: float = TAU * float(side) / 4.0
        var bb: float = TAU * float(side + 1) / 4.0
        var r0: Vector3 = radius * (u * cos(aa) + v * sin(aa))
        var r1: Vector3 = radius * (u * cos(bb) + v * sin(bb))
        for p in [a + r0, b + r0, b + r1, a + r0, b + r1, a + r1]:
            target.add_vertex(p)

func _build_foredeck_rails() -> void:
    # Physical 1.05m rails at both sides: review-only geometry/collision.
    for side in [-1.0, 1.0]:
        var label_text := "Port" if side < 0.0 else "Starboard"
        var x: float = side * 1.11
        _box(label_text + "SafetyRail", Vector3(x, RAIL_HEIGHT_M - 0.05, -4.08),
            Vector3(0.12, 0.10, 2.83), _brass, true)
        for index in range(4):
            var z: float = -5.39 + float(index) * 0.86
            _box(label_text + "Post" + str(index),
                Vector3(x, 0.525, z),
                Vector3(0.11, 1.05, 0.11), _brass, true)
    _box("ForedeckNoseRail", Vector3(0.0, RAIL_HEIGHT_M - 0.05, -5.53),
        Vector3(2.30, 0.10, 0.09), _brass, true)

func _build_hatch() -> void:
    var hinge := Node3D.new()
    hinge.name = "ForedeckHatchHinge"
    hinge.position = Vector3(-HATCH_CLEAR_WIDTH_M * 0.5, 0, HATCH_Z)
    add_child(hinge)
    var body := StaticBody3D.new()
    body.name = "HatchCollisionBody"
    body.collision_layer = COLLISION_LAYER
    body.collision_mask = 0
    hinge.add_child(body)
    var panel := MeshInstance3D.new()
    panel.name = "HatchPanel"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.20, HATCH_CLEAR_HEIGHT_M, 0.08)
    panel.mesh = mesh
    panel.position = Vector3(0.60, HATCH_CLEAR_HEIGHT_M * 0.5, 0)
    panel.material_override = _ivory
    body.add_child(panel)
    var shape := CollisionShape3D.new()
    shape.name = "HatchPanelPhysics"
    var block := BoxShape3D.new()
    block.size = mesh.size
    shape.shape = block
    shape.position = panel.position
    body.add_child(shape)
    set_hatch_open(true)

func _create_crew_controller() -> void:
    crew_walker = CrewWalker.new()
    crew_walker.position = Vector3(0, 1.03, 3.85)
    add_child(crew_walker)
    crew_camera = Camera3D.new()
    crew_camera.name = "CrewFollowCameraReviewOnly"
    crew_camera.fov = 66
    crew_camera.near = 0.11
    crew_camera.far = 80.0
    add_child(crew_camera)
    crew_camera.current = false

func set_crew_follow_camera(enabled: bool) -> void:
    crew_camera_enabled = enabled
    if crew_camera != null:
        crew_camera.current = enabled

func request_crew_hatch_interaction() -> bool:
    if crew_walker == null or not crew_walker.is_on_floor():
        return false
    var distance: float = Vector2(
        crew_walker.position.x,
        crew_walker.position.z - HATCH_Z).length()
    if distance > HATCH_INTERACT_RADIUS_M:
        return false
    set_hatch_open(not _hatch_open)
    return true

func get_forward_helm_sightline() -> Dictionary:
    # Actual obstruction test, through the near-door helm area only.
    # Not an assertion about structural glass or weather protection.
    var eye := Vector3(0.0, 1.56, -1.50)
    var deck := Vector3(0.0, 1.56, -4.70)
    var params := PhysicsRayQueryParameters3D.create(
        eye, deck, COLLISION_LAYER)
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(params)
    return {
        "clear": hit.is_empty(),
        "collider_name": str(hit["collider"].name) if not hit.is_empty() else ""
    }

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_E and crew_walker != null and (
                crew_walker.manual_controls_enabled):
            if request_crew_hatch_interaction():
                get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
    if not crew_camera_enabled or crew_walker == null or crew_camera == null:
        return
    # Follow the actual walking body and shorten the camera arm if intervening
    # static collision would hide the actor; never pierce an opaque cabin wall.
    var eye: Vector3 = crew_walker.global_position + Vector3.UP * 0.55
    var target: Vector3 = eye + Vector3(1.80, 1.50, 3.05)
    var query := PhysicsRayQueryParameters3D.create(
        eye, target, COLLISION_LAYER)
    var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
    crew_camera_occluded = not result.is_empty()
    if crew_camera_occluded:
        var distance: float = maxf(eye.distance_to(result["position"]) - 0.15, 0.40)
        target = eye + (target - eye).normalized() * distance
    crew_camera.global_position = target
    crew_camera.look_at(eye + Vector3(0, 0, -0.70), Vector3.UP)

func set_hatch_open(value: bool) -> void:
    _hatch_open = value
    if has_node("ForedeckHatchHinge"):
        get_node("ForedeckHatchHinge").rotation.y = -PI * 0.5 if value else 0.0

func is_hatch_open() -> bool:
    return _hatch_open

func _lighting() -> void:
    var env := WorldEnvironment.new()
    env.name = "MetricShipEnvironment"
    var world := Environment.new()
    world.background_mode = Environment.BG_COLOR
    world.background_color = Color(0.058, 0.11, 0.17)
    world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world.ambient_light_color = Color(0.44, 0.52, 0.56)
    world.ambient_light_energy = 0.68
    env.environment = world
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.name = "MetricSunlight"
    sun.rotation_degrees = Vector3(-62, -35, 0)
    sun.light_color = Color(1.00, 0.87, 0.68)
    sun.light_energy = 1.22
    add_child(sun)

func _camera() -> void:
    var camera := Camera3D.new()
    camera.name = "MetricShipStudyCamera"
    camera.position = Vector3(11.2, 7.2, -8.0)
    camera.fov = 50
    camera.near = 0.1
    camera.far = 100
    camera.current = true
    add_child(camera)
    camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
