extends SceneTree
## Native Chapter I candidate can execute a forest visual-policy contract,
## while declining asset/collision/gameplay promotion.
const Bridge = preload("res://scripts/forest_visual_bridge.gd")

var failures: Array[String] = []
func expect(value: bool, description: String) -> void:
    if not value:
        failures.append(description)

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var manifest: Dictionary = {
        "protocol": Bridge.PROTOCOL,
        "coordinate_space": "local_tangent_study",
        "presentation_only": true,
        "canon_approved": false,
        "collision_changes": false,
        "save_changes": false,
        "navigation_changes": false,
        "asset_status": "unapproved_study",
        "batches": [
            {"id": "forest-e0", "species": "evergreen",
                "local_bounds": AABB(Vector3(16,0,-20), Vector3(24,12,40))},
            {"id": "forest-e1", "species": "evergreen",
                "local_bounds": AABB(Vector3(40,0,-20), Vector3(24,12,40))},
            {"id": "forest-b0", "species": "broadleaf",
                "local_bounds": AABB(Vector3(16,0,-20), Vector3(24,12,40))},
            {"id": "forest-b1", "species": "broadleaf",
                "local_bounds": AABB(Vector3(40,0,-20), Vector3(24,12,40))}
        ]
    }
    expect(Bridge.validate_candidate(manifest)["ok"], "valid review-only manifest")
    var far: Vector3 = Vector3(-100, 22, 0)
    var close: Vector3 = Vector3(30, 16, 0)
    var source_state: Dictionary = {}
    var settled: Dictionary = Bridge.plan(manifest, source_state, far)
    expect(settled["ok"] and settled["swaps"].is_empty(),
        "far camera retains coarse canopy")
    var pending_observed: bool = false
    var swaps_applied: int = 0
    var current: Dictionary = settled["states"]
    for tick in range(10):
        var next_state: Dictionary = Bridge.plan(manifest, current, close)
        expect(next_state["ok"] and next_state["swaps"].size() <= 1,
            "one spatial cell swap per normal update")
        if tick == 0:
            pending_observed = next_state["pending"] > 0
        swaps_applied += next_state["swaps"].size()
        current = next_state["states"]
        if next_state["pending"] == 0:
            break
    expect(pending_observed and swaps_applied == 4,
        "all four local canopy groups converge across bounded steps")
    expect(source_state.is_empty(), "planner never mutates the input state")
    var low: Dictionary = Bridge.plan(manifest, current, close, true)
    expect(low["ok"] and low["swaps"].size() == 4 and low["pending"] == 0,
        "low-quality fallback is immediate, not deferred")
    expect(current.values().has(true), "low-quality never mutates caller state")
    var rejected: Dictionary = manifest.duplicate(true)
    rejected["collision_changes"] = true
    expect(not Bridge.validate_candidate(rejected)["ok"],
        "scene collision authority is never imported")
    rejected = manifest.duplicate(true)
    rejected["canon_approved"] = true
    expect(not Bridge.validate_candidate(rejected)["ok"],
        "study art cannot be silently promoted as canon")
    rejected = manifest.duplicate(true)
    rejected["save_changes"] = true
    expect(not Bridge.validate_candidate(rejected)["ok"],
        "visual study cannot mutate Chapter I save format")
    rejected = manifest.duplicate(true)
    rejected["coordinate_space"] = "planet_world"
    expect(not Bridge.validate_candidate(rejected)["ok"],
        "unresolved global coordinate schema fails closed")
    rejected = manifest.duplicate(true)
    rejected["batches"][1]["id"] = "forest-e0"
    expect(not Bridge.validate_candidate(rejected)["ok"],
        "duplicate instance group identifiers rejected")
    if failures.is_empty():
        print("FOREST_CH1_BRIDGE_PASS: review-only GDScript, bounded LOD, low fallback, authority separation")
        quit(0)
        return
    for failure in failures:
        push_error("FOREST_CH1_BRIDGE_FAIL: " + failure)
    quit(1)
