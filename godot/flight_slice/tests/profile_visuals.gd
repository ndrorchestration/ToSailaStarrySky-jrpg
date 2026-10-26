extends SceneTree
## Wall-clock intervals between completed frame callbacks. Software host only.
const CUTS: Array = [["coast",9.0],["forest",23.0],["highland",34.0]]
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var baseline: bool = OS.get_cmdline_user_args().has("--baseline")
    var low: bool = OS.get_cmdline_user_args().has("--low")
    if scene.visuals != null: scene.visuals.set_low_quality(low)
    var label_text: String = "baseline" if baseline else ("low" if low else "high")
    var observations: Array = []
    for cut in CUTS:
        scene._clock = cut[1]
        scene._update_scene(10.0)
        for warmup in range(20):
            await process_frame
            await RenderingServer.frame_post_draw
        var samples: Array[float] = []
        var previous: int = Time.get_ticks_usec()
        for n in range(120):
            scene._clock = float(cut[1]) + float(n) / 30.0
            # Animate effects only: camera and terrain remain matched for profiling.
            if scene.visuals != null: scene.visuals.set_clock(scene._clock, false)
            await process_frame
            await RenderingServer.frame_post_draw
            var now: int = Time.get_ticks_usec()
            samples.append(float(now-previous)/1000.0)
            previous = now
        samples.sort()
        observations.append({"view":cut[0],"median_ms":samples[59],"p95_ms":samples[113],"worst_ms":samples[119],"samples_ms":samples,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
    var folder: String = ProjectSettings.globalize_path("res://evidence")
    DirAccess.make_dir_recursive_absolute(folder)
    var path: String = folder.path_join("profile-"+label_text+".json")
    var file := FileAccess.open(path,FileAccess.WRITE)
    if file == null:
        push_error("PROFILE_WRITE_FAILED")
        quit(1)
        return
    file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"resolution":[960,640],"mode":label_text,"warmup":20,"samples_per_view":120,"method":"wall intervals between frame_post_draw callbacks; not GPU timestamps or target FPS","observations":observations},"  "))
    file.close()
    print("PROFILE_SAVED:",path)
    scene.queue_free()
    await process_frame
    quit(0)
