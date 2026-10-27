extends SceneTree
## Native Godot contracts for noncanonical weather/light/magic cinematography.
## No screenshot or artistic-acceptance claims; graphical capture is separate.
const StudyScene = preload("res://main.tscn")
const Mood = preload("res://environment_mood.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, label_text: String) -> void:
    checks += 1
    if not ok:
        failures.append(label_text)

func _run() -> void:
    var scene = StudyScene.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var visuals = scene.visuals
    check(visuals.current_mood["time_name"] == "GOLDEN", "default time unchanged")
    check(visuals.current_mood["weather_name"] == "CLEAR", "default weather unchanged")
    check(is_zero_approx(float(visuals.sky_material.get_shader_parameter(
        "magic_veil_strength"))), "magic preview is opt-in")
    check(not visuals.rain.instances.visible, "default has no artificial precipitation")
    check(visuals.rain.instances.multimesh.instance_count == 112,
        "rain geometry has a bounded single-instanced budget")
    check(visuals.rain.instances.cast_shadow ==
        GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
        "rain does not add shadow cost")
    check(visuals.SUN_DIRECTION ==
        visuals.sky_material.get_shader_parameter("sun_direction"),
        "sky and water retain authored sun direction")
    for t in range(4):
        for w in range(4):
            var a: Dictionary = Mood.sample(t, w, t == 3)
            var b: Dictionary = Mood.sample(t, w, t == 3)
            check(a == b, "all looks are deterministic %s/%s" % [t, w])
            check(is_finite(float(a["fog_density"])) and
                float(a["fog_density"]) < 0.018,
                "look fog remains bounded %s/%s" % [t, w])
            check(float(a["key_energy"]) >= 0.0, "no negative sun light")
    check(Mood.sample(4, 4, false) == Mood.sample(0, 0, false),
        "out-of-range indices wrap without invalid state")
    var height: float = scene.terrain.sample_height(12.0, -9.0)
    var position: Vector3 = scene.ship.position
    scene._clock = 23.0
    visuals.set_environment_look(3, 3, true)
    check(visuals.current_mood["time_name"] == "NIGHT", "night grade selects")
    check(visuals.current_mood["weather_name"] == "STORM", "storm grade selects")
    check(is_equal_approx(float(visuals.sky_material.get_shader_parameter(
        "magic_veil_strength")), 0.70), "magical veil opt-in reached shader")
    check(is_equal_approx(float(visuals.sky_material.get_shader_parameter(
        "time_palette")), 3.0), "night sky reached shader")
    check(is_equal_approx(float(visuals.sky_material.get_shader_parameter(
        "weather_strength")), 1.0), "storm sky reached shader")
    var env: Environment = (visuals.get_node("Atmosphere") as WorldEnvironment).environment
    check(is_equal_approx(env.fog_density,
        float(visuals.current_mood["fog_density"])), "storm fog matches palette")
    visuals.set_clock(23.0, false)
    check(visuals.rain.instances.visible, "rain appears only in active storm look")
    check(is_equal_approx(float(visuals.rain.material.get_shader_parameter(
        "study_time")), 23.0), "rain uses exact deterministic scene clock")
    visuals.set_low_quality(true)
    check(not visuals.rain.instances.visible, "V omits precipitation impostors")
    visuals.set_low_quality(false)
    check(visuals.rain.instances.visible, "high detail restores precipitation")
    visuals.set_clock(23.0, true)
    check(not visuals.rain.instances.visible, "M disables moving rain")
    check(is_zero_approx(float(visuals.rain.material.get_shader_parameter(
        "study_time"))), "M freezes precipitation clock")
    check(is_zero_approx(float(visuals.sky_material.get_shader_parameter(
        "study_time"))), "M freezes magical sky motion")
    visuals.set_environment_look(0, 0, false)
    visuals.set_clock(23.0, false)
    check(not visuals.rain.instances.visible, "clear sky removes rain")
    check(is_zero_approx(float(visuals.sky_material.get_shader_parameter(
        "magic_veil_strength"))), "clear preview removes magical veil")
    check(is_equal_approx(visuals.get_node("GoldenHourKey").light_energy, 1.15),
        "default key energy remains established value")
    check(is_equal_approx(env.fog_density, 0.0035),
        "default fog matches established presentation")
    check(is_equal_approx(height, scene.terrain.sample_height(12.0, -9.0)),
        "looks never alter terrain height")
    check(scene._clock == 23.0 and scene.ship.position == position,
        "look toggles do not control time, flight or actor position")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_ENVIRONMENT_MOOD_PASS checks=", checks)
        quit(0)
    else:
        for failure in failures:
            push_error("GODOT_ENVIRONMENT_MOOD_FAIL: " + failure)
        quit(1)
