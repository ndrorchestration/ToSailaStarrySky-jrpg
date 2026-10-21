extends SceneTree
## Genuine renderer before/after review. Never a promotional mockup or accepted scene.
const OUTPUT := "res://review-evidence/"

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(name: String) -> Image:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    if image.is_empty() or image.get_width() != 960 or image.get_height() != 640:
        push_error("DOCK_CAPTURE_FAIL: invalid native render dimensions")
        return null
    if image.save_png(OUTPUT + name) != OK:
        push_error("DOCK_CAPTURE_FAIL: could not save " + name)
        return null
    return image

func _capture() -> void:
    root.size = Vector2i(960, 640)
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("DOCK_CAPTURE_FAIL: evidence output unavailable")
        quit(1)
        return
    world.ender.set_walk_review_enabled(true)
    world.ionia.set_aligned_review_enabled(true)
    var initial_ender: Vector2 = world.ender.global_position
    var initial_ionia: Vector2 = world.ionia.global_position
    var before := await _snapshot("dock-original-native-960x640.png")
    if before == null:
        quit(2)
        return
    world.set_dock_depth_review_enabled(true)
    await process_frame
    var after := await _snapshot("dock-depth-review-native-960x640.png")
    if after == null:
        quit(3)
        return
    if world.ender.global_position != initial_ender or world.ionia.global_position != initial_ionia:
        push_error("DOCK_CAPTURE_FAIL: visual-only switch moved characters")
        quit(4)
        return
    if before.get_region(Rect2i(250, 160, 200, 110)).get_data() == after.get_region(Rect2i(250, 160, 200, 110)).get_data():
        push_error("DOCK_CAPTURE_FAIL: scenery unchanged in horizon ROI")
        quit(5)
        return
    if before.get_region(Rect2i(260, 420, 165, 105)).get_data() == after.get_region(Rect2i(260, 420, 165, 105)).get_data():
        push_error("DOCK_CAPTURE_FAIL: supporting deck unchanged")
        quit(6)
        return
    world.ionia.set_ionia_walk_review_enabled(true)
    Input.action_press("ui_right")
    for i in range(37):
        await physics_frame
    Input.action_release("ui_right")
    var walking := await _snapshot("dock-depth-both-actors-moving-native-960x640.png")
    if walking == null:
        quit(7)
        return
    if world.ender.global_position == initial_ender or world.ionia.global_position.y <= 419.0:
        push_error("DOCK_CAPTURE_FAIL: both actors did not genuinely move")
        quit(8)
        return
    if walking.get_region(Rect2i(250, 340, 440, 190)).get_data() == after.get_region(Rect2i(250, 340, 440, 190)).get_data():
        push_error("DOCK_CAPTURE_FAIL: scene movement made no rendered pixel change")
        quit(9)
        return
    print("DOCK_CAPTURE_PASS: authentic native 960x640 baseline, opt-in depth and both-moving character states")
    print("DOCK_CAPTURE_ACCEPTANCE=PENDING: no external artifact delivery or creator visual signoff")
    quit(0)
