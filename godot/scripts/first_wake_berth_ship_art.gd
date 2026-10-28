extends Node2D
## Original source-palette 2D *study* of the Aureate Wake at local berth,
## attached directly to the real RigidBody2D, NOT its CollisionShape2D.
## Four independently drawn dragonfly planforms echo the in-game 3D source.
const BRASS := Color("#e0bd7e")
const TIMBER := Color("#79563f")
const MINT := Color("#9de4e0")
const CANOPY := Color("#244c5a")
var lines_secured: bool = false

func _poly(coords: Array[Vector2], pigment: Color) -> void:
    draw_colored_polygon(PackedVector2Array(coords), pigment)

func set_lines_secured(value: bool) -> void:
    if lines_secured == value:
        return
    lines_secured = value
    queue_redraw()

func _draw() -> void:
    # Quiet sea shadow offsets the hull from the source-native animated water.
    draw_ellipse_shadow()
    # Four transparent wing planforms. Deliberately low contrast so the
    # independent contact sensor and warm dock fittings remain readable.
    for side in [-1.0, 1.0]:
        for k in range(2):
            var anchor_x := -25.0 + float(k) * 51.0
            var tip_x := anchor_x + (-12.0 if k == 0 else 10.0)
            var wing_height: float = (53.0 if k == 0 else 48.0) * float(side)
            _poly([
                Vector2(anchor_x - 16, -7),
                Vector2(tip_x - 22, wing_height * 0.82),
                Vector2(tip_x + 6, wing_height),
                Vector2(anchor_x + 16, 6),
            ], Color(0.45, 0.79, 0.82, 0.46))
            draw_line(Vector2(anchor_x - 4, 0),
                Vector2(tip_x - 5, wing_height * 0.8),
                Color(0.82, 0.96, 0.89, 0.44), 1.4)
    # Dark undercarriage / gold-railed streamlined hull.
    _poly([Vector2(-69, -9), Vector2(53, -10), Vector2(69, -2),
        Vector2(59, 15), Vector2(-58, 15), Vector2(-72, 4)],
        Color("#2c3033"))
    _poly([Vector2(-65, -11), Vector2(53, -10), Vector2(67, -2),
        Vector2(57, 9), Vector2(-61, 10), Vector2(-70, 0)], TIMBER)
    _poly([Vector2(-58, -11), Vector2(48, -11), Vector2(62, -3),
        Vector2(-60, -3)], Color("#b88a58"))
    draw_line(Vector2(-61, -11), Vector2(54, -11), BRASS, 2.3)
    draw_line(Vector2(-57, 10), Vector2(58, 10), BRASS.darkened(0.14), 2.0)
    draw_line(Vector2(-53, 3), Vector2(56, 3), Color("#423731"), 1.5)
    # Bridge canopy and subtle icosphere-like ribs: aesthetic study only.
    draw_circle(Vector2(18, -10), 16.0, Color("#1a333e"))
    draw_circle(Vector2(18, -10), 13.6, CANOPY)
    draw_arc(Vector2(18, -10), 13.9, PI, TAU, 25, BRASS, 1.7, true)
    for x in [-5.0, 5.0]:
        draw_line(Vector2(18 + x, -22), Vector2(18 + x, -1),
            Color(0.77, 0.94, 0.86, 0.3), 1.0)
    draw_line(Vector2(4, -10), Vector2(31, -10),
        Color(0.73, 0.91, 0.85, 0.39), 1.2)
    # Tapered stern/rail and brass ventilation fittings.
    for x in [-44.0, -32.0, 0.0, 45.0]:
        draw_circle(Vector2(x, -10), 2.2, BRASS.darkened(0.10))
    draw_line(Vector2(-60, -18), Vector2(-39, -18), BRASS, 1.7)
    draw_line(Vector2(-60, -18), Vector2(-57, -9), BRASS, 1.5)
    draw_line(Vector2(-39, -18), Vector2(-36, -10), BRASS, 1.5)
    # A physical line cannot be created by a luminous cue. It only appears
    # after the parent has verified stable overlap and explicit player action.
    if lines_secured:
        draw_circle(Vector2(64, -3), 4.2, MINT)
        draw_circle(Vector2(64, -3), 2, Color("#f7e2ac"))
    else:
        draw_circle(Vector2(64, -3), 2.3, BRASS)

func draw_ellipse_shadow() -> void:
    for i in range(4, 0, -1):
        draw_circle(Vector2(0, 20), 55.0 + float(i) * 3.0,
            Color(0.02, 0.16, 0.19, 0.007))
    draw_line(Vector2(-63, 17), Vector2(64, 17), Color(0.04, 0.16, 0.19, 0.26), 4)
