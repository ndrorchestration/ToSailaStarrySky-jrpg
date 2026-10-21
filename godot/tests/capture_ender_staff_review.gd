extends SceneTree
## Native renderer A/B: original east raster vs independent west vector.
## Captures are genuine 960x640 Godot images; not creator visual approval.

const OUTPUT := "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(label: String) -> Image:
    await RenderingServer.frame_post_draw
    var im: Image = root.get_texture().get_image()
    if im.is_empty() or im.get_width() != 960 or im.get_height() != 640:
        push_error("STAFF_CAPTURE_FAIL: not a real native 960x640 scene")
        return null
    if im.save_png(OUTPUT + label) != OK:
        push_error("STAFF_CAPTURE_FAIL: cannot store " + label)
        return null
    return im

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var ender = world.ender
    ender.set_walk_review_enabled(true)
    world.set_dock_depth_review_enabled(true)
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("STAFF_CAPTURE_FAIL: output directory unavailable")
        quit(1)
        return
    ender.position = Vector2(350, 462)
    Input.action_press("ui_right")
    for i in range(24):
        await physics_frame
    Input.action_release("ui_right")
    var east_at: Vector2 = ender.global_position
    if ender.walk_facing != "east" or not ender.walk_review_sprite.visible:
        push_error("STAFF_CAPTURE_FAIL: original east sprite not shown")
        quit(2)
        return
    var east := await _snapshot("ender-east-original-source-native-960x640.png")
    if east == null:
        quit(3)
        return
    ender.position = Vector2(470, 462)
    Input.action_press("ui_left")
    for i in range(24):
        await physics_frame
    Input.action_release("ui_left")
    var west_at: Vector2 = ender.global_position
    if ender.walk_facing != "west" or not ender.walk_west_sprite.visible or ender.walk_review_sprite.visible:
        push_error("STAFF_CAPTURE_FAIL: separate west sprite not shown")
        quit(4)
        return
    if ender.walk_west_sprite.flip_h or ender.walk_review_sprite.flip_h:
        push_error("STAFF_CAPTURE_FAIL: animation mirrored despite independent west art")
        quit(5)
        return
    if east_at.distance_to(west_at) > 8.0:
        push_error("STAFF_CAPTURE_FAIL: evidence A/B positions not comparable")
        quit(6)
        return
    var west := await _snapshot("ender-west-centered-staff-native-960x640.png")
    if west == null:
        quit(7)
        return
    var crop := Rect2i(370, 360, 100, 115)
    if east.get_region(crop).get_data() == west.get_region(crop).get_data():
        push_error("STAFF_CAPTURE_FAIL: east and west cropped render pixels indistinguishable")
        quit(8)
        return
    print("STAFF_CAPTURE_PASS: real native 960x640 matched-position east/west sprites differ; west is not flipped")
    print("STAFF_CAPTURE_VISUAL_ACCEPTANCE=PENDING")
    quit(0)
