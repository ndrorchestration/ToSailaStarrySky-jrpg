extends Node2D
## Opt-in 2.5D stage dressing for the isolated Godot feasibility pilot.
## Decorative only: no collision, no routes, no ship/world/canon assertions.
## Separate background and foreground instances provide real actor occlusion.

@export var foreground: bool = false
@export var painted_sky_enabled: bool = true
## Painterly dock material pass. Visual-only and directly reversible with M on the dock.
@export var refined_materials_enabled: bool = true
const MATERIAL_REVISION := "dock-grain-v1"
## Visual only. Reuses the existing project-approved-for-testing cinematic shader.
const PaintedSkyShader = preload("res://shaders/first_wake_cinematic_sky.gdshader")
var painted_sky: ColorRect

func _ready() -> void:
    if foreground or not painted_sky_enabled:
        return
    var sky := ColorRect.new()
    sky.name = "PaintedCoastSkyVisualOnly"
    sky.size = Vector2(960.0, 402.0)
    sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
    sky.show_behind_parent = true
    sky.z_index = -1
    var sky_material := ShaderMaterial.new()
    sky_material.shader = PaintedSkyShader
    sky.material = sky_material
    painted_sky = sky
    add_child(sky)
    queue_redraw()


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
    # Keep historic procedural sky as an exact rollback fallback.
    # The cinematic sky is a material-only visual; physics remains unchanged.
    if painted_sky == null:
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
    if refined_materials_enabled:
        _draw_coastal_atmosphere()
    for i in range(22):
        var yy := 387.0 + i * 12.0
        var t: float = float(i) / 21.0
        draw_rect(Rect2(0, yy, 960, 13), SEA_TOP.lerp(SEA_LOW, t))
    if refined_materials_enabled:
        _draw_sea_microdetail()
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
        var plank_vertices := PackedVector2Array([
            Vector2(left0 + 2, y0 + 1), Vector2(right0 - 2, y0 + 1),
            Vector2(right1 - 2, y1), Vector2(left1 + 2, y1)
        ])
        if refined_materials_enabled:
            # Native vertex tint interpolates real light across each perspective
            # plank, retaining the exact same authored walkable footprint.
            var highlight_tone: Color = wood.lightened(0.11)
            var lower_tone: Color = wood.darkened(0.12)
            draw_polygon(plank_vertices, PackedColorArray([
                highlight_tone, highlight_tone, lower_tone, lower_tone
            ]))
        else:
            draw_colored_polygon(plank_vertices, wood)
        draw_line(Vector2(left1 + 2, y1), Vector2(right1 - 2, y1), Color("#44382f"), 2.0)
        draw_line(Vector2(left0 + 11, y0 + 2), Vector2(right0 - 15, y0 + 2), Color(1, 0.83, 0.60, 0.13), 1.0)
        if refined_materials_enabled:
            _draw_plank_grain(j, y0, y1, left0, left1, right0, right1)
        for k in range(1, 6):
            var seam := lerpf(left0 + 7, right0 - 7, float(k) / 6.0) + (j % 2) * 23.0
            if seam < right0 - 10:
                draw_line(Vector2(seam, y0 + 2), Vector2(seam + (left1 - left0) * 0.15, y1 - 2), Color(0.21, 0.17, 0.15, 0.30), 1.0)
    if refined_materials_enabled:
        _draw_deck_hardware_and_wear()
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

func set_refined_materials_enabled(enabled: bool) -> void:
    refined_materials_enabled = enabled
    queue_redraw()

func _draw_coastal_atmosphere() -> void:
    # Distant ridges and quiet suspended haze — no new traversable geography.
    for i in range(34):
        var x := float((i * 79 + 11) % 970)
        var y := 305.0 + float((i * 23) % 40)
        var length := float(23 + (i * 19) % 57)
        draw_line(Vector2(x, y), Vector2(minf(x + length, 957.0), y - 2.0),
            Color(0.93, 0.81, 0.68, 0.042 + float(i % 4) * 0.012), 1.0)
    for strip in range(5):
        var yy := 338.0 + float(strip) * 10.0
        draw_line(Vector2(0.0, yy), Vector2(960.0, yy + 3.0),
            Color(0.83, 0.88, 0.82, 0.032 - float(strip) * 0.004), 4.0)

func _draw_sea_microdetail() -> void:
    # Directional, deterministic ripples: sparse reflective paths either side
    # of the existing supported pier, not animation or a new water collision.
    for i in range(80):
        var x := float((i * 113 + 29) % 950)
        var y := 404.0 + float((i * 41 + 7) % 204)
        if (x > 88.0 and x < 890.0 and y > 440.0 and y < 535.0):
            continue
        var length := float(7 + (i * 11) % 29)
        var amber := Color(0.98, 0.78, 0.51, 0.047 + float(i % 5) * 0.012)
        draw_line(Vector2(x, y), Vector2(minf(x + length, 955.0), y), amber, 0.85)
    for band in range(7):
        var t := float(band) / 6.0
        var y := 398.0 + t * 187.0
        draw_line(Vector2(0, y), Vector2(90, y + t * 2.0),
            Color(0.06, 0.24, 0.32, 0.048), 1.0)
        draw_line(Vector2(885, y + t * 2.0), Vector2(960, y),
            Color(0.06, 0.24, 0.32, 0.048), 1.0)

