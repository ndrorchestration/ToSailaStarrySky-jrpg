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
    check(not scene.route_progress.disembark(false), "scene must be ready before disembark")
    var ground_scene = load("res://route_ground_stage.tscn").instantiate()
    check(not ground_scene.ready_for_disembark, "ground fixture not ready before tree admission")
    scene.add_child(ground_scene)
    await process_frame
    check(ground_scene.is_inside_tree() and ground_scene.ready_for_disembark,
        "native ground stage entered tree")
    check(scene.route_progress.disembark(ground_scene.is_inside_tree() and ground_scene.ready_for_disembark),
        "real native ground scene readiness advances ON_FOOT")
    check(not scene.route_progress.return_to_ship(Route.HOME_SHIP_ID, false),
        "return cannot be inferred from ground scene load")
    check(not ground_scene.can_board(), "boarding not admitted without a walk")
    check(not ground_scene.walk(Vector3(INF, 0, 0), 0.05), "invalid movement denied")
    check(not ground_scene.walk(Vector3(1, 1, 0), 0.05), "vertical movement denied")
    for step in range(20):
        check(ground_scene.walk(Vector3(1, 0, 0), 0.1), "bounded walk outward")
    check(not ground_scene.can_board(), "boarding denied outside ship radius")
    check(not scene.route_progress.return_to_ship(Route.HOME_SHIP_ID, ground_scene.can_board()),
        "route does not return when far from ship")
    for step in range(20):
        check(ground_scene.walk(Vector3(-1, 0, 0), 0.1), "bounded walk home")
    check(ground_scene.can_board(), "boarding admitted after returning to ship radius")
    check(scene.route_progress.return_to_ship(Route.HOME_SHIP_ID, ground_scene.can_board()),
        "return requires actual ground fixture boarding readiness")
    check(scene.route_progress.phase == Route.Phase.RETURNED, "journey returns to home ship")


    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_PLANETARY_ROUTE_PHYSICS_BRIDGE_PASS checks=", checks)
        quit(0)
    else:
        for failure in failures:
            push_error("GODOT_PLANETARY_ROUTE_PHYSICS_BRIDGE_FAIL: " + failure)
        quit(1)
