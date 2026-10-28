extends Node2D
## Deterministic stone-and-copper set with directly lightable CanvasItem draw calls.
## Designed to prove *actual* native 2D lighting rather than painted glow.
func _ready() -> void:
    z_index = -6
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0.0, 0.0, 960.0, 640.0), Color("#13212d"))
    draw_rect(Rect2(0.0, 150.0, 960.0, 295.0), Color("#293940"))
    draw_rect(Rect2(0.0, 443.0, 960.0, 197.0), Color("#394a4b"))
    for row in range(5):
        for col in range(10):
            var offset := 32.0 if row % 2 == 1 else 0.0
            var x := float(col) * 106.0 - 32.0 + offset
            var y := 164.0 + float(row) * 58.0
            draw_rect(Rect2(x, y, 102.0, 54.0), Color("#4a5555" if (row + col) % 3 == 0 else "#415051"))
            draw_line(Vector2(x + 2.0, y + 4.0), Vector2(x + 98.0, y + 4.0), Color("#6c7067"), 1.0)
    for i in range(8):
        var x := float(i) * 140.0
        draw_line(Vector2(x, 447.0), Vector2(x - 70.0, 640.0), Color("#273d40"), 2.0)
    for i in range(5):
        var y := 462.0 + float(i) * 41.0
        draw_line(Vector2(0.0, y), Vector2(960.0, y), Color("#65716a"), 1.0)
    # Copper-lit technical wall plates and a pale swatch prove reflected color.
    draw_rect(Rect2(652.0, 245.0, 128.0, 141.0), Color("#928a70"))
    draw_rect(Rect2(661.0, 256.0, 109.0, 121.0), Color("#b2aa90"))
    draw_rect(Rect2(687.0, 287.0, 60.0, 56.0), Color("#d3c8a7"))
    draw_rect(Rect2(681.0, 405.0, 92.0, 37.0), Color("#a4ad9b"))
    # Dedicated unoccluded surface for a genuine light on/off framebuffer A/B.
    draw_rect(Rect2(454.0, 400.0, 73.0, 34.0), Color("#b2c0b1"))
