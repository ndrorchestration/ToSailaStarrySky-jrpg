extends RefCounted
## Test-only, public-safe adapter between native Chapter I and a neutral 3D
## ship presentation sink. NOT a gameplay, boarding, save or flight controller.
const Timeline = preload("res://scripts/ship_visual_pose_timeline.gd")
const CUE_NEUTRAL := "neutral"
const CUE_GENTLE_SWEEP := "gentle_sweep"
const SOURCE_PR: int = 490
const SOURCE_HEAD := "7abee4f14971868f52626d032d238c7140e0c457"

var _timeline = Timeline.new()

func source_contract() -> Dictionary:
    return {
        "source_pr": SOURCE_PR,
        "source_head": SOURCE_HEAD,
        "review_only": true,
        "requires_explicit_opt_in": true,
        "has_runtime_input": false,
        "changes_save": false,
        "modifies_flight_authority": false,
        "includes_3d_ship_assets": false
    }

func _eligible(world: Node) -> bool:
    if world == null or not is_instance_valid(world):
        return false
    if str(world.get("room")) != "engineering":
        return false
    if not bool(world.get("_ship_spaces_requested")):
        return false
    var spaces: Node2D = world.get("ship_spaces_handoff") as Node2D
    if spaces == null or not spaces.visible:
        return false
    var opening = world.get("opening")
    if opening == null or not opening.has_method("step_key"):
        return false
    if str(opening.step_key()) not in ["engineering", "preflight"]:
        return false
    var party = opening.get("active_party_ids")
    return party == ["ender", "ionia"]

func request_preview(world: Node, sink: Node3D, cue: String) -> bool:
    if not _eligible(world):
        return false
    if sink == null or not is_instance_valid(sink):
        return false
    if not sink.has_method("set_wing_review_sweep"):
        return false
    if cue != CUE_NEUTRAL and cue != CUE_GENTLE_SWEEP:
        return false
    var target: float = 1.0 if cue == CUE_GENTLE_SWEEP else 0.0
    return _timeline.request_pose(target)

func advance_preview(world: Node, sink: Node3D, delta: float,
        reduced_motion: bool) -> bool:
    if not _eligible(world):
        return false
    return _timeline.advance(sink, delta, reduced_motion)

func clear_preview(sink: Node3D) -> bool:
    # Resets transient presentation even when boarding/scene opt-in is revoked.
    if sink == null or not is_instance_valid(sink):
        return false
    if not sink.has_method("set_wing_review_sweep"):
        return false
    if not _timeline.request_pose(0.0):
        return false
    return _timeline.advance(sink, 0.0, true)

func snapshot() -> Dictionary:
    return {
        "current": _timeline.current_pose,
        "target": _timeline.target_pose,
        "active": _timeline.active
    }
