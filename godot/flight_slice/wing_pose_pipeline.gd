extends RefCounted
## Public-safe integration seam: a generic, opt-in four-wing pose interpolator.
## This is NOT connected to runtime input, save systems, secrets or navigation.
## The owning scene decides when a pose is requested; the ship owns geometry.
const DEFAULT_DURATION: float = 1.8
const MIN_DURATION: float = 0.1
const MAX_DURATION: float = 8.0

var current_pose: float = 0.0
var target_pose: float = 0.0
var _start_pose: float = 0.0
var _elapsed: float = 0.0
var _duration: float = DEFAULT_DURATION
var active: bool = false

func request_pose(target: float, seconds: float = DEFAULT_DURATION) -> bool:
    if not is_finite(target) or not is_finite(seconds) or seconds <= 0.0:
        return false
    _start_pose = current_pose
    target_pose = clampf(target, 0.0, 1.0)
    _duration = clampf(seconds, MIN_DURATION, MAX_DURATION)
    _elapsed = 0.0
    active = not is_equal_approx(_start_pose, target_pose)
    return true

func advance(ship: Node3D, delta: float, reduced_motion: bool) -> bool:
    # Validate before any state mutation. A missing or invalid ship fails closed.
    if ship == null or not is_instance_valid(ship):
        return false
    if not ship.has_method("set_wing_review_sweep"):
        return false
    if not is_finite(delta) or delta < 0.0:
        return false
    var next_elapsed: float = _elapsed
    var next_pose: float = current_pose
    var next_active: bool = active
    if active and reduced_motion:
        next_pose = target_pose
        next_elapsed = _duration
        next_active = false
    elif active:
        next_elapsed = minf(_duration, _elapsed + delta)
        var t: float = next_elapsed / _duration
        var ease: float = t * t * (3.0 - 2.0 * t)
        next_pose = lerpf(_start_pose, target_pose, ease)
        next_active = next_elapsed < _duration
    # Method returns false if the wing rig is absent or invalid; do not
    # commit interpolation state if the ship cannot accept the pose.
    if not ship.set_wing_review_sweep(next_pose):
        return false
    _elapsed = next_elapsed
    current_pose = next_pose
    active = next_active
    return true
