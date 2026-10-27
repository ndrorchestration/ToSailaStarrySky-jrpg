extends Node2D
## Geometric art study, not finished sprite art. Draws selected equipment live.
const Catalog = preload("res://scripts/weapon_skill_catalog.gd")
const SHADOW := Color("#172333")
const STEEL := Color("#e2e8df")
const IRON := Color("#93aeb7")
const BRASS := Color("#d3a35d")
const WOOD := Color("#825638")
const GRIP := Color("#403634")

var catalog = Catalog.new()
var weapon_id: String = "full_length_staff"

func select_weapon(next_id: String) -> bool:
    if catalog.weapon(next_id).is_empty():
        return false
    weapon_id = next_id
    queue_redraw()
    return true

func visual_contract() -> Dictionary:
    var item := catalog.weapon(weapon_id)
    if item.is_empty():
        return {}
    return {"weaponId":weapon_id,"family":item["family"],"silhouette":item["silhouette"],
        "sourceStatus":"ORIGINAL_GEOMETRIC_PLACEHOLDER_NOT_APPROVED_ART"}

func _draw() -> void:
    var item := catalog.weapon(weapon_id)
    if item.is_empty():
        return
    draw_circle(Vector2.ZERO,106.0,Color("#1c3743"))
    draw_arc(Vector2.ZERO,104.0,0.25,6.0,40,Color("#587c81"),1.0)
    match str(item["family"]):
        "staff": _draw_staff()
        "sword": _draw_sword()
        "pike": _draw_pike()
        "rifle": _draw_rifle()

func _stroke(a: Vector2,b: Vector2,color: Color,width: float) -> void:
    draw_line(a,b,SHADOW,width + 3.0,false)
    draw_line(a,b,color,width,false)

func _draw_staff() -> void:
    # Ender's staff stays full length, straight, with midpoint grip and ferrules.
    _stroke(Vector2(0,-96),Vector2(0,96),WOOD,9.0)
    _stroke(Vector2(0,-29),Vector2(0,29),GRIP,11.0)
    for y in [-23.0,-11.0,1.0,13.0,25.0]:
        draw_line(Vector2(-5,y-3),Vector2(5,y+2),BRASS,1.5)
    _stroke(Vector2(0,-98),Vector2(0,-82),BRASS,11.0)
    _stroke(Vector2(0,82),Vector2(0,98),BRASS,11.0)
    draw_rect(Rect2(-3,-99,3,13),STEEL)

func _draw_sword() -> void:
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,-103),Vector2(11,-83),Vector2(9,29),
        Vector2(0,43),Vector2(-9,29),Vector2(-11,-83)]),IRON)
    draw_line(Vector2(0,-96),Vector2(0,31),STEEL,2.0)
    _stroke(Vector2(-32,45),Vector2(32,45),BRASS,7.0)
    _stroke(Vector2(0,47),Vector2(0,91),GRIP,9.0)
    draw_circle(Vector2(0,95),8.0,BRASS)

func _draw_pike() -> void:
    _stroke(Vector2(0,-56),Vector2(0,101),WOOD,8.0)
    draw_colored_polygon(PackedVector2Array([
        Vector2(0,-107),Vector2(13,-80),Vector2(10,-55),
        Vector2(-10,-55),Vector2(-13,-80)]),STEEL)
    draw_line(Vector2(0,-103),Vector2(0,-59),IRON,2.0)
    _stroke(Vector2(-15,-51),Vector2(15,-51),BRASS,5.0)
    _stroke(Vector2(0,93),Vector2(0,101),BRASS,9.0)

func _draw_rifle() -> void:
    # Non-specific silhouette: no markings or invented military insignia.
    _stroke(Vector2(-48,-8),Vector2(92,-8),IRON,11.0)
    _stroke(Vector2(47,-8),Vector2(105,-8),STEEL,5.0)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-48,-14),Vector2(9,-14),Vector2(33,2),
        Vector2(-18,15),Vector2(-58,13)]),WOOD)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-54,-8),Vector2(-100,7),Vector2(-104,39),
        Vector2(-81,39),Vector2(-54,17)]),WOOD)
    _stroke(Vector2(-4,5),Vector2(-12,34),GRIP,12.0)
    _stroke(Vector2(4,-22),Vector2(29,-22),BRASS,5.0)
    draw_line(Vector2(8,-22),Vector2(8,-9),BRASS,3.0)
    draw_rect(Rect2(88,-11,9,9),BRASS)
