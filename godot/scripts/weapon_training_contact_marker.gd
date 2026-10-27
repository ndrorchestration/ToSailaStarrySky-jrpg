extends Node2D
## Distinctive stage-only target reaction. This is a noncanonical practice marker,
## never an authored enemy hit, hitbox, formula result or combat outcome.
var cue: Dictionary = {}

func apply_cue(next_cue: Dictionary) -> bool:
    if next_cue.is_empty() or str(next_cue.get("source","")) != \
        "REVIEW_ONLY_DIRECTIONAL_CINEMATIC" \
        or bool(next_cue.get("hitAuthorized",true)) \
        or bool(next_cue.get("combatCommandIssued",true)):
        return false
    cue = next_cue.duplicate(true)
    queue_redraw()
    return true

func _draw() -> void:
    if cue.is_empty() or bool(cue.get("motionReduced",false)):
        return
    var strength := clampf(float(cue.get("contactStrength",0.0)),0.0,0.55)
    if strength < 0.01:
        return
    var pos := Vector2(170,-73)
    draw_arc(pos,27.0,0.0,TAU,40,Color("#d9e9da",strength),2.0)
    draw_line(pos+Vector2(-16,0),pos+Vector2(16,0),
        Color("#fff0b5",strength),2.0)
    draw_line(pos+Vector2(0,-16),pos+Vector2(0,16),
        Color("#fff0b5",strength),2.0)
    draw_circle(pos,3.0+strength*6.0,Color("#f2e0aa",strength*0.48))
