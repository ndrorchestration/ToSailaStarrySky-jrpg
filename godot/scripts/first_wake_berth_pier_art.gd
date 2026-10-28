extends Node2D
## Local berth ART ONLY. The low-cost original timber/brass vector language
## follows first_wake_cinematic_deck_architecture.gd without importing another
## story's shoreline or inventing a canonical settlement.
const DARK := Color("#172834")
const TIMBER := Color("#795640")
const WARM_PLANK := Color("#b58a5d")
const BRASS := Color("#d7b57b")
const MINT := Color("#a7e2cb")
const AMBER := Color("#f0ba70")
const PIER_AT := Vector2(790, 367)

var phase: String = "awaiting_approach"
var ship_x: float = 215.0
var dwell_fraction: float = 0.0

func set_berth_display(state: String, hull_x: float, progress: float) -> void:
    if phase == state and absf(ship_x - hull_x) < 0.5 and absf(dwell_fraction - progress) < 0.025:
        return
    phase = state
    ship_x = hull_x
    dwell_fraction = clampf(progress, 0.0, 1.0)
    queue_redraw()

func _poly(points: Array[Vector2], color: Color) -> void:
    draw_colored_polygon(PackedVector2Array(points), color)

func _draw() -> void:
    # Distant maritime shapes are a lighting/scale cue, NOT approved geography.
    _poly([Vector2(0, 315), Vector2(28, 299), Vector2(80, 305),
        Vector2(117, 318), Vector2(162, 325), Vector2(0, 336)],
        Color(0.18, 0.29, 0.35, 0.47))
    _poly([Vector2(596, 322), Vector2(636, 308), Vector2(679, 307),
        Vector2(734, 323), Vector2(784, 334), Vector2(576, 336)],
        Color(0.23, 0.34, 0.37, 0.27))
    draw_line(Vector2(24, 323), Vector2(934, 323), Color("#ffe5ba", 0.28), 1.4)
    for i in range(11):
        var x := 30.0 + float(i) * 92.0
        draw_line(Vector2(x, 345 + float(i % 3) * 13),
            Vector2(x + 36, 345 + float(i % 3) * 13),
            Color(0.79, 0.90, 0.83, 0.10), 2.0)
    # The pier's layered piling and horizontal deck are drawn as a legible
    # working berth rather than the crude rectangular block from the pilot.
    # Only the real Area2D in the parent controls physical contact.
    draw_rect(Rect2(789, 353, 21, 179), Color("#243542", 0.6))
    for x in [804.0, 843.0, 883.0]:
        draw_rect(Rect2(x - 6, 341, 14, 178), DARK)
        draw_rect(Rect2(x - 4, 343, 6, 172), Color("#624a3e"))
        draw_line(Vector2(x + 3, 346), Vector2(x + 3, 512), Color("#ab835b", 0.58), 1.5)
        for knot in [383.0, 468.0]:
            draw_circle(Vector2(x, knot), 3.1, BRASS.darkened(0.22))
    _poly([Vector2(787, 341), Vector2(925, 327), Vector2(940, 348),
        Vector2(788, 366)], Color("#352d2b"))
    _poly([Vector2(784, 329), Vector2(918, 317), Vector2(941, 334),
        Vector2(789, 349)], TIMBER)
    for i in range(8):
        var yy := 326.0 + float(i) * 2.6
        var alpha := 0.30 if i % 2 == 0 else 0.14
        draw_line(Vector2(796, yy + 9), Vector2(922, yy - 3),
            Color(0.96, 0.77, 0.50, alpha), 1.1)
    draw_line(Vector2(789, 349), Vector2(942, 333), BRASS, 2.3)
    draw_line(Vector2(792, 363), Vector2(941, 347), Color("#443832"), 4.0)
    # Vertical brass-capped mooring bitts and tactile rope fittings.
    for pos in [Vector2(803, 316), Vector2(897, 307)]:
        draw_rect(Rect2(pos.x - 5, pos.y, 11, 30), Color("#493b31"))
        draw_rect(Rect2(pos.x - 8, pos.y - 2, 17, 5), BRASS)
        draw_circle(pos + Vector2(0, -2), 2.5, Color("#f8ddaa"))
    for x in [812.0, 869.0, 922.0]:
        draw_line(Vector2(x, 356), Vector2(x + 3, 507),
            Color("#1e3340", 0.47), 3)
        draw_line(Vector2(x, 385), Vector2(x + 7, 398), Color("#d7c39a", 0.24), 1.3)
    # A reflection of the warm timberwork on shader-backed sea.
    for i in range(9):
        var y := 371.0 + float(i) * 14.5
        draw_line(Vector2(807 - i * 2.5, y), Vector2(875 + i * 3.2, y),
            Color(0.81, 0.62, 0.38, 0.12 - float(i) * 0.008), 1.2)
    # A navigation cue is presentation only. Phase/progress comes from the
    # actual physics pilot; no overlap can be asserted by this artwork.
    var secured := phase == "secured_local_berth"
    var contact := phase in ["settling", "berth_ready", "secured_local_berth"]
    var cue := MINT if secured else (AMBER if contact else BRASS)
    for i in range(5, 0, -1):
        draw_circle(PIER_AT + Vector2(7, 27), 16 + float(i) * 5,
            Color(cue.r, cue.g, cue.b, 0.014))
    draw_arc(PIER_AT + Vector2(7, 27), 23, -PI * 0.9,
        -PI * 0.9 + TAU * (1.0 if secured else dwell_fraction), 46, cue, 3.2, true)
    draw_circle(PIER_AT + Vector2(7, 27), 5.0, cue)
    draw_line(Vector2(790, 405), Vector2(820, 405),
        Color(cue.r, cue.g, cue.b, 0.6), 2)
    if secured:
        # Player-requested line appears only after verified physical dwell
        # AND explicit securing, with a calm restrained material sheen.
        var cleat := Vector2(805, 327)
        var bow := Vector2(ship_x + 66.0, 387.0)
        var slack := Vector2(0, 15)
        draw_polyline(PackedVector2Array([bow, bow.lerp(cleat, 0.45) + slack,
            cleat]), Color("#352d27"), 5, true)
        draw_polyline(PackedVector2Array([bow, bow.lerp(cleat, 0.45) + slack,
            cleat]), Color("#e8d6ac"), 2.2, true)
        draw_circle(cleat, 4, BRASS)
    # Clear HUD beds match the existing #555 shipboard scene.
    draw_rect(Rect2(0, 0, 960, 107), Color(0.034, 0.058, 0.09, 0.92))
    draw_line(Vector2(25, 101), Vector2(937, 101), BRASS, 1.35)
    draw_rect(Rect2(0, 543, 960, 97), Color(0.032, 0.055, 0.082, 0.96))
    draw_line(Vector2(27, 545), Vector2(933, 545), BRASS, 1.55)
    draw_line(Vector2(28, 629), Vector2(930, 629),
        Color(0.75, 0.78, 0.72, 0.21), 1.0)
    for i in range(6):
        var opacity := (6.0 - float(i)) / 6.0 * 0.032
        draw_rect(Rect2(i * 8, 108, 8, 435), Color(0.04, 0.08, 0.11, opacity))
        draw_rect(Rect2(952 - i * 8, 108, 8, 435), Color(0.04, 0.08, 0.11, opacity))
