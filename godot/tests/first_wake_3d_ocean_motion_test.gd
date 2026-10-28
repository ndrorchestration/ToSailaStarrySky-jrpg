extends SceneTree
## Native Godot 4.7.2 reduced-motion contract on the actual 3D sea material.
const Sea = preload("res://scripts/first_wake_maritime_atmosphere_review.gd")
var problems: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene = Sea.new()
    root.add_child(scene)
    await process_frame
    var before: Dictionary = scene.visual_review_snapshot()
    if not before.get("directional_sun_active", false):
        problems.append("3D maritime sun with deck shadows missing")
    if not before.get("ocean_mesh_present", false):
        problems.append("native 3D water mesh missing")
    if before.get("motion_scale", -1.0) != 1.0:
        problems.append("default original wave motion missing")
    scene.set_reduced_motion(true)
    var paused: Dictionary = scene.visual_review_snapshot()
    if not paused.get("reduced_motion", false) or paused.get("motion_scale", -1.0) != 0.0:
        problems.append("reduced motion did not freeze shader time")
    if paused.get("source_sea_level") != before.get("source_sea_level"):
        problems.append("motion setting modified sea geometry origin")
    scene.set_reduced_motion(false)
    var resumed: Dictionary = scene.visual_review_snapshot()
    if resumed.get("motion_scale", -1.0) != 1.0 or resumed.get("reduced_motion", true):
        problems.append("wave animation did not resume")
    if resumed.get("has_buoyancy_authority", true) or resumed.get("canonical_geography", true):
        problems.append("presentation changed protected authority flags")
    scene.set_twilight_review(true)
    var dusk: Dictionary = scene.visual_review_snapshot()
    if not dusk.get("twilight_review", false) or dusk.get("water_twilight_blend", -1.0) != 1.0:
        problems.append("twilight must grade actual water material alongside sky")
    if scene.sunlight.light_color != Color("#ffc29a"):
        problems.append("sunlight must match twilight ocean grade")
    scene.set_twilight_review(false)
    var daylight: Dictionary = scene.visual_review_snapshot()
    if daylight.get("twilight_review", true) or daylight.get("water_twilight_blend", -1.0) != 0.0:
        problems.append("daylight must restore original water grade")
    if daylight.get("source_sea_level") != before.get("source_sea_level"):
        problems.append("lighting grade cannot move sea physics geometry")
    scene.queue_free()
    await process_frame
    if problems.is_empty():
        print("TSTSS_3D_OCEAN_MOTION_PASS reversible=true physics_unchanged=true")
        quit(0)
    else:
        for issue in problems:
            push_error("TSTSS_3D_OCEAN_MOTION_FAIL: " + issue)
        quit(1)
