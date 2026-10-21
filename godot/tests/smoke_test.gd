extends SceneTree
## Runs under actual Godot headless CLI. No release, user state, or gameplay claims.

func _initialize() -> void:
    call_deferred("_verify_scenes")

func _verify_scenes() -> void:
    var world_scene: PackedScene = load("res://scenes/first_wake.tscn")
    var arena_scene: PackedScene = load("res://scenes/training_arena.tscn")
    if world_scene == null or arena_scene == null:
        push_error("GODOT_PILOT_FAIL: scene resources did not load")
        quit(1)
        return
    var world := world_scene.instantiate()
    root.add_child(world)
    await process_frame
    var ender := world.get_node_or_null("YSortedActors/EnderPilot")
    var ionia := world.get_node_or_null("YSortedActors/IoniaPilot")
    if ender == null or ionia == null:
        push_error("GODOT_PILOT_FAIL: character actors missing")
        quit(2)
        return
    if not Rect2(Vector2(145, 410), Vector2(670, 112)).has_point((ender as Node2D).position) or not Rect2(Vector2(145, 410), Vector2(670, 112)).has_point((ionia as Node2D).position):
        push_error("GODOT_PILOT_FAIL: actors are not grounded on test dock")
        quit(3)
        return
    # Native-engine SVG import and preview visibility must be exercised,
    # rather than merely checking the art path in a source-text assertion.
    var art_sprite := ionia.get_node_or_null("IoniaArtReviewUnapproved") as Sprite2D
    if art_sprite == null or art_sprite.texture == null:
        push_error("GODOT_PILOT_FAIL: Ionia SVG did not import into the native texture review")
        quit(6)
        return
    if art_sprite.visible:
        push_error("GODOT_PILOT_FAIL: unapproved art shown without review opt-in")
        quit(7)
        return
    ionia.call("set_review_art_enabled", true)
    await process_frame
    if not art_sprite.visible or not ionia.call("is_review_art_enabled"):
        push_error("GODOT_PILOT_FAIL: opt-in art review cannot be enabled")
        quit(8)
        return
    ionia.call("set_review_art_enabled", false)
    await process_frame
    if art_sprite.visible or ionia.call("is_review_art_enabled"):
        push_error("GODOT_PILOT_FAIL: art review cannot be disabled")
        quit(9)
        return
    world.queue_free()
    await process_frame
    var arena := arena_scene.instantiate()
    root.add_child(arena)
    await process_frame
    if arena.get("hero_hp") != 100 or arena.get("dummy_hp") != 35:
        push_error("GODOT_PILOT_FAIL: turn-based arena initial state")
        quit(4)
        return
    arena.call("_enemy_turn", 0)
    if arena.get("hero_hp") != 90:
        push_error("GODOT_PILOT_FAIL: deterministic training turn")
        quit(5)
        return
    print("GODOT_PILOT_PASS: native dock, two actors, opt-in Ionia SVG import/review, separate mock arena")
    quit(0)
