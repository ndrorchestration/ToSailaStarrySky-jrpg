extends SceneTree
## Purely visual night+storm value separation, OFF by default.
## Does not affect calendar, moon alignment, ship physics or plot state.
const Study = preload("res://main.tscn")
var issues: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool, why: String) -> void:
    checks += 1
    if not condition:
        issues.append(why)

func _run() -> void:
    var scene = Study.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var v = scene.visuals
    var env: Environment = (v.get_node("Atmosphere") as WorldEnvironment).environment
    var position: Vector3 = scene.ship.position
    var clock: float = scene._clock
    check(is_zero_approx(v.storm_depth_study_strength), "review OFF by default")
    v.set_storm_depth_study_strength(1.0)
    check(is_equal_approx(v.get_node("GoldenHourKey").light_energy,1.15),
        "default daylight sunlight must be byte-value unchanged")
    check(is_equal_approx(env.fog_density,0.0035),
        "daytime fog unaffected by optional storm contrast")
    v.set_environment_look(3,3,true)
    var base: Dictionary = v.current_mood.duplicate(true)
    v.set_storm_depth_study_strength(0.0)
    check(is_equal_approx(v.get_node("GoldenHourKey").light_energy,
        float(base["key_energy"])), "0 restores exact prior storm key")
    check(is_equal_approx(env.ambient_light_energy,
        float(base["ambient_energy"])), "0 restores exact prior storm ambient")
    check(is_equal_approx(env.fog_density,
        float(base["fog_density"])), "0 restores exact prior storm fog")
    v.set_storm_depth_study_strength(1.0)
    check(v.current_mood == base,"readability study never rewrites mood sampler")
    check(is_equal_approx(v.get_node("GoldenHourKey").light_energy,
        float(base["key_energy"])*1.32), "1 improves storm directional detail")
    check(is_equal_approx(env.ambient_light_energy,
        float(base["ambient_energy"])*0.86), "1 softens flattening ambient")
    check(is_equal_approx(env.fog_density,
        float(base["fog_density"])*0.74), "1 reduces storm flattening fog")
    v.set_storm_depth_study_strength(0.5)
    check(v.get_node("GoldenHourKey").light_energy >
        float(base["key_energy"]), "intermediate key increases smoothly")
    check(env.fog_density < float(base["fog_density"]) and
        env.fog_density > float(base["fog_density"])*0.74,
        "intermediate fog stays between bounded endpoints")
    v.set_storm_depth_study_strength(NAN)
    check(is_zero_approx(v.storm_depth_study_strength),
        "invalid strength fails closed to baseline")
    v.set_storm_depth_study_strength(1.0)
    v.queue_environment_look(0,0,false,1.8)
    v.advance_environment_transition(0.9,false)
    var intermediate: float = v.get_node("GoldenHourKey").light_energy
    check(v.transition_active, "halfway atmosphere blend still active")
    check(is_finite(intermediate) and intermediate > 0.0,
        "blended light remains finite and positive")
    v.advance_environment_transition(0.9,false)
    check(not v.transition_active, "blend reaches destination")
    check(is_equal_approx(v.get_node("GoldenHourKey").light_energy,1.15),
        "golden grade returns to exact original light with review ON")
    check(scene.ship.position == position and scene._clock == clock,
        "visual relief may not move player ship or simulation clock")
    scene.queue_free()
    await process_frame
    if issues.is_empty():
        print("GODOT_STORM_DEPTH_REVIEW_PASS checks=",checks)
        quit(0)
    else:
        for issue in issues:
            push_error("GODOT_STORM_DEPTH_REVIEW_FAIL: "+issue)
        quit(1)
