extends Node2D
## Noncanonical, opt-in distant ridge silhouettes on EXISTING dock-depth art.
## No terrain authoring, collisions, tree gameplay, or planetary data.
## Fixed pixel-scale illustration; does NOT instantiate flight_slice meshes.
@export var low_quality: bool = false
const RidgeSurface = preload("res://scripts/dock_ridge_surface.gd")
const ANCHOR_X := [276.0, 316.0, 352.0, 384.0, 416.0, 448.0]
var surface_anchors: Array[Vector2] = []
var source_surface_id: String = ""

func _ready() -> void:
    # Derive feet from the exact polygon drawn behind the pilot actors.
    # Any missing or wrong surface refuses to render the visual patch.
    source_surface_id = RidgeSurface.SURFACE_ID
    surface_anchors.clear()
    for screen_x in ANCHOR_X:
        var result: Dictionary = RidgeSurface.sample_root(screen_x, source_surface_id)
        if not result["ok"]:
            surface_anchors.clear()
            push_warning("Ridge vegetation surface probe rejected: " + str(screen_x))
            return
        surface_anchors.append(result["point"])
    queue_redraw()
const NEEDLE := Color("#476d70")
const NEEDLE_LIGHT := Color("#71918a")
const CANOPY := Color("#648480")
const CANOPY_SHADE := Color("#3c666b")
const BARK := Color("#53625d")

func set_low_quality(enabled: bool) -> void:
    low_quality = enabled
    queue_redraw()

func _draw() -> void:
    # All anchors sit on the pre-existing atmospheric ridge silhouette.
    # Bounded geometry: 6 crowns high quality / 3 simplified low quality.
    if surface_anchors.size() != ANCHOR_X.size():
        return # Fail closed: never guess terrain/footprint coordinates.
    for i in range(surface_anchors.size()):
        if low_quality and (i % 2) != 0:
            continue
        var root: Vector2 = surface_anchors[i]
        var tall: float = 19.0 + float((i * 7) % 13)
        if i % 2 == 0:
            _needle_tree(root, tall)
        else:
            _broadleaf_tree(root, tall)

func _needle_tree(anchor: Vector2, height: float) -> void:
    var top: Vector2 = anchor + Vector2(0.0, -height)
    draw_line(anchor, top + Vector2(0, 8), BARK, 2.0)
    var width: float = 7.0 + height * 0.16
    if low_quality:
        draw_colored_polygon(PackedVector2Array([
            top, anchor + Vector2(-width, -3),
            anchor + Vector2(width, -3)]), NEEDLE)
        return
    for tier in range(3):
        var level: float = float(tier) / 3.0
        var y: float = lerpf(top.y + 6.0, anchor.y - 4.0, level)
        var w: float = width * (0.58 + level * 0.45)
        draw_colored_polygon(PackedVector2Array([
            Vector2(anchor.x + 1.0, y - 8.0),
            Vector2(anchor.x - w, y + 8.0),
            Vector2(anchor.x + w * 0.85, y + 8.0)
        ]), NEEDLE if tier % 2 == 0 else NEEDLE_LIGHT)

func _broadleaf_tree(anchor: Vector2, height: float) -> void:
    var center := anchor + Vector2(0, -height * 0.67)
    draw_line(anchor, center, BARK, 2.0)
    if low_quality:
        draw_circle(center, 8.0, CANOPY_SHADE)
        return
    draw_circle(center + Vector2(-7, 2), 7.0, CANOPY_SHADE)
    draw_circle(center + Vector2(5, -3), 9.0, CANOPY)
    draw_circle(center + Vector2(0, -7), 7.0, NEEDLE_LIGHT)
