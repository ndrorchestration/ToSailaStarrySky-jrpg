extends Node3D
## Camera exclusive to opt-in 2D↔3D Chapter I review. No canon/gameplay data.
## Local zone-aware third-person framing avoids peering through dome walls.
const VIEW_STATUS := "REVIEW_ONLY_NOT_PRODUCTION"
const COLLISION_MASK: int = 8
const FOLLOW_SMOOTH: float = 13.0
const MIN_CAMERA_DISTANCE_M: float = 0.38
enum Shot { FOLLOW, ELEVATED }
var shot: Shot = Shot.FOLLOW
var zone: String = "cabin"
var occluded: bool = false
var camera: Camera3D
var actor: CharacterBody3D
var active: bool = false
var frame_updates: int = 0
var last_unobstructed_distance: float = 0.0

func _ready() -> void:
    name = "OptionalZoneAwareShipCamera"
    camera = Camera3D.new()
    camera.name = "ActualShipboardCamera"
    camera.fov = 60.0
    camera.near = 0.10
    camera.far = 70.0
    camera.current = false
    add_child(camera)

func set_active(enabled: bool) -> void:
    active = enabled
    if camera != null:
        camera.current = enabled
    if enabled:
        snap_to_actor()

func set_shot(next_shot: int) -> bool:
    if next_shot not in [Shot.FOLLOW, Shot.ELEVATED]:
        return false
    shot = next_shot as Shot
    if active:
        snap_to_actor()
    return true

func cycle_shot() -> void:
    set_shot(Shot.ELEVATED if shot == Shot.FOLLOW else Shot.FOLLOW)

func _zone_for(z: float) -> String:
    if z > 0.10:
        return "cabin"
    if z > -2.63:
        return "helm"
    return "foredeck"

func _camera_offset() -> Vector3:
    match zone:
        "cabin":
            return Vector3(0.36, 0.87, 1.43) if shot == Shot.FOLLOW else Vector3(0.10, 1.72, 1.56)
        "helm":
            return Vector3(0.26, 0.78, 1.14) if shot == Shot.FOLLOW else Vector3(0.10, 1.47, 1.13)
        "foredeck":
            return Vector3(0.50, 1.16, 1.00) if shot == Shot.FOLLOW else Vector3(0.17, 1.90, 1.35)
    return Vector3(0.20, 0.95, 1.20)

func _find_safe_position(eye: Vector3, desired: Vector3) -> Vector3:
    var space := get_world_3d().direct_space_state
    var ray := PhysicsRayQueryParameters3D.create(
        eye, desired, COLLISION_MASK)
    ray.exclude = [actor.get_rid()]
    var hit: Dictionary = space.intersect_ray(ray)
    occluded = not hit.is_empty()
    if occluded:
        var travel: Vector3 = (desired - eye).normalized()
        var allowed: float = maxf(
            MIN_CAMERA_DISTANCE_M,
            eye.distance_to(hit["position"]) - 0.16)
        desired = eye + travel * allowed
    last_unobstructed_distance = eye.distance_to(desired)
    return desired

func snap_to_actor() -> void:
    update_view(1.0, true)

func update_view(delta: float, snap: bool = false) -> void:
    if not active or actor == null or camera == null:
        return
    zone = _zone_for(actor.global_position.z)
    # Aim at visible torso/head instead of sky. The avatar can be seen ahead
    # of the lens, even on the open deck near the geodesic door.
    var target: Vector3 = actor.global_position + Vector3(0.0, 0.20, -0.42)
    var eye: Vector3 = actor.global_position + Vector3(0, 0.39, 0)
    var desired: Vector3 = eye + _camera_offset()
    var safe: Vector3 = _find_safe_position(eye, desired)
    var factor: float = 1.0 if snap else 1.0 - exp(-FOLLOW_SMOOTH * maxf(delta, 0.0))
    camera.global_position = camera.global_position.lerp(safe, factor)
    camera.look_at(target, Vector3.UP)
    frame_updates += 1
