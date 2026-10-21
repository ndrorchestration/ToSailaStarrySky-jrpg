extends SceneTree

func _initialize() -> void:
    call_deferred("_test")

func _key(world: Node, code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    world._unhandled_key_input(event)

func _test() -> void:
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    _key(world, KEY_E)
    if world.dialogue.visible:
        quit(1)
        return
    _key(world, KEY_R)
    _key(world, KEY_Y)
    for i in range(5):
        await physics_frame
    world.ender.position = world.ionia.position + Vector2(-70, 0)
    _key(world, KEY_E)
    var ender_start: Vector2 = world.ender.position
    var ionia_start: Vector2 = world.ionia.position
    var route_segment: int = world.ionia.ionia_route_segment
    Input.action_press("ui_left")
    for i in range(12):
        await physics_frame
    Input.action_release("ui_left")
    if not world.dialogue.visible or world.ender.position != ender_start or world.ionia.position != ionia_start:
        push_error("DIALOGUE_PAUSE_FAIL: actors move while dialogue is open")
        quit(2)
        return
    _key(world, KEY_T)
    _key(world, KEY_Y)
    if world.ionia.position != ionia_start or not world.ionia.ionia_route_review_enabled or world.ionia.ionia_route_segment != route_segment:
        push_error("DIALOGUE_PAUSE_FAIL: route hotkey teleports or resets conversation")
        quit(3)
        return
    _key(world, KEY_ESCAPE)
    Input.action_press("ui_left")
    for i in range(6):
        await physics_frame
    Input.action_release("ui_left")
    if world.dialogue.visible or world.ender.position.x >= ender_start.x or world.ionia.position == ionia_start:
        push_error("DIALOGUE_PAUSE_FAIL: close does not resume player and route")
        quit(4)
        return
    world.ender.position = world.ionia.position + Vector2(-70, 0)
    _key(world, KEY_E)
    _key(world, KEY_E)
    if world.dialogue.visible:
        quit(5)
        return
    print("DIALOGUE_PAUSE_PASS: range, both actors pause, route retained, hotkeys guarded, Esc/E resume")
    quit(0)
