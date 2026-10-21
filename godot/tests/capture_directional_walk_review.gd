extends SceneTree
## Actual native 960x640 diagnostic images, no marketing illustration or acceptance claim.

const OUT := "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var im := root.get_texture().get_image()
    if im.is_empty() or im.get_width() != 960 or im.get_height() != 640:
        push_error("DIRECTION_CAPTURE_FAIL: not a genuine 960x640 renderer surface")
        return null
    if im.save_png(OUT + name) != OK:
        push_error("DIRECTION_CAPTURE_FAIL: could not save " + name)
        return null
    return im

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var ender = world.ender
    ender.set_walk_review_enabled(true)
    var full_path := ProjectSettings.globalize_path(OUT)
    if DirAccess.make_dir_recursive_absolute(full_path) != OK:
        push_error("DIRECTION_CAPTURE_FAIL: cannot prepare private evidence directory")
        quit(1)
        return
    Input.action_press("ui_down")
    for i in range(22):
        await physics_frame
    Input.action_release("ui_down")
    var south := await _snapshot("ender-south-actual-native-960x640.png")
    if south == null:
        quit(2)
        return
    ender.position = Vector2(350, 510)
    Input.action_press("ui_up")
    for i in range(22):
        await physics_frame
    Input.action_release("ui_up")
    var north := await _snapshot("ender-north-actual-native-960x640.png")
    if north == null:
        quit(3)
        return
    if south.get_region(Rect2i(290, 330, 120, 200)).get_data() == north.get_region(Rect2i(290, 330, 120, 200)).get_data():
        push_error("DIRECTION_CAPTURE_FAIL: authored front/back in-scene pixels identical")
        quit(4)
        return
    var ionia = world.ionia
    ionia.set_ionia_walk_review_enabled(true)
    for i in range(58):
        await physics_frame
    var moving := await _snapshot("ionia-sixphase-moving-native-960x640.png")
    if moving == null:
        quit(5)
        return
    for i in range(70):
        await physics_frame
    var stop := await _snapshot("ionia-sixphase-stopped-native-960x640.png")
    if stop == null:
        quit(6)
        return
    if moving.get_region(Rect2i(510, 300, 140, 245)).get_data() == stop.get_region(Rect2i(510, 300, 140, 245)).get_data():
        push_error("DIRECTION_CAPTURE_FAIL: moving and stopped Ionia pixels identical")
        quit(7)
        return
    print("DIRECTION_CAPTURE_PASS: four genuine Godot 960x640 review states, distinct Ender front/back and moving/stopped Ionia")
    print("DIRECTION_CAPTURE_ART_ACCEPTANCE=PENDING")
    quit(0)
