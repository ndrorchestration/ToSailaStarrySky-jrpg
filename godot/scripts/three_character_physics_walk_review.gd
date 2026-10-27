extends Node2D
## Isolated native physics walk laboratory. Never loaded by the First Wake main scene.
const ReviewActor = preload("res://scripts/character_field_walk_review_actor.gd")
const NAMES: Array[String] = ["Lyra", "Aepex", "Reson"]
const X_ANCHORS: Array[float] = [285.0, 505.0, 725.0]
const LABELS := ["WATER / PINK SPIRIT ACCENT", "AIR / DIAGNOSTICS", "FIRE / WEAPON MASTER"]
var actors: Dictionary = {}

func _ready() -> void:
    name = "ThreeProtagonistPhysicsWalkReviewOnly"
    var group := Node2D.new()
    group.name = "NativePhysicsWalkActors"
    group.y_sort_enabled = true
    add_child(group)
    for index in range(NAMES.size()):
        var actor: CharacterBody2D = ReviewActor.new()
        actor.name = NAMES[index] + "WalkReviewUnapproved"
        actor.set("character_id", NAMES[index])
        actor.position = Vector2(X_ANCHORS[index], 300.0)
        group.add_child(actor)
        actors[NAMES[index]] = actor
    queue_redraw()

func start_all() -> void:
    for character_id in NAMES:
        (actors[character_id] as Node).call("start_route_review")

func stop_all() -> void:
    for character_id in NAMES:
        (actors[character_id] as Node).call("stop_route_review")

func get_actor(character_id: String) -> CharacterBody2D:
    return actors.get(character_id) as CharacterBody2D

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode == KEY_SPACE:
        start_all()
    elif event.keycode == KEY_ESCAPE:
        stop_all()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(960, 640)), Color("#0c1e2b"))
    draw_rect(Rect2(0.0, 0.0, 960.0, 125.0), Color("#13384a"))
    draw_string(ThemeDB.fallback_font, Vector2(30.0, 45.0), "NATIVE PHYSICS CHARACTER WALK / REVIEW ONLY", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#f3e4cb"))
    draw_string(ThemeDB.fallback_font, Vector2(32.0, 79.0), "Original four-facing candidate atlases. Space: closed path. Esc: stop.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c8dad8"))
    for i in range(NAMES.size()):
        var x: float = X_ANCHORS[i]
        draw_rect(Rect2(x - 123.0, 146.0, 210.0, 344.0), Color("#183342"))
        draw_rect(Rect2(x - 123.0, 146.0, 210.0, 3.0), Color("#a5bbab"))
        draw_string(ThemeDB.fallback_font, Vector2(x - 116.0, 180.0), NAMES[i].to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 197, 22, Color("#f6ead9"))
        draw_string(ThemeDB.fallback_font, Vector2(x - 116.0, 206.0), LABELS[i], HORIZONTAL_ALIGNMENT_CENTER, 197, 11, Color("#b7cbcd"))
        draw_line(Vector2(x - 110.0, 305.0), Vector2(x + 55.0, 305.0), Color("#426577"), 1.0)
        draw_rect(Rect2(x - 111.0, 309.0, 159.0, 116.0), Color("#254457"))
        draw_line(Vector2(x - 110.0, 425.0), Vector2(x + 55.0, 425.0), Color("#a8b8ac"), 2.0)
    draw_rect(Rect2(0.0, 513.0, 960.0, 127.0), Color("#122e3b"))
    draw_string(ThemeDB.fallback_font, Vector2(32.0, 546.0), "Every actor moves using CharacterBody2D.move_and_slide() and actual displacement.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#e8ddce"))
    draw_string(ThemeDB.fallback_font, Vector2(32.0, 575.0), "Six-phase source frame advances by distance, not by a simulated time-only sequence.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b8ced1"))
    draw_string(ThemeDB.fallback_font, Vector2(32.0, 604.0), "Not proof of planted feet, approved likeness, playable party recruitment or combat magic.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b8ced1"))
