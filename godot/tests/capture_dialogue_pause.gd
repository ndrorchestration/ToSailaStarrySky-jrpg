extends SceneTree
## Synthetic interaction fixture in the real native renderer, not player acceptance.

func _initialize() -> void:
    call_deferred("_capture")

func _key(world: Node, code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    world._unhandled_key_input(event)

func _save(name: String) -> bool:
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    return image.get_size() == Vector2i(960, 640) and image.save_png("res://review-evidence/" + name) == OK

func _capture() -> void:
    root.size = Vector2i(960, 640)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://review-evidence/"))
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    for key in [KEY_R, KEY_G, KEY_Y]:
        _key(world, key)
    for tick in range(5):
        await physics_frame
    world.ender.position = world.ionia.position + Vector2(-70, 0)
    _key(world, KEY_E)
    var ender_start: Vector2 = world.ender.position
    var ionia_start: Vector2 = world.ionia.position
    Input.action_press("ui_left")
    for tick in range(12):
        await physics_frame
    Input.action_release("ui_left")
    if world.ender.position != ender_start or world.ionia.position != ionia_start:
        quit(2)
        return
    if not await _save("dialogue-paused-native.png"):
        quit(3)
        return
    _key(world, KEY_ESCAPE)
    Input.action_press("ui_left")
    for tick in range(20):
        await physics_frame
    Input.action_release("ui_left")
    if not await _save("dialogue-resumed-native.png"):
        quit(4)
        return
    print("DIALOGUE_CAPTURE_PASS: stationary conversation and resumed native movement")
    quit(0)
