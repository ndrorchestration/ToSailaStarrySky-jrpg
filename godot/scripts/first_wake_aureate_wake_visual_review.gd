extends Node2D
## Hand-layered Aureate Wake side-profile dressing for the bounded First Wake
## flight/water scene. Cosmetic ONLY. Local physics is owned by the parent
## RigidBody2D; this node changes no hitboxes, propulsion, story or ship mode.
## The bridge dome echoes the approved geodesic-design *direction*, but is
## provisional game art rather than accepted final source geometry.

const GOLD := Color("#dfb97a")
const EDGE := Color("#f9dfaa")
const COPPER := Color("#986e55")
const HULL_SHADOW := Color("#283c49")
const DEEP_METAL := Color("#364b51")
const TEAL := Color("#8bd6d2")
const GLASS := Color("#537d89")
const LIGHT_GLASS := Color("#bad7cf")

var stage: String = "awaiting_launch"
var motion_seconds: float = 0.0
var reduced_motion: bool = false

func set_visual_phase(value: String) -> void:
    stage = value
    queue_redraw()

func visual_contract() -> Dictionary:
    return {
        "review_only": true,
        "physics_authority": false,
        "combat_authority": false,
        "world_travel_authority": false,
        "ship_transformation_revealed": false,
        "bridge_profile": "provisional_geodesic_dome",
        "art_accepted": false,
        "stage": stage,
    }

func _process(delta: float) -> void:
    if reduced_motion:
        return
    if stage in ["ascent", "warning", "descent", "waterborne", "recovery_approach", "berth_contact", "berth_securing", "berth_ready"]:
        motion_seconds = fmod(motion_seconds + minf(delta, 0.05), 60.0)
        queue_redraw()

func _poly(points: Array[Vector2], fill: Color) -> void:
    draw_colored_polygon(PackedVector2Array(points), fill)

func _line(a: Vector2, b: Vector2, color: Color, width: float = 1.0) -> void:
    draw_line(a, b, color, width)

