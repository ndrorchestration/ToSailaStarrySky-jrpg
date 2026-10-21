extends Node2D
## Opt-in 2.5D stage dressing for the isolated Godot feasibility pilot.
## Decorative only: no collision, no routes, no ship/world/canon assertions.
## Separate background and foreground instances provide real actor occlusion.

@export var foreground: bool = false

const SKY_TOP := Color("#304565")
const SKY_MID := Color("#7da4b7")
const SKY_LOW := Color("#eed8ab")
const SEA_TOP := Color("#528da2")
const SEA_LOW := Color("#285c77")
const DECK_SHADE := Color("#3e3b36")
const DECK_WOOD := Color("#99714d")
const WOOD_HIGHLIGHT := Color("#d1aa78")
const BRASS := Color("#dcba7b")

func _draw() -> void:
    if foreground:
        _draw_foreground()
    else:
        _draw_stage()

func _poly(points: Array[Vector2], color: Color) -> void:
    draw_colored_polygon(PackedVector2Array(points), color)

func _draw_stage() -> void:
    # Color grading is built into the scene's actual CanvasItem, not a mock screenshot.
    for strip in range(0, 79):
        var t := float(strip) / 78.0
        var c: Color = SKY_TOP.lerp(SKY_MID, min(t * 1.5, 1.0)) if t < 0.57 else SKY_MID.lerp(SKY_LOW, (t - 0.57) / 0.43)
        draw_rect(Rect2(0, strip * 5, 960, 6), c)
    draw_circle(Vector2(174, 113), 79, Color(1.0, 0.91, 0.70, 0.065))
    draw_circle(Vector2(174, 113), 45, Color(1.0, 0.91, 0.73, 0.14))
    draw_circle(Vector2(174, 113), 23, Color("#fbe9bb"))
    # Cloud layers have distinct depth planes, not floating traversal surfaces.
    for i in range(7):
        var x := 44.0 + float(i) * 141.0
        var y := 160.0 + float(i % 3) * 34.0
        draw_circle(Vector2(x, y), 30.0, Color(0.93, 0.96, 0.94, 0.23))
        draw_circle(Vector2(x + 28, y - 11), 37.0, Color(0.96, 0.96, 0.94, 0.16))
        draw_circle(Vector2(x + 58, y + 4), 28.0, Color(0.97, 0.94, 0.88, 0.17))
    _poly([Vector2(0, 319), Vector2(92, 277), Vector2(143, 293), Vector2(196, 254), Vector2(240, 304), Vector2(330, 268), Vector2(392, 310), Vector2(460, 293), Vector2(535, 322), Vector2(620, 273), Vector2(697, 306), Vector2(790, 269), Vector2(850, 296), Vector2(960, 263), Vector2(960, 408), Vector2(0, 408)], Color("#719598"))
    _poly([Vector2(0, 366), Vector2(85, 341), Vector2(158, 354), Vector2(222, 333), Vector2(294, 358), Vector2(379, 331), Vector2(449, 361), Vector2(536, 344), Vector2(650, 369), Vector2(769, 342), Vector2(842, 363), Vector2(960, 340), Vector2(960, 400), Vector2(0, 400)], Color("#527e88"))
    for i in range(22):
        var yy := 387.0 + i * 12.0
        var t: float = float(i) / 21.0
        draw_rect(Rect2(0, yy, 960, 13), SEA_TOP.lerp(SEA_LOW, t))
    # Water glints stay in open side channels beside the supported pier.
    for i in range(25):
        var x := float((i * 97 + 19) % 955)
        var y := 415.0 + float((i * 41) % 193)
        if x < 107 or x > 842 or y > 544:
            draw_line(Vector2(x, y), Vector2(x + 22 + (i % 4) * 9, y), Color(0.96, 0.90, 0.69, 0.19), 1.1)
    # Structural underside is drawn before the plank surface: supports are visible.
    _poly([Vector2(104, 509), Vector2(852, 509), Vector2(875, 559), Vector2(83, 559)], Color("#352f30"))
    for bx in [142.0, 345.0, 613.0, 816.0]:
        _poly([Vector2(bx - 11, 527), Vector2(bx + 12, 527), Vector2(bx + 19, 611), Vector2(bx - 17, 614)], Color("#423931"))
        draw_line(Vector2(bx - 7, 533), Vector2(bx - 10, 611), Color("#a07c55"), 2.0)
        draw_line(Vector2(bx - 13, 572), Vector2(bx + 13, 552), Color("#705b47"), 5.0)
    draw_line(Vector2(130, 566), Vector2(820, 553), Color("#715941"), 8.0)
    draw_line(Vector2(154, 566), Vector2(352, 531), Color("#9c7850"), 4.0)
    draw_line(Vector2(612, 530), Vector2(817, 557), Color("#9c7850"), 4.0)
    # Same physically supported dock footprint, not a newly claimed canon route.
    _poly([Vector2(122, 401), Vector2(835, 401), Vector2(890, 533), Vector2(66, 533)], Color("#393531"))
    _poly([Vector2(128, 398), Vector2(830, 398), Vector2(878, 525), Vector2(78, 525)], DECK_WOOD)
    # Receding board rows widen toward camera: a continuous walkable surface.
    for j in range(9):
        var t0 := float(j) / 9.0
        var t1 := float(j + 1) / 9.0
        var y0 := lerpf(399.0, 525.0, t0)
        var y1 := lerpf(399.0, 525.0, t1)
        var left0 := lerpf(128.0, 78.0, t0)
        var left1 := lerpf(128.0, 78.0, t1)
        var right0 := lerpf(830.0, 878.0, t0)
        var right1 := lerpf(830.0, 878.0, t1)
        var wood := Color("#9c7451") if j % 2 == 0 else Color("#876448")
        _poly([Vector2(left0 + 2, y0 + 1), Vector2(right0 - 2, y0 + 1), Vector2(right1 - 2, y1), Vector2(left1 + 2, y1)], wood)
        draw_line(Vector2(left1 + 2, y1), Vector2(right1 - 2, y1), Color("#44382f"), 2.0)
        draw_line(Vector2(left0 + 11, y0 + 2), Vector2(right0 - 15, y0 + 2), Color(1, 0.83, 0.60, 0.13), 1.0)
        for k in range(1, 6):
            var seam := lerpf(left0 + 7, right0 - 7, float(k) / 6.0) + (j % 2) * 23.0
            if seam < right0 - 10:
                draw_line(Vector2(seam, y0 + 2), Vector2(seam + (left1 - left0) * 0.15, y1 - 2), Color(0.21, 0.17, 0.15, 0.30), 1.0)
    draw_line(Vector2(128, 399), Vector2(78, 525), WOOD_HIGHLIGHT, 4.0)
    draw_line(Vector2(830, 399), Vector2(878, 525), WOOD_HIGHLIGHT, 4.0)
    draw_line(Vector2(82, 528), Vector2(874, 528), Color("#dec093"), 4.0)
    # Far rail and signal posts are behind actors and do not create barriers.
    for x in [157.0, 310.0, 648.0, 804.0]:
        draw_rect(Rect2(x, 365, 11, 50), Color("#584738"))
        draw_line(Vector2(x + 3, 368), Vector2(x + 3, 411), Color("#bc9163"), 2.0)
        draw_rect(Rect2(x - 2, 360, 15, 6), BRASS)
    draw_line(Vector2(164, 375), Vector2(811, 375), Color("#6e5443"), 7.0)
    draw_line(Vector2(164, 373), Vector2(811, 373), Color("#e1be81"), 2.0)
    for x in [158.0, 804.0]:
        draw_line(Vector2(x + 4, 362), Vector2(x + 4, 331), Color("#51463f"), 3.0)
        draw_circle(Vector2(x + 4, 329), 12.0, Color(1, 0.81, 0.42, 0.07))
        draw_circle(Vector2(x + 4, 329), 5.0, Color("#f5d696"))
    # Subtle deck material reflections / contextual props kept outside actor route.
    _draw_crate(Vector2(101, 450), 0.8)
    _draw_crate(Vector2(825, 445), 0.72)
    _draw_plant(Vector2(116, 423))
    _draw_plant(Vector2(833, 416))

