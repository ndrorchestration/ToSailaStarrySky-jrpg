extends SceneTree
## Deterministic noncanonical sampled-contact landing review, not physics collision.
const Study = preload("res://landing_study.gd")
const Flight = preload("res://flight_controller.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)

func _run() -> void:
    var safe_pos := Vector3(8.0, Study.assess(Vector3(8, 0, -12))["height"] + 7.0, -12.0)
    var chosen: Dictionary = Study.assess(safe_pos)
    check(chosen["ok"], "known test field is grass terrain with acceptable gradient")
    check(chosen["slope"] <= Study.MAX_SLOPE, "sampled landing slope threshold")
    check(not Study.assess(Vector3(-55.0, 8.0, 0.0))["ok"], "ocean is not a landing zone")
    check(not Study.assess(Vector3(34.0, 12.0, -12.0))["ok"], "forest or settlement unreviewed site is blocked")
    var steep_test: Dictionary = Study.assess(Vector3(15.0, 9.0, -7.0))
    check(steep_test["field"] and steep_test["land"], "steep test point lies on dry field")
    check(steep_test["slope"] > Study.MAX_SLOPE and not steep_test["ok"],
        "local steep ground is blocked even inside reviewed field")
    var landing = Study.new()
    check(landing.state == "FLYING", "initial state airborne")
    check(landing.toggle(safe_pos), "first touchdown request accepted")
    check(landing.state == "DESCENDING", "approach state begun")
    check(not landing.toggle(safe_pos), "repeat request while descending denied")
    var at: Vector3 = safe_pos
    for step in range(80):
        at = landing.tick(at, 0.05)
    check(landing.state == "LANDED", "finite descent reaches touchdown")
    check(is_equal_approx(at.y - chosen["height"], Study.HOVER_CONTACT_HEIGHT),
        "contact hover height is exact relative to sampled terrain")
    check(landing.tick(at, 0.1) == at, "landed ship remains still")
    check(landing.toggle(at), "takeoff allowed after landed")
    check(landing.state == "TAKING_OFF", "takeoff state entered")
    check(not landing.toggle(at), "no repeated takeoff request in transition")
    for step in range(80):
        at = landing.tick(at, 0.05)
    check(landing.state == "FLYING", "takeoff reaches normal safe flight")
    check(Flight.clearance(at) >= Flight.MIN_CLEARANCE,
        "takeoff returns at safe terrain clearance")
    landing.reset()
    check(landing.state == "FLYING", "reset clears pending touchdown")
    var excessive := Study.new()
    check(excessive.toggle(safe_pos), "approach can begin for large-step clamp")
    var small_step_y: float = excessive.tick(safe_pos, 20.0).y
    check(safe_pos.y - small_step_y <= Study.APPROACH_SPEED * 0.101,
        "large frame elapsed is clamped during approach")
    var scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var t_event := InputEventKey.new()
    t_event.keycode = KEY_T
    t_event.pressed = true
    scene._unhandled_key_input(t_event)
    check(scene.landing.state == "FLYING", "T cannot change cinematic mode")
    scene.set_manual_mode(true)
    check(not scene.request_touchdown(), "unsafe current route is denied")
    scene._manual_position = safe_pos
    scene._update_scene(0.05)
    scene._unhandled_key_input(t_event)
    check(scene.landing.state == "DESCENDING", "T engages approach at actual safe field")
    scene._update_scene(0.05)
    check(scene.ship.get_node("TouchdownFoot_Port").visible and
        scene.ship.get_node("TouchdownFoot_Starboard").visible,
        "visual feet deployed during approach")
    for step in range(80):
        scene.advance_manual(Vector3(1, 1, -1), 0.05)
    scene._update_scene(0.05)
    check(scene.landing.state == "LANDED", "native study scene reaches landed state")
    var landed: Vector3 = scene.ship.position
    scene.advance_manual(Vector3(0, 1, 1), 0.1)
    scene._update_scene(0.1)
    check(landed == scene.ship.position, "no manual thrust while landed")
    scene._paused = true
    scene._unhandled_key_input(t_event)
    check(scene.landing.state == "LANDED", "paused toggle cannot start takeoff")
    scene._paused = false
    scene._unhandled_key_input(t_event)
    check(scene.landing.state == "TAKING_OFF", "T begins takeoff from landed")
    for step in range(80):
        scene.advance_manual(Vector3.ZERO, 0.05)
    scene._update_scene(0.05)
    check(scene.landing.state == "FLYING", "scene returns to piloting after takeoff")
    check(not scene.ship.get_node("TouchdownFoot_Port").visible,
        "landing feet retract when safely airborne")
    scene.set_manual_mode(false)
    check(scene.landing.state == "FLYING", "leaving pilot mode clears ground state")
    check(scene.terrain.chunk_count() == 64, "existing 64-tile art scene preserved")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_TOUCHDOWN_STUDY_PASS checks=", checks)
        quit(0)
    else:
        for message in failures:
            push_error("GODOT_TOUCHDOWN_STUDY_FAIL: " + message)
        quit(1)
