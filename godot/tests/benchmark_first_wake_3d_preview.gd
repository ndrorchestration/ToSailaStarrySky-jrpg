extends SceneTree
## Renderer-specific PREVIEW cadence sample, not a production benchmark.
## Captures observed frame intervals for this exact standalone 3D scene.
const Slice = preload("res://scenes/first_wake_3d_visual_slice.tscn")
const WARMUP_FRAMES := 24
const SAMPLE_FRAMES := 90

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene = Slice.instantiate()
    root.add_child(scene)
    for frame in range(WARMUP_FRAMES):
        await process_frame
        await RenderingServer.frame_post_draw
    var start_usec: int = Time.get_ticks_usec()
    for frame in range(SAMPLE_FRAMES):
        await process_frame
        await RenderingServer.frame_post_draw
    var elapsed_usec: int = Time.get_ticks_usec() - start_usec
    if elapsed_usec <= 0:
        push_error("TSTSS_3D_CADENCE_FAIL:Invalid performance timer")
        quit(1)
        return
    var mean_ms: float = float(elapsed_usec) / 1000.0 / float(SAMPLE_FRAMES)
    var observed_fps: float = float(SAMPLE_FRAMES) * 1000000.0 / float(elapsed_usec)
    var snap: Dictionary = scene.quality_snapshot()
    print("TSTSS_3D_CADENCE_PASS:sampled_frames=", SAMPLE_FRAMES,
        ":elapsed_ms=", snappedf(float(elapsed_usec) / 1000.0, 0.01),
        ":mean_frame_ms=", snappedf(mean_ms, 0.01),
        ":observed_fps=", snappedf(observed_fps, 0.1),
        ":geometry_count=", snap.get("true_3d_geometry_count"),
        ":rigged_hero_assets=", snap.get("rigged_creator_models_ready"),
        ":nonproduction_scene=true",
        ":vsync_or_driver_dependence=true")
    scene.queue_free()
    await process_frame
    quit(0)
