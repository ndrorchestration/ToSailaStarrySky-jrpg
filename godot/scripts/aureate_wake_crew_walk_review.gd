extends CharacterBody3D
## Original anonymous human-scale pilot capsule for isolated metric ship tests.
## No canon character art or live Chapter I player controls are transplanted.
const CAPSULE_HEIGHT_M: float = 1.74
const CAPSULE_RADIUS_M: float = 0.26
const WALK_SPEED_M_S: float = 3.2
const GRAVITY_M_S2: float = 19.0
const FLOOR_SNAP_M: float = 0.40
const COLLISION_MASK: int = 8
var manual_controls_enabled: bool = true
var deterministic_test_mode: bool = false
var test_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
    name = "CrewWalkingCapsulePrototype"
    collision_layer = 16
    collision_mask = COLLISION_MASK
    floor_snap_length = FLOOR_SNAP_M
    safe_margin = 0.006
    var capsule := CollisionShape3D.new()
    capsule.name = "ActorCapsulePhysics"
    var shape := CapsuleShape3D.new()
    shape.radius = CAPSULE_RADIUS_M
    shape.height = CAPSULE_HEIGHT_M
    capsule.shape = shape
    add_child(capsule)

    var avatar := MeshInstance3D.new()
    avatar.name = "AnonymousCrewBodyVisual"
    var body := CapsuleMesh.new()
    body.radius = CAPSULE_RADIUS_M * 0.82
    body.height = CAPSULE_HEIGHT_M * 0.98
    avatar.mesh = body
    var outfit := StandardMaterial3D.new()
    outfit.albedo_color = Color(0.85, 0.76, 0.55)
    outfit.roughness = 0.88
    avatar.material_override = outfit
    add_child(avatar)

    var heading := MeshInstance3D.new()
    heading.name = "FacingMarker"
    var bead := SphereMesh.new()
    bead.radius = 0.075
    bead.height = 0.15
    heading.mesh = bead
    heading.position = Vector3(0.0, 0.40, -0.19)
    heading.material_override = outfit
    add_child(heading)

func set_test_direction(next_direction: Vector2) -> void:
    deterministic_test_mode = true
    test_direction = next_direction.limit_length(1.0)

func clear_test_direction() -> void:
    test_direction = Vector2.ZERO
    deterministic_test_mode = false

func _physics_process(delta: float) -> void:
    var direction: Vector2 = Vector2.ZERO
    if deterministic_test_mode:
        direction = test_direction
    elif manual_controls_enabled:
        direction = Vector2(
            float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
            - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
            float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
            - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))).normalized()
    direction = direction.limit_length(1.0)
    velocity.x = direction.x * WALK_SPEED_M_S
    velocity.z = direction.y * WALK_SPEED_M_S
    if not is_on_floor():
        velocity.y -= GRAVITY_M_S2 * delta
    else:
        velocity.y = -0.05
    move_and_slide()

    if direction.length_squared() > 0.01:
        var marker: MeshInstance3D = get_node("FacingMarker")
        marker.position = Vector3(
            direction.x * 0.19, 0.40, direction.y * 0.19)
