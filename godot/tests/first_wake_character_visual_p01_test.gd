extends SceneTree
## Real First Wake scene + one opt-in UNRECRUITED visual-only character.
## This is P-01A only: painted dock bounds, NOT production deck terrain colliders.
const SOURCE := "res://art-review/lyra-%s-sixphase-v1-unapproved.svg"
const FACINGS: Array[String] = ["south", "west", "north", "east"]

func _initialize() -> void:
    call_deferred("_verify")

func _fail(message: String, code: int) -> void:
    push_error("FIRST_WAKE_CHARACTER_P01_FAIL: " + message)
    quit(code)

func _event(key: int) -> InputEventKey:
    var e := InputEventKey.new()
    e.keycode = key
    e.pressed = true
    return e

func _verify() -> void:
    var scene: PackedScene = load("res://scenes/first_wake.tscn")
    if scene == null:
        _fail("real First Wake scene did not load", 1)
        return
    var stage = scene.instantiate()
    root.add_child(stage)
    await process_frame
    var ender: CharacterBody2D = stage.get("ender")
    var ionia: CharacterBody2D = stage.get("ionia")
    if ender == null or ionia == null:
        _fail("canonical scene actors missing", 2)
        return
    var ender_ref := ender
    var ionia_ref := ionia
    var ender_start: Vector2 = ender.global_position
    var ionia_start: Vector2 = ionia.global_position
    var original_dialogue: String = (stage.get("dialogue") as Label).text
    var actors: Node2D = stage.get_node("YSortedActors")
    if not actors.y_sort_enabled or stage.call("is_character_visual_p01_enabled") or stage.call("get_character_visual_p01_actor") != null:
        _fail("review is not default-off or cannot use real y-sort scene parent", 3)
        return
    if actors.get_node_or_null("P01UnrecruitedLyraVisualFixture") != null:
        _fail("unrecruited prototype actor exists without opt-in", 4)
        return
    if not (stage.get("p01_character_visual") as Node).call("route_is_inside_deck"):
        _fail("review path exceeds existing dock visual bounds", 5)
        return
    # Exercise the real user-accessible F6 path.
    stage.call("_unhandled_key_input", _event(KEY_F6))
    var actor: CharacterBody2D = stage.call("get_character_visual_p01_actor")
    if actor == null or not stage.call("is_character_visual_p01_enabled") or actor.get_parent() != actors:
        _fail("F6 did not bind source actor into real First Wake renderer", 6)
        return
    if actor.get("character_id") != "Lyra" or not actor.get("review_enabled") or actor.collision_layer != 2 or actor.collision_mask != 1:
        _fail("visual-only source or physics layers unexpected", 7)
        return
    var sprites: Dictionary = actor.get("source_sprites")
    if sprites.size() != 4:
        _fail("missing four original directions", 8)
        return
    for facing in FACINGS:
        var sprite: Sprite2D = sprites.get(facing)
        if sprite == null or sprite.texture == null or sprite.texture.resource_path != SOURCE % facing or sprite.flip_h or sprite.hframes != 6:
            _fail("original SVG source custody or directional frame contract changed", 9)
            return
    var seen := {"south": {}, "west": {}, "north": {}, "east": {}}
    var previous: Vector2 = actor.global_position
    var physics_ticks := 0
    for tick in range(326):
        await physics_frame
        if actor.get("completed"):
            break
        physics_ticks += 1
        if actor.global_position.distance_to(previous) > 2.1:
            _fail("visual-only actor teleported instead of physics moving", 10)
            return
        previous = actor.global_position
        if not Rect2(Vector2(145, 410), Vector2(670, 112)).has_point(actor.global_position):
            _fail("visual actor left First Wake dock bounds", 11)
            return
        seen[actor.get("facing")][actor.get("current_phase")] = true
        var visible_count := 0
        for facing in FACINGS:
            var sprite: Sprite2D = sprites[facing]
            if sprite.visible:
                visible_count += 1
                if facing != actor.get("facing") or sprite.frame != actor.get("current_phase"):
                    _fail("wrong source direction/frame during actual dock movement", 12)
                    return
        if visible_count != 1:
            _fail("original directional art not exclusive", 13)
            return
    if not actor.get("completed") or physics_ticks < 255 or absf(actor.get("travel_distance") - 400.0) > 3.0:
        _fail("four-way First Wake physical route did not close", 14)
        return
    for facing in FACINGS:
        if seen[facing].size() < 6:
            _fail("source not exercised through six native phases in " + facing, 15)
            return
    if ender != ender_ref or ionia != ionia_ref or ender.global_position != ender_start or ionia.global_position != ionia_start:
        _fail("review moved/replaced an established Chapter I actor", 16)
        return
    if (stage.get("dialogue") as Label).text != original_dialogue or stage.get("dialogue_open") or stage.get("character_lineup_review_enabled"):
        _fail("review interfered with dialogue or lineup", 17)
        return
    print("FIRST_WAKE_CHARACTER_P01_ROUTE: native First Wake scene; 400.0px; four directions; six phases; unchanged Ender and Ionia")
    stage.call("_unhandled_key_input", _event(KEY_F6))
    await process_frame
    if stage.call("is_character_visual_p01_enabled") or stage.call("get_character_visual_p01_actor") != null or actors.get_node_or_null("P01UnrecruitedLyraVisualFixture") != null:
        _fail("F6 opt-out did not remove the world visual fixture", 18)
        return
    # The same real First Wake scene must physically block a newly inserted
    # temporary StaticBody2D, rather than trusting painted deck pixels.
    var wall := StaticBody2D.new()
    wall.name = "P01TestOnlyDeckBarrier"
    wall.collision_layer = 1
    wall.position = Vector2(730.0, 460.0)
    var shape_node := CollisionShape2D.new()
    var box := RectangleShape2D.new()
    box.size = Vector2(44.0, 10.0)
    shape_node.shape = box
    wall.add_child(shape_node)
    stage.add_child(wall)
    stage.call("set_character_visual_p01_enabled", true)
    actor = stage.call("get_character_visual_p01_actor")
    if actor == null:
        _fail("cannot restart fixture for physical collision test", 19)
        return
    for tick in range(85):
        await physics_frame
    if actor.get("collision_ticks") < 1 or actor.get("segment") != 0 or actor.global_position.y > 450.0:
        _fail("visual fixture passed through real Godot StaticBody2D obstacle", 20)
        return
    var blocked_y: float = actor.global_position.y
    stage.call("set_character_visual_p01_enabled", false)
    wall.queue_free()
    await process_frame
    if stage.call("is_character_visual_p01_enabled") or ender.global_position != ender_start or ionia.global_position != ionia_start:
        _fail("blocked probe did not return First Wake to original actors", 21)
        return
    if (stage.get("p01_character_visual") as Node).get_child_count() != 0:
        _fail("visual bridge leaked a gameplay node", 22)
        return
    print("FIRST_WAKE_CHARACTER_P01_OBSTACLE: contact_ticks>0 stopped_y=%.2f" % blocked_y)
    print("FIRST_WAKE_CHARACTER_P01_PASS: integrated visual fixture real First Wake 2D dock, F6 reversible, no actor/dialogue authority changes")
    print("FIRST_WAKE_CHARACTER_P01_TERRAIN_2_5D=NOT_TESTED")
    print("FIRST_WAKE_CHARACTER_P01_SAVE_PARTY_STATE=NO_SAVE_OR_PARTY_IMPLEMENTATION_IN_THIS_PILOT")
    quit(0)
