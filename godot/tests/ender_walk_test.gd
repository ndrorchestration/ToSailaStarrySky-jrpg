extends SceneTree

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var actor = world.ender
    var sprite = actor.get_node_or_null("EnderWalkReviewUnapproved")
    if sprite == null:
        push_error("ENDER_WALK_FAIL: native six-frame sprite missing")
        quit(1)
        return
    if sprite.visible or sprite.hframes != 6:
        quit(2)
        return
    actor.set_walk_review_enabled(true)
    var start: Vector2 = actor.position
    Input.action_press("ui_right")
    var seen := {}
    for i in range(50):
        await physics_frame
        seen[sprite.frame] = true
    Input.action_release("ui_right")
    if actor.position.x <= start.x or seen.size() != 6 or not sprite.visible:
        push_error("ENDER_WALK_FAIL: movement does not animate")
        quit(3)
        return
    await physics_frame
    await physics_frame
    if sprite.frame != 0:
        push_error("ENDER_WALK_FAIL: idle does not return to rest")
        quit(4)
        return
    actor.position.x = actor.walking_bounds.end.x
    Input.action_press("ui_right")
    for i in range(8):
        await physics_frame
    Input.action_release("ui_right")
    if sprite.frame != 0:
        push_error("ENDER_WALK_FAIL: wall causes foot skating")
        quit(5)
        return
    Input.action_press("ui_left")
    await physics_frame
    await physics_frame
    Input.action_release("ui_left")
    if not sprite.flip_h:
        push_error("ENDER_WALK_FAIL: left movement does not mirror side view")
        quit(7)
        return
    actor.set_walk_review_enabled(false)
    if sprite.visible:
        quit(6)
        return
    print("ENDER_WALK_PASS: opt-in six frames, actual movement, idle, wall stop")
    quit(0)
