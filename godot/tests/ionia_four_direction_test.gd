extends SceneTree
## Four authored direction studies, real bounded native displacement, and fail-closed opt-in.
## Engineering verification only: no automatic character/field-pack acceptance.

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var ionia = world.ionia
    var directions := ["south", "west", "north", "east"]
    var sprites := {}
    for pair in [
        ["south", "IoniaFrontWalkReviewUnapproved"],
        ["north", "IoniaRearWalkReviewUnapproved"],
        ["east", "IoniaEastWalkReviewUnapproved"],
        ["west", "IoniaWestWalkReviewUnapproved"]
    ]:
        var sprite = ionia.get_node_or_null(pair[1]) as Sprite2D
        if sprite == null or sprite.texture == null:
            push_error("IONIA_ROUTE_FAIL: direction import missing: " + pair[0])
            quit(1)
            return
        if sprite.visible or sprite.hframes != 6:
            push_error("IONIA_ROUTE_FAIL: direction not default-hidden or wrong frame count")
            quit(2)
            return
        if sprite.texture.get_width() != 3072 or sprite.texture.get_height() != 768:
            push_error("IONIA_ROUTE_FAIL: imported full-resolution 6x512 source dimensions incorrect")
            quit(3)
            return
        sprites[pair[0]] = sprite
        if pair[0] != "south":
            # Pixel-bake check: distinct frame indices alone are not evidence of
            # six different drawn poses. Godot must import six differing images.
            var atlas_pixels: Image = sprite.texture.get_image()
            if atlas_pixels.is_empty():
                push_error("IONIA_ROUTE_FAIL: SVG did not bake into pixels for " + pair[0])
                quit(19)
                return
            var frame_pixels := []
            for frame_idx in range(6):
                var bounds := Rect2i(frame_idx * 512, 0, 512, 768)
                frame_pixels.append(atlas_pixels.get_region(bounds).get_data())
            for left_idx in range(6):
                for right_idx in range(left_idx + 1, 6):
                    if frame_pixels[left_idx] == frame_pixels[right_idx]:
                        push_error("IONIA_ROUTE_FAIL: visually duplicate atlas frames in " + pair[0])
                        quit(20)
                        return
    var paths := {}
    for name in directions:
        var path: String = sprites[name].texture.resource_path
        if paths.has(path):
            push_error("IONIA_ROUTE_FAIL: different directions share the same source atlas")
            quit(4)
            return
        paths[path] = true
    # V4 is a reversible upper-body/coat mass study; face and leg pixels must
    # remain unchanged relative to independently authored V3. No sprite admission.
    for facing in ["east", "west"]:
        var source_text: String = FileAccess.get_file_as_string("res://art-review/ionia-%s-sidebody-v4-candidate.svg" % facing)
        if source_text.is_empty() or source_text.count('id="' + facing + '-v4-pose-') != 6 or source_text.count('id="' + facing + '-v4-profile-torso-') != 6 or source_text.count('id="' + facing + '-v4-side-profile-nose-') != 6 or source_text.count('id="' + facing + '-v4-front-leg-') != 6:
            push_error("IONIA_ROUTE_FAIL: V4 six-phase art identity missing")
            quit(21)
            return
        var baseline_texture: Texture2D = load("res://art-review/ionia-%s-sidebody-v3-candidate.svg" % facing)
        var current_texture: Texture2D = sprites[facing].texture
        if baseline_texture == null or current_texture == null:
            push_error("IONIA_ROUTE_FAIL: missing V3/V4 side view")
            quit(22)
            return
        var baseline_image: Image = baseline_texture.get_image()
        var current_image: Image = current_texture.get_image()
        if baseline_image.is_empty() or current_image.is_empty():
            push_error("IONIA_ROUTE_FAIL: unreadable V3/V4 texture")
            quit(23)
            return
        if baseline_image.get_width() != 3072 or current_image.get_width() != 3072 or baseline_image.get_height() != 768 or current_image.get_height() != 768:
            push_error("IONIA_ROUTE_FAIL: V4 sheet geometry drift")
            quit(24)
            return
        # All six phases retain identical facial anatomy/hair and leg/foot pixels.
        if baseline_image.get_region(Rect2i(0, 110, 3072, 190)).get_data() != current_image.get_region(Rect2i(0, 110, 3072, 190)).get_data():
            push_error("IONIA_ROUTE_FAIL: V4 changes head proportions")
            quit(25)
            return
        if baseline_image.get_region(Rect2i(0, 618, 3072, 150)).get_data() != current_image.get_region(Rect2i(0, 618, 3072, 150)).get_data():
            push_error("IONIA_ROUTE_FAIL: V4 changes leg/foot contact art")
            quit(26)
            return
        var base_left := 512
        var base_right := -1
        var new_left := 512
        var new_right := -1
        for x in range(128, 392):
            if baseline_image.get_pixel(x, 460).a > 0.2:
                base_left = mini(base_left, x)
                base_right = maxi(base_right, x)
            if current_image.get_pixel(x, 460).a > 0.2:
                new_left = mini(new_left, x)
                new_right = maxi(new_right, x)
        var base_span: int = base_right - base_left
        var new_span: int = new_right - new_left
        if base_span <= 0 or new_left < 155 or new_right > 370 or new_span < base_span + 15 or new_span > base_span + 48:
            push_error("IONIA_ROUTE_FAIL: V4 side garment width is unchanged, off-cell, or excessive")
            quit(27)
            return
        print("IONIA_V4_PROFILE_WAIST:%s:V3=%d:V4=%d" % [facing, base_span, new_span])
    var start: Vector2 = ionia.global_position
    var old_bounds: Rect2 = ionia.walking_bounds
    ionia.set_ionia_route_review_enabled(true)
    if not ionia.is_ionia_route_review_enabled() or not ionia.is_review_art_enabled():
        push_error("IONIA_ROUTE_FAIL: opt-in route not enabled")
        quit(5)
        return
    if ionia.review_sprite.visible or ionia.aligned_sprite.visible:
        push_error("IONIA_ROUTE_FAIL: old static source still visible")
        quit(6)
        return
    var seen := {}
    var phase_coverage := {}
    for i in range(415):
        await physics_frame
        if ionia.global_position.x < old_bounds.position.x or ionia.global_position.x > old_bounds.end.x or ionia.global_position.y < old_bounds.position.y or ionia.global_position.y > old_bounds.end.y:
            push_error("IONIA_ROUTE_FAIL: crossed bounded native dock geometry")
            quit(7)
            return
        if ionia.ionia_route_segment < 4:
            var facing: String = ionia.ionia_facing
            if not sprites.has(facing):
                push_error("IONIA_ROUTE_FAIL: nonexistent authored direction")
                quit(8)
                return
            for name in directions:
                if sprites[name].visible != (name == facing):
                    push_error("IONIA_ROUTE_FAIL: more than one direction visible or wrong facing")
                    quit(9)
                    return
            seen[facing] = true
            if not phase_coverage.has(facing):
                phase_coverage[facing] = {}
            phase_coverage[facing][sprites[facing].frame] = true
    if seen.size() != 4:
        push_error("IONIA_ROUTE_FAIL: not all four authored views traversed")
        quit(10)
        return
    for name in directions:
        if not phase_coverage.has(name) or phase_coverage[name].size() < 6:
            push_error("IONIA_ROUTE_FAIL: six contact phases not exercised in " + name)
            quit(11)
            return
    if ionia.ionia_route_segment != 4 or ionia.global_position.distance_to(Vector2(570, 419)) > 0.5:
        push_error("IONIA_ROUTE_FAIL: did not return to the start of the closed pilot-only route")
        quit(12)
        return
    if sprites[ionia.ionia_facing].frame != 0:
        push_error("IONIA_ROUTE_FAIL: frame does not reset at rest")
        quit(13)
        return
    if ionia.walking_bounds != old_bounds:
        push_error("IONIA_ROUTE_FAIL: character walkable geometry mutated")
        quit(14)
        return
    ionia.set_ionia_route_review_enabled(false)
    if ionia.is_ionia_route_review_enabled() or ionia.is_review_art_enabled():
        push_error("IONIA_ROUTE_FAIL: review art not fully disabled")
        quit(15)
        return
    for name in directions:
        if sprites[name].visible:
            push_error("IONIA_ROUTE_FAIL: view remained visible after opt-out")
            quit(16)
            return
    ionia.set_ionia_walk_review_enabled(true)
    if not sprites["south"].visible or sprites["west"].visible or sprites["north"].visible or sprites["east"].visible:
        push_error("IONIA_ROUTE_FAIL: original front-only T review regressed")
        quit(17)
        return
    ionia.set_aligned_review_enabled(true)
    if not ionia.aligned_sprite.visible or ionia.is_ionia_walk_review_enabled():
        push_error("IONIA_ROUTE_FAIL: original C source comparison regressed")
        quit(18)
        return
    print("IONIA_ROUTE_PASS: four distinct authored directions, six actual phases each, bounded real displacement, legacy review isolation")
    quit(0)
