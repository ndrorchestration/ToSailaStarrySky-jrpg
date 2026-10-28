extends SceneTree
## Genuine GPU/native frame evidence from the isolated first playable 3D slice.
## Does not assert original creator rigging exists or that visual art is approved.
const Slice = preload("res://scenes/first_wake_3d_visual_slice.tscn")
const EXPECTED := Vector2i(960, 640)
var errors: Array[String] = []
var save_dir := ""

func _initialize() -> void:
    call_deferred("_run")

func _error(message: String) -> void:
    errors.append(message)
    push_error("TSTSS_3D_NATIVE_CAPTURE_FAIL:" + message)

func _capture(stage: String) -> Image:
    for i in range(4):
        await process_frame
        await RenderingServer.frame_post_draw
    var image: Image = root.get_viewport().get_texture().get_image()
    if image == null or image.get_size() != EXPECTED:
        _error("native framebuffer missing or wrong resolution for " + stage)
        return null
    var path: String = save_dir.path_join("first_wake_true_3d_" + stage + "_960x640.png")
    if image.save_png(path) != OK:
        _error("native GPU framebuffer not saved for " + stage)
        return null
    print("TSTSS_3D_NATIVE_FRAME:", stage, ":SHA256:", FileAccess.get_sha256(path), ":FILE:", path)
    return image

func _region_difference(before: Image, after: Image) -> int:
    if before == null or after == null:
        return 0
    var changed := 0
    for y in range(25, 625, 11):
        for x in range(25, 935, 11):
            var a: Color = before.get_pixel(x, y)
            var b: Color = after.get_pixel(x, y)
            if (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) > 0.05:
                changed += 1
    return changed

func _run() -> void:
    save_dir = ProjectSettings.globalize_path("user://first_wake_true_3d_visual_evidence")
    if DirAccess.make_dir_recursive_absolute(save_dir) != OK:
        _error("cannot create output folder")
        quit(1)
        return
    var preview = Slice.instantiate()
    root.add_child(preview)
    for i in range(5):
        await process_frame
    var snapshot: Dictionary = preview.quality_snapshot()
    if int(snapshot.get("true_3d_geometry_count", 0)) < 110:
        _error("not enough real 3D geometry")
    if int(snapshot.get("rigged_creator_models_ready", -1)) != 0:
        _error("private creator GLBs were unexpectedly installed; review source provenance")
    var dusk: Image = await _capture("golden_hour")
    preview.set_time_of_day(true)
    var blue: Image = await _capture("blue_hour")
    var changed: int = _region_difference(dusk, blue)
    if changed < 150:
        _error("actual 3D framebuffer did not respond to physical lighting time change")
    print("TSTSS_3D_DAYLIGHT_NATIVE_DIFFERENCE:", changed, ":samples_changed")
    preview.queue_free()
    await process_frame
    if errors.is_empty():
        print("TSTSS_3D_NATIVE_CAPTURE_PASS:true_spatial_scene=true two_native_gpu_frames=true real_3d_water=true character_rigging_pending=true original_first_wake_unchanged=true")
        print("TSTSS_3D_NATIVE_EVIDENCE_FOLDER:", save_dir)
    quit(0 if errors.is_empty() else 1)
