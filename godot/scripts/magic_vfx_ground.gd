extends Node2D
## Cinematic floor-contact illumination and reactive motifs, local to the VFX node.
## Draw-only: neither modifies terrain nor sets Wet/Burn/Break or any encounter state.

const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const SEGMENTS = 48

var character_id: String = "ender"
var progress: float = 0.29
var reduced_motion: bool = true

func set_visual(next_id: String, next_progress: float, use_reduced_motion: bool) -> bool:
    if not Catalog.has_character(next_id) or is_nan(next_progress) or is_inf(next_progress):
        return false
    character_id = next_id
    progress = clampf(next_progress, 0.0, 1.0)
    reduced_motion = use_reduced_motion
    queue_redraw()
    return true

func _tint(c: Color, alpha: float) -> Color:
    return Color(c.r, c.g, c.b, clampf(alpha, 0.0, 0.65))

func _ellipse(center: Vector2, radius_x: float, radius_y: float) -> PackedVector2Array:
    var points := PackedVector2Array()
    for i in range(SEGMENTS + 1):
        var a := TAU * float(i) / float(SEGMENTS)
        points.append(center + Vector2(cos(a) * radius_x, sin(a) * radius_y))
    return points

func _draw() -> void:
    var profile: Dictionary = Catalog.profile(character_id)
    if profile.is_empty():
        return
    var core := Color(str(profile["color"]))
    var accent := Color(str(profile["accent"]))
    var power := 0.32 + 0.56 * sin(progress * PI)
    var wide := 1.0 + (0.13 * progress if not reduced_motion else 0.0)
    draw_colored_polygon(_ellipse(Vector2.ZERO, 144.0 * wide, 28.0 * wide), _tint(core, 0.11 * power))
    draw_polyline(_ellipse(Vector2.ZERO, 140.0 * wide, 27.0 * wide), _tint(accent, 0.43 * power), 1.8, true)
    match character_id:
        "ender":
            for i in range(5):
                var a := TAU * float(i) / 5.0
                var point := Vector2(cos(a) * 113.0, sin(a) * 23.0)
                draw_line(Vector2.ZERO, point, _tint(core, power * 0.38), 1.1, true)
                draw_circle(point, 3.4, _tint(accent, power * 0.78))
        "lyra":
            for i in range(3):
                var spread := 69.0 + float(i) * 25.0 + progress * 6.0
                draw_polyline(_ellipse(Vector2.ZERO, spread, spread * 0.21), _tint(accent if i == 2 else core, power * (0.51 - i * 0.08)), 1.7, true)
            for i in range(7):
                var a := float(i) * 2.39996
                var droplet := Vector2(cos(a) * (57.0 + 14 * (i % 3)), sin(a) * (13.0 + 5 * (i % 2)))
                draw_circle(droplet, 1.6, _tint(accent if i % 3 == 0 else core, power * 0.67))
        "ionia":
            for i in range(7):
                var x := float(i - 3) * 35.0
                var from := Vector2(x - 17.0, 14.0)
                var to := Vector2(x + 12.0, -12.0 - float(i % 3) * 6.0)
                draw_line(from, to, _tint(core, 0.62 * power), 2.0, true)
                draw_line(to, to + Vector2(17.0, 7.0), _tint(accent, 0.37 * power), 1.1, true)
        "reson":
            for i in range(4):
                var x := float(i - 2) * 56.0
                draw_line(Vector2(x - 31.0, 8.0), Vector2(x + 12.0, -7.0), _tint(accent, 0.55 * power), 2.2, true)
                draw_line(Vector2(x + 12.0, -7.0), Vector2(x + 31.0, -1.0), _tint(core, 0.52 * power), 2.1, true)
            draw_polyline(_ellipse(Vector2.ZERO, 94.0 * wide, 19.0), _tint(core, power * 0.50), 3.0, true)
        "aepex":
            for i in range(6):
                var y := float(i - 3) * 8.0
                var dx := float(i) * 9.0
                draw_line(Vector2(-117.0 + dx, y), Vector2(101.0 + dx * 0.33, y - 12.0), _tint(core if i % 2 == 0 else accent, power * 0.37), 1.4, true)
            draw_arc(Vector2.ZERO, 81.0, -PI * 0.52, PI * 0.44, 48, _tint(accent, power * 0.61), 2.0, true)
