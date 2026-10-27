extends RefCounted
## P0 route progress contract (NONCANON). This is not a global planet map,
## a save format or evidence of a playable Chapter I integration.
## Only a properly validated real Godot landing contact advances landing.

enum Phase { DOCKED, DEPARTED, COAST_REACHED, TOUCHDOWN, ON_FOOT, RETURNED }

const HOME_SHIP_ID: String = "aureate_wake"
const FRIGATE_ID: String = "dragonfly_frigate"

var phase: Phase = Phase.DOCKED
var visited_coast: bool = false

func start_departure(ship_id: String) -> bool:
    if ship_id != HOME_SHIP_ID or phase != Phase.DOCKED:
        return false
    phase = Phase.DEPARTED
    return true

func mark_coast(in_bounds: bool, over_water_or_coast: bool) -> bool:
    if phase != Phase.DEPARTED or not in_bounds or not over_water_or_coast:
        return false
    visited_coast = true
    phase = Phase.COAST_REACHED
    return true

func mark_touchdown(native_contact: Dictionary, native_landing_state: String) -> bool:
    if phase != Phase.COAST_REACHED or not visited_coast:
        return false
    if native_landing_state != "LANDED" or not native_contact.get("valid", false):
        return false
    # landing_collision.gd returns position and normal only after a genuine
    # collider-scoped physics raycast; never require a nonexistent collider key.
    if not native_contact.has("position") or not native_contact.has("normal"):
        return false
    if not (native_contact["position"] is Vector3 and native_contact["normal"] is Vector3):
        return false
    var contact_position: Vector3 = native_contact["position"]
    var contact_normal: Vector3 = native_contact["normal"]
    if not contact_position.is_finite() or not contact_normal.is_finite():
        return false
    # The native raycast supplies a unit-length support normal. Reject
    # fabricated, zero-length or unnormalized data at the contract boundary.
    if absf(contact_normal.length_squared() - 1.0) > 0.01:
        return false
    if contact_normal.y < 0.985:
        return false
    phase = Phase.TOUCHDOWN
    return true

func disembark(ground_scene_ready: bool) -> bool:
    if phase != Phase.TOUCHDOWN or not ground_scene_ready:
        return false
    phase = Phase.ON_FOOT
    return true

func return_to_ship(ship_id: String, physically_boarded: bool) -> bool:
    if phase != Phase.ON_FOOT or ship_id != HOME_SHIP_ID or not physically_boarded:
        return false
    phase = Phase.RETURNED
    return true

func reset() -> void:
    phase = Phase.DOCKED
    visited_coast = false

func snapshot() -> Dictionary:
    return {"phase": phase, "visited_coast": visited_coast, "home_ship": HOME_SHIP_ID}
