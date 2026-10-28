extends SceneTree
## Actual native 960x640 Godot snapshots of an existing playable scene.
## Private review. OFF/ON/low/restored evidence is not canonical art.
const OUT := "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_run")

func _image(path: String) -> Image:
    for i in range(3):
        await process_frame
        await RenderingServer.frame_post_draw
    var im: Image = root.get_texture().get_image()
    if im.is_empty() or im.get_size() != Vector2i(960, 640):
        push_error("RIDGE_CAPTURE_INVALID_FRAME")
        return null
    if im.save_png(OUT + path) != OK:
        push_error("RIDGE_CAPTURE_WRITE_FAILED")
        return null
    return im

func _run() -> void:
    root.size = Vector2i(960,640)
    var w = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(w)
    await process_frame
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) != OK:
        push_error("RIDGE_CAPTURE_MISSING_OUTPUT_DIR")
        quit(1)
        return
    w.set_dock_depth_review_enabled(true)
    var root_sample: Dictionary = preload("res://scripts/dock_ridge_surface.gd").sample_root(276.0)
    if not root_sample["ok"] or root_sample["point"].y >= w.ender.walking_bounds.position.y:
        push_error("RIDGE_CAPTURE_INVALID_AUTHORED_SURFACE")
        quit(1)
        return
    w.ender.set_walk_review_enabled(true)
    w.ionia.set_aligned_review_enabled(true)
    var before: Image = await _image("ridge-vegetation-off-native-960x640.png")
    w.set_ridge_vegetation_review_enabled(true)
    var after: Image = await _image("ridge-vegetation-on-native-960x640.png")
    w.set_ridge_vegetation_low_quality(true)
    var low: Image = await _image("ridge-vegetation-low-native-960x640.png")
    w.set_ridge_vegetation_review_enabled(false)
    var restored: Image = await _image("ridge-vegetation-restored-native-960x640.png")
    if before == null or after == null or low == null or restored == null:
        quit(1)
        return
    # A/B must be localized to the atmospheric ridge; actor/deck crop must
    # remain identical with the same scene camera and unchanged player state.
    var ridge := Rect2i(260,214,220,120)
    var gameplay := Rect2i(250,404,440,128)
    if before.get_region(ridge).get_data() == after.get_region(ridge).get_data():
        push_error("RIDGE_CAPTURE_NO_VISIBLE_RENDER_DIFFERENCE")
        quit(1)
        return
    if after.get_region(ridge).get_data() == low.get_region(ridge).get_data():
        push_error("RIDGE_CAPTURE_LOW_DETAIL_NOT_VISUALLY_DISTINCT")
        quit(1)
        return
    if before.get_region(gameplay).get_data() != after.get_region(gameplay).get_data():
        push_error("RIDGE_CAPTURE_ALTERED_PLAYABLE_REGION")
        quit(1)
        return
    if before.get_region(ridge).get_data() != restored.get_region(ridge).get_data():
        push_error("RIDGE_CAPTURE_NOT_REVERSIBLE")
        quit(1)
        return
    print("NATIVE_RIDGE_VEGETATION_PAIR_PASS resolution=960x640 off=on=low=restore=4 gameplay_roi_unchanged=true source_ridge_sampler=true")
    print("NATIVE_RIDGE_VEGETATION_ART_ACCEPTANCE=PENDING")
    w.queue_free()
    await process_frame
    quit(0)
