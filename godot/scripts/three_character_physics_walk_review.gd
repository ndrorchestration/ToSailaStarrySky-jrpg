extends Node2D
## Isolated native physics walk laboratory. Never loaded by the First Wake main scene.
const ReviewActor = preload("res://scripts/character_field_walk_review_actor.gd")
const FootPixelOverlay = preload("res://scripts/character_foot_pixel_overlay.gd")
const StanceCandidateOverlay = preload("res://scripts/character_stance_candidate_overlay.gd")
const NAMES: Array[String] = ["Lyra", "Aepex", "Reson"]
const X_ANCHORS: Array[float] = [285.0, 505.0, 725.0]
const LABELS := ["WATER / PINK SPIRIT ACCENT", "AIR / DIAGNOSTICS", "FIRE / WEAPON MASTER"]
var actors: Dictionary = {}
var guides: Dictionary = {}
var source_guides_enabled := false
var stance_guides: Dictionary = {}
var stance_guides_enabled := false

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
        actor.position = Vector2(X_ANCHORS[index] + 35.0, 340.0)
        group.add_child(actor)
        actors[NAMES[index]] = actor
        var guide: Node2D = FootPixelOverlay.new()
        guide.name = NAMES[index] + "SourcePixelGuideOnly"
        guide.set("target", actor)
        actor.add_child(guide)
        guide.call("set_guides_enabled", false)
        guides[NAMES[index]] = guide
        var stance_guide: Node2D = StanceCandidateOverlay.new()
        stance_guide.name = NAMES[index] + "StanceHypothesisOnly"
        stance_guide.set("target", actor)
        actor.add_child(stance_guide)
        stance_guide.call("set_guides_enabled", false)
        stance_guides[NAMES[index]] = stance_guide
    queue_redraw()

func start_all() -> void:
    for character_id in NAMES:
        (actors[character_id] as Node).call("start_route_review")

func stop_all() -> void:
    for character_id in NAMES:
        (actors[character_id] as Node).call("stop_route_review")

func set_source_guides_enabled(enabled: bool) -> void:
    source_guides_enabled = enabled
    for character_id in NAMES:
        (guides[character_id] as Node).call("set_guides_enabled", enabled)
    queue_redraw()

func set_stance_guides_enabled(enabled: bool) -> void:
    stance_guides_enabled = enabled
    for character_id in NAMES:
        (stance_guides[character_id] as Node).call("set_guides_enabled", enabled)
    queue_redraw()

func get_actor(character_id: String) -> CharacterBody2D:
    return actors.get(character_id) as CharacterBody2D

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode == KEY_SPACE:
        start_all()
    elif event.keycode == KEY_P:
        set_source_guides_enabled(not source_guides_enabled)
    elif event.keycode == KEY_K:
        set_stance_guides_enabled(not stance_guides_enabled)
    elif event.keycode == KEY_ESCAPE:
        stop_all()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(960, 640)), Color("#0c1e2b"))
    draw_rect(Rect2(0.0, 0.0, 960.0, 125.0), Color("#13384a"))
    draw_string(ThemeDB.fallback_font, Vector2(30.0, 45.0), "NATIVE PHYSICS CHARACTER WALK / REVIEW ONLY", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#f3e4cb"))
    draw_string(ThemeDB.fallback_font, Vector2(32.0, 79.0), "Original four-facing candidate atlases. Space: route. P: alpha guides. K: stance hypotheses. Esc: stop.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c8dad8"))
    for i in range(NAMES.size()):
        var x: float = X_ANCHORS[i]
        draw_rect(Rect2(x - 123.0, 146.0, 210.0, 344.0), Color("#183342"))
        draw_rect(Rect2(x - 123.0, 146.0, 210.0, 3.0), Color("#a5bbab"))
        draw_string(ThemeDB.fallback_font, Vector2(x - 116.0, 180.0), NAMES[i].to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 197, 22, Color("#f6ead9"))
        draw_string(ThemeDB.fallback_font, Vector2(x - 116.0, 206.0), LABELS[i], HORIZONTAL_ALIGNMENT_CENTER, 197, 11, Color("#b7cbcd"))
        draw_line(Vector2(x - 110.0, 329.0), Vector2(x + 55.0, 329.0), Color("#426577"), 1.0)
        draw_rect(Rect2(x - 111.0, 330.0, 159.0, 136.0), Color("#254457"))
        draw_line(Vector2(x - 110.0, 466.0), Vector2(x + 55.0, 466.0), Color("#a8b8ac"), 2.0)
    draw_rect(Rect2(0.0, 513.0, 960.0, 127.0), Color("#122e3b"))
    draw_string(ThemeDB.fallback_font, Vector2(32.0, 546.0), "Every actor moves using CharacterBody2D.move_and_slide() and actual displacement.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#e8ddce"))
    draw_string(ThemeDB.fallback_font, Vector2(32.0, 575.0), "Boot baseline normalized to imported alpha footprint; phase advances by distance.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b8ced1"))
    draw_string(ThemeDB.fallback_font, Vector2(32.0, 604.0), "Orange stance markers are screen-half guesses, NOT certified planted-foot mechanics.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b8ced1"))
