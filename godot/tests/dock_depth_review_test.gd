extends SceneTree
## Opt-in scene-depth review contract. No map authoring or visual acceptance.

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var back: Node2D = world.get_node_or_null("DockDepthBackgroundReviewOnly")
    var front: Node2D = world.get_node_or_null("DockDepthForegroundReviewOnly")
    if back == null or front == null or back.visible or front.visible:
        push_error("DOCK_DEPTH_FAIL: isolated scenery layers must start hidden")
        quit(1)
        return
    var ender = world.ender
    var ionia = world.ionia
    var before_bounds: Rect2 = ender.walking_bounds
    var before_ionia_bounds: Rect2 = ionia.walking_bounds
    var old_ender: Vector2 = ender.global_position
    var old_ionia: Vector2 = ionia.global_position
    world.set_dock_depth_review_enabled(true)
    await process_frame
    if not world.is_dock_depth_review_enabled() or not back.visible or not front.visible:
        push_error("DOCK_DEPTH_FAIL: scene enhancement is not opt-in")
        quit(2)
        return
    if ender.walking_bounds != before_bounds or ionia.walking_bounds != before_ionia_bounds:
        push_error("DOCK_DEPTH_FAIL: presentation changed walkable geometry")
        quit(3)
        return
    if ender.global_position != old_ender or ionia.global_position != old_ionia:
        push_error("DOCK_DEPTH_FAIL: review toggle moved characters")
        quit(4)
        return
    if front.z_index <= back.z_index:
        push_error("DOCK_DEPTH_FAIL: over/under depth order reversed")
        quit(5)
        return
    # Real movement stays available in the new scene without an invisible wall.
    ender.set_walk_review_enabled(true)
    Input.action_press("ui_right")
    var start: Vector2 = ender.global_position
    for i in range(17):
        await physics_frame
    Input.action_release("ui_right")
    if ender.global_position.x <= start.x + 1.0 or not ender.walk_review_sprite.visible:
        push_error("DOCK_DEPTH_FAIL: scene layer blocked live character movement")
        quit(6)
        return
    ionia.set_ionia_walk_review_enabled(true)
    for i in range(12):
        await physics_frame
    if ionia.global_position.y <= 419.0:
        push_error("DOCK_DEPTH_FAIL: scene depth disabled genuine Ionia walk")
        quit(7)
        return
    ionia.set_ionia_walk_review_enabled(false)
    world.set_dock_depth_review_enabled(false)
    await process_frame
    if world.is_dock_depth_review_enabled() or back.visible or front.visible:
        push_error("DOCK_DEPTH_FAIL: reference scene cannot be restored")
        quit(8)
        return
    if ender.walking_bounds != before_bounds:
        push_error("DOCK_DEPTH_FAIL: scene changed collision state after opt out")
        quit(9)
        return
    print("DOCK_DEPTH_PASS: reversible 2.5D staging, real Ender and Ionia movement, unchanged collision and geography")
    quit(0)
