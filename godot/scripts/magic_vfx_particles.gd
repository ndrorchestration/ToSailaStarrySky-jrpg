extends Node2D
## CPU-drawn seeded micro-particles: deterministic, bounded and allocation-free per frame.
## All positions are decorative; no gameplay particles, physics or camera changes.

const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const MAX_PARTICLES = 48
const STATIC_PARTICLES = 14
const QUALITY_CAPS = [12, 30, MAX_PARTICLES]

var character_id: String = "ender"
var progress: float = 0.29
var reduced_motion: bool = true
var quality_level: int = 1

func set_visual(next_id: String, next_progress: float, use_reduced_motion: bool, quality: int = 1) -> bool:
    if not Catalog.has_character(next_id) or is_nan(next_progress) or is_inf(next_progress):
        return false
    character_id = next_id
    progress = clampf(next_progress, 0.0, 1.0)
    reduced_motion = use_reduced_motion
    quality_level = clampi(quality, 0, 2)
    queue_redraw()
    return true

func particle_budget() -> int:
    return mini(STATIC_PARTICLES, QUALITY_CAPS[quality_level]) if reduced_motion else QUALITY_CAPS[quality_level]

func _tint(base: Color, opacity: float) -> Color:
    return Color(base.r, base.g, base.b, clampf(opacity, 0.0, 0.78))

func _draw() -> void:
    var record: Dictionary = Catalog.profile(character_id)
    if record.is_empty():
        return
    var main_color := Color(str(record["color"]))
    var accent := Color(str(record["accent"]))
    var weight := clampf(0.17 + 0.70 * sin(progress * PI), 0.0, 0.84)
    var count := particle_budget()
    for i in range(count):
        var index := float(i)
        var random_a: float = sin(index * 127.1 + 8.27) * 43758.5453
        var random_b: float = sin(index * 58.9 + 2.65) * 22578.1459
        var a: float = TAU * (random_a - floor(random_a))
        var f: float = random_b - floor(random_b)
        var center := Vector2.ZERO
        var radius: float = 58.0 + f * 100.0
        var mot := progress if not reduced_motion else 0.29
        var light := accent if i % 5 == 0 else main_color
        var color := _tint(light, weight * (0.45 + f * 0.50))
        match character_id:
            "ender":
                center = Vector2.from_angle(a + mot * 0.70) * radius
                var to_core := center * (0.78 - mot * 0.35)
                draw_line(center, to_core, _tint(main_color, 0.27 * weight), 0.9, true)
                draw_circle(to_core, 1.3 + float(i % 3) * 0.6, color)
            "lyra":
                center = Vector2(cos(a + mot * 2.4) * radius, sin(a + mot * 2.4) * radius * 0.63)
                draw_line(center - Vector2(7.0, -2.0), center + Vector2(4.0, 2.0), color, 1.3, true)
                draw_circle(center + Vector2(3.0, -2.0), 1.1 + f * 2.0, _tint(accent if i % 3 == 0 else main_color, 0.65 * weight))
            "ionia":
                center = Vector2.from_angle(a) * (57.0 + f * 102.0) + Vector2(0, -mot * (13.0 + 19.0 * f))
                var shard := PackedVector2Array([
                    center + Vector2(0, -4.0 - f * 5.0),
                    center + Vector2(2.0 + f, 0),
                    center + Vector2(0, 3.0 + f * 3.0),
                    center + Vector2(-2.0 - f, 0)
                ])
                draw_colored_polygon(shard, color)
            "reson":
                center = Vector2((f - 0.5) * 250.0 + sin(a * 4.0 + mot * 6.0) * 10.0, 94.0 - mot * (152.0 + 58.0 * f))
                draw_line(center, center + Vector2(-1.0 - f * 2.0, 5.0 + 7.0 * f), color, 1.5, true)
                draw_circle(center, 1.2 + f * 1.8, _tint(accent, 0.76 * weight))
            "aepex":
                center = Vector2.from_angle(a + mot * 2.1) * radius * Vector2(1.0, 0.74)
                var travel := Vector2.from_angle(a + PI * 0.50 + mot * 2.1)
                draw_line(center - travel * (3.0 + f * 8.0), center + travel * (5.0 + f * 9.0), color, 1.2, true)
