extends Node2D
## Opt-in only. Orange tether measures a screen-side alpha candidate, NOT a true stance foot.
const Stance = preload("res://scripts/character_stance_hypothesis.gd")
var target: CharacterBody2D
var guides_enabled := false
var _last_key := ""
var _anchor := Vector2.ZERO
var _candidate := Vector2.ZERO
var _side := ""
var _has_marker := false
var _slip := 0.0

func set_guides_enabled(enabled: bool) -> void:
    guides_enabled = enabled
    visible = enabled
    if not enabled:
        _last_key = ""
        _has_marker = false
        _slip = 0.0
    queue_redraw()

func _physics_process(_delta: float) -> void:
    if not guides_enabled or target == null:
        return
    if not bool(target.get("review_enabled")) or bool(target.get("completed")):
        _last_key = ""
        _has_marker = false
        queue_redraw()
        return
    var facing: String = target.get("facing")
    var phase: int = target.get("current_phase")
    var spec: Dictionary = Stance.annotation(String(target.get("character_id")), facing, phase)
    var screen_side: String = String(spec.get("candidate_screen_side", Stance.UNKNOWN))
    if screen_side == Stance.UNKNOWN:
        _last_key = ""
        _has_marker = false
        queue_redraw()
        return
    var observed: Dictionary = Stance.world_support(target, facing, phase, screen_side)
    if not observed.get("valid", false):
        _has_marker = false
        queue_redraw()
        return
    _candidate = observed["world_pixel"]
    var key: String = facing + ":" + screen_side
    if _last_key != key:
        _last_key = key
        _anchor = _candidate
    _side = screen_side
    _slip = _candidate.distance_to(_anchor)
    _has_marker = true
    queue_redraw()

func get_candidate_displacement() -> float:
    return _slip if _has_marker else 0.0

func _draw() -> void:
    if not guides_enabled or not _has_marker:
        return
    var anchor_local := to_local(_anchor)
    var candidate_local := to_local(_candidate)
    draw_line(anchor_local, candidate_local, Color("#f3a55a"), 2.0)
    draw_circle(anchor_local, 3.0, Color("#f1d0a2"))
    draw_circle(candidate_local, 2.0, Color("#f17c56"))
    draw_string(ThemeDB.fallback_font, Vector2(-49.0, 28.0),
        "HYPOTHESIS " + ("L" if _side == Stance.SCREEN_LEFT else "R") + " %.1f px" % _slip,
        HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#f5c49d"))
