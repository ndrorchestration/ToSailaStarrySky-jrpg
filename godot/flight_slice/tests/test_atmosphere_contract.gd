extends SceneTree
## Native sky/material contract, separate from GL image and creator art review.
const StudyScene = preload("res://main.tscn")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, title: String) -> void:
    checks += 1
    if not value:
        failures.append(title)

func _run() -> void:
    var scene = StudyScene.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var sky: ShaderMaterial = scene.visuals.sky_material
    var initial_strength: Variant = sky.get_shader_parameter("cloud_depth_strength")
    check(initial_strength is float, "sky depth strength is explicitly bound")
    if initial_strength is float:
        check(is_equal_approx(initial_strength, 1.0),
            "new cloud bank defaults on in high detail")
    check(sky.get_shader_parameter("sun_direction") == scene.visuals.SUN_DIRECTION,
        "cloud rim shares existing scene sun vector")
    check(not bool(sky.get_shader_parameter("low_quality")),
        "high detail remains initial default")
    scene.visuals.set_low_quality(true)
    check(bool(sky.get_shader_parameter("low_quality")),
        "low-quality shader branch enabled")
    scene.visuals.set_low_quality(false)
    sky.set_shader_parameter("cloud_depth_strength", 0.0)
    var reference_strength: Variant = sky.get_shader_parameter("cloud_depth_strength")
    check(reference_strength is float, "reference sky strength remains a float")
    if reference_strength is float:
        check(is_zero_approx(reference_strength),
            "reference sky can be selected for matched native capture")
    sky.set_shader_parameter("cloud_depth_strength", 1.0)
    scene.visuals.set_clock(18.0, true)
    check(is_zero_approx(float(sky.get_shader_parameter("study_time"))),
        "reduced motion fixes sky clock")
    scene.visuals.set_clock(18.0, false)
    check(is_equal_approx(float(sky.get_shader_parameter("study_time")), 18.0),
        "normal motion follows authored explicit clock")
    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("GODOT_ATMOSPHERE_CONTRACT_PASS checks=", checks)
        quit(0)
    else:
        for issue in failures:
            push_error("GODOT_ATMOSPHERE_CONTRACT_FAIL: " + issue)
        quit(1)
