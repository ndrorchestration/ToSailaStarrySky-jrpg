extends SceneTree
## Native look-blend contract: purely visual transitions, pause, interrupts and M/V.
const Study = preload("res://main.tscn")
const Mood = preload("res://environment_mood.gd")
const Blend = preload("res://environment_blend.gd")
var errors: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, note: String) -> void:
    checks += 1
    if not ok:
        errors.append(note)

func _run() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var visuals = scene.visuals
    var initial: Dictionary = visuals.current_mood.duplicate(true)
    var dark: Dictionary = Mood.sample(3, 3, true)
    check(not visuals.transition_active, "initial golden look is stable")
    check(initial == Mood.sample(0, 0, false), "unchanged golden clear initial values")
    check(Blend.sample(initial, dark, 0.0) == initial, "zero fraction exact")
    check(Blend.sample(initial, dark, 1.0) == dark, "one fraction exact")
    check(Blend.sample(initial, dark, NAN) == initial, "invalid fraction fails closed")
    for fraction in [0.02, 0.25, 0.5, 0.75, 0.98]:
        var a: Dictionary = Blend.sample(initial, dark, fraction)
        var b: Dictionary = Blend.sample(initial, dark, fraction)
        check(a == b, "pure blend is reproducible at %s" % fraction)
        check(float(a["fog_density"]) >= minf(float(initial["fog_density"]),
            float(dark["fog_density"])), "fog never undershoots %s" % fraction)
        check(float(a["fog_density"]) <= maxf(float(initial["fog_density"]),
            float(dark["fog_density"])), "fog never overshoots %s" % fraction)
        check(float(a["rain_strength"]) >= 0.0 and
            float(a["rain_strength"]) <= 1.0, "rain opacity remains bounded")
    visuals.queue_environment_look(3, 3, true, 2.0)
    check(visuals.transition_active, "new environment queues gradual review")
    check(visuals.current_mood == initial, "request does not snap")
    visuals.advance_environment_transition(0.0, false)
    check(visuals.current_mood == initial, "zero delta does not advance grade")
    visuals.advance_environment_transition(1.0, false)
    var halfway: Dictionary = visuals.current_mood.duplicate(true)
    check(halfway == Blend.sample(initial, dark, 0.5), "halfway grade is exact")
    check(is_equal_approx(float(halfway["rain_strength"]), 0.5),
        "rain opacity is smoothly interpolated")
    check(is_equal_approx(float(visuals.sky_material.get_shader_parameter(
        "magic_veil_strength")), float(halfway["magic_veil_strength"])),
        "sky uses interpolated magic, not instantaneous destination")
    check(is_equal_approx(float(visuals.water.get_shader_parameter(
        "sun_visibility")), float(halfway["sun_visibility"])),
        "ocean solar reflection fades with sky")
    check(is_equal_approx((visuals.get_node("Atmosphere") as WorldEnvironment
        ).environment.fog_density, float(halfway["fog_density"])),
        "native fog receives intermediate weather grade")
    check(visuals.rain.instances.visible, "halfway storm preview displays rain")
    visuals.queue_environment_look(2, 2, false, 2.0)
    check(visuals.current_mood == halfway, "interrupt starts from current pixels")
    visuals.advance_environment_transition(0.75, false)
    var interrupted: Dictionary = visuals.current_mood.duplicate(true)
    check(float(interrupted["magic_veil_strength"]) > 0.0 and
        float(interrupted["magic_veil_strength"]) <
        float(halfway["magic_veil_strength"]),
        "interrupt eases magical veil out rather than popping")
    scene._paused = true
    scene._update_scene(2.0)
    check(visuals.current_mood == interrupted, "pause freezes grade interpolation")
    scene._paused = false
    scene._reduced_motion = true
    scene._update_scene(0.0)
    check(not visuals.transition_active, "M snaps transition to stable destination")
    check(visuals.current_mood == Mood.sample(2, 2, false),
        "M reaches the intended stationary look")
    check(not visuals.rain.instances.visible, "M suppresses moving rain even in storm")
    visuals.set_low_quality(true)
    visuals.queue_environment_look(3, 3, true, 1.0)
    visuals.advance_environment_transition(1.0, false)
    check(not visuals.rain.instances.visible, "V hides rain under all grades")
    check(visuals.low_quality, "V quality mode not modified by transitions")
    visuals.set_low_quality(false)
    visuals.set_environment_look(0, 0, false)
    check(not visuals.rain.instances.visible, "clear restore removes rain")
    check(visuals.current_mood == initial, "instant A/B reference remains exact")
    check(not visuals.transition_active, "instant A/B cancels queued transition")
    check(is_equal_approx(visuals.get_node("GoldenHourKey").light_energy, 1.15),
        "original daytime light energy survives round trip")
    check(scene.terrain.chunk_count() == 64, "transition keeps native terrain tiles")
    # Integrated review: visual transitions do not replace the lived-in
    # Aureate Wake with the separate Dragonfly frigate or touch its physics.
    check(scene.ship.name == "AureateWakeSilhouetteStudy",
        "ship identity stays the creator-established home vessel")
    var hull: MeshInstance3D = scene.ship.get_node("LongHull")
    check(hull.mesh is ArrayMesh, "blended environment retains shaped hull")
    var fixed_ship: Transform3D = scene.ship.global_transform
    for wing_name in ["PortFore", "PortAft", "StarboardFore", "StarboardAft"]:
        var rig: Node3D = scene.ship.get_node("WingRig_" + wing_name)
        check(rig.get_node("Membrane_" + wing_name) is MeshInstance3D,
            "weather transition keeps four separate wing membranes " + wing_name)
    visuals.queue_environment_look(3, 3, true, 2.0)
    visuals.advance_environment_transition(1.0, false)
    check(visuals.transition_active, "halfway storm can coexist with intact ship")
    check(scene.ship.global_transform == fixed_ship,
        "halfway blended weather does not alter ship transform")
    scene.ship.set_motion(23.0, true)
    for wing_name in ["PortFore", "PortAft", "StarboardFore", "StarboardAft"]:
        check(is_zero_approx(scene.ship.get_node("WingRig_" + wing_name).rotation.z),
            "reduced-motion keeps integrated wing flex still " + wing_name)
    check(scene.ship.global_transform == fixed_ship,
        "reduced-motion atmospheric test never changes ship transform")
    scene.queue_free()
    await process_frame
    if errors.is_empty():
        print("GODOT_ENVIRONMENT_BLEND_PASS checks=", checks)
        quit(0)
    else:
        for issue in errors:
            push_error("GODOT_ENVIRONMENT_BLEND_FAIL: " + issue)
        quit(1)
