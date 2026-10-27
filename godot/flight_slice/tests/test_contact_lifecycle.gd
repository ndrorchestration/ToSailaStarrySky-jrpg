extends SceneTree
## Real native scene: a previous ray hit must not authorize unsupported landing.
const Study = preload("res://landing_study.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        print("GODOT_CONTACT_LIFECYCLE_FAIL: ", label)

func _physics_done() -> void:
    # physics_frame precedes node callbacks; inspect only after they finish.
    await physics_frame
    await process_frame

func _place(scene) -> void:
    scene.set_manual_mode(false)
    scene.set_manual_mode(true)
    scene._manual_position = Vector3(8.0, 9.40262, -12.0)
    scene._update_scene(0.0)

func _run() -> void:
    var scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    scene.set_process(false)
    await _physics_done()
    _place(scene)
    check(scene.request_touchdown(), "queue initial touchdown")
    await _physics_done()
    check(scene.landing.state == "DESCENDING", "native contact starts descent")
    var render_before: Vector3 = scene._manual_position
    scene.advance_manual(Vector3(1, 1, -1), 10.0)
    check(scene._manual_position == render_before, "render input cannot advance unchecked descent")
    for step in range(50):
        await _physics_done()
    var before: Vector3 = scene._manual_position
    scene.landing_ground.collision_layer = 0
    await _physics_done()
    check(scene.landing.state == "RECOVERING", "lost collision layer aborts descent")
    check(scene._manual_position.y >= before.y, "support loss never advances downward")
    check(not scene.last_touchdown_contact.get("valid", false), "stale valid contact is cleared")
    check(not scene.request_touchdown(), "landing request blocked during recovery")
    for step in range(100):
        await _physics_done()
    check(scene.landing.state == "FLYING", "recovery reaches ordinary pilot hover")
    check(scene._manual_position.y >= 8.39, "recovery maintains at least five units of clearance")

    scene.landing_ground.collision_layer = 2
    await _physics_done()
    _place(scene)
    check(scene.request_touchdown(), "fresh request after restored collider")
    await _physics_done()
    var start_y: float = scene._manual_position.y
    await _physics_done()
    check(scene._manual_position.y < start_y, "descent progresses on native physics ticks")
    for step in range(120):
        await _physics_done()
    check(scene.landing.state == "LANDED", "supported descent completes")
    before = scene._manual_position
    scene._paused = true
    scene.landing_ground.get_node("VerifiedTerrainTrimesh").disabled = true
    await _physics_done()
    check(scene._manual_position == before, "pause holds the ship despite removed support")
    scene._paused = false
    await _physics_done()
    check(scene.landing.state == "RECOVERING", "resume rechecks disabled shape before landed motion")

    # A body removed from the tree must fail closed instead of calling a freed object.
    scene.landing_ground.queue_free()
    await _physics_done()
    _place(scene)
    check(scene.request_touchdown(), "missing-body request still uses admission queue")
    await _physics_done()
    check(scene.landing.state == "FLYING", "missing body cannot admit touchdown")
    check(not scene.last_touchdown_contact.get("valid", false), "missing body records invalid contact")

    scene.landing_ground = load("res://landing_collision.gd").new()
    scene.add_child(scene.landing_ground)
    await _physics_done()
    _place(scene)
    check(scene.request_touchdown(), "replacement fixture permits a fresh request")
    await _physics_done()
    for step in range(50):
        await _physics_done()
    before = scene._manual_position
    scene.landing_ground.position.y = 0.06
    await _physics_done()
    check(scene.landing.state == "RECOVERING", "shifted support invalidates the cached landing height")
    check(scene._manual_position.y >= before.y, "shifted support cannot pull ship downward")
    check(scene.last_touchdown_contact.get("reason") == "SUPPORT_MOVED_OR_UNSAFE",
        "small collider shift rejected even within admission sampler tolerance")

    scene.landing_ground.position.y = 0.0
    await _physics_done()
    _place(scene)
    check(scene.request_touchdown(), "request for body-removal descent")
    await _physics_done()
    for step in range(50):
        await _physics_done()
    before = scene._manual_position
    scene.landing_ground.queue_free()
    await _physics_done()
    check(scene.landing.state == "RECOVERING", "freed body during descent triggers recovery")
    check(scene._manual_position.y >= before.y, "body removal stops downward motion")

    scene.landing_ground = load("res://landing_collision.gd").new()
    scene.add_child(scene.landing_ground)
    await _physics_done()
    _place(scene)
    check(scene.request_touchdown(), "request for queued-takeoff loss scenario")
    for step in range(120):
        await _physics_done()
    check(scene.landing.state == "LANDED", "takeoff-loss scenario starts supported and landed")
    scene.landing_ground.position.y = 0.06
    check(scene.request_touchdown(), "takeoff queues before changed support is observed")
    await _physics_done()
    check(scene.landing.state == "RECOVERING", "support loss takes priority over queued takeoff")
    check(not scene.last_touchdown_contact.get("valid", false), "queued takeoff cannot retain shifted valid hit")

    # Recovery above cruise clearance must never move down to the old field.
    var model = Study.new()
    var high := Vector3(8.0, 25.0, -12.0)
    model.recover(high)
    var recovered: Vector3 = model.tick(high, 0.1)
    check(recovered == high and model.state == "FLYING", "high-altitude recovery holds height")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_CONTACT_LIFECYCLE_PASS checks=", checks)
        quit(0)
    else:
        for message in failures:
            push_error("GODOT_CONTACT_LIFECYCLE_FAIL: " + message)
        quit(1)
