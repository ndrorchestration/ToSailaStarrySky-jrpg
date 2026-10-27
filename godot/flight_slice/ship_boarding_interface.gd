extends Node3D
## Native, isolated PUBLIC-SAFE bow-to-cabin access feasibility study.
## 1 study metre = 1 physics metre in this scene ONLY. Not a production hull.
## No closed-compartment certification, marine handling or travel unlocks.
const BowStudy = preload("res://ship_foredeck.gd")
const ART_TO_METRES: float = 2.5
const CABIN_FRONT_Z: float = -3.075
const CABIN_REAR_Z: float = -0.85
const FLOOR_TOP_Y: float = 0.0
const DOORWAY_WIDTH_M: float = 1.36
const DOORWAY_HEIGHT_M: float = 1.96
const MODEL_RAIL_HEIGHT_M: float = 0.725
const COLLISION_LAYER: int = 8

var _door_open: bool = true
var _wood: StandardMaterial3D
var _brass: StandardMaterial3D
var _ivory: StandardMaterial3D
var _glass: StandardMaterial3D

func _ready() -> void:
    _wood = _material(Color(0.20, 0.28, 0.26), 0.70, 0.04)
    _brass = _material(Color(0.66, 0.47, 0.28), 0.35, 0.55)
    _ivory = _material(Color(0.69, 0.69, 0.58), 0.71, 0.03)
    _glass = _material(Color(0.22, 0.43, 0.48), 0.32, 0.13)
    _world_lights()

    # Deliberately declared art-to-metre bridge; this is a *hypothesis*, not
    # correspondence to the separately authored 10.4 m cabin design.
    var bow := BowStudy.new()
    bow.name = "MappedForedeck"
    bow.scale = Vector3.ONE * ART_TO_METRES
    bow.position.y = -BowStudy.PLATFORM_Y * ART_TO_METRES
    add_child(bow)

    # Collision copies the exact triangulation, not a giant enclosing box.
    var bow_floor := StaticBody3D.new()
    bow_floor.name = "BowFloorPhysics"
    bow_floor.collision_layer = COLLISION_LAYER
    bow_floor.collision_mask = 0
    bow.add_child(bow_floor)
    var hit_shape := CollisionShape3D.new()
    hit_shape.name = "ExactForedeckTriangleCollision"
    var top: MeshInstance3D = bow.get_node("OpenPlatform")
    var triangle_shape: ConcavePolygonShape3D = top.mesh.create_trimesh_shape()
    triangle_shape.backface_collision = true
    hit_shape.shape = triangle_shape
    bow_floor.add_child(hit_shape)

    # A short, separate forward cabin *threshold* only. Other rooms and
    # bunks from the earlier full-length cutaway are not silently squeezed in.
    var length: float = CABIN_REAR_Z - CABIN_FRONT_Z
    var center: float = (CABIN_REAR_Z + CABIN_FRONT_Z) * 0.5
    _solid("CrewEntryFloor", Vector3(0.0, -0.07, center),
        Vector3(2.35, 0.14, length), _wood, true)
    _solid("CabinTrimPort", Vector3(-0.92, 0.94, CABIN_FRONT_Z),
        Vector3(0.51, 1.88, 0.13), _wood, true)
    _solid("CabinTrimStarboard", Vector3(0.92, 0.94, CABIN_FRONT_Z),
        Vector3(0.51, 1.88, 0.13), _wood, true)
    _solid("CabinHeader", Vector3(0.0, 2.09, CABIN_FRONT_Z),
        Vector3(2.35, 0.26, 0.13), _brass, true)
    # A raised upper backframe provides a readable cabin entrance outline;
    # the exposed deck remains open air and is never sealed by a visual roof.
    for side in [-1.0, 1.0]:
        var side_name: String = "Port" if side < 0.0 else "Starboard"
        _solid("CabinSide_" + side_name,
            Vector3(side * 1.12, 0.78, center),
            Vector3(0.11, 1.56, length), _wood, true)
        _solid("InteriorBrace_" + side_name,
            Vector3(side * 1.08, 1.85, -1.30),
            Vector3(0.10, 0.12, 0.75), _brass, false)
    _solid("DoorThreshold", Vector3(0.0, 0.024, CABIN_FRONT_Z),
        Vector3(1.37, 0.048, 0.10), _brass, false)

    var hinge := Node3D.new()
    hinge.name = "DoorHinge"
    hinge.position = Vector3(-0.66, 0.0, CABIN_FRONT_Z)
    add_child(hinge)
    # Hinged panel in the *crew entrance*, normally held open for access.
    var door := StaticBody3D.new()
    door.name = "SwingDoor"
    door.collision_layer = COLLISION_LAYER
    door.collision_mask = 0
    hinge.add_child(door)
    var panel := MeshInstance3D.new()
    panel.name = "TimberPanel"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.30, 1.85, 0.085)
    panel.mesh = mesh
    panel.position = Vector3(0.65, 0.955, 0.0)
    panel.material_override = _ivory
    door.add_child(panel)
    var shape := CollisionShape3D.new()
    shape.name = "DoorPanelCollision"
    var block := BoxShape3D.new()
    block.size = mesh.size
    shape.shape = block
    shape.position = panel.position
    door.add_child(shape)
    _add_knob(door)
    set_door_open(true)
    _add_review_camera()

