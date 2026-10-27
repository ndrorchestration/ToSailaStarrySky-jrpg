extends Node2D
## Non-character-specific mannequin scene for rehearsal. Original procedural
## geometry; NOT approved protagonist art or a production battle scene.
const Catalog = preload("res://scripts/weapon_skill_catalog.gd")
const Silhouette = preload("res://scripts/weapon_silhouette_review.gd")
const PAPER := Color("#e8ddbe")
const DEEP := Color("#0a1d2d")
const SLATE := Color("#385769")
const BRASS := Color("#d6a85c")
const AETHER := Color("#70b8b3")

var catalog = Catalog.new()
var weapon: Node2D
var pose: Dictionary = {}
var show_mannequin: bool = true

func _ready() -> void:
    weapon = Silhouette.new()
    weapon.name = "EquippedWeapon"
    weapon.show_backplate = false
    weapon.scale = Vector2(0.52,0.52)
    add_child(weapon)
    if pose.is_empty():
        apply_pose({
            "weaponId":"full_length_staff","family":"staff","action":"idle",
            "weaponAngle":0.0,"lean":0.0,"advance":0.0,"bob":0.0,
            "effect":0.0,"recoil":0.0,"motionReduced":true
        })
    else:
        apply_pose(pose)

func apply_pose(next_pose: Dictionary) -> bool:
    var item := catalog.weapon(str(next_pose.get("weaponId", "")))
    if item.is_empty() or str(next_pose.get("family","")) != str(item["family"]):
        return false
    pose = next_pose.duplicate(true)
    if weapon != null:
        weapon.select_weapon(str(pose["weaponId"]))
        var angle := float(pose.get("weaponAngle",0.0))
        weapon.rotation_degrees = angle
        weapon.scale = Vector2(0.52,0.52)
        # Pivot by physical family: the grip remains at the drawn hand when
        # the equipment changes and rotates, rather than hovering beside it.
        var hand := Vector2(-6.0 + float(pose.get("advance",0.0)),
            -19.0 + float(pose.get("bob",0.0)))
        var anchor := Vector2.ZERO
        match str(item["family"]):
            "sword": anchor = Vector2(0.0,75.0)
            "pike": anchor = Vector2(0.0,38.0)
            "rifle": anchor = Vector2(-10.0,30.0)
        var rotated_grip := (anchor * 0.52).rotated(deg_to_rad(angle))
        weapon.position = hand - rotated_grip - Vector2(float(pose.get("recoil",0.0)),0.0)
        weapon.queue_redraw()
    queue_redraw()
    return true

func visual_contract() -> Dictionary:
    if pose.is_empty():
        return {}
    return {
        "weaponId":str(pose["weaponId"]),
        "family":str(pose["family"]),
        "action":str(pose["action"]),
        "stage":"MANNEQUIN_STUDY",
        "canExecute":false,
        "effect":float(pose.get("effect",0.0)),
        "motionReduced":bool(pose.get("motionReduced",false))
    }

