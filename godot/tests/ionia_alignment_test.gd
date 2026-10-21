extends SceneTree
## Review isolation and import contract. No artistic or canonical acceptance.

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var world = load("res://scenes/first_wake.tscn").instantiate()
    root.add_child(world)
    await process_frame
    var ionia = world.ionia
    var original = ionia.get_node_or_null("IoniaArtReviewUnapproved") as Sprite2D
    var aligned = ionia.get_node_or_null("IoniaAlignmentReviewUnapproved") as Sprite2D
    if original == null or aligned == null or original.texture == null or aligned.texture == null:
        push_error("IONIA_ALIGN_FAIL: both native SVG textures must import")
        quit(1)
        return
    if original.texture.resource_path == aligned.texture.resource_path:
        push_error("IONIA_ALIGN_FAIL: reference and derivative are not distinct sources")
        quit(2)
        return
    if original.visible or aligned.visible:
        push_error("IONIA_ALIGN_FAIL: unapproved art was not hidden by default")
        quit(3)
        return
    ionia.set_review_art_enabled(true)
    if not original.visible or aligned.visible or not ionia.is_review_art_enabled():
        push_error("IONIA_ALIGN_FAIL: original comparison state")
        quit(4)
        return
    ionia.set_aligned_review_enabled(true)
    if original.visible or not aligned.visible or not ionia.is_aligned_review_enabled():
        push_error("IONIA_ALIGN_FAIL: opt-in alignment must exclude old source")
        quit(5)
        return
    ionia.set_review_art_enabled(true)
    if not original.visible or aligned.visible:
        push_error("IONIA_ALIGN_FAIL: reverse comparison state")
        quit(6)
        return
    ionia.set_review_art_enabled(false)
    if original.visible or aligned.visible or ionia.is_review_art_enabled():
        push_error("IONIA_ALIGN_FAIL: comparison cannot be disabled")
        quit(7)
        return
    var ender = world.ender
    ender.set_walk_review_enabled(true)
    ionia.set_aligned_review_enabled(true)
    if not ender.walk_review_sprite.visible or not aligned.visible:
        push_error("IONIA_ALIGN_FAIL: same-scene Ender plus Ionia preview")
        quit(8)
        return
    print("IONIA_ALIGN_PASS: two imported original SVGs, exclusive opt-in, same-scene native actors")
    quit(0)
