extends SceneTree
## Native renderer review only: unapproved assets, no visual acceptance.

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var output := "res://review-evidence/"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    await RenderingServer.frame_post_draw
    var before := root.get_texture().get_image()
    if before.save_png(output + "ender-placeholder.png") != OK:
        quit(1)
        return

    # Both toggles run in the genuine Godot dock scene, not a composited poster.
    world.ender.set_walk_review_enabled(true)
    world.ionia.set_review_art_enabled(true)
    await process_frame
    await RenderingServer.frame_post_draw
    var together := root.get_texture().get_image()
    var ender_bounds := Rect2i(300, 350, 100, 130)
    var ionia_bounds := Rect2i(520, 335, 100, 150)
    if before.get_region(ender_bounds).get_data() == together.get_region(ender_bounds).get_data():
        push_error("PAIR_CAPTURE_FAIL: Ender preview pixels unchanged")
        quit(2)
        return
    if before.get_region(ionia_bounds).get_data() == together.get_region(ionia_bounds).get_data():
        push_error("PAIR_CAPTURE_FAIL: Ionia preview pixels unchanged")
        quit(5)
        return
    if together.save_png(output + "ender-ionia-native-unapproved.png") != OK:
        quit(3)
        return
    # Keep the earlier single-Ender output reproducible for comparison.
    world.ionia.set_review_art_enabled(false)
    await process_frame
    await RenderingServer.frame_post_draw
    if root.get_texture().get_image().save_png(output + "ender-native-review.png") != OK:
        quit(6)
        return
    Input.action_press("ui_right")
    for i in range(24):
        for tick in range(3):
            await physics_frame
        await RenderingServer.frame_post_draw
        if root.get_texture().get_image().save_png(output + "walk-%02d.png" % i) != OK:
            Input.action_release("ui_right")
            quit(4)
            return
    Input.action_release("ui_right")
    print("PAIR_CAPTURE_PASS: authentic baseline, native Ender/Ionia comparison, 24 input-driven Ender frames; unapproved art")
    quit(0)