func set_door_open(value: bool) -> void:
    _door_open = value
    if has_node("DoorHinge"):
        # Open panel folds beside the opening, leaving actor-scale passage.
        get_node("DoorHinge").rotation.y = -PI * 0.5 if value else 0.0

func is_door_open() -> bool:
    return _door_open

func _add_knob(door: StaticBody3D) -> void:
    var knob := MeshInstance3D.new()
    knob.name = "DoorHandle"
    var ball := SphereMesh.new()
    ball.radius = 0.043
    ball.height = 0.086
    knob.mesh = ball
    knob.material_override = _brass
    knob.position = Vector3(1.16, 0.99, -0.075)
    door.add_child(knob)

func _solid(label: String, center: Vector3, dimensions: Vector3,
        material: Material, physics: bool) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = label
    mesh.position = center
    var box := BoxMesh.new()
    box.size = dimensions
    mesh.mesh = box
    mesh.material_override = material
    add_child(mesh)
    if physics:
        var body := StaticBody3D.new()
        body.name = label + "Physics"
        body.position = center
        body.collision_layer = COLLISION_LAYER
        body.collision_mask = 0
        add_child(body)
        var collision := CollisionShape3D.new()
        collision.name = "VerifiedBox"
        var shape := BoxShape3D.new()
        shape.size = dimensions
        collision.shape = shape
        body.add_child(collision)

func _add_review_camera() -> void:
    var camera := Camera3D.new()
    camera.name = "CrewThresholdCamera"
    camera.position = Vector3(5.0, 4.5, -7.7)
    camera.fov = 52.0
    camera.near = 0.15
    camera.far = 60.0
    camera.current = true
    add_child(camera)
    camera.look_at(Vector3(0.0, 1.0, -3.25), Vector3.UP)

func _world_lights() -> void:
    var env := WorldEnvironment.new()
    env.name = "ThresholdWorldEnvironment"
    var atmosphere := Environment.new()
    atmosphere.background_mode = Environment.BG_COLOR
    atmosphere.background_color = Color(0.052, 0.092, 0.14)
    atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    atmosphere.ambient_light_color = Color(0.45, 0.52, 0.57)
    atmosphere.ambient_light_energy = 0.65
    env.environment = atmosphere
    add_child(env)
    var sunlight := DirectionalLight3D.new()
    sunlight.name = "StudySun"
    sunlight.rotation_degrees = Vector3(-58.0, -33.0, 0.0)
    sunlight.light_color = Color(1.0, 0.84, 0.66)
    sunlight.light_energy = 1.10
    sunlight.shadow_enabled = true
    add_child(sunlight)

func _material(color: Color, rough: float, metal: float) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.roughness = rough
    result.metallic = metal
    return result
