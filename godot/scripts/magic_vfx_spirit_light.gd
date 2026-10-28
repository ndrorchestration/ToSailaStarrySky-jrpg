extends Node2D
## Independent Lyra spirit-light color cue; never converts Water into Spirit spell mastery.
## Low-intensity unshaded ink withstands ambient nighttime tint without screen-wide exposure.
const Catalog = preload("res://scripts/magic_vfx_catalog.gd")
const PINK = Color("#f9a0de")

var character_id: String = "ender"
var progress: float = 0.29
var reduced_motion: bool = true

func _ready() -> void:
    var ink := CanvasItemMaterial.new()
    ink.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
    material = ink
    queue_redraw()

func set_visual(identity: String, next_progress: float, static_frame: bool) -> bool:
    if not Catalog.has_character(identity) or is_nan(next_progress) or is_inf(next_progress):
        return false
    character_id = identity
    progress = clampf(next_progress, 0.0, 1.0)
    reduced_motion = static_frame
    visible = identity == "lyra"
    queue_redraw()
    return true

func _draw() -> void:
    if character_id != "lyra":
        return
    # Off-center to protect Ender's silhouette in Chapter I; pink is a separate
    # spiritual *visual* from the water ribbons, not another learned ability.
    var alpha: float = 0.70 if reduced_motion else 0.52 + 0.16 * sin(progress * PI)
    for side in [-1.0, 1.0]:
        var path := PackedVector2Array()
        for step in range(25):
            var t: float = float(step) / 24.0
            var x: float = side * (77.0 + 8.0 * sin(t * PI))
            var y: float = -84.0 + 165.0 * t + 4.0 * sin(t * TAU + progress * 1.7)
            path.append(Vector2(x, y))
        draw_polyline(path, Color(PINK.r, PINK.g, PINK.b, alpha), 2.5, true)
        draw_circle(path[3], 4.2, Color(PINK.r, PINK.g, PINK.b, minf(0.86, alpha + 0.12)))
        draw_circle(path[21], 3.3, Color(PINK.r, PINK.g, PINK.b, alpha))
