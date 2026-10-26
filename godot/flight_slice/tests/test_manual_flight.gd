extends SceneTree
## Bounded manual-pilot input/scene integration; no physics or canon acceptance.
const Flight = preload("res://flight_controller.gd")
const Terrain = preload("res://terrain.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, label_text: String) -> void:
    checks += 1
    if not ok:
        failures.append(label_text)

func _run() -> void:
    var initial := Vector3(-8.0, 14.0, -14.0)
    var none: Dictionary = Flight.advance(initial, 0.0, Vector3.ZERO, 0.0)
    check(none["position"] == initial, "zero-delta preserves valid position")
    var forward: Dictionary = Flight.advance(initial, 0.0, Vector3(0, 1, 0), 0.1)
    check(forward["position"].x > initial.x + 1.6, "forward command moves east")
    check(absf(forward["position"].z - initial.z) < 0.0001, "forward does not drift sideways")
    var reverse: Dictionary = Flight.advance(initial, 0.0, Vector3(0, -1, 0), 0.1)
    check(reverse["position"].x < initial.x, "reverse command works")
    var steer: Dictionary = Flight.advance(initial, 0.0, Vector3(1, 0, 0), 0.1)
    check(float(steer["heading"]) > 0.13, "steer changes heading")
    check(steer["position"].distance_to(initial) < 0.001, "yaw alone does not translate")
    var climb: Dictionary = Flight.advance(initial, 0.0, Vector3(0, 0, 1), 0.1)
    check(climb["position"].y > initial.y, "ascend increases absolute altitude")
    var descend: Dictionary = Flight.advance(initial, 0.0, Vector3(0, 0, -1), 0.1)
    check(descend["position"].y < initial.y, "descend lowers absolute altitude")
    var long_frame: Dictionary = Flight.advance(initial, 0.0, Vector3(0, 1, 0), 20.0)
    check(long_frame["position"].x - initial.x < 1.8,
        "large frame-time is clamped against movement teleport")
    var unsafe: Vector3 = Vector3(45.0, -500.0, -24.0)
    var safe: Dictionary = Flight.advance(unsafe, 0.0, Vector3(0, 0, -1), 0.1)
    check(Flight.clearance(safe["position"]) >= Flight.MIN_CLEARANCE - 0.00001,
        "sampled terrain/ocean clearance never breached")
    var edge: Dictionary = Flight.advance(Vector3(500, 500, -500),
        0.0, Vector3(0, 1, 0), 0.1)
    check(absf(edge["position"].x) <= 79.0 and absf(edge["position"].z) <= 79.0,
        "local study bounds prevent out-of-world flight")
    check(Flight.clearance(edge["position"]) >= Flight.MIN_CLEARANCE,
        "terrain safety maintained at study bounds")
    var scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var before: Vector3 = scene.ship.position
    var press := InputEventKey.new()
    press.keycode = KEY_F
    press.pressed = true
    scene._unhandled_key_input(press)
    check(scene._manual_active, "F key enters pilot mode")
    for i in range(30):
        scene.advance_manual(Vector3(0, 1, 0), 0.05)
    scene._update_scene(0.05)
    check(scene.ship.position.x > before.x + 20.0, "pilot moves native Dragonfly silhouette")
    check(Flight.clearance(scene.ship.position) >= Flight.MIN_CLEARANCE,
        "ship stays above sampled terrain")
    var pilot_position: Vector3 = scene.ship.position
    scene._paused = true
    scene.advance_manual(Vector3(1, 1, -1), 0.08)
    scene._update_scene(0.08)
    check(scene.ship.position == pilot_position, "pause blocks manual motion")
    scene._paused = false
    scene._reduced_motion = true
    scene.advance_manual(Vector3(1, 0, 0), 0.05)
    scene._update_scene(0.05)
    check(absf(scene.ship.rotation.y) > 0.7, "manual heading survives reduced motion")
    scene._unhandled_key_input(press)
    check(not scene._manual_active, "F returns to automatic flyover")
    scene._update_scene(0.05)
    check(scene.ship.position != pilot_position, "cinematic route returns without altering script")
    press.keycode = KEY_R
    scene._clock = 17.0
    scene._unhandled_key_input(press)
    check(scene._clock == 0.0 and not scene._manual_active, "R returns safe automatic start")
    check(scene.terrain.chunk_count() == 64, "manual study preserves tile count")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_MANUAL_FLIGHT_PASS checks=", checks)
        quit(0)
    else:
        for failure in failures:
            push_error("GODOT_MANUAL_FLIGHT_FAIL: " + failure)
        quit(1)
