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
    var west = ender.get_node_or_null("EnderWestWalkReviewUnapproved") as Sprite2D
    var south = ender.get_node_or_null("EnderFrontWalkReviewUnapproved") as Sprite2D
    var north = ender.get_node_or_null("EnderBackWalkReviewUnapproved") as Sprite2D
    if side == null or west == null or south == null or north == null:
        push_error("DIRECTIONAL_FAIL: missing independently authored Ender views")
        quit(1)
        return
    if south.texture == null or north.texture == null or south.texture.resource_path == north.texture.resource_path:
        push_error("DIRECTIONAL_FAIL: authored front/back source identity missing")
        quit(2)
        return
    for sprite in [side, west, south, north]:
        if sprite.visible or sprite.hframes != 6 or sprite.texture.get_width() != 384 or sprite.texture.get_height() != 96:
            push_error("DIRECTIONAL_FAIL: direction atlas import or default visibility")
            quit(3)
            return
    if west.texture.resource_path == side.texture.resource_path:
        push_error("DIRECTIONAL_FAIL: west must have independent authored source")
        quit(17)
        return
    var west_pixels: Image = west.texture.get_image()
    if west_pixels.is_empty():
        push_error("DIRECTIONAL_FAIL: west SVG did not rasterize in Godot")
        quit(18)
        return
    var rendered_frames := []
    for phase in range(6):
        var frame_pixels: PackedByteArray = west_pixels.get_region(Rect2i(phase * 64, 0, 64, 96)).get_data()
        for previous in rendered_frames:
            if previous == frame_pixels:
                push_error("DIRECTIONAL_FAIL: west atlas has duplicate imported artwork phases")
                quit(19)
                return
        rendered_frames.append(frame_pixels)
    var west_source := FileAccess.get_file_as_string("res://art-review/ender-west-ferruled-sixframe-candidate.svg")
    # The original source paints an outline AND a shaft per pose on x31.
    # Six unique staff groups and two identical anchored strokes per group.
    if west_source.count("id=\"staff-source-") != 6 or west_source.count("M31 8 L31 88") != 12:
        push_error("DIRECTIONAL_FAIL: back-carry staff alignment source is inconsistent")
        quit(20)
        return
    ender.set_walk_review_enabled(true)
    ender.position = Vector2(350, 518)
    Input.action_press("ui_up")
    await physics_frame
    await physics_frame
    var north_seen := {}
    for i in range(52):
        await physics_frame
        north_seen[north.frame] = true
        if not north.visible or south.visible or side.visible or west.visible or ender.walk_facing != "north":
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
    await physics_frame
    await physics_frame
    var south_seen := {}
    for i in range(52):
        await physics_frame
        south_seen[south.frame] = true
        if not south.visible or north.visible or side.visible or west.visible or ender.walk_facing != "south":
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
    # The left-facing source must animate independently, never flipping right art.
    ender.position = Vector2(350, 462)
    Input.action_press("ui_left")
    await physics_frame
    await physics_frame
    var west_seen := {}
    for i in range(52):
        await physics_frame
        west_seen[west.frame] = true
        if not west.visible or side.visible or south.visible or north.visible or west.flip_h or side.flip_h or ender.walk_facing != "west":
            push_error("DIRECTIONAL_FAIL: west independently authored sprite was not selected")
            Input.action_release("ui_left")
            quit(21)
            return
    Input.action_release("ui_left")
    if west_seen.size() != 6:
        push_error("DIRECTIONAL_FAIL: west six contact phases were not exercised")
        quit(22)
        return
    await physics_frame
    await physics_frame
    if west.frame != 0:
        push_error("DIRECTIONAL_FAIL: west feet animate when idle")
        quit(23)
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
    if side.visible or west.visible or north.visible or south.visible:
        push_error("DIRECTIONAL_FAIL: Ender opt-out left an unapproved sprite visible")
        quit(16)
        return
    print("DIRECTIONAL_PASS: Ender original east + unmirrored six-phase west + front/back, Ionia native movement; bounded")
    quit(0)
