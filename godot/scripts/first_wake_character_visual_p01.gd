extends Node
## P-01A: opt-in, visual-only prototype adapter in the REAL First Wake dock scene.
## No party, save, dialogue, inventory, recruitment, class or magic authority.
const ReviewActor = preload("res://scripts/character_field_walk_review_actor.gd")
const REVIEW_CHARACTER_ID := "Lyra"
const REVIEW_ORIGIN := Vector2(730.0, 414.0)
const DECK_BOUNDS := Rect2(Vector2(145.0, 410.0), Vector2(670.0, 112.0))
var _actor: CharacterBody2D
var _enabled := false

func set_review_enabled(enabled: bool, visual_parent: Node2D) -> void:
    if enabled == _enabled:
        return
    if enabled:
        if visual_parent == null or visual_parent.name != "YSortedActors":
            push_error("CHARACTER_P01_FAIL: missing real First Wake y-sort parent")
            return
        var actor: CharacterBody2D = ReviewActor.new()
        actor.name = "P01UnrecruitedLyraVisualFixture"
        actor.set("character_id", REVIEW_CHARACTER_ID)
        actor.position = REVIEW_ORIGIN
        visual_parent.add_child(actor)
        if actor.get("source_sprites").size() != 4:
            actor.queue_free()
            push_error("CHARACTER_P01_FAIL: no original four-way imported source art")
            return
        _actor = actor
        _enabled = true
        actor.call("start_route_review")
    else:
        if _actor != null and is_instance_valid(_actor):
            _actor.call("stop_route_review")
            if _actor.get_parent() != null:
                _actor.get_parent().remove_child(_actor)
            _actor.queue_free()
        _actor = null
        _enabled = false

func is_review_enabled() -> bool:
    return _enabled and _actor != null and is_instance_valid(_actor)

func get_review_actor() -> CharacterBody2D:
    return _actor if is_review_enabled() else null

func route_is_inside_deck() -> bool:
    for offset in ReviewActor.ROUTE_OFFSETS:
        if not DECK_BOUNDS.has_point(REVIEW_ORIGIN + offset):
            return false
    return true

func _exit_tree() -> void:
    if _actor != null and is_instance_valid(_actor):
        _actor.call("stop_route_review")
        if _actor.get_parent() != null:
            _actor.get_parent().remove_child(_actor)
        _actor.queue_free()
    _actor = null
    _enabled = false
