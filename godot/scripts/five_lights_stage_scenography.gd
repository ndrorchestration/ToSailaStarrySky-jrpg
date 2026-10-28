extends Node2D
## Filmic review set, visual geometry only: no collision, canonical terrain or save effects.
const GOLD = Color("#a78b62")
func _ready() -> void:
    queue_redraw()

func _draw() -> void:
    # Distant settlement and its suggestion of lived-in harbor life.
    for i in range(21):
        var x: float = 5.0 + float(i) * 47.0
        var h: float = 42.0 + float((i * 13) % 42)
        draw_rect(Rect2(x, 285.0 - h, 34.0, h + 18.0), Color("#132737"))
        draw_line(Vector2(x - 4, 285 - h), Vector2(x + 17, 270 - h), Color("#234051"), 2.0)
        draw_line(Vector2(x + 17, 270 - h), Vector2(x + 37, 285 - h), Color("#234051"), 2.0)
        if i % 3 != 0:
            draw_rect(Rect2(x + 12, 284 - h + 17, 4, 7), Color(0.81, 0.52, 0.25, 0.34))
    # Source-neutral wooden pier and genuine-looking but nonphysical depth cues.
    draw_line(Vector2(18, 386), Vector2(942, 386), Color("#514338"), 8.0)
    draw_line(Vector2(18, 382), Vector2(942, 382), GOLD, 2.0)
    for x in [57.0, 238.0, 420.0, 602.0, 784.0, 903.0]:
        draw_rect(Rect2(x - 5, 347, 10, 97), Color("#443930"))
        draw_rect(Rect2(x - 5, 347, 10, 3), GOLD)
    for y in [446.0, 471.0, 502.0, 525.0]:
        draw_line(Vector2(20, y), Vector2(940, y), Color("#9a7955"), 1.0)
        draw_line(Vector2(20, y + 2), Vector2(940, y + 2), Color(0.0, 0.0, 0.0, 0.22), 1.0)
    for x in range(80, 960, 136):
        draw_line(Vector2(x, 429), Vector2(x + (x - 480) * 0.16, 533), Color(0.02, 0.03, 0.03, 0.34), 1.0)
    _lantern(Vector2(30, 375))
    _lantern(Vector2(930, 375))
    # Editorial UI areas. Labels and actual controls are in the parent scene.
    draw_rect(Rect2(19, 16, 922, 85), Color(0.01, 0.024, 0.040, 0.74))
    draw_rect(Rect2(19, 16, 922, 85), GOLD, false, 1.0)
    draw_line(Vector2(38, 98), Vector2(923, 98), Color("#cfaa71"), 1.0)
    draw_rect(Rect2(19, 535, 922, 91), Color(0.012, 0.027, 0.043, 0.95))
    draw_rect(Rect2(19, 535, 922, 91), GOLD, false, 1.0)
    draw_line(Vector2(38, 574), Vector2(922, 574), Color("#70583d"), 1.0)
    for x in [134.0, 307.0, 480.0, 653.0, 826.0]:
        draw_rect(Rect2(x - 74, 475, 148, 38), Color(0.015, 0.032, 0.048, 0.91))
        draw_rect(Rect2(x - 74, 475, 148, 38), GOLD, false, 1.0)
        draw_line(Vector2(x - 60, 479), Vector2(x + 60, 479), Color("#d2b27e"), 1.0)

func _lantern(p: Vector2) -> void:
    for i in range(4):
        draw_circle(p + Vector2(0, -18), float(5 - i) * 10.0, Color(0.98, 0.60, 0.25, 0.01))
    draw_rect(Rect2(p.x - 6, p.y - 34, 12, 28), Color("#0e1925"))
    draw_rect(Rect2(p.x - 4, p.y - 30, 8, 19), Color("#e0ab62"))
    draw_line(p + Vector2(-9, -34), p + Vector2(9, -34), GOLD, 2.0)
    draw_line(p + Vector2(-9, -5), p + Vector2(9, -5), GOLD, 2.0)
