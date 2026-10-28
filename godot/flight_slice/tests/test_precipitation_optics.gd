extends SceneTree
const PrecipitationStudy = preload("res://precipitation_study.gd")
const DuneStudy = preload("res://dune_study.gd")
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var study := PrecipitationStudy.new()
    root.add_child(study)
    await process_frame
    check(study.study_mesh != null,"reuses existing smooth deterministic terrain")
    check(study.ground_material != null,"new independent ground material exists")
    if study.ground_material == null or study.study_mesh == null:
        push_error("PRECIPITATION_STUDY_FAIL missing renderer")
        quit(1)
        return
    check(study.ground_material.shader.resource_path ==
        "res://shaders/precipitation_ground.gdshader",
        "source is original reusable weather ground shader")
    check(study.study_mesh.dune_mesh.mesh != null,
        "uses prior bounded and verifiable smooth terrain geometry")
    check(study.study_mesh.get_child_count() == 1,
        "one ground draw mesh and no individual grains or water particles")
    check(study.study_mesh.dune_mesh.get_child_count() == 0,
        "weather optics do not create particle or collider children")
    check(study.ground_material.get_shader_parameter("prevailing_wind") ==
        PrecipitationStudy.WIND_AXIS,
        "snow ridges follow explicit world-space wind direction")
    check(study.ground_material.get_shader_parameter("sun_direction") ==
        PrecipitationStudy.SUN_DIRECTION,
        "crystal view sheen is linked to shared authored sun")
    var vertices: PackedVector3Array = study.study_mesh.dune_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    var old_vertices: PackedVector3Array = vertices.duplicate()
    for mode in [0,1]:
        study.set_weather_mode(mode)
        check(int(study.ground_material.get_shader_parameter("weather_mode")) == mode,
            "snow and rain have independently selected material mode")
        study.set_optics_strength(0.0)
        check(is_zero_approx(float(study.ground_material.get_shader_parameter(
            "weather_optics_strength"))),"optics off provides exact unlit reference")
        study.set_optics_strength(1.0)
        study.set_low_quality(true)
        check(study.ground_material.get_shader_parameter("low_quality") == true,
            "V fallback bypasses weather optics")
        study.set_low_quality(false)
    study.set_weather_mode(0)
    study.set_clock(31.0,true)
    check(is_zero_approx(float(study.ground_material.get_shader_parameter(
        "study_time"))),"reduced motion freezes material clock")
    study.set_clock(31.0,false)
    check(is_equal_approx(float(study.ground_material.get_shader_parameter(
        "study_time")),31.0),"non-reduced material follows externally controlled clock")
    check(study.study_mesh.dune_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] ==
        old_vertices,"snow/rain uniforms preserve all terrain heights")
    study.queue_free()
    await process_frame
    if failures.is_empty():
        print("PRECIPITATION_OPTICS_CONTRACT_PASS modes=2 geometry=unchanged")
        quit(0)
    else:
        for failure in failures:
            push_error("PRECIPITATION_OPTICS_FAIL: "+failure)
        quit(1)
