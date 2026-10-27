extends Node2D
## Optional optical source-pixel diagnostic overlay; NEVER a collision or footplant.
var target: CharacterBody2D
var guides_enabled: bool = false

func _process(_delta: float) -> void:
    if guides_enabled:
        queue_redraw()

func set_guides_enabled(enabled: bool) -> void:
    guides_enabled = enabled
    visible = enabled
    queue_redraw()

func _draw() -> void:
    if not guides_enabled or target == null:
        return
    var facing: String = target.get("facing")
    var phase: int = target.get("current_phase")
    var sample: Dictionary = target.call("get_source_boot_sample", facing, phase)
    if not sample.get("valid", false):
        return
    var sprites: Dictionary = target.get("source_sprites")
    var sprite: Sprite2D = sprites.get(facing) as Sprite2D
    if sprite == null:
        return
    draw_line(Vector2(-27.0, 0.0), Vector2(27.0, 0.0), Color("#f2e1bf"), 1.0)
    for side in ["left", "right"]:
        var support: Dictionary = sample[side]
        if not support.get("present", false):
            continue
        var marker := Vector2(float(support["x"]) - 40.0, float(support["y"]) - 64.0 + sprite.position.y)
        var tint := Color("#f7d17c") if side == "left" else Color("#9be4ef")
        draw_circle(marker, 2.5, tint)
        draw_arc(marker, 5.0, 0.0, TAU, 12, Color(0.02, 0.1, 0.14, 0.7), 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(-28.0, 22.0),
        "PIXEL y=%d" % int(sample["bottom_y"]), HORIZONTAL_ALIGNMENT_LEFT,
        -1, 11, Color("#e8d6b0"))