func _draw_plank_grain(row: int, y0: float, y1: float,
        left0: float, left1: float, right0: float, right1: float) -> void:
    # Geometry is bounded within each authored perspective plank. No random
    # state, external files, tile seams or physics/actor dependence.
    for strand in range(29):
        var sample := float((strand * 31 + row * 17) % 101) / 101.0
        var depth := 0.16 + float((strand * 13 + row * 7) % 65) / 100.0
        var y := lerpf(y0 + 2.0, y1 - 2.0, depth)
        var side := (y - y0) / maxf(y1 - y0, 1.0)
        var left := lerpf(left0, left1, side) + 5.0
        var right := lerpf(right0, right1, side) - 5.0
        var width := maxf(right - left, 1.0)
        var x := left + width * sample
        var grain_length := float(14 + (strand * 29 + row * 17) % 65)
        var endpoint := minf(x + grain_length, right)
        if endpoint <= x + 3.0:
            continue
        var warm := strand % 4 == 0
        var tint := Color(0.92, 0.75, 0.55, 0.12) if warm else Color(0.18, 0.12, 0.085, 0.075)
        draw_line(Vector2(x, y), Vector2(endpoint, y + float(strand % 3 - 1) * 0.6),
            tint, 0.72, true)
    # Long intermittent grain bands provide legible roughness at 960x640.
    # The bands stay inside the authored trapezoids and are deterministic.
    for ribbon in range(5):
        var t := (float(ribbon) + 0.65) / 6.0
        var y := lerpf(y0 + 2.0, y1 - 2.0, t)
        var left := lerpf(left0, left1, t) + 10.0
        var right := lerpf(right0, right1, t) - 10.0
        var shade := Color(0.13, 0.088, 0.06, 0.065 + float(ribbon % 3) * 0.014)
        if ribbon % 2 == 0:
            shade = Color(0.99, 0.80, 0.60, 0.055)
        for segment in range(3):
            var start_x := left + float(segment) * (right - left) / 3.0 + float((row * 19 + segment * 23) % 17)
            var reach := float(82 + (row * 37 + ribbon * 53 + segment * 19) % 119)
            var end_x := minf(start_x + reach, right)
            if end_x > start_x + 6.0:
                var mid := (start_x + end_x) * 0.5
                draw_polyline(PackedVector2Array([
                    Vector2(start_x, y),
                    Vector2(mid, y + float((row + ribbon) % 3 - 1) * 0.9),
                    Vector2(end_x, y + float((row + segment) % 3 - 1) * 0.45)
                ]), shade, 1.05, true)
    # Individual small ring-scar knots, not a repeated visible stencil.
    if row in [2, 5, 7]:
        var fx := 0.24 + float(row % 3) * 0.21
        var middle_y := (y0 + y1) * 0.5
        var center_x := lerpf(lerpf(left0, left1, 0.5), lerpf(right0, right1, 0.5), fx)
        draw_arc(Vector2(center_x, middle_y), 3.2, -1.5, 1.5,
            9, Color(0.18, 0.11, 0.08, 0.22), 0.7, true)
        draw_line(Vector2(center_x - 8.0, middle_y),
            Vector2(center_x - 3.2, middle_y), Color(0.24, 0.16, 0.10, 0.14), 0.6)

func _draw_deck_hardware_and_wear() -> void:
    # Brass nail heads and slightly uneven pitch: non-interactive material detail.
    for row in range(8):
        var t := (float(row) + 0.5) / 9.0
        var yy := lerpf(399.0, 525.0, t)
        var left := lerpf(128.0, 78.0, t)
        var right := lerpf(830.0, 878.0, t)
        for column in range(7):
            var fraction := (float(column) + 0.38) / 7.0
            var xx := lerpf(left + 10.0, right - 10.0, fraction)
            draw_circle(Vector2(xx + 0.7, yy + 0.7), 1.5,
                Color(0.15, 0.11, 0.09, 0.38))
            draw_circle(Vector2(xx, yy), 0.85,
                Color(0.91, 0.72, 0.43, 0.47))
    for i in range(17):
        var xx := 103.0 + float((i * 43 + 17) % 740)
        var yy := 409.0 + float((i * 19) % 108)
        draw_line(Vector2(xx, yy), Vector2(xx + 11.0, yy),
            Color(0.11, 0.08, 0.07, 0.095), 0.9)

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
