extends SceneTree
## Genuine Godot resource/direction/actual-displacement contract. Art acceptance excluded.

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var ender = world.ender
    var side = ender.get_node_or_null("EnderWalkReviewUnapproved") as Sprite2D
    var south = ender.get_node_or_null("EnderFrontWalkReviewUnapproved") as Sprite2D
    var north = ender.get_node_or_null("EnderBackWalkReviewUnapproved") as Sprite2D
    if side == null or south == null or north == null:
        push_error("DIRECTIONAL_FAIL: missing independently authored Ender views")
        quit(1)
        return
    if south.texture == null or north.texture == null or south.texture.resource_path == north.texture.resource_path:
        push_error("DIRECTIONAL_FAIL: authored front/back source identity missing")
        quit(2)
        return
    for sprite in [side, south, north]:
        if sprite.visible or sprite.hframes != 6 or sprite.texture.get_width() != 384 or sprite.texture.get_height() != 96:
            push_error("DIRECTIONAL_FAIL: direction atlas import or default visibility")
            quit(3)
            return
    ender.set_walk_review_enabled(true)
    ender.position = Vector2(350, 518)
    Input.action_press("ui_up")
    var north_seen := {}
    for i in range(52):
        await physics_frame
        north_seen[north.frame] = true
        if not north.visible or south.visible or side.visible or ender.walk_facing != "north":
            push_error("DIRECTIONAL_FAIL: facing north selection")
            Input.action_release("ui_up")
            quit(4)
            return
    Input.action_release("ui_up")
    if north_seen.size() != 6:
        push_error("DIRECTIONAL_FAIL: north strip does not advance through six contact phases")
        quit(5)
        return
    await physics_frame
    if north.frame != 0 or not north.visible:
        push_error("DIRECTIONAL_FAIL: north idle reset")
        quit(6)
        return
    Input.action_press("ui_down")
    var south_seen := {}
    for i in range(52):
        await physics_frame
        south_seen[south.frame] = true
        if not south.visible or north.visible or side.visible or ender.walk_facing != "south":
            push_error("DIRECTIONAL_FAIL: facing south selection")
            Input.action_release("ui_down")
            quit(7)
            return
    Input.action_release("ui_down")
    if south_seen.size() != 6:
        push_error("DIRECTIONAL_FAIL: south strip does not advance through six contact phases")
        quit(8)
        return
    await physics_frame
    if south.frame != 0 or not south.visible:
        push_error("DIRECTIONAL_FAIL: south idle reset")
        quit(9)
        return
    # Bounded NPC movement must be driven by real displacement, not a simulated clock.
    var ionia = world.ionia
    var animated = ionia.get_node_or_null("IoniaFrontWalkReviewUnapproved") as Sprite2D
    if animated == null or animated.texture == null or animated.visible or animated.hframes != 6:
        push_error("DIRECTIONAL_FAIL: hidden-by-default Ionia six-pose source")
        quit(10)
        return
    ionia.set_aligned_review_enabled(true)
    ionia.set_ionia_walk_review_enabled(true)
    if ionia.aligned_sprite.visible or ionia.review_sprite.visible or not animated.visible:
        push_error("DIRECTIONAL_FAIL: animated source did not isolate originals")
        quit(11)
        return
    var initial_y: float = ionia.global_position.y
    var ionia_seen := {}
    for i in range(135):
        await physics_frame
        ionia_seen[animated.frame] = true
    if ionia.global_position.y <= initial_y + 80.0 or ionia.global_position.y > 510.001:
        push_error("DIRECTIONAL_FAIL: Ionia bounded genuine forward displacement")
        quit(12)
        return
    if ionia_seen.size() != 6:
        push_error("DIRECTIONAL_FAIL: six distinct Ionia contact-phase indices not exercised")
        quit(13)
        return
    await physics_frame
    await physics_frame
    if animated.frame != 0:
        push_error("DIRECTIONAL_FAIL: stop must reset Ionia to rest phase")
        quit(14)
        return
    ionia.set_ionia_walk_review_enabled(false)
    if animated.visible or ionia.is_review_art_enabled():
        push_error("DIRECTIONAL_FAIL: Ionia candidate cannot be hidden")
        quit(15)
        return
    ender.set_walk_review_enabled(false)
    if side.visible or north.visible or south.visible:
        push_error("DIRECTIONAL_FAIL: Ender opt-out left an unapproved sprite visible")
        quit(16)
        return
    print("DIRECTIONAL_PASS: Ender original side + distinct front/back, Ionia six contact phases; all distance-driven, opt-in, bounded")
    quit(0)
