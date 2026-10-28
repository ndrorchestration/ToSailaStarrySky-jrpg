extends CharacterBody3D
## Explicitly NON-CANONICAL navigation marker on the real spatial coastal dock.
## This body establishes physics/input contract, never masquerades as Ender.
## A source-approved rigged GLB can later be mounted under VisualAnchor.
const MOVE_SPEED := 4.5
const ACCELERATION := 18.0
const ACTIONS := {
    "tstss_3d_forward": KEY_W,
    "tstss_3d_backward": KEY_S,
    "tstss_3d_left": KEY_A,
    "tstss_3d_right": KEY_D
}
var traveled_distance := 0.0
var travel_facing := "north"
var movement_enabled := true
var visual_anchor: Node3D
var foot_locator: MeshInstance3D
var ground_contact_frames := 0

func _ready() -> void:
    name = "NavigationMarker_NotApprovedEnderModel"
    collision_layer = 2
    collision_mask = 1
    floor_snap_length = 0.16
    floor_max_angle = deg_to_rad(45)
    _install_review_input()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.32
    shape.height = 1.65
    var collider := CollisionShape3D.new()
    collider.name = "MeasuredHumanFootprintForFutureGLB"
    collider.shape = shape
    collider.position.y = 0.83
    add_child(collider)

    visual_anchor = Node3D.new()
    visual_anchor.name = "VisualAnchor_ApprovedCharacterGLBWillAttachHere"
    add_child(visual_anchor)

    # A floor-mounted geometric LOCATOR is a deliberate debugging UI, not
    # a costume, human body, animation frame, or substitute character.
    var torus := TorusMesh.new()
    torus.inner_radius = 0.25
    torus.outer_radius = 0.32
    torus.rings = 12
    torus.ring_segments = 24
    foot_locator = MeshInstance3D.new()
    foot_locator.name = "ExplicitNonCharacterFootprintCursor"
    foot_locator.mesh = torus
    foot_locator.position.y = 0.085
    var cursor_material := StandardMaterial3D.new()
    cursor_material.albedo_color = Color("#58c7d8")
    cursor_material.emission_enabled = true
    cursor_material.emission = Color("#1f819c")
    cursor_material.emission_energy_multiplier = 0.8
    cursor_material.metallic = 0.1
    cursor_material.roughness = 0.3
    foot_locator.material_override = cursor_material
    visual_anchor.add_child(foot_locator)

func _install_review_input() -> void:
    for action in ACTIONS:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        var expected: int = int(ACTIONS[action])
        var found := false
        for existing in InputMap.action_get_events(action):
            if existing is InputEventKey and (existing as InputEventKey).physical_keycode == expected:
                found = true
        if not found:
            var key := InputEventKey.new()
            key.physical_keycode = expected
            InputMap.action_add_event(action, key)

func _physics_process(delta: float) -> void:
    var x := Input.get_axis("tstss_3d_left", "tstss_3d_right")
    var z := Input.get_axis("tstss_3d_forward", "tstss_3d_backward")
    var drive := Vector3(x, 0, z).normalized()
    if not movement_enabled:
        drive = Vector3.ZERO
    var old_pos := global_position
    velocity.x = move_toward(velocity.x, drive.x * MOVE_SPEED, ACCELERATION * delta)
    velocity.z = move_toward(velocity.z, drive.z * MOVE_SPEED, ACCELERATION * delta)
    if not is_on_floor():
        velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)) * delta
    else:
        velocity.y = -0.12
        ground_contact_frames += 1
    move_and_slide()
    var step := Vector2(global_position.x - old_pos.x,
                        global_position.z - old_pos.z).length()
    traveled_distance += step
    if drive.length_squared() > 0.01:
        if absf(drive.x) > absf(drive.z):
            travel_facing = "east" if drive.x > 0.0 else "west"
        else:
            travel_facing = "south" if drive.z > 0.0 else "north"
    # Stable 3D art anchor; future GLB animations are driven by actual steps.
    visual_anchor.rotation.y = match_facing_yaw(travel_facing)

func match_facing_yaw(direction: String) -> float:
    match direction:
        "north": return 0.0
        "south": return PI
        "east": return -PI / 2.0
        "west": return PI / 2.0
    return 0.0

func movement_snapshot() -> Dictionary:
    return {
        "body_is_real_physics": true,
        "body_type": "CharacterBody3D",
        "traveled_distance": traveled_distance,
        "facing": travel_facing,
        "ground_frames": ground_contact_frames,
        "foot_position": global_position,
        "source_character_model": false,
        "story_authority": false,
        "release_approved": false
    }
