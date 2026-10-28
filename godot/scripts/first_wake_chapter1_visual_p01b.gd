extends Node
## P-01B: isolated noncanonical visual fixture on the Chapter I entry-point scene.
## Source art is inherited byte-for-byte from #487 and remains NOT APPROVED.
const ReviewActor = preload("res://scripts/character_field_walk_review_actor.gd")
const VISUAL_ID := "Lyra"
const ORIGIN := Vector2(728.0, 410.0)
const DECK_BOUNDS := Rect2(Vector2(110.0, 404.0), Vector2(740.0, 118.0))
var _fixture: CharacterBody2D = null
var _active := false

func set_review_enabled(enabled: bool, parent: Node2D) -> void:
    if _active == enabled:
        return
    if enabled:
        if parent == null or parent.name != "ChapterOneMigrationActors" or not parent.y_sort_enabled:
            push_error("CH1_CHARACTER_P01B_FAIL: missing actual Chapter I visual actor parent")
            return
        if not route_inside_bounds():
            push_error("CH1_CHARACTER_P01B_FAIL: route outside real Chapter I save-position bounds")
            return
        var actor: CharacterBody2D = ReviewActor.new()
        actor.name = "P01BUnrecruitedLyraVisualOnly"
        actor.set("character_id", VISUAL_ID)
        actor.position = ORIGIN
        parent.add_child(actor)
        var sources: Dictionary = actor.get("source_sprites")
        if sources.size() != 4:
            parent.remove_child(actor)
            actor.queue_free()
            push_error("CH1_CHARACTER_P01B_FAIL: native source atlases unavailable")
            return
        _fixture = actor
        _active = true
        actor.call("start_route_review")
    else:
        _remove_fixture()

func _remove_fixture() -> void:
    if _fixture != null and is_instance_valid(_fixture):
        _fixture.call("stop_route_review")
        if _fixture.get_parent() != null:
            _fixture.get_parent().remove_child(_fixture)
        _fixture.queue_free()
    _fixture = null
    _active = false

func is_review_enabled() -> bool:
    return _active and _fixture != null and is_instance_valid(_fixture)

func get_review_actor() -> CharacterBody2D:
    return _fixture if is_review_enabled() else null

func route_inside_bounds() -> bool:
    for offset in ReviewActor.ROUTE_OFFSETS:
        if not DECK_BOUNDS.has_point(ORIGIN + offset):
            return false
    return true

func _exit_tree() -> void:
    _remove_fixture()