func _draw() -> void:
    # Pixel-conscious multi-layer silhouettes, retaining the original
    # right-facing orientation and the existing 144x34 physics shape.
    # Rear wing and low fixed profile are intentionally not a gameplay
    # transformation state or a disclosure of submersible/lunar technology.
    _poly([
        Vector2(-26, -14), Vector2(-101, -48),
        Vector2(-107, -41), Vector2(-80, -17),
        Vector2(-105, -6), Vector2(-78, 0),
        Vector2(-15, 5),
    ], DEEP_METAL)
    _poly([
        Vector2(-30, -18), Vector2(-99, -44),
        Vector2(-73, -18), Vector2(-94, -9),
        Vector2(-53, -4), Vector2(-12, 2),
    ], Color("#477a83"))
    _line(Vector2(-94, -43), Vector2(-18, -10), Color("#d3d6bd"), 1.1)
    _line(Vector2(-80, -16), Vector2(-17, 1), Color("#c8a873"), 1.2)

    # Forward stabilizer / copper-tipped secondary wing.
    _poly([
        Vector2(21, -9), Vector2(88, -38),
        Vector2(108, -27), Vector2(68, -10),
        Vector2(87, 4), Vector2(30, 5),
    ], HULL_SHADOW)
    _poly([
        Vector2(28, -13), Vector2(88, -35),
        Vector2(102, -28), Vector2(55, -6),
        Vector2(80, 1), Vector2(22, 1),
    ], Color("#588993"))
    _line(Vector2(29, -9), Vector2(96, -30), Color("#e1c088"), 1.4)

    # Lower hull: continuous keel, purposeful raised prow and layered
    # wood/copper relief; no primitive rectangular vessel placeholder.
    _poly([
        Vector2(-83, -5), Vector2(54, -6), Vector2(75, -14),
        Vector2(82, -10), Vector2(75, 8), Vector2(57, 18),
        Vector2(14, 24), Vector2(-60, 20), Vector2(-79, 9),
        Vector2(-87, 1),
    ], HULL_SHADOW)
    _poly([
        Vector2(-78, -9), Vector2(53, -11), Vector2(77, -17),
        Vector2(76, 1), Vector2(58, 12), Vector2(9, 19),
        Vector2(-59, 14), Vector2(-78, 5),
    ], COPPER)
    _poly([
        Vector2(-73, -9), Vector2(54, -11), Vector2(74, -17),
        Vector2(67, -7), Vector2(-71, -3),
    ], GOLD)
    _poly([
        Vector2(-69, 5), Vector2(53, 5), Vector2(60, 11),
        Vector2(8, 16), Vector2(-58, 12),
    ], Color("#bd8a5c"))
    _line(Vector2(-63, 12), Vector2(11, 19), Color("#66504a"), 1.8)
    _line(Vector2(-67, 4), Vector2(55, 4), Color("#f4cf93"), 1.5)
    _line(Vector2(-58, 13), Vector2(9, 20), Color("#e7c38f"), 1.2)
    for i in range(10):
        var x := -53.0 + float(i) * 11.0
        _line(Vector2(x, 6), Vector2(x + 2.0, 11), Color(0.32, 0.23, 0.24, 0.5), 1.0)

    # Exposed open-air forward deck and fine railing. Enclosing capabilities
    # remain story-locked; only visible structural elements are depicted here.
    _line(Vector2(-65, -16), Vector2(73, -19), EDGE, 1.8)
    for x in [-62.0, -41.0, 46.0, 67.0]:
        _line(Vector2(x, -16), Vector2(x, -28), GOLD, 1.6)
    _line(Vector2(-63, -28), Vector2(-41, -28), Color("#d4cbaa"), 1.3)
    _line(Vector2(46, -28), Vector2(69, -28), Color("#d4cbaa"), 1.3)

    # Geodesic bridge: luminous segmented glass against structural brass.
    # Deliberately not rendered as a fully airtight pressure hull.
    _poly([
        Vector2(-31, -18), Vector2(-29, -40), Vector2(-15, -57),
        Vector2(3, -62), Vector2(23, -56), Vector2(37, -42),
        Vector2(39, -18),
    ], Color("#273e4b"))
    _poly([
        Vector2(-26, -21), Vector2(-23, -40), Vector2(-11, -53),
        Vector2(4, -57), Vector2(20, -52), Vector2(33, -39),
        Vector2(34, -21),
    ], GLASS)
    _poly([
        Vector2(-22, -40), Vector2(-10, -52), Vector2(4, -56),
        Vector2(12, -45), Vector2(-3, -34),
    ], Color("#94b9b3"))
    _poly([
        Vector2(13, -46), Vector2(20, -51), Vector2(31, -38),
        Vector2(32, -24), Vector2(14, -28),
    ], Color("#385a6d"))
    _line(Vector2(-26, -21), Vector2(34, -21), GOLD, 2.2)
    for segment in [
        [Vector2(-26, -21), Vector2(-11, -53)],
        [Vector2(-11, -53), Vector2(4, -57)],
        [Vector2(4, -57), Vector2(20, -52)],
        [Vector2(20, -52), Vector2(34, -21)],
        [Vector2(-26, -21), Vector2(4, -57)],
        [Vector2(4, -57), Vector2(34, -21)],
        [Vector2(-11, -53), Vector2(20, -52)],
        [Vector2(-12, -35), Vector2(22, -35)],
        [Vector2(-12, -35), Vector2(4, -57)],
        [Vector2(22, -35), Vector2(4, -57)],
    ]:
        _line(segment[0], segment[1], Color("#cfbf94"), 1.1)
    draw_circle(Vector2(4, -57), 2.3, EDGE)
    draw_circle(Vector2(-11, -53), 1.7, GOLD)
    draw_circle(Vector2(20, -52), 1.7, GOLD)
    # Optical glints follow the existing bridge silhouette, with no change
    # to collision, camera, navigation, pressure systems or ship modes.
    var glass_glint: float = 0.0 if reduced_motion else 0.5 + 0.5 * sin(motion_seconds * 1.3)
    _poly([
        Vector2(-20, -42), Vector2(-10, -52), Vector2(-3, -54),
        Vector2(-13, -35), Vector2(-22, -30),
    ], Color(0.87, 0.98, 0.94, 0.10 + 0.09 * glass_glint))
    _line(Vector2(-16, -46), Vector2(-10, -50), Color(0.98, 0.97, 0.83, 0.32 + 0.13 * glass_glint), 1.2)
    for rivet_x in [-23.0, -13.0, -2.0, 10.0, 21.0, 31.0]:
        draw_circle(Vector2(rivet_x, -21), 1.0, Color("#edc986"))

    # Warm fittings, hand-worked utility elements and restrained power halo.
    for x in [-46.0, -26.0, 43.0]:
        draw_rect(Rect2(x, -5, 8, 5), Color("#243e48"))
        _line(Vector2(x + 1, -4), Vector2(x + 6, -4), Color("#a9d5ca"), 1.0)
    draw_circle(Vector2(69, -5), 3.5, GOLD)
    draw_circle(Vector2(-70, -5), 2.8, GOLD)
    var active: bool = stage in ["ascent", "warning", "descent"]
    var glow: float = 0.68 + 0.25 * sin(motion_seconds * 2.8)
    if active:
        draw_circle(Vector2(-63, 13), 11.0, Color(0.22, 0.77, 0.79, 0.09 * glow))
        draw_circle(Vector2(-63, 13), 5.0, Color(0.47, 0.87, 0.87, 0.45 * glow))
    else:
        draw_circle(Vector2(-63, 13), 2.8, Color("#8aa5a1"))

    # Nonphysical surface highlights only after the simulation actually
    # records contact. The visual cannot itself set any gameplay flag.
    if stage in ["waterborne", "postflight_diagnosis", "recovery_approach", "berth_contact", "berth_securing", "berth_ready"]:
        var oscillation: float = 0.0 if reduced_motion else sin(motion_seconds * 2.1)
        _line(Vector2(-85, 23), Vector2(-54, 26 + oscillation), Color(0.69, 0.90, 0.85, 0.42), 1.2)
        _line(Vector2(28, 27), Vector2(77, 23 - oscillation), Color(0.68, 0.90, 0.83, 0.37), 1.1)
