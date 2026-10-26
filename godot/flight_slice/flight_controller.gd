extends RefCounted
## NONCANON locally planar flight-study controller, not airship flight physics.
## Pure deterministic math; no input device, SceneTree or save changes.
const TerrainStudy = preload("res://terrain.gd")
const CRUISE_SPEED: float = 17.0
const CLIMB_SPEED: float = 8.0
const TURN_SPEED: float = 1.35
const MIN_CLEARANCE: float = 5.0
const MAX_WORLD_ALTITUDE: float = 52.0
const X_BOUND: Vector2 = Vector2(-79.0, 79.0)
const Z_BOUND: Vector2 = Vector2(-79.0, 79.0)

static func surface_height(x: float, z: float) -> float:
    return maxf(TerrainStudy.SEA_LEVEL, TerrainStudy.sample_height(x, z))

static func clearance(at: Vector3) -> float:
    return at.y - surface_height(at.x, at.z)

static func advance(at: Vector3, heading: float, controls: Vector3, delta: float) -> Dictionary:
    # controls.x=turn right (+), controls.y=forward (+), controls.z=climb (+)
    # No acceleration or collision response: bounded cinematic prototyping only.
    var step: float = clampf(delta, 0.0, 0.10)
    var turn: float = clampf(controls.x, -1.0, 1.0)
    var thrust: float = clampf(controls.y, -1.0, 1.0)
    var climb: float = clampf(controls.z, -1.0, 1.0)
    var new_heading: float = wrapf(heading + turn * TURN_SPEED * step, -PI, PI)
    var forward := Vector3(cos(new_heading), 0.0, sin(new_heading))
    var proposed: Vector3 = at + forward * (thrust * CRUISE_SPEED * step) + Vector3.UP * (climb * CLIMB_SPEED * step)
    proposed.x = clampf(proposed.x, X_BOUND.x, X_BOUND.y)
    proposed.z = clampf(proposed.z, Z_BOUND.x, Z_BOUND.y)
    var floor_y: float = surface_height(proposed.x, proposed.z) + MIN_CLEARANCE
    # A fixed world ceiling prevents instant down-teleport when leaving mountains.
    proposed.y = clampf(proposed.y, floor_y, maxf(MAX_WORLD_ALTITUDE, floor_y))
    return {"position": proposed, "heading": new_heading}
