extends SceneTree
## Live native PhysicsServer touchdown bridge; coast is explicitly seeded,
## not evidence of a real spherical voyage or ground-scene transition.
const Landing = preload("res://landing_study.gd")
const Route = preload("res://planetary_route_progress.gd")
var failures: Array[String] = []
var checks := 0

func check(ok: bool, name: String) -> void:
    checks += 1
    if not ok:
        failures.append(name)

func _initialize() -> void:
    call_deferred("_run")

func _tick() -> void:
    await physics_frame
    await process_frame

func _run() -> void:
    var scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    await _tick()
    scene.set_process(false)
    scene._route_study_enabled = true
    scene.set_manual_mode(true)
    check(scene.route_progress.phase == Route.Phase.DEPARTED, "native opt-in departure")
    check(scene.route_progress.mark_coast(true, true), "synthetic coast fixture")
    var safe_pos := Vector3(8.0, Landing.assess(Vector3(8, 0, -12))["height"] + 7.0, -12.0)
    scene._manual_position = safe_pos
    scene.landing_ground.collision_layer = 0
    await _tick()
    check(scene.request_touchdown(), "queued missing-collider touchdown")
    await _tick()
    check(scene.landing.state == "FLYING", "disabled collider denies touchdown")
    check(scene.route_progress.phase == Route.Phase.COAST_REACHED,
        "missing physics cannot advance route")
    scene.landing_ground.collision_layer = 2
    await _tick()
    check(scene.request_touchdown(), "queued valid collider touchdown")
    await _tick()
    check(scene.landing.state == "DESCENDING", "real raycast admitted descent")
    for step in range(120):
        await _tick()
        if scene.landing.state == "LANDED":
            break
    check(scene.landing.state == "LANDED", "native contact reaches landed")
    check(scene.route_progress.phase == Route.Phase.TOUCHDOWN,
        "route progresses only on re-probed live physics support")
    check(scene.route_progress.phase != Route.Phase.ON_FOOT,
        "no fake ground scene admission")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_PLANETARY_ROUTE_PHYSICS_BRIDGE_PASS checks=", checks)
        quit(0)
    else:
        for failure in failures:
            push_error("GODOT_PLANETARY_ROUTE_PHYSICS_BRIDGE_FAIL: " + failure)
        quit(1)
