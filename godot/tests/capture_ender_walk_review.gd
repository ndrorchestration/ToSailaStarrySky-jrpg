extends SceneTree
## Native renderer diagnostic. Does not establish creator acceptance.

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
    world.ender.set_walk_review_enabled(true)
    await process_frame
    await RenderingServer.frame_post_draw
    var after := root.get_texture().get_image()
    if before.get_region(Rect2i(300, 350, 100, 130)).get_data() == after.get_region(Rect2i(300, 350, 100, 130)).get_data():
        push_error("ENDER_CAPTURE_FAIL: preview pixels unchanged")
        quit(2)
        return
    if after.save_png(output + "ender-native-review.png") != OK:
        quit(3)
        return
    Input.action_press("ui_right")
    for i in range(24):
        for tick in range(3):
            await physics_frame
        await RenderingServer.frame_post_draw
        if root.get_texture().get_image().save_png(output + "walk-%02d.png" % i) != OK:
            quit(4)
            return
    Input.action_release("ui_right")
    print("ENDER_CAPTURE_PASS: baseline, opt-in and 24 genuine input-driven frames")
    quit(0)
