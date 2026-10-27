extends SceneTree
## Scripted sweep of the local automatic flight route on the GL renderer.
## Wall intervals include scene update and waiting for frame_post_draw.
## The path is sampled at 0.38 simulated seconds per rendered frame: it is
## not real-time user input, an FPS benchmark or target-device measurement.
const StudyScene = preload("res://main.tscn")
const STEP_COUNT: int = 96
const SIMULATION_STEP: float = 0.38

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene = StudyScene.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.overlay.visible = false
    scene._clock = 0.0
    scene._update_scene(SIMULATION_STEP)
    for warmup in range(10):
        await process_frame
        await RenderingServer.frame_post_draw
    var times: Array[float] = []
    var update_times: Array[float] = []
    var observations: Array[Dictionary] = []
    for i in range(STEP_COUNT):
        var started: int = Time.get_ticks_usec()
        scene._clock = float(i) * SIMULATION_STEP
        scene._update_scene(SIMULATION_STEP)
        var after_update: int = Time.get_ticks_usec()
        await process_frame
        await RenderingServer.frame_post_draw
        var finished: int = Time.get_ticks_usec()
        var update_ms: float = float(after_update - started) / 1000.0
        var interval_ms: float = float(finished - started) / 1000.0
        if not is_finite(interval_ms) or interval_ms < update_ms or update_ms < 0.0:
            push_error("RENDERED_SWEEP_INVALID_TIMING")
            quit(1)
            return
        times.append(interval_ms)
        update_times.append(update_ms)
        observations.append({"step":i,"simulation_time_s":scene._clock,
            "ship_position":[scene.ship.position.x,scene.ship.position.y,scene.ship.position.z],
            "visible_tiles":scene.terrain.visible_tiles,
            "high_detail_tiles":scene.terrain.detailed_tiles,
            "scene_update_ms":update_ms,"rendered_interval_ms":interval_ms})
    if observations.size() != STEP_COUNT or scene.terrain.visible_tiles == 0:
        push_error("RENDERED_SWEEP_NO_SCENE")
        quit(1)
        return
    var ordered: Array[float] = times.duplicate()
    ordered.sort()
    var update_sorted: Array[float] = update_times.duplicate()
    update_sorted.sort()
    var folder: String = ProjectSettings.globalize_path("res://evidence")
    if DirAccess.make_dir_recursive_absolute(folder) != OK:
        push_error("RENDERED_SWEEP_DIRECTORY_FAILED")
        quit(1)
        return
    var file := FileAccess.open(folder.path_join("rendered-flight-sweep.json"), FileAccess.WRITE)
    if file == null:
        push_error("RENDERED_SWEEP_WRITE_FAILED")
        quit(1)
        return
    file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,
        "adapter":RenderingServer.get_video_adapter_name(),
        "renderer":RenderingServer.get_current_rendering_method(),
        "resolution":[960,640],"samples":STEP_COUNT,"simulated_step_s":SIMULATION_STEP,
        "method":"wall interval from manual scene update through frame_post_draw; compressed-time scripted path, software renderer; not GPU timestamps or target FPS",
        "median_ms":ordered[48],"p95_ms":ordered[91],"max_ms":ordered[95],
        "update_median_ms":update_sorted[48],"update_p95_ms":update_sorted[91],
        "update_max_ms":update_sorted[95],"observations":observations}, "  "))
    file.close()
    print("RENDERED_SWEEP_PASS samples=", STEP_COUNT,
        " median_ms=", ordered[48], " p95_ms=", ordered[91], " max_ms=", ordered[95],
        " update_median_ms=", update_sorted[48], " update_p95_ms=", update_sorted[91],
        " update_max_ms=", update_sorted[95])
    scene.queue_free()
    await process_frame
    quit(0)
