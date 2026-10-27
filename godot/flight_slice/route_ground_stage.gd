extends Node3D
## Bounded noncanonical on-foot/boarding fixture; no gameplay save or
## character animation. Boarding is only valid after actual movement back
## into the explicit near-ship radius following ground-scene initialization.
const WALK_SPEED: float = 3.0
const BOARD_RADIUS: float = 1.5
const MAX_RADIUS: float = 12.0
var ready_for_disembark: bool = false
var steps_taken: int = 0
var walker_position: Vector3 = Vector3.ZERO

func _ready() -> void:
    ready_for_disembark = true

func walk(direction: Vector3, delta: float) -> bool:
    if not ready_for_disembark or not is_inside_tree():
        return false
    if not direction.is_finite() or not is_finite(delta) or delta <= 0.0 or delta > 0.1:
        return false
    if absf(direction.y) > 0.001 or direction.length_squared() > 1.001:
        return false
    var next: Vector3 = walker_position + direction * WALK_SPEED * delta
    if next.length_squared() > MAX_RADIUS * MAX_RADIUS:
        return false
    if next == walker_position:
        return false
    walker_position = next
    steps_taken += 1
    return true

func can_board() -> bool:
    return ready_for_disembark and is_inside_tree() and steps_taken > 0 and walker_position.length() <= BOARD_RADIUS
