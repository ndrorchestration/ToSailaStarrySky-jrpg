extends SceneTree
## Four authored direction studies, real bounded native displacement, and fail-closed opt-in.
## Engineering verification only: no automatic character/field-pack acceptance.

func _initialize() -> void:
    call_deferred("_test")

func _alpha_row_span(img: Image, y: int) -> int:
    var low := 512
    var high := -1
    for x in range(65, 445):
        if img.get_pixel(x, y).a > 0.2:
            low = mini(low, x)
            high = maxi(high, x)
    return maxi(0, high - low)

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
    # This is a full side-body v3, not a cosmetic late-layer face patch.
    # The six phases must be pixel-unique and visibly narrower through the waist
    # than the prior opt-in V2's essentially rear-facing body silhouette.
    for facing in ["east", "west"]:
        var profile_source: String = FileAccess.get_file_as_string("res://art-review/ionia-%s-sidebody-v4-candidate.svg" % facing)
        if profile_source.is_empty() or profile_source.count('id="' + facing + '-v4-pose-') != 6 or profile_source.count('id="' + facing + '-v4-profile-torso-') != 6 or profile_source.count('id="' + facing + '-v4-side-profile-nose-') != 6 or profile_source.count('id="' + facing + '-v4-front-leg-') != 6:
            push_error("IONIA_ROUTE_FAIL: 6 independently constructed V4 side-body phases absent: " + facing)
            quit(21)
            return
        if profile_source.count('id="' + facing + '-v4-back-silhouette-') != 6 or profile_source.count('id="' + facing + '-v4-hair-coat-detail-') != 6:
            push_error("IONIA_ROUTE_FAIL: V4 secondary silhouette/motion layers missing: " + facing)
            quit(28)
            return
        var old_texture: Texture2D
        if facing == "east":
            old_texture = load("res://art-review/ionia-east-profile-v2-candidate.svg")
        else:
            old_texture = load("res://art-review/ionia-west-profile-v2-candidate.svg")
        if old_texture == null:
            push_error("IONIA_ROUTE_FAIL: original V2 reference missing")
            quit(22)
            return
        var old_image: Image = old_texture.get_image()
        var candidate_image: Image = sprites[facing].texture.get_image()
        # Compare actual Godot-imported pixels to the UNMODIFIED v3 source.
        # Broader curls/head and coat hems must change the character silhouette
        # visibly at native field source scale, not just add hidden SVG layers.
        var prior_source: Texture2D = load("res://art-review/ionia-%s-sidebody-v3-candidate.svg" % facing)
        if prior_source == null:
            push_error("IONIA_ROUTE_FAIL: V3 source rollback reference unavailable")
            quit(29)
            return
        var previous_pixels: Image = prior_source.get_image()
        if previous_pixels.is_empty():
            push_error("IONIA_ROUTE_FAIL: V3 rollback source fails Godot import")
            quit(30)
            return
        var curls_before := _alpha_row_span(previous_pixels, 250)
        var curls_now := _alpha_row_span(candidate_image, 250)
        var hem_before := _alpha_row_span(previous_pixels, 580)
        var hem_now := _alpha_row_span(candidate_image, 580)
        print("IONIA_V4_SILHOUETTE:" + facing + ":HEAD=" + str(curls_before) + ">" + str(curls_now) + ":HEM=" + str(hem_before) + ">" + str(hem_now))
        if curls_now < curls_before + 20 or hem_now < hem_before + 20:
            push_error("IONIA_ROUTE_FAIL: V4 must materially improve head AND coat silhouette from V3")
            quit(31)
            return
        if old_image.is_empty() or candidate_image.is_empty():
            push_error("IONIA_ROUTE_FAIL: cannot rasterize side-body comparison")
            quit(23)
            return
        var old_left := 512
        var old_right := -1
        var new_left := 512
        var new_right := -1
        # A controlled source-space waist span. Game-scale leg/coat variation
        # still needs actual Godot fixed-anchor native human review.
        for x in range(128, 392):
            if old_image.get_pixel(x, 460).a > 0.2:
                old_left = mini(old_left, x)
                old_right = maxi(old_right, x)
            if candidate_image.get_pixel(x, 460).a > 0.2:
                new_left = mini(new_left, x)
                new_right = maxi(new_right, x)
        # Every sprite cell must be centered around its native local x=256.
        # Guards against art authored at x≈25 spilling into adjacent frame cells.
        if new_left < 170 or new_right > 355 or new_left > 280 or new_right < 235:
            push_error("IONIA_ROUTE_FAIL: V3 side-body art is off center / frame-leaking")
            quit(27)
            return
        print("IONIA_V3_WAIST_SPAN:%s:OLD=%d:NEW=%d:LEFT=%d:RIGHT=%d" % [facing, old_right-old_left, new_right-new_left, new_left, new_right])
        if old_right < old_left or new_right < new_left or (old_right - old_left) - (new_right - new_left) < 25:
            push_error("IONIA_ROUTE_FAIL: V3 body side silhouette insufficiently narrower than rear-derived V2")
            quit(24)
            return
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
