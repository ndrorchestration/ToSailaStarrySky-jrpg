extends SceneTree
## Native composition contract. Structural tests are NOT visual/art approval.
const Rig = preload("res://cinematic_shot_rig.gd")
const StudyScene = preload("res://main.tscn")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, description: String) -> void:
    checks += 1
    if not ok:
        failures.append(description)

func _run() -> void:
    var origin := Vector3(13.0, 17.0, -11.0)
    var samples: Array[Dictionary] = []
    for second in [0.0, 9.0, 10.5, 12.0, 13.5, 23.0, 24.5, 26.0, 27.5, 34.0]:
        var shot: Dictionary = Rig.sample(second, origin, false)
        samples.append(shot)
        _check((shot["position"] as Vector3).is_finite(), "finite camera %s" % second)
        _check((shot["focus"] as Vector3).is_finite(), "finite gaze %s" % second)
        _check(float(shot["fov"]) >= 48.0 and float(shot["fov"]) <= 62.0,
            "bounded lens %s" % second)
        _check((shot["position"] as Vector3).distance_to(
            shot["focus"] as Vector3) > 12.0, "staged depth %s" % second)
    _check(samples[1]["shot"] == "coastal_departure", "coast has an authored shot")
    _check(samples[5]["shot"] == "forest_passage", "forest has an authored shot")
    _check(samples[9]["shot"] == "highland_reveal", "highland has an authored shot")
    _check(samples[3]["shot"] == "dissolve", "coast/forest uses an eased bridge")
    _check(samples[7]["shot"] == "dissolve", "forest/highland uses an eased bridge")
    _check(Rig.sample(9.0, origin, false) == Rig.sample(9.0, origin, false),
        "same timestamp yields deterministic pose")
    var still: Dictionary = Rig.sample(9.0, origin, true)
    _check((still["position"] as Vector3).distance_to(
        samples[1]["position"] as Vector3) > 0.01,
        "reduced motion disables authored camera drift")
    _check(Rig.sample(46.0, origin, false) == samples[1],
        "37 second authored route wraps deterministically")
    _check(Rig.sample(INF, origin)["shot"] == "fallback",
        "invalid clock fails to stable wide frame")
    _check(Rig.sample(9.0, Vector3(INF, 0, 0))["shot"] == "fallback",
        "invalid ship location cannot poison camera")
    for boundary in [10.5, 13.5, 24.5, 27.5]:
        var before: Vector3 = Rig.sample(boundary-0.01, origin, true)["position"]
        var after: Vector3 = Rig.sample(boundary+0.01, origin, true)["position"]
        _check(before.distance_to(after) < 0.20,
            "shot boundary avoids hard camera cuts %s" % boundary)

    var scene = StudyScene.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene._clock = 23.0
    scene._update_scene(10.0)
    var expected: Dictionary = Rig.sample(23.0, scene.ship.position, false)
    _check(scene.camera.position.distance_to(expected["position"]) < 0.01,
        "main scene uses cinematic authored pose")
    _check(is_equal_approx(scene.camera.fov, float(expected["fov"])),
        "main scene uses authored lens")
    scene._reduced_motion = true
    scene._update_scene(10.0)
    expected = Rig.sample(23.0, scene.ship.position, true)
    _check(scene.camera.position.distance_to(expected["position"]) < 0.01,
        "reduced motion reaches static relative staging")
    scene._cinematic = false
    scene._update_scene(10.0)
    _check(is_equal_approx(scene.camera.fov, 62.0),
        "C follow framing restores the normal lens")
    scene.set_manual_mode(true)
    scene._update_scene(10.0)
    _check(is_equal_approx(scene.camera.fov, 62.0),
        "manual pilot retains navigation-first lens")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_CINEMATIC_CAMERA_PASS checks=", checks)
        quit(0)
    else:
        for failure in failures:
            push_error("GODOT_CINEMATIC_CAMERA_FAIL: " + failure)
        quit(1)
