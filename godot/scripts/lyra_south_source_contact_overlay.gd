extends Node2D
## Optional exact-SVG-path contact candidate overlay. One character/direction only.
const Contact = preload("res://scripts/lyra_south_source_contact_proposal.gd")
var target: CharacterBody2D
var review_enabled := false
var _anchor := Vector2.ZERO
var _candidate := Vector2.ZERO
var _contact_foot := ""
var _visible_contact := false
var _drift := 0.0

func set_guides_enabled(enabled: bool) -> void:
    review_enabled = enabled
    visible = enabled
    if not enabled:
        _contact_foot = ""
        _visible_contact = false
        _drift = 0.0
    queue_redraw()

func get_candidate_displacement() -> float:
    return _drift if _visible_contact else 0.0

func _physics_process(_delta: float) -> void:
    if not review_enabled or target == null:
        return
    if not bool(target.get("review_enabled")) or bool(target.get("completed")):
        _contact_foot = ""
        _visible_contact = false
        queue_redraw()
        return
    if String(target.get("facing")) != Contact.SOURCE_VIEW:
        _contact_foot = ""
        _visible_contact = false
        queue_redraw()
        return
    var phase: int = int(target.get("current_phase"))
    var foot: String = Contact.REVIEW_STANCE[phase]
    if foot == Contact.SWING:
        _contact_foot = ""
        _visible_contact = false
        queue_redraw()
        return
    var sample: Dictionary = Contact.world_point(target, phase, foot)
    if not sample.get("valid", false):
        _visible_contact = false
        queue_redraw()
        return
    _candidate = sample["world_pixel"]
    if _contact_foot != foot:
        _anchor = _candidate
        _contact_foot = foot
    _drift = _candidate.distance_to(_anchor)
    _visible_contact = true
    queue_redraw()

func _draw() -> void:
    if not review_enabled or not _visible_contact:
        return
    var center: Vector2 = to_local(_candidate)
    var pin: Vector2 = to_local(_anchor)
    draw_line(pin, center, Color("#e591b5"), 2.0)
    draw_circle(pin, 3.0, Color("#f7c9dc"))
    draw_circle(center, 2.0, Color("#f55a9a"))
    draw_string(ThemeDB.fallback_font, Vector2(-60.0, 40.0),
        "LYRA SOURCE SHOE  %.1f px" % _drift, HORIZONTAL_ALIGNMENT_LEFT,
        -1, 10, Color("#f7bed5"))
