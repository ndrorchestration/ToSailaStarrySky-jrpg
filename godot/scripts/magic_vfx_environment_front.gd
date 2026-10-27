extends Node2D
## Solid foreground review prop. Explicit Z draw-over and a separate occluder.
## A study fixture, not production map geometry or physical collider.
var occluder: LightOccluder2D

func _ready() -> void:
    z_index = 8
    occluder = LightOccluder2D.new()
    occluder.name = "StoneLightOccluder"
    occluder.position = Vector2(0.0, 0.0)
    var outline := OccluderPolygon2D.new()
    outline.polygon = PackedVector2Array([
        Vector2(7.0, 8.0), Vector2(100.0, 8.0),
        Vector2(100.0, 208.0), Vector2(7.0, 208.0)
    ])
    occluder.occluder = outline
    occluder.occluder_light_mask = 1
    occluder.sdf_collision = false
    add_child(occluder)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0.0, 0.0, 107.0, 218.0), Color("#3c505b"))
    draw_rect(Rect2(6.0, 4.0, 94.0, 202.0), Color("#66716f"))
    draw_rect(Rect2(15.0, 13.0, 76.0, 184.0), Color("#6c7772"))
    for i in range(5):
        var y := 20.0 + float(i) * 38.0
        draw_line(Vector2(12.0, y), Vector2(96.0, y + 3.0), Color("#415657"), 2.0)
    draw_line(Vector2(24.0, 18.0), Vector2(43.0, 149.0), Color("#809086"), 2.0)
    draw_rect(Rect2(5.0, 6.0, 9.0, 202.0), Color("#929d85"))
    draw_rect(Rect2(97.0, 6.0, 9.0, 207.0), Color("#334650"))