func _draw() -> void:
    # Five fixed depth bands: dusk sky, cloud, distant pylons, deck, foreground.
    draw_rect(Rect2(-218,-186,436,381),Color("#172c43"))
    draw_rect(Rect2(-218,-185,436,87),Color("#1d3d58"))
    for i in range(6):
        var x := -203.0 + float(i * 79)
        var y := -154.0 + float((i * 19) % 41)
        draw_line(Vector2(x,y),Vector2(x+20,y-4),Color("#6a94a0",0.18),1.0)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-218,-67),Vector2(-157,-104),Vector2(-98,-73),
        Vector2(-39,-97),Vector2(35,-70),Vector2(118,-116),
        Vector2(218,-78),Vector2(218,111),Vector2(-218,111)
    ]),Color("#244259"))
    for i in range(7):
        var xx := -206.0 + i * 68.0
        draw_rect(Rect2(xx,-58,7,174),Color("#456270",0.28))
        draw_line(Vector2(xx-12,-59),Vector2(xx+19,-59),BRASS.darkened(0.48),2.0)
    draw_rect(Rect2(-218,113,436,81),Color("#3e4e51"))
    for i in range(9):
        var yy := 121.0 + float(i*10)
        draw_line(Vector2(-215,yy),Vector2(215,yy),Color("#698084",0.37),1.0)
    draw_line(Vector2(-216,113),Vector2(216,113),BRASS.darkened(0.52),3.0)
    # A neutral physical target is not an authorized opponent.
    draw_rect(Rect2(166,-66,9,182),Color("#716653"))
    draw_circle(Vector2(170,-73),25.0,Color("#765944"))
    draw_arc(Vector2(170,-73),18.0,0.0,TAU,32,BRASS,2.0)
    draw_line(Vector2(151,-73),Vector2(189,-73),PAPER.darkened(0.35),2.0)
    draw_line(Vector2(170,-92),Vector2(170,-54),PAPER.darkened(0.35),2.0)
    draw_line(Vector2(146,111),Vector2(196,111),Color("#7e8e8e"),3.0)

    var advance := float(pose.get("advance",0.0))
    var bob := float(pose.get("bob",0.0))
    var lean := float(pose.get("lean",0.0))
    var origin := Vector2(-45+advance,bob)
    if show_mannequin:
        draw_colored_polygon(PackedVector2Array([
            origin+Vector2(-51,112),origin+Vector2(13,112),
            origin+Vector2(33,117),origin+Vector2(-62,118)
        ]),Color("#101d22",0.45))
        # Anonymous rehearsal dummy: no borrowed facial design, hair or insignia.
        _line(origin+Vector2(-17,10),origin+Vector2(-31,98),SLATE,15.0)
        _line(origin+Vector2(8,10),origin+Vector2(12,100),SLATE,15.0)
        _line(origin+Vector2(-32,102),origin+Vector2(-7,103),DEEP,13.0)
        _line(origin+Vector2(10,103),origin+Vector2(36,102),DEEP,13.0)
        draw_colored_polygon(PackedVector2Array([
            origin+Vector2(-36,-56),origin+Vector2(19+lean*0.22,-53),
            origin+Vector2(26+lean*0.35,22),origin+Vector2(-30,22)
        ]),Color("#476877"))
        draw_line(origin+Vector2(-30,-51),origin+Vector2(22+lean*0.2,-51),
            Color("#9ac5bf"),3.0)
        draw_circle(origin+Vector2(-5+lean*0.18,-80),19.0,PAPER.darkened(0.18))
        draw_rect(Rect2(origin+Vector2(-22,-91),Vector2(35,8)),Color("#283c4b"))
        _line(origin+Vector2(15,-44),origin+Vector2(39,-19),Color("#718f94"),11.0)
        _line(origin+Vector2(-30,-42),origin+Vector2(-7,-15),Color("#718f94"),11.0)
        draw_circle(origin+Vector2(39,-19),6.0,PAPER.darkened(0.2))
    
    if not bool(pose.get("motionReduced",false)):
        var energy := clampf(float(pose.get("effect",0.0)),0.0,1.0)
        if energy > 0.0:
            var action := str(pose.get("action",""))
            var family := str(pose.get("family",""))
            if action == "attack":
                if family == "rifle":
                    var muzzle := Vector2(126+advance,-27+bob)
                    draw_line(muzzle,muzzle+Vector2(28+energy*10,0),
                        Color("#f6c783",energy*0.7),3.0)
                    draw_circle(muzzle,5.0+energy*5.0,Color("#eed1a2",energy*0.5))
                elif family == "pike":
                    draw_line(Vector2(74+advance,-41+bob),
                        Vector2(145+advance,-41+bob),Color("#b5d5d2",energy*0.7),4.0)
                else:
                    draw_arc(Vector2(43+advance,-23+bob),
                        79.0,-1.15,0.42,24,Color("#d8c6a3",energy*0.66),3.0)
            if action == "guard":
                draw_arc(origin+Vector2(12,-22),56.0,-1.8,1.1,30,
                    Color("#76beb3",0.3),2.0)
    draw_line(Vector2(-218,151),Vector2(218,151),Color("#9ca99a",0.26),2.0)

func _line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
    draw_line(from,to,DEEP,width+3.0,false)
    draw_line(from,to,color,width,false)
