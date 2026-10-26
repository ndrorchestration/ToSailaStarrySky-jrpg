extends RefCounted
## NONCANON local-world touchdown review: deterministic sampled terrain and
## controlled visual hover-contact only. No physics engine contact shapes,
## rigidbody dynamics, collision avoidance, landing authorization or saved state.
const TerrainStudy = preload("res://terrain.gd")
const FlightStudy = preload("res://flight_controller.gd")
const FIELD_X := Vector2(6.0, 15.0)
const FIELD_Z := Vector2(-18.0, -7.0)
const MAX_SLOPE: float = 0.27
const HOVER_CONTACT_HEIGHT: float = 1.1
const APPROACH_SPEED: float = 4.0
const DEPART_SPEED: float = 5.0

var state: String = "FLYING"
var _target: Vector3 = Vector3.ZERO
var _ground: float = 0.0

static func assess(at: Vector3) -> Dictionary:
    var valid_field: bool = at.x >= FIELD_X.x and at.x <= FIELD_X.y and at.z >= FIELD_Z.x and at.z <= FIELD_Z.y
    var h: float = TerrainStudy.sample_height(at.x, at.z)
    var span: float = 0.75
    var dx: float = (TerrainStudy.sample_height(at.x + span, at.z) -
        TerrainStudy.sample_height(at.x - span, at.z)) / (2.0 * span)
    var dz: float = (TerrainStudy.sample_height(at.x, at.z + span) -
        TerrainStudy.sample_height(at.x, at.z - span)) / (2.0 * span)
    var slope: float = Vector2(dx, dz).length()
    var ground_only: bool = h > TerrainStudy.SEA_LEVEL + 0.8
    return {"ok": valid_field and ground_only and slope <= MAX_SLOPE,
        "height": h, "slope": slope, "field": valid_field, "land": ground_only}

func toggle(at: Vector3) -> bool:
    if state == "FLYING":
        var site: Dictionary = assess(at)
        if not site["ok"] or FlightStudy.clearance(at) < HOVER_CONTACT_HEIGHT:
            return false
        _ground = site["height"]
        _target = Vector3(at.x, _ground + HOVER_CONTACT_HEIGHT, at.z)
        state = "DESCENDING"
        return true
    if state == "LANDED":
        state = "TAKING_OFF"
        return true
    return false

func tick(at: Vector3, delta: float) -> Vector3:
    var step: float = clampf(delta, 0.0, 0.10)
    if state == "DESCENDING":
        var next_y: float = move_toward(at.y, _target.y, APPROACH_SPEED * step)
        var position := Vector3(_target.x, next_y, _target.z)
        if absf(next_y - _target.y) <= 0.0001:
            state = "LANDED"
            return _target
        return position
    if state == "LANDED":
        return _target
    if state == "TAKING_OFF":
        var limit: float = _ground + FlightStudy.MIN_CLEARANCE + 1.0
        var lifted: float = move_toward(at.y, limit, DEPART_SPEED * step)
        if lifted >= limit - 0.0001:
            state = "FLYING"
        return Vector3(_target.x, lifted, _target.z)
    return at

func reset() -> void:
    state = "FLYING"
    _target = Vector3.ZERO
    _ground = 0.0