func _draw_crate(pos: Vector2, scale_amount: float) -> void:
    var w := 43.0 * scale_amount
    var h := 33.0 * scale_amount
    draw_rect(Rect2(pos.x, pos.y - h, w, h), Color("#735a42"))
    draw_line(Vector2(pos.x + 2, pos.y - h + 2), Vector2(pos.x + w - 2, pos.y - 2), Color("#ceb080"), 3.0)
    draw_line(Vector2(pos.x + w - 2, pos.y - h + 2), Vector2(pos.x + 2, pos.y - 2), Color("#ceb080"), 3.0)
    draw_rect(Rect2(pos.x, pos.y - h, w, h), Color("#392e29"), false, 2.0)

func _draw_plant(pos: Vector2) -> void:
    draw_rect(Rect2(pos.x - 11, pos.y - 17, 22, 17), Color("#775640"))
    draw_line(pos + Vector2(-8, -12), pos + Vector2(8, -12), BRASS, 2.0)
    for i in range(7):
        var x := float(i - 3)
        draw_line(pos + Vector2(0, -16), pos + Vector2(x * 5, -23 - abs(x) * 3.3), Color("#487a63"), 2.4)
        draw_circle(pos + Vector2(x * 5, -23 - abs(x) * 3.3), 3.0, Color("#83b582"))

func _draw_foreground() -> void:
    # Preserve the pilot's dialogue readability above the decorative scene.
    draw_rect(Rect2(95, 542, 780, 86), Color(0.04, 0.08, 0.18, 0.78))
    draw_line(Vector2(98, 543), Vector2(871, 543), Color("#a88b64"), 2.0)
    # Narrow corner rails form an honest over/under depth cue without masking actors.
    for x in [78.0, 867.0]:
        draw_rect(Rect2(x - 7, 504, 14, 60), Color("#514035"))
        draw_rect(Rect2(x - 10, 498, 20, 9), Color("#b58a60"))
        draw_line(Vector2(x - 3, 509), Vector2(x - 3, 563), Color("#c19d69"), 2.0)
    draw_line(Vector2(77, 504), Vector2(138, 533), Color("#b08c61"), 4.0)
    draw_line(Vector2(866, 504), Vector2(814, 534), Color("#b08c61"), 4.0)
    for p in [Vector2(78, 498), Vector2(868, 498)]:
        draw_circle(p + Vector2(0, -5), 7.0, Color(1.0, 0.83, 0.52, 0.12))
        draw_circle(p + Vector2(0, -5), 3.0, Color("#eacc93"))
